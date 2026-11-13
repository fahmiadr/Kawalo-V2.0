import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/utils/jwt_utils.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/join_channel/join_channel_params.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/join_channel/join_channel_usecase.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/start_transmission/start_transmission_params.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/start_transmission/start_transmission_usecase.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/utils/ptt_platform.dart';

class PttCubit extends Cubit<PttState> {
  PttCubit({
    required this.joinChannelUseCase,
    required this.startTransmissionUseCase,
    required this.repository,
    this.storageService,
    this.apiBaseUrl,
    this.refreshAccessToken,
  }) : super(const PttInitial()) {
    _initStreamSubscriptions();
  }

  final JoinChannelUseCase joinChannelUseCase;
  final StartTransmissionUseCase startTransmissionUseCase;
  final PttRepository repository;
  final SecureStorageService? storageService;

  /// Resolved lazily because the environment may not be loaded when the cubit
  /// is created.
  final String Function()? apiBaseUrl;

  /// Refreshes the stored access token (the `ApiClient` rotation hook then
  /// pushes the new one to the native service).
  final Future<void> Function()? refreshAccessToken;

  /// Do not hammer the refresh endpoint when the server keeps rejecting a
  /// freshly issued token (the native service retries every 2-15 s).
  static const _refreshCooldown = Duration(seconds: 20);
  DateTime? _lastRefreshAt;

  StreamSubscription<PttFloorStateEntity>? _floorSubscription;
  StreamSubscription<PttConnectionStatus>? _connectionSubscription;
  StreamSubscription<int>? _memberCountSubscription;
  StreamSubscription<Map<String, dynamic>>? _transmissionSubscription;
  StreamSubscription<void>? _authRejectedSubscription;

  void _initStreamSubscriptions() {
    _floorSubscription = repository.watchFloorState().listen((floorState) {
      final currentChannel = state.channel.copyWith(
        memberCount: floorState.memberCount,
      );

      if (floorState.isOccupied) {
        // Jika pembicara aktif adalah orang lain dan kita tidak
        // sedang mentransmisi atau sedang meminta floor
        if (state is! PttTransmitting && state is! PttRequestingFloor) {
          emit(PttListening(channel: currentChannel, floorState: floorState));
        }
      } else {
        // Channel IDLE
        if (state is! PttRequestingFloor && state is! PttTransmitting) {
          emit(PttIdle(channel: currentChannel, floorState: floorState));
        }
      }
    });

    _connectionSubscription = repository.watchConnectionStatus().listen((
      connectionStatus,
    ) {
      final updatedChannel = state.channel.copyWith(
        connectionStatus: connectionStatus,
      );

      switch (connectionStatus) {
        case PttConnectionStatus.connecting:
          emit(
            PttConnecting(
              channel: updatedChannel,
              floorState: state.floorState,
            ),
          );
        case PttConnectionStatus.connected:
          if (state is! PttTransmitting && state is! PttListening) {
            emit(
              PttIdle(channel: updatedChannel, floorState: state.floorState),
            );
          }
        case PttConnectionStatus.reconnecting:
          emit(
            PttReconnecting(
              channel: updatedChannel,
              floorState: state.floorState,
            ),
          );
        case PttConnectionStatus.disconnected:
          emit(
            PttDisconnected(
              channel: updatedChannel,
              floorState: state.floorState,
            ),
          );
      }
    });

    _memberCountSubscription = repository.watchMemberCount().listen((
      memberCount,
    ) {
      final updatedChannel = state.channel.copyWith(memberCount: memberCount);
      final updatedFloor = PttFloorStateEntity(
        status: state.floorState.status,
        speaker: state.floorState.speaker,
        memberCount: memberCount,
      );

      if (state is PttIdle) {
        emit(PttIdle(channel: updatedChannel, floorState: updatedFloor));
      } else if (state is PttListening) {
        emit(
          PttListening(
            channel: updatedChannel,
            floorState: updatedFloor,
            preemptedBy: (state as PttListening).preemptedBy,
          ),
        );
      } else if (state is PttTransmitting) {
        emit(
          PttTransmitting(
            channel: updatedChannel,
            floorState: updatedFloor,
            leaseTtlMs: (state as PttTransmitting).leaseTtlMs,
          ),
        );
      }
    });

    _transmissionSubscription = repository.watchTransmissionEvents().listen((
      event,
    ) {
      final eventState = event['state']?.toString().toUpperCase();

      if (eventState == 'GRANTED') {
        final leaseTtlMs = (event['leaseTtlMs'] as num?)?.toInt() ?? 2000;
        emit(
          PttTransmitting(
            channel: state.channel,
            floorState: state.floorState,
            leaseTtlMs: leaseTtlMs,
          ),
        );
      } else if (eventState == 'DENIED') {
        final reason = event['reason']?.toString() ?? 'CHANNEL_BUSY';
        emit(
          PttFloorDenied(
            channel: state.channel,
            floorState: state.floorState,
            reason: reason,
          ),
        );
      } else if (eventState == 'REVOKED') {
        final preemptedBy = event['preemptedBy']?.toString();
        emit(
          PttListening(
            channel: state.channel,
            floorState: state.floorState,
            preemptedBy: preemptedBy,
          ),
        );
      } else if (eventState == 'RELEASED' &&
          (state is PttTransmitting || state is PttRequestingFloor)) {
        // Sent only when the notification's Talk/Stop button ends a turn
        // that this cubit never started.
        emit(
          PttIdle(
            channel: state.channel,
            floorState: const PttFloorStateEntity.idle(),
          ),
        );
      }
    });

    _authRejectedSubscription = repository.watchAuthRejected().listen(
      (_) => unawaited(_onAuthRejected()),
    );
  }

  /// The native service reconnects on its own, but only knows the token it was
  /// given. The access token is short-lived and is rotated only by API calls,
  /// so after a long idle spell the reconnect is refused with 401 until Dart
  /// refreshes it.
  Future<void> _onAuthRejected() async {
    final refresh = refreshAccessToken;
    if (refresh == null) return;
    final now = DateTime.now();
    final last = _lastRefreshAt;
    if (last != null && now.difference(last) < _refreshCooldown) return;
    _lastRefreshAt = now;
    try {
      await refresh();
    } on Object catch (_) {}
  }

  /// Bergabung ke saluran PTT grup dengan kredensial aktif.
  Future<void> joinChannel({
    required String channelUrl,
    required String groupUid,
    required String token,
  }) async {
    emit(
      PttConnecting(
        channel: PttChannelEntity(
          groupUid: groupUid,
          connectionStatus: PttConnectionStatus.connecting,
        ),
        floorState: state.floorState,
      ),
    );

    final result = await joinChannelUseCase(
      JoinChannelParams(
        channelUrl: channelUrl,
        groupUid: groupUid,
        token: token,
      ),
    );

    result.fold((failure) {
      emit(
        PttDisconnected(
          channel: state.channel.copyWith(
            connectionStatus: PttConnectionStatus.disconnected,
          ),
          floorState: state.floorState,
          errorMessage: failure.message,
        ),
      );
    }, (_) {});
  }

  /// Joins the PTT channel of [groupUid] using the stored access token.
  ///
  /// A no-op on non-Android platforms, without a group, a usable token or base
  /// URL, or while a channel of the same group is already connecting/connected.
  /// A channel still bound to a different group (after `switch-group`) is left
  /// first. Never throws: the PTT channel is optional for the caller.
  Future<void> joinForGroup(String? groupUid) async {
    try {
      if (!isPttSupportedPlatform) return;
      if (groupUid == null || groupUid.isEmpty) return;
      final boundGroup = state.channel.groupUid;
      if (state is! PttInitial &&
          boundGroup.isNotEmpty &&
          boundGroup != groupUid) {
        await leaveChannel();
      }
      if (state is! PttInitial && state is! PttDisconnected) return;

      var token = await storageService?.getAccessToken();
      final refresh = refreshAccessToken;
      if (refresh != null &&
          token != null &&
          token.isNotEmpty &&
          JwtUtils.isExpired(token)) {
        // Offline: the join below still goes ahead and the service keeps
        // retrying; the 401 path refreshes once the network is back.
        try {
          await refresh();
        } on Object catch (_) {}
        token = await storageService?.getAccessToken();
      }
      final baseUrl = apiBaseUrl;
      if (token == null || token.isEmpty || baseUrl == null) return;

      final baseUri = Uri.parse(baseUrl());
      final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
      final portPart = baseUri.hasPort ? ':${baseUri.port}' : '';
      await joinChannel(
        channelUrl: '$wsScheme://${baseUri.host}$portPart/ws/ptt/$groupUid',
        groupUid: groupUid,
        token: token,
      );
    } on Object catch (_) {}
  }

  /// Keluar dari saluran PTT dan hentikan background service.
  Future<void> leaveChannel() async {
    await repository.leaveChannel();
    emit(const PttInitial());
  }

  /// Memeriksa dan meminta izin mikrofon jika belum diberikan.
  Future<bool> checkAndRequestMicrophonePermission() async {
    final hasPermission = await repository.hasRecordAudioPermission();
    if (!hasPermission) {
      return await repository.requestRecordAudioPermission();
    }
    return true;
  }

  /// Aksi saat tombol PTT ditekan (Touch Down / Hardware Key Down).
  Future<void> pressPttButton() async {
    // Abaikan jika sedang mentransmisi atau sedang menunggu response
    if (state is PttTransmitting || state is PttRequestingFloor) return;

    final hasPermission = await repository.hasRecordAudioPermission();
    if (!hasPermission) {
      final granted = await repository.requestRecordAudioPermission();
      if (!granted) {
        emit(
          PttFloorDenied(
            channel: state.channel,
            floorState: state.floorState,
            reason: 'PERMISSION_DENIED',
          ),
        );
        return;
      }
    }

    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    emit(
      PttRequestingFloor(
        channel: state.channel,
        floorState: state.floorState,
        requestId: requestId,
      ),
    );

    final result = await startTransmissionUseCase(
      StartTransmissionParams(requestId: requestId),
    );

    result.fold((failure) {
      emit(
        PttFloorDenied(
          channel: state.channel,
          floorState: state.floorState,
          reason: failure.message,
        ),
      );
    }, (_) {});
  }

  /// Aksi saat tombol PTT dilepas (Touch Up / Hardware Key Up).
  Future<void> releasePttButton() async {
    // Selalu kirim stop transmission untuk menjamin mikrofon native
    // berhenti dan server melepaskan floor terlepas dari state UI apapun
    await repository.stopTransmission();

    if (state is PttTransmitting || state is PttRequestingFloor) {
      emit(
        PttIdle(
          channel: state.channel,
          floorState: const PttFloorStateEntity.idle(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _floorSubscription?.cancel();
    _connectionSubscription?.cancel();
    _memberCountSubscription?.cancel();
    _transmissionSubscription?.cancel();
    _authRejectedSubscription?.cancel();
    return super.close();
  }
}
