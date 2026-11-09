/// @docImport 'package:dio/dio.dart';
/// @docImport 'package:kawalo_mobile/core/widgets/app_static_map.dart';
/// @docImport 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/app_map_picker_dialog.dart';
library;

import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';

/// Status hasil eksekusi operasi reverse geocoding.
///
/// Digunakan oleh [ReverseGeocodeResult] untuk mengidentifikasi kategori
/// keberhasilan atau penyebab spesifik kegagalan secara deterministik.
enum ReverseGeocodeStatus {
  /// Alamat berhasil ditemukan dan diformat menjadi teks yang dapat dibaca.
  success,

  /// Koordinat berhasil diproses namun tidak menghasilkan nama jalan fisik.
  noResult,

  /// Kegagalan koneksi soket, resolusi DNS, atau galat jaringan eksternal.
  networkError,

  /// Batas waktu koneksi atau penerimaan respons HTTP terlampaui.
  timeout,

  /// Permintaan dibatalkan melalui [AppCancellationToken] atau gestur peta.
  cancelled,

  /// Frekuensi permintaan melebihi kuota resmi OpenStreetMap (HTTP 429).
  rateLimited,
}

/// Representasi nilai objek murni (*immutable value object*) hasil reverse
/// geocoding dari suatu titik koordinat geografis.
///
/// Menyediakan informasi diagnostik lengkap melalui [status], pasangan
/// koordinat geografis [latitude] dan [longitude], serta representasi alamat
/// [address] jika operasi berhasil.
///
/// Mewarisi [Equatable] untuk mendukung kesetaraan nilai (*value equality*)
/// guna mencegah render ulang yang tidak perlu (*targeted rebuilds*) pada
/// komponen antarmuka seperti [AppMapPickerDialog] dan [AppStaticMap].
///
/// Contoh dekonstruksi status menggunakan *pattern matching*:
/// ```dart
/// final result = await geocodeService.reverseGeocode(
///   latitude: -6.2088,
///   longitude: 106.8456,
/// );
///
/// final displayText = switch (result.status) {
///   ReverseGeocodeStatus.success => result.address!,
///   ReverseGeocodeStatus.noResult => 'Alamat tidak ditemukan',
///   ReverseGeocodeStatus.cancelled => 'Resolusi alamat dibatalkan',
///   ReverseGeocodeStatus.timeout => 'Batas waktu koneksi terlampaui',
///   ReverseGeocodeStatus.rateLimited => 'Batas kuota peta terlampaui',
///   ReverseGeocodeStatus.networkError => 'Gangguan koneksi internet',
/// };
/// ```
@immutable
final class ReverseGeocodeResult extends Equatable {
  /// Membuat instans [ReverseGeocodeResult] secara eksplisit.
  ///
  /// Digunakan ketika seluruh properti diinisialisasi secara manual. Untuk
  /// kemudahan, gunakan factory constructor seperti
  /// [ReverseGeocodeResult.success] atau [ReverseGeocodeResult.failure].
  const ReverseGeocodeResult({
    required this.status,
    required this.latitude,
    required this.longitude,
    this.address,
    this.errorMessage,
  });

  /// Membuat instans [ReverseGeocodeResult] berstatus sukses.
  ///
  /// Menerima koordinat [latitude], [longitude], dan teks alamat [address].
  const ReverseGeocodeResult.success({
    required double latitude,
    required double longitude,
    required String address,
  }) : this(
          status: ReverseGeocodeStatus.success,
          latitude: latitude,
          longitude: longitude,
          address: address,
        );

  /// Membuat instans [ReverseGeocodeResult] ketika koordinat tidak berpenghuni.
  ///
  /// Menandakan server berhasil dihubungi namun tidak menemukan nama jalan
  /// atau alamat fisik pada koordinat [latitude] dan [longitude].
  const ReverseGeocodeResult.noResult({
    required double latitude,
    required double longitude,
  }) : this(
          status: ReverseGeocodeStatus.noResult,
          latitude: latitude,
          longitude: longitude,
        );

  /// Membuat instans [ReverseGeocodeResult] ketika operasi dibatalkan.
  ///
  /// Dihasilkan ketika permintaan jaringan dibatalkan melalui token
  /// pembatalan [AppCancellationToken] atau gestur peta interaktif.
  const ReverseGeocodeResult.cancelled({
    required double latitude,
    required double longitude,
  }) : this(
          status: ReverseGeocodeStatus.cancelled,
          latitude: latitude,
          longitude: longitude,
        );

  /// Membuat instans [ReverseGeocodeResult] ketika terjadi kegagalan jaringan.
  ///
  /// Memerlukan penentuan [status] kegagalan yang spesifik beserta pesan
  /// diagnostik opsional [errorMessage].
  const ReverseGeocodeResult.failure({
    required double latitude,
    required double longitude,
    required ReverseGeocodeStatus status,
    String? errorMessage,
  }) : this(
          status: status,
          latitude: latitude,
          longitude: longitude,
          errorMessage: errorMessage,
        );

  /// Status eksekusi reverse geocoding.
  final ReverseGeocodeStatus status;

  /// Titik lintang koordinat geografis yang diresolusi.
  final double latitude;

  /// Titik bujur koordinat geografis yang diresolusi.
  final double longitude;

  /// Teks representasi alamat jalan yang telah diformat.
  ///
  /// Bernilai `null` jika resolusi alamat gagal, dibatalkan, atau koordinat
  /// tidak memiliki nama jalan fisik.
  final String? address;

  /// Pesan diagnostik kesalahan jika status menunjukkan kegagalan.
  final String? errorMessage;

  /// Menyatakan apakah alamat berhasil diperoleh.
  bool get isSuccess => status == ReverseGeocodeStatus.success;

  /// Menyatakan apakah operasi dibatalkan oleh pengguna atau gestur.
  bool get isCancelled => status == ReverseGeocodeStatus.cancelled;

  /// Menyatakan apakah resolusi alamat mengalami kegagalan riil (bukan batal).
  bool get isFailure => !isSuccess && !isCancelled;

  /// Pasangan koordinat geografis `(latitude, longitude)`.
  (double latitude, double longitude) get coordinates => (latitude, longitude);

  /// Menghasilkan salinan baru dari [ReverseGeocodeResult] dengan properti
  /// terpilih.
  ///
  /// Menerapkan pola sentinel agar penugasan nilai `null` pada [address]
  /// atau [errorMessage] dapat dilakukan secara eksplisit.
  ReverseGeocodeResult copyWith({
    ReverseGeocodeStatus? status,
    double? latitude,
    double? longitude,
    Object? address = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return ReverseGeocodeResult(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address == _sentinel ? this.address : address as String?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        latitude,
        longitude,
        address,
        errorMessage,
      ];

  static const Object _sentinel = Object();
}

/// Kontrak layanan reverse geocoding untuk mengonversi koordinat geografis.
///
/// Menyediakan antarmuka murni yang independen dari pustaka jaringan pihak
/// ketiga. Komponen antarmuka seperti [AppMapPickerDialog] dan [AppStaticMap]
/// mengonsumsi kontrak ini untuk menampilkan nama alamat fisik secara ramah
/// pengguna.
///
/// Mengikuti prinsip Inversion of Control (IoC), pengujian unit dapat
/// menginjeksi implementasi tiruan (*mock*) atau fungsional murni tanpa
/// ketergantungan jaringan eksternal.
///
/// Contoh injeksi dependensi murni:
/// ```dart
/// final ReverseGeocodeService service = OsmNominatimReverseGeocodeService(
///   dio: customDioClient,
/// );
/// final result = await service.reverseGeocode(
///   latitude: -6.2088,
///   longitude: 106.8456,
/// );
/// ```
abstract interface class ReverseGeocodeService {
  /// Instans singleton bersama untuk konsumsi cepat di lingkungan produksi.
  static ReverseGeocodeService get instance =>
      OsmNominatimReverseGeocodeService.instance;

  /// Meresolusi koordinat [latitude] dan [longitude] menjadi alamat fisik.
  ///
  /// Mengembalikan [ReverseGeocodeResult] yang deterministik dan tidak pernah
  /// melempar unhandled exception (*fail-safe command invocation*).
  ///
  /// Operasi jaringan dapat dibatalkan sewaktu-waktu melalui [cancelToken].
  Future<ReverseGeocodeResult> reverseGeocode({
    required double latitude,
    required double longitude,
    AppCancellationToken? cancelToken,
  });
}

/// Implementasi [ReverseGeocodeService] berbasis OpenStreetMap Nominatim.
///
/// Menggunakan API resmi OSM Nominatim
/// (https://nominatim.openstreetmap.org/reverse) dengan kepatuhan penuh
/// terhadap kebijakan penggunaan OSM:
/// - Menerapkan GoF Strategy Pattern sebagai strategi konkret penyedia peta.
/// - Mengimplementasikan *single-flight request deduplication* pada permintaan
///   paralel untuk mencegah beban berlebih (*rate limit* 1 req/detik).
/// - Menyimpan hasil resolusi di in-memory cache berbasis instans dengan
///   kebijakan penggusuran LRU (*Least Recently Used*) berkapasitas terbatas.
/// - Menyediakan identitas [userAgent] resmi Kawalo Mobile pada setiap header.
/// - Mendukung pembatalan permintaan jaringan melalui [AppCancellationToken].
final class OsmNominatimReverseGeocodeService implements ReverseGeocodeService {
  /// Membuat instans [OsmNominatimReverseGeocodeService].
  ///
  /// Parameter [dio] memungkinkan injeksi klien HTTP kustom untuk pengujian
  /// terisolasi. Jika tidak diberikan, klien [Dio] default akan dibuat secara
  /// otomatis dengan batas waktu [defaultTimeout] dan header [userAgent].
  ///
  /// Parameter [maxCacheEntries] menentukan batas kapasitas maksimum entri
  /// cache in-memory (default: [defaultMaxCacheEntries]).
  OsmNominatimReverseGeocodeService({
    Dio? dio,
    int maxCacheEntries = defaultMaxCacheEntries,
  })  : _maxCacheEntries = maxCacheEntries,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: defaultTimeout,
                receiveTimeout: defaultTimeout,
                headers: const <String, String>{
                  'User-Agent': userAgent,
                },
              ),
            );

  /// Batas waktu default untuk koneksi dan respons HTTP (5 detik).
  static const Duration defaultTimeout = Duration(seconds: 5);

  /// Identitas User-Agent resmi Kawalo Mobile untuk OpenStreetMap Nominatim.
  static const String userAgent = 'KawaloMobile/1.0 (com.kawalo.app)';

  /// Kapasitas maksimum entri cache koordinat in-memory (LRU bounded).
  static const int defaultMaxCacheEntries = 100;

  /// URL endpoint layanan OpenStreetMap Nominatim Reverse Geocoding.
  static const String nominatimEndpoint =
      'https://nominatim.openstreetmap.org/reverse';

  /// Instans singleton bersama untuk penggunaan produksi terpadu.
  static final OsmNominatimReverseGeocodeService instance =
      OsmNominatimReverseGeocodeService();

  final Dio _dio;
  final int _maxCacheEntries;

  /// Cache in-memory berbasis instance dengan penggusuran FIFO/LRU.
  final LinkedHashMap<String, ReverseGeocodeResult> _cache =
      LinkedHashMap<String, ReverseGeocodeResult>();

  /// Peta permintaan in-flight untuk deduplikasi single-flight paralel.
  final Map<String, Future<ReverseGeocodeResult>> _inFlight =
      <String, Future<ReverseGeocodeResult>>{};

  /// Menghapus seluruh entri cache in-memory.
  void clearCache() => _cache.clear();

  /// Menghasilkan format kunci koordinat berpresisi 6 digit desimal (~0.1m).
  static String formatCoordinateKey(double lat, double lng) =>
      '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

  @override
  Future<ReverseGeocodeResult> reverseGeocode({
    required double latitude,
    required double longitude,
    AppCancellationToken? cancelToken,
  }) async {
    final cacheKey = formatCoordinateKey(latitude, longitude);

    final cached = _cache[cacheKey];
    if (cached != null) {
      // Perbarui posisi LRU (pindahkan entri ke urutan paling baru)
      _cache.remove(cacheKey);
      _cache[cacheKey] = cached;
      return cached;
    }

    final inFlightRequest = _inFlight[cacheKey];
    if (inFlightRequest != null) {
      return await inFlightRequest;
    }

    final future = _executeReverseGeocode(
      cacheKey: cacheKey,
      latitude: latitude,
      longitude: longitude,
      cancelToken: cancelToken,
    );

    _inFlight[cacheKey] = future;
    try {
      return await future;
    } finally {
      unawaited(_inFlight.remove(cacheKey));
    }
  }

  Future<ReverseGeocodeResult> _executeReverseGeocode({
    required String cacheKey,
    required double latitude,
    required double longitude,
    AppCancellationToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        nominatimEndpoint,
        queryParameters: <String, dynamic>{
          'lat': latitude,
          'lon': longitude,
          'format': 'jsonv2',
          'accept-language': 'id',
        },
        cancelToken: cancelToken?.toDio(),
      );

      final data = response.data;
      if (data == null) {
        return ReverseGeocodeResult.noResult(
          latitude: latitude,
          longitude: longitude,
        );
      }

      final formatted = _formatAddress(data);
      if (formatted != null && formatted.isNotEmpty) {
        final result = ReverseGeocodeResult.success(
          latitude: latitude,
          longitude: longitude,
          address: formatted,
        );
        _putCache(cacheKey, result);
        return result;
      }

      return ReverseGeocodeResult.noResult(
        latitude: latitude,
        longitude: longitude,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return ReverseGeocodeResult.cancelled(
          latitude: latitude,
          longitude: longitude,
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return ReverseGeocodeResult.failure(
          latitude: latitude,
          longitude: longitude,
          status: ReverseGeocodeStatus.timeout,
          errorMessage: 'Batas waktu koneksi ke layanan alamat terlampaui.',
        );
      }
      if (e.response?.statusCode == 429) {
        return ReverseGeocodeResult.failure(
          latitude: latitude,
          longitude: longitude,
          status: ReverseGeocodeStatus.rateLimited,
          errorMessage:
              'Batas frekuensi permintaan ke layanan peta terlampaui.',
        );
      }
      return ReverseGeocodeResult.failure(
        latitude: latitude,
        longitude: longitude,
        status: ReverseGeocodeStatus.networkError,
        errorMessage: 'Gagal menghubungi server layanan alamat.',
      );
    } on Object catch (e) {
      return ReverseGeocodeResult.failure(
        latitude: latitude,
        longitude: longitude,
        status: ReverseGeocodeStatus.networkError,
        errorMessage: e.toString(),
      );
    }
  }

  void _putCache(String key, ReverseGeocodeResult value) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  /// Memformat JSON kembalian Nominatim menjadi alamat padat dan informatif.
  String? _formatAddress(Map<String, dynamic> data) {
    final address = switch (data['address']) {
      final Map<String, dynamic> map => map,
      final Map<dynamic, dynamic> map => map.cast<String, dynamic>(),
      _ => null,
    };
    if (address != null) {
      final parts = <String>[];

      final road = _firstNonEmpty(
        address,
        const ['road', 'pedestrian', 'footway', 'street'],
      );
      if (road != null) parts.add(road);

      final suburb = _firstNonEmpty(
        address,
        const ['suburb', 'village', 'neighbourhood', 'quarter'],
      );
      if (suburb != null) parts.add(suburb);

      final city = _firstNonEmpty(
        address,
        const ['city', 'town', 'city_district', 'municipality'],
      );
      if (city != null) parts.add(city);

      final state = _firstNonEmpty(address, const ['state']);
      if (state != null) parts.add(state);

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }

    return switch (data['display_name']) {
      final String name when name.trim().isNotEmpty => name.trim(),
      _ => null,
    };
  }

  /// Mengambil nilai teks pertama yang tidak kosong dari daftar kandidat kunci.
  static String? _firstNonEmpty(
    Map<String, dynamic> source,
    List<String> candidateKeys,
  ) {
    for (final key in candidateKeys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
