import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';

/// Representasi status konektivitas jaringan global aplikasi.
enum ConnectivityStatus {
  /// Terhubung ke jaringan internet aktif.
  online,

  /// Tidak terhubung atau koneksi internet terputus.
  offline,
}

/// Ekstensi pembantu untuk [ConnectivityStatus].
extension ConnectivityStatusX on ConnectivityStatus {
  /// Bernilai `true` jika perangkat terhubung ke internet.
  bool get isOnline => this == ConnectivityStatus.online;

  /// Bernilai `true` jika perangkat kehilangan koneksi internet.
  bool get isOffline => this == ConnectivityStatus.offline;
}

/// Cubit pengelola status konektivitas global (App State) pada
/// Presentation Layer.
///
/// Mengikuti arsitektur **Unidirectional Data Flow (UDF)**:
/// Mengonsumsi stream dan status koneksi dari [NetworkInfo]
/// (Data / Core Infrastructure) dan memancarkan [ConnectivityStatus] yang
/// immutable untuk dikonsumsi oleh UI Layer.
///
/// Secara otomatis menyinkronkan status koneksi saat siklus hidup aplikasi
/// berubah kembali ke foreground ([AppLifecycleState.resumed]).
class ConnectivityCubit extends Cubit<ConnectivityStatus>
    with WidgetsBindingObserver {
  /// Membuat instance [ConnectivityCubit].
  ConnectivityCubit({
    NetworkInfo? networkInfo,
    ConnectivityStatus initialState = ConnectivityStatus.online,
    bool autoStart = true,
    Future<bool> Function()? checkConnection,
  }) : _ownsNetworkInfo = networkInfo == null,
       _networkInfo =
           networkInfo ?? NetworkInfoImpl(checkConnection: checkConnection),
       super(initialState) {
    if (autoStart) {
      _startMonitoring();
    }
  }

  final bool _ownsNetworkInfo;
  final NetworkInfo _networkInfo;
  StreamSubscription<bool>? _networkSubscription;

  /// Bernilai `true` jika status saat ini adalah online.
  bool get isOnline => state.isOnline;

  /// Bernilai `true` jika status saat ini adalah offline.
  bool get isOffline => state.isOffline;

  void _startMonitoring() {
    // Daftarkan observer siklus hidup aplikasi untuk re-probe saat resumed
    try {
      WidgetsBinding.instance.addObserver(this);
    } on Object catch (_) {}

    // Jalankan pemeriksaan awal
    checkNow();

    // Dengarkan perubahan konektivitas dari NetworkInfo (UDF)
    _networkSubscription = _networkInfo.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-probe koneksi seketika saat aplikasi kembali ke foreground
      checkNow();
    }
  }

  void _handleConnectivityChanged(bool isConnected) {
    final newStatus = isConnected
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
    if (state != newStatus) {
      emit(newStatus);
    }
  }

  /// Menjalankan pemeriksaan konektivitas aktif secara manual (Active Probe)
  /// dan memancarkan perubahan state jika berbeda.
  Future<void> checkNow() async {
    final isConnected = await _networkInfo.checkConnectivity();
    final newStatus = isConnected
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
    if (state != newStatus) {
      emit(newStatus);
    }
  }

  /// Alias yang lebih deskriptif untuk [checkNow].
  Future<void> checkConnectivity() => checkNow();

  /// Menyetel status konektivitas secara langsung untuk keperluan pengujian.
  @visibleForTesting
  void setStatus(ConnectivityStatus status) {
    if (state != status) {
      emit(status);
    }
  }

  @override
  Future<void> close() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } on Object catch (_) {}
    _networkSubscription?.cancel();
    if (_ownsNetworkInfo && _networkInfo is NetworkInfoImpl) {
      _networkInfo.dispose();
    }
    return super.close();
  }
}
