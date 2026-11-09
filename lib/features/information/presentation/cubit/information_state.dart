import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/cubit/list_fetch_cubit.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';

/// Status state dasar untuk modul Informasi / Feed.
abstract class InformationState extends Equatable implements ListFilterState {
  /// Membuat instance [InformationState].
  const InformationState();

  /// Accessor seragam untuk presentation layer yang menyajikan daftar data
  /// informasi aktif, baik dari respons server maupun fallback cache offline.
  List<InformationItemEntity> get displayedInformation => const [];

  /// Periode filter waktu yang sedang aktif.
  @override
  AppDateFilterPeriod get filterPeriod => AppDateFilterPeriod.today;

  /// Email pembuat informasi yang sedang difilter (ADMIN).
  String? get filterAuthorEmail => null;

  /// Nama pembuat informasi yang sedang difilter (ADMIN).
  String? get filterAuthorName => null;

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

  /// Apakah terdapat filter pembuat informasi yang sedang aktif.
  bool get hasActiveAuthorFilter => false;

  /// Apakah terdapat filter pencarian, tanggal, atau pembuat yang sedang aktif.
  bool get hasActiveFilter => false;

  /// Menandakan apakah data yang disajikan bersumber dari cache offline.
  bool get isFromCache => false;

  @override
  List<Object?> get props => [];
}

/// Keadaan awal sebelum data informasi diambil.
class InformationInitial extends InformationState {
  /// Membuat instance [InformationInitial].
  const InformationInitial({this.lastSync = ''});

  @override
  final String lastSync;

  @override
  List<Object?> get props => [lastSync];
}

/// Keadaan saat memuat data informasi dari sumber data.
class InformationLoading extends InformationState {
  /// Membuat instance [InformationLoading].
  const InformationLoading({this.lastSync = ''});

  @override
  final String lastSync;

  @override
  List<Object?> get props => [lastSync];
}

/// Keadaan ketika data informasi berhasil dimuat.
class InformationLoaded extends InformationState implements ListLoadedState {
  /// Membuat instance [InformationLoaded].
  const InformationLoaded({
    required this.information,
    required this.lastSync,
    this.isFromCache = false,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.filterPeriod = AppDateFilterPeriod.today,
    this.filterAuthorEmail,
    this.filterAuthorName,
    this.startDate,
    this.endDate,
    this.startDateIso,
    this.endDateIso,
    this.searchQuery,
  });

  /// Daftar data informasi / feed yang sedang ditampilkan.
  final List<InformationItemEntity> information;

  /// Menandakan apakah data informasi yang ditampilkan bersumber dari
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

  /// Email pembuat informasi yang sedang difilter.
  @override
  final String? filterAuthorEmail;

  /// Nama pembuat informasi yang sedang difilter.
  @override
  final String? filterAuthorName;

  /// Accessor seragam untuk presentation layer yang menyajikan data informasi
  /// aktif (filter `created_by` telah diterapkan pada sumber data backend atau
  /// cache offline lokal Isar).
  @override
  List<InformationItemEntity> get displayedInformation => information;

  /// Tanggal awal rentang kustom (jika [filterPeriod] adalah custom).
  @override
  final DateTime? startDate;

  /// Tanggal akhir rentang kustom (jika [filterPeriod] adalah custom).
  @override
  final DateTime? endDate;

  /// Representasi ISO 8601 string tanggal awal yang telah disanitasi.
  @override
  final String? startDateIso;

  /// Representasi ISO 8601 string tanggal akhir yang telah disanitasi.
  @override
  final String? endDateIso;

  /// Kata kunci pencarian saat ini.
  @override
  final String? searchQuery;

  /// Apakah terdapat filter tanggal aktif.
  @override
  bool get hasActiveDateFilter =>
      filterPeriod != AppDateFilterPeriod.today ||
      startDate != null ||
      endDate != null;

  /// Apakah terdapat filter pembuat informasi aktif.
  @override
  bool get hasActiveAuthorFilter =>
      filterAuthorEmail != null && filterAuthorEmail!.isNotEmpty;

  /// Apakah terdapat filter pencarian, tanggal, atau pembuat yang sedang aktif.
  @override
  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      hasActiveDateFilter ||
      hasActiveAuthorFilter;

  /// Membuat salinan [InformationLoaded] dengan modifikasi tertentu.
  InformationLoaded copyWith({
    List<InformationItemEntity>? information,
    String? lastSync,
    bool? isFromCache,
    bool? hasMore,
    bool? isLoadingMore,
    AppDateFilterPeriod? filterPeriod,
    String? filterAuthorEmail,
    String? filterAuthorName,
    bool clearAuthorFilter = false,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
    String? searchQuery,
  }) {
    return InformationLoaded(
      information: information ?? this.information,
      lastSync: lastSync ?? this.lastSync,
      isFromCache: isFromCache ?? this.isFromCache,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filterPeriod: filterPeriod ?? this.filterPeriod,
      filterAuthorEmail: clearAuthorFilter
          ? null
          : (filterAuthorEmail ?? this.filterAuthorEmail),
      filterAuthorName: clearAuthorFilter
          ? null
          : (filterAuthorName ?? this.filterAuthorName),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startDateIso: startDateIso ?? this.startDateIso,
      endDateIso: endDateIso ?? this.endDateIso,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    information,
    isFromCache,
    lastSync,
    hasMore,
    isLoadingMore,
    filterPeriod,
    filterAuthorEmail,
    filterAuthorName,
    startDate,
    endDate,
    startDateIso,
    endDateIso,
    searchQuery,
  ];
}

/// Keadaan saat terjadi kegagalan saat memuat data informasi.
class InformationError extends InformationState {
  /// Membuat instance [InformationError].
  const InformationError({
    required this.message,
    this.failure,
    this.cachedInformation = const [],
    this.lastSync = '',
    this.filterPeriod = AppDateFilterPeriod.today,
    this.filterAuthorEmail,
    this.filterAuthorName,
    this.startDate,
    this.endDate,
    this.startDateIso,
    this.endDateIso,
    this.searchQuery,
  });

  /// Pesan kesalahan teknis atau jaringan.
  final String message;

  /// Objek kegagalan domain yang mendasari (opsional untuk audit tipe Failure).
  final Failure? failure;

  /// Data cache offline yang dapat ditampilkan sebagai cadangan.
  final List<InformationItemEntity> cachedInformation;

  @override
  bool get isFromCache => cachedInformation.isNotEmpty;

  /// Label waktu sinkronisasi terakhir data offline yang ditampilkan.
  @override
  final String lastSync;

  /// Periode filter waktu saat error terjadi.
  @override
  final AppDateFilterPeriod filterPeriod;

  /// Email pembuat informasi saat error terjadi.
  @override
  final String? filterAuthorEmail;

  /// Nama pembuat informasi saat error terjadi.
  @override
  final String? filterAuthorName;

  /// Accessor seragam untuk presentation layer yang menyajikan data informasi
  /// cadangan dari cache offline saat terjadi error.
  @override
  List<InformationItemEntity> get displayedInformation => cachedInformation;

  /// Tanggal awal rentang kustom saat error terjadi.
  @override
  final DateTime? startDate;

  /// Tanggal akhir rentang kustom saat error terjadi.
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

  /// Apakah terdapat filter tanggal aktif saat error.
  @override
  bool get hasActiveDateFilter =>
      filterPeriod != AppDateFilterPeriod.today ||
      startDate != null ||
      endDate != null;

  /// Apakah terdapat filter pembuat informasi aktif saat error.
  @override
  bool get hasActiveAuthorFilter =>
      filterAuthorEmail != null && filterAuthorEmail!.isNotEmpty;

  /// Apakah terdapat filter pencarian atau tanggal yang sedang aktif
  /// saat error.
  @override
  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      hasActiveDateFilter ||
      hasActiveAuthorFilter;

  @override
  List<Object?> get props => [
    message,
    failure,
    cachedInformation,
    lastSync,
    filterPeriod,
    filterAuthorEmail,
    filterAuthorName,
    startDate,
    endDate,
    startDateIso,
    endDateIso,
    searchQuery,
  ];
}
