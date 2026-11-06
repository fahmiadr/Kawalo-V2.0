import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Kontrak murni untuk memeriksa dan memantau status konektivitas
/// jaringan aplikasi pada lapisan Data dan Domain tanpa keterikatan
/// framework UI.
abstract interface class NetworkInfo {
  /// Mengembalikan `true` jika perangkat memiliki koneksi internet aktif.
  Future<bool> get isConnected;

  /// Stream perubahan status konektivitas internet secara real-time.
  Stream<bool> get onConnectivityChanged;

  /// Meminta verifikasi ulang koneksi internet aktif (active probe)
  /// dan memancarkan pembaruan status jika terjadi perubahan.
  Future<bool> checkConnectivity();

  /// Alias untuk [checkConnectivity].
  Future<bool> checkReachability();
}

/// Implementasi konkret [NetworkInfo] yang menggabungkan event interface OS
/// (`connectivity_plus`) dan active probe reachability komprehensif
/// (HTTP 204 Ping kebal Captive Portal + DNS fallback) dengan toleransi
/// handover, heartbeat periodic, sequence guard, dan single-flight
/// deduplication.
class NetworkInfoImpl implements NetworkInfo {
  /// Membuat instance [NetworkInfoImpl].
  NetworkInfoImpl({
    Connectivity? connectivity,
    Future<bool> Function()? checkConnection,
    Duration retryDelay = const Duration(milliseconds: 1200),
    Duration probeTimeout = const Duration(seconds: 2),
    Duration offlineCacheTtl = const Duration(milliseconds: 2000),
    Duration heartbeatInterval = const Duration(seconds: 30),
  })  : _connectivity = connectivity ?? Connectivity(),
        _checkConnection = checkConnection ?? _createDefaultProbe(probeTimeout),
        _retryDelay = retryDelay,
        _offlineCacheTtl = offlineCacheTtl,
        _heartbeatInterval = heartbeatInterval;

  final Connectivity _connectivity;
  final Future<bool> Function() _checkConnection;
  final Duration _retryDelay;
  final Duration _offlineCacheTtl;
  final Duration _heartbeatInterval;

  StreamController<bool>? _controller;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _heartbeatTimer;
  bool? _lastKnownState;
  DateTime? _lastProbeTimestamp;
  List<ConnectivityResult>? _lastInterfaceResults;
  int _currentProbeId = 0;
  Future<bool>? _inFlightProbe;

  static Future<bool> Function() _createDefaultProbe(Duration timeout) {
    return () => probeReachability(timeout: timeout);
  }

  /// Default active probe reachability komprehensif:
  /// 1. HTTP 204 Probe ke Google Connectivity Check (kebal Captive Portal).
  /// 2. Fallback HTTP 204 Probe ke Cloudflare (menembus DNS cache OS).
  /// 3. Fallback DNS lookup ringan ke 1.1.1.1 dan google.com jika HTTP
  ///    diblokir.
  static Future<bool> probeReachability({
    Duration timeout = const Duration(seconds: 2),
    HttpClient Function()? clientFactory,
  }) async {
    // 1. Primary: Google Generate 204
    final successGoogle204 = await _probeHttp(
      url: 'http://connectivitycheck.gstatic.com/generate_204',
      timeout: timeout,
      clientFactory: clientFactory,
    );
    if (successGoogle204) return true;

    // 2. Secondary fallback: Cloudflare Generate 204
    final successCloudflare204 = await _probeHttp(
      url: 'http://cp.cloudflare.com/generate_204',
      timeout: timeout,
      clientFactory: clientFactory,
    );
    if (successCloudflare204) return true;

    // 3. Fallback ketiga: DNS Lookup ringan jika jaringan membatasi HTTP
    try {
      final result = await InternetAddress.lookup('one.one.one.one')
          .timeout(timeout);
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on Object catch (_) {}

    try {
      final fallback = await InternetAddress.lookup('google.com')
          .timeout(timeout);
      return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
    } on Object catch (_) {
      return false;
    }
  }

  static Future<bool> _probeHttp({
    required String url,
    required Duration timeout,
    HttpClient Function()? clientFactory,
  }) async {
    try {
      final client = (clientFactory != null ? clientFactory() : HttpClient())
        ..connectionTimeout = timeout;
      try {
        final request = await client.getUrl(Uri.parse(url)).timeout(timeout);
        final response = await request.close().timeout(timeout);
        await response.drain<void>().timeout(timeout);
        return response.statusCode == 204 || response.statusCode == 200;
      } finally {
        client.close(force: true);
      }
    } on Object catch (_) {
      return false;
    }
  }

  /// Alias statis untuk kompatibilitas.
  static Future<bool> defaultCheckConnection() => probeReachability();

  @override
  Future<bool> get isConnected async {
    // 1. Fast-path: Periksa antarmuka OS (< 5 ms). Jika tidak ada antarmuka
    // sama sekali (Mode Pesawat atau Wi-Fi & Seluler mati), langsung false.
    final results = await _connectivity.checkConnectivity();
    final hasNoInterface =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);

    if (hasNoInterface) {
      _emitIfChanged(false);
      return false;
    }

    // 2. Fast-path: Jika state terakhir terverifikasi online dan antarmuka
    // masih ada, kembalikan true seketika untuk responsivitas tinggi (0 ms).
    if (_lastKnownState == true) {
      return true;
    }

    // 3. Throttle Fast-path saat offline: Jika state terakhir offline dan
    // baru saja diuji dalam jendela _offlineCacheTtl, kembalikan false
    // seketika untuk mencegah spamming active probe pada request paralel.
    if (_lastKnownState == false && _lastProbeTimestamp != null) {
      final elapsed = DateTime.now().difference(_lastProbeTimestamp!);
      if (elapsed < _offlineCacheTtl) {
        return false;
      }
    }

    // 4. Jika di luar jendela throttle offline atau belum diinisialisasi:
    // jalankan active probe untuk memverifikasi apakah internet sudah pulih.
    return await checkConnectivity();
  }

  @override
  Future<bool> checkReachability() => checkConnectivity();

  @override
  Future<bool> checkConnectivity() {
    // Single-Flight Deduplication: Gabungkan panggilan serentak ke Future sama
    if (_inFlightProbe != null) {
      return _inFlightProbe!;
    }
    final future = _performCheckConnectivity();
    _inFlightProbe = future;
    return future.whenComplete(() {
      _inFlightProbe = null;
    });
  }

  Future<bool> _performCheckConnectivity() async {
    final probeId = ++_currentProbeId;
    final results = await _connectivity.checkConnectivity();
    final hasNoInterface =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);

    if (hasNoInterface) {
      if (probeId == _currentProbeId) {
        _emitIfChanged(false);
      }
      return false;
    }

    // Ada antarmuka aktif, jalankan active probe
    var online = await _checkConnection();

    // Toleransi retry jika probe awal gagal pada antarmuka aktif
    if (!online && _retryDelay > Duration.zero) {
      await Future<void>.delayed(_retryDelay);
      if (probeId == _currentProbeId) {
        final currentResults = await _connectivity.checkConnectivity();
        final stillHasInterface = currentResults.isNotEmpty &&
            !currentResults.every((r) => r == ConnectivityResult.none);
        if (stillHasInterface) {
          online = await _checkConnection();
        }
      }
    }

    if (probeId == _currentProbeId) {
      _lastProbeTimestamp = DateTime.now();
      _emitIfChanged(online);
    }
    return online;
  }

  @override
  Stream<bool> get onConnectivityChanged {
    _controller ??= StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _controller!.stream;
  }

  void _startListening() {
    _subscription ??= _connectivity.onConnectivityChanged.listen(
      _handleOsConnectivityChanged,
    );
    _startHeartbeat();
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _stopHeartbeat();
  }

  void _startHeartbeat() {
    if (_heartbeatInterval <= Duration.zero) return;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _probeIfInterfaceActive();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _probeIfInterfaceActive() async {
    final results = await _connectivity.checkConnectivity();
    final hasActiveInterface = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
    if (hasActiveInterface) {
      await checkConnectivity();
    }
  }

  Future<void> _handleOsConnectivityChanged(
    List<ConnectivityResult> results,
  ) async {
    final probeId = ++_currentProbeId;
    final hasNoInterface =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);

    final previousResults = _lastInterfaceResults;
    _lastInterfaceResults = List<ConnectivityResult>.from(results);

    if (hasNoInterface) {
      // Antarmuka mati total (misal Mode Pesawat): langsung OFFLINE seketika
      if (probeId == _currentProbeId) {
        _emitIfChanged(false);
      }
      return;
    }

    // Deteksi apakah terjadi perpindahan tipe antarmuka
    // (handover Wi-Fi <-> Seluler)
    final isHandover = previousResults == null ||
        !listEquals(previousResults, _lastInterfaceResults);

    // Jalankan probe pertama
    var online = await _checkConnection();

    // Toleransi retry saat handover antarmuka jika probe awal gagal
    if (!online && isHandover && _retryDelay > Duration.zero) {
      await Future<void>.delayed(_retryDelay);
      if (probeId == _currentProbeId) {
        final currentResults = await _connectivity.checkConnectivity();
        final stillHasInterface = currentResults.isNotEmpty &&
            !currentResults.every((r) => r == ConnectivityResult.none);
        if (stillHasInterface) {
          online = await _checkConnection();
        }
      }
    }

    if (probeId == _currentProbeId) {
      _lastProbeTimestamp = DateTime.now();
      _emitIfChanged(online);
    }
  }

  void _emitIfChanged(bool isOnline) {
    if (_lastKnownState != isOnline) {
      _lastKnownState = isOnline;
      if (_controller != null && !_controller!.isClosed) {
        _controller!.add(isOnline);
      }
    }
  }

  /// Menutup subscription, timer, dan controller saat service di-dispose.
  void dispose() {
    _stopListening();
    _controller?.close();
    _controller = null;
  }
}
