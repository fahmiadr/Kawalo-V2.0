import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';

/// Status state dasar untuk modul Aktifitas Operasional.
abstract class OperationalState extends Equatable {
  /// Membuat instance [OperationalState].
  const OperationalState();

  /// Periode filter waktu yang aktif.
  AppDateFilterPeriod get filterPeriod => AppDateFilterPeriod.today;

  /// Tanggal awal rentang kustom (jika [filterPeriod] adalah custom).
  DateTime? get startDate => null;

  /// Tanggal akhir rentang kustom (jika [filterPeriod] adalah custom).
  DateTime? get endDate => null;

  /// Tanggal awal ISO 8601 terstandarisasi yang dikirim ke API backend.
  String? get startDateIso => null;

  /// Tanggal akhir ISO 8601 terstandarisasi yang dikirim ke API backend.
  String? get endDateIso => null;

  /// Kata kunci pencarian saat ini.
  String? get searchQuery => null;

  /// Label waktu terakhir pembaruan data yang berhasil.
  String get lastSync => '';

  /// Apakah terdapat filter tanggal aktif selain default hari ini.
  bool get hasActiveDateFilter => false;

  /// Apakah terdapat filter pencarian atau tanggal yang sedang aktif.
  bool get hasActiveFilter => false;

  /// Penanda apakah data bersumber dari cache lokal.
  bool get isFromCache => false;

  /// Daftar data personil tenaga kerja operasional yang ditampilkan.
  List<OperationalItemEntity> get displayedOperationals => const [];

  @override
  List<Object?> get props => [];
}

/// Keadaan awal sebelum aktifitas operasional diambil.
class OperationalInitial extends OperationalState {
  /// Membuat instance [OperationalInitial].
  const OperationalInitial({this.lastSync = ''});

  @override
  final String lastSync;

  @override
  List<Object?> get props => [lastSync];
}

/// Keadaan saat memuat aktifitas operasional dari sumber data.
class OperationalLoading extends OperationalState {
  /// Membuat instance [OperationalLoading].
  const OperationalLoading({this.lastSync = ''});

  @override
  final String lastSync;

  @override
  List<Object?> get props => [lastSync];
}

/// Keadaan ketika aktifitas operasional berhasil dimuat.
class OperationalLoaded extends OperationalState {
  /// Membuat instance [OperationalLoaded].
  const OperationalLoaded({
    required this.operationals,
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

  /// Daftar data personil tenaga kerja operasional.
  final List<OperationalItemEntity> operationals;

  @override
  List<OperationalItemEntity> get displayedOperationals => operationals;

  @override
  final bool isFromCache;

  @override
  final String lastSync;

  /// Apakah masih terdapat data berikutnya di server untuk pagination.
  final bool hasMore;

  /// Apakah sedang memuat data halaman berikutnya (infinite scroll).
  final bool isLoadingMore;

  @override
  final AppDateFilterPeriod filterPeriod;

  @override
  final DateTime? startDate;

  @override
  final DateTime? endDate;

  @override
  final String? startDateIso;

  @override
  final String? endDateIso;

  @override
  final String? searchQuery;

  @override
  bool get hasActiveDateFilter =>
      filterPeriod != AppDateFilterPeriod.today ||
      startDate != null ||
      endDate != null;

  @override
  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) || hasActiveDateFilter;

  /// Membuat salinan [OperationalLoaded] dengan atribut baru.
  OperationalLoaded copyWith({
    List<OperationalItemEntity>? operationals,
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
    return OperationalLoaded(
      operationals: operationals ?? this.operationals,
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
        operationals,
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

/// Keadaan ketika terjadi kegagalan pengambilan aktifitas operasional.
class OperationalError extends OperationalState {
  /// Membuat instance [OperationalError].
  const OperationalError({
    required this.message,
    this.failure,
    this.cachedOperationals = const [],
    this.lastSync = '',
    this.filterPeriod = AppDateFilterPeriod.today,
    this.startDate,
    this.endDate,
    this.startDateIso,
    this.endDateIso,
    this.searchQuery,
  });

  /// Pesan kesalahan yang ramah pengguna.
  final String message;

  /// Objek kegagalan domain yang mendasari (opsional untuk audit tipe Failure).
  final Failure? failure;

  /// Data cache offline yang dapat ditampilkan sebagai cadangan.
  final List<OperationalItemEntity> cachedOperationals;

  @override
  List<OperationalItemEntity> get displayedOperationals => cachedOperationals;

  @override
  bool get isFromCache => cachedOperationals.isNotEmpty;

  @override
  final String lastSync;

  @override
  final AppDateFilterPeriod filterPeriod;

  @override
  final DateTime? startDate;

  @override
  final DateTime? endDate;

  @override
  final String? startDateIso;

  @override
  final String? endDateIso;

  @override
  final String? searchQuery;

  @override
  bool get hasActiveDateFilter =>
      filterPeriod != AppDateFilterPeriod.today ||
      startDate != null ||
      endDate != null;

  @override
  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) || hasActiveDateFilter;

  @override
  List<Object?> get props => [
        message,
        failure,
        cachedOperationals,
        lastSync,
        filterPeriod,
        startDate,
        endDate,
        startDateIso,
        endDateIso,
        searchQuery,
      ];
}
