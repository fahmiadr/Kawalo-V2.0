import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/cubit/list_fetch_cubit.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';

/// Status state dasar untuk modul Data Absensi.
abstract class AttendanceState extends Equatable implements ListFilterState {
  /// Membuat instance [AttendanceState].
  const AttendanceState();

  /// Periode filter waktu yang sedang aktif.
  @override
  AppDateFilterPeriod get filterPeriod => AppDateFilterPeriod.today;

  /// Tanggal awal rentang kustom (jika [filterPeriod] adalah custom).
  @override
  DateTime? get startDate => null;

  /// Tanggal akhir rentang kustom (jika [filterPeriod] adalah custom).
  @override
  DateTime? get endDate => null;

  /// Tanggal awal filter dalam format ISO 8601 string yang telah disanitasi.
  @override
  String? get startDateIso => null;

  /// Tanggal akhir filter dalam format ISO 8601 string yang telah disanitasi.
  @override
  String? get endDateIso => null;

  /// Kata kunci pencarian yang sedang aktif.
  @override
  String? get searchQuery => null;

  /// Label waktu sinkronisasi terakhir data dengan server.
  @override
  String get lastSync => '';

  /// Apakah terdapat filter tanggal aktif selain default hari ini.
  bool get hasActiveDateFilter => false;

  /// Apakah terdapat filter pencarian atau tanggal yang sedang aktif.
  bool get hasActiveFilter => false;

  /// Menandakan apakah data yang disajikan bersumber dari cache offline.
  bool get isFromCache => false;

  /// Daftar data catatan absensi yang ditampilkan.
  List<AttendanceItemEntity> get displayedAttendances => const [];

  @override
  List<Object?> get props => [];
}

/// Keadaan awal sebelum data absensi diambil.
class AttendanceInitial extends AttendanceState {
  /// Membuat instance [AttendanceInitial].
  const AttendanceInitial({this.lastSync = ''});

  @override
  final String lastSync;

  @override
  List<Object?> get props => [lastSync];
}

/// Keadaan saat memuat data absensi dari sumber data.
class AttendanceLoading extends AttendanceState {
  /// Membuat instance [AttendanceLoading].
  const AttendanceLoading({this.lastSync = ''});

  @override
  final String lastSync;

  @override
  List<Object?> get props => [lastSync];
}

/// Keadaan ketika data absensi berhasil dimuat.
class AttendanceLoaded extends AttendanceState implements ListLoadedState {
  /// Membuat instance [AttendanceLoaded].
  const AttendanceLoaded({
    required this.attendances,
    required this.lastSync,
    this.isFromCache = false,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.filterPeriod = AppDateFilterPeriod.today,
    this.startDate,
    this.endDate,
    this.startDateIso,
    this.endDateIso,
    this.searchQuery,
  });

  /// Daftar data catatan absensi.
  final List<AttendanceItemEntity> attendances;

  @override
  List<AttendanceItemEntity> get displayedAttendances => attendances;

  /// Menandakan apakah data absensi yang ditampilkan bersumber dari
  /// cache lokal.
  @override
  final bool isFromCache;

  /// Label waktu terakhir pembaruan data pada klien.
  @override
  final String lastSync;

  /// Apakah masih terdapat data berikutnya di server untuk pagination.
  @override
  final bool hasMore;

  /// Apakah sedang memuat data halaman berikutnya (infinite scroll).
  @override
  final bool isLoadingMore;

  /// Periode filter waktu yang sedang aktif.
  @override
  final AppDateFilterPeriod filterPeriod;

  /// Tanggal awal rentang kustom (jika [filterPeriod] adalah custom).
  @override
  final DateTime? startDate;

  /// Tanggal akhir rentang kustom (jika [filterPeriod] adalah custom).
  @override
  final DateTime? endDate;

  /// Tanggal awal filter dalam format ISO 8601 string yang telah disanitasi.
  @override
  final String? startDateIso;

  /// Tanggal akhir filter dalam format ISO 8601 string yang telah disanitasi.
  @override
  final String? endDateIso;

  /// Kata kunci pencarian yang sedang aktif.
  @override
  final String? searchQuery;

  /// Menandakan apakah filter tanggal selain "Hari ini" sedang aktif.
  @override
  bool get hasActiveDateFilter =>
      filterPeriod != AppDateFilterPeriod.today ||
      startDate != null ||
      endDate != null;

  /// Menandakan apakah terdapat filter aktif baik kata kunci maupun tanggal.
  @override
  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) || hasActiveDateFilter;

  /// Membuat salinan [AttendanceLoaded] dengan perubahan parsial.
  AttendanceLoaded copyWith({
    List<AttendanceItemEntity>? attendances,
    String? lastSync,
    bool? isFromCache,
    bool? hasMore,
    bool? isLoadingMore,
    AppDateFilterPeriod? filterPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
    String? searchQuery,
  }) {
    return AttendanceLoaded(
      attendances: attendances ?? this.attendances,
      lastSync: lastSync ?? this.lastSync,
      isFromCache: isFromCache ?? this.isFromCache,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filterPeriod: filterPeriod ?? this.filterPeriod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startDateIso: startDateIso ?? this.startDateIso,
      endDateIso: endDateIso ?? this.endDateIso,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        attendances,
        isFromCache,
        lastSync,
        hasMore,
        isLoadingMore,
        filterPeriod,
        startDate,
        endDate,
        startDateIso,
        endDateIso,
        searchQuery,
      ];
}

/// Keadaan saat terjadi kegagalan saat memuat data absensi.
class AttendanceError extends AttendanceState {
  /// Membuat instance [AttendanceError].
  const AttendanceError({
    required this.message,
    this.failure,
    this.cachedAttendances = const [],
    this.lastSync = '',
    this.filterPeriod = AppDateFilterPeriod.today,
    this.startDate,
    this.endDate,
    this.startDateIso,
    this.endDateIso,
    this.searchQuery,
  });

  /// Pesan kesalahan yang dapat dipahami oleh pengguna.
  final String message;

  /// Objek kegagalan domain yang mendasari (opsional untuk audit tipe Failure).
  final Failure? failure;

  /// Data cache offline yang dapat ditampilkan sebagai cadangan.
  final List<AttendanceItemEntity> cachedAttendances;

  @override
  List<AttendanceItemEntity> get displayedAttendances => cachedAttendances;

  @override
  bool get isFromCache => cachedAttendances.isNotEmpty;

  /// Label waktu sinkronisasi terakhir data offline yang ditampilkan.
  @override
  final String lastSync;

  /// Periode filter saat error terjadi.
  @override
  final AppDateFilterPeriod filterPeriod;

  /// Tanggal awal filter saat error terjadi.
  @override
  final DateTime? startDate;

  /// Tanggal akhir filter saat error terjadi.
  @override
  final DateTime? endDate;

  /// Tanggal awal filter ISO 8601 string saat error terjadi.
  @override
  final String? startDateIso;

  /// Tanggal akhir filter ISO 8601 string saat error terjadi.
  @override
  final String? endDateIso;

  /// Query pencarian saat error terjadi.
  @override
  final String? searchQuery;

  /// Menandakan apakah filter tanggal selain "Hari ini" sedang aktif saat
  /// error.
  @override
  bool get hasActiveDateFilter =>
      filterPeriod != AppDateFilterPeriod.today ||
      startDate != null ||
      endDate != null;

  /// Menandakan apakah terdapat filter aktif baik kata kunci maupun tanggal
  /// saat error.
  @override
  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) || hasActiveDateFilter;

  @override
  List<Object?> get props => [
        message,
        failure,
        cachedAttendances,
        lastSync,
        filterPeriod,
        startDate,
        endDate,
        startDateIso,
        endDateIso,
        searchQuery,
      ];
}
