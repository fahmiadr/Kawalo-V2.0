import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_qr_payload.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_qr_scan_state.dart';

/// Resolves scanned QR codes to guests via `GET /guests/:qr_uid`.
///
/// The camera emits the same code many times per second, so a code is only
/// processed while the state is [GuestQrScanning], and the code that was just
/// handled is ignored for [cooldown] so that "Pindai lagi" with the QR still in
/// view does not loop on the same error.
class GuestQrScanCubit extends Cubit<GuestQrScanState> {
  GuestQrScanCubit({
    required GuestRepository repository,
    DateTime Function()? clock,
    this.cooldown = const Duration(seconds: 3),
  }) : _repository = repository,
       _now = clock ?? DateTime.now,
       super(const GuestQrScanning());

  final GuestRepository _repository;
  final DateTime Function() _now;
  final Duration cooldown;

  String? _lastRaw;
  DateTime? _lastHandledAt;

  Future<void> onCode(String raw) async {
    if (state is! GuestQrScanning) return;
    final lastAt = _lastHandledAt;
    if (raw == _lastRaw &&
        lastAt != null &&
        _now().difference(lastAt) < cooldown) {
      return;
    }
    _lastRaw = raw;
    _lastHandledAt = _now();

    final identifier = GuestQrPayload.tryParse(raw);
    if (identifier == null) {
      emit(const GuestQrInvalid());
      return;
    }
    await _resolve(identifier);
  }

  /// Repeats the lookup that ended in [GuestQrFailed].
  Future<void> retry() async {
    final current = state;
    if (current is GuestQrFailed) await _resolve(current.identifier);
  }

  void resumeScanning() {
    if (state is GuestQrScanning || state is GuestQrResolving) return;
    _lastHandledAt = _now();
    emit(const GuestQrScanning());
  }

  Future<void> _resolve(String identifier) async {
    emit(GuestQrResolving(identifier));
    final result = await _repository.getGuestByIdentifier(identifier);
    if (isClosed) return;
    result.fold(
      (failure) => emit(_stateFor(identifier, failure)),
      (item) => emit(GuestQrResolved(item)),
    );
  }

  GuestQrScanState _stateFor(String identifier, Failure failure) {
    if (failure is ForbiddenFailure || failure.statusCode == 403) {
      return GuestQrForbidden(failure.message);
    }
    if (failure.statusCode == 404) return GuestQrNotFound(identifier);
    return GuestQrFailed(identifier, failure.message);
  }
}
