import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/cubit/list_fetch_cubit.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';

/// Keadaan dasar untuk fitur data tamu.
abstract class GuestState extends Equatable implements ListFilterState {
  /// Membuat instance [GuestState].
  const GuestState();

  /// Accessor seragam untuk presentation layer yang menyajikan daftar data
  /// tamu aktif, baik dari respons server maupun fallback cache offline.
  List<GuestItemEntity> get displayedGuests => const [];

  /// Periode filter waktu yang sedang aktif.
  @override
  AppDateFilterPeriod get filterPeriod => AppDateFilterPeriod.today;

  /// Email pembuat data tamu yang sedang difilter (ADMIN).
  String? get filterCreatorEmail => null;

  /// Nama pembuat data tamu yang sedang difilter (ADMIN).
  String? get filterCreatorName => null;

  /// Filter status kunjungan: `true` hanya yang masih di lokasi, `false` hanya
  /// yang sudah keluar, `null` semua.
  bool? get filterIsActive => null;

  /// Apakah filter status "Masih di lokasi" sedang aktif.
  bool get hasActiveStatusFilter => false;

  /// Tanggal awal rentang kustom (jika [filterPeriod] adalah custom).
  @override
  DateTime? get startDate => null;

  /// Tanggal akhir rentang kustom (jika [filterPeriod] adalah custom).
  @override
  DateTime? get endDate => null;

  /// Representasi ISO 8601 string tanggal awal yang telah disanitasi.
  @override
  String? get startDateIso => null;

  /// Representasi ISO 8601 string tanggal akhir yang telah disanitasi.
  @override
  String? get endDateIso => null;

  /// Kata kunci pencarian saat ini.
  @override
  String? get searchQuery => null;

  /// Label waktu terakhir pembaruan data yang berhasil.
  @override
  String get lastSync => '';

  /// Apakah terdapat filter tanggal aktif selain default hari ini.
  bool get hasActiveDateFilter => false;

  /// Apakah terdapat filter pembuat data tamu yang sedang aktif.
  bool get hasActiveCreatorFilter => false;

  /// Apakah terdapat filter pencarian, tanggal, atau pembuat yang sedang aktif.
  bool get hasActiveFilter => false;

  /// Penanda apakah data bersumber dari cache lokal.
  bool get isFromCache => false;

  @override
  List<Object?> get props => [];
}

/// Keadaan awal saat modul tamu belum memuat data apa pun.
class GuestInitial extends GuestState {
  /// Membuat instance [GuestInitial].
  const GuestInitial({this.lastSync = ''});

  @override
  final String lastSync;

  @override
  List<Object?> get props => [lastSync];
}

/// Keadaan ketika sedang memuat data tamu pertama kali.
class GuestLoading extends GuestState {
  /// Membuat instance [GuestLoading].
  const GuestLoading({this.lastSync = ''});

  @override
  final String lastSync;

  @override
  List<Object?> get props => [lastSync];
}

/// Keadaan ketika data tamu berhasil dimuat.
class GuestLoaded extends GuestState implements ListLoadedState {
  /// Membuat instance [GuestLoaded].
  const GuestLoaded({
    required this.guests,
    required this.lastSync,
    this.isFromCache = false,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.filterPeriod = AppDateFilterPeriod.today,
    this.filterCreatorEmail,
    this.filterCreatorName,
    this.filterIsActive,
    this.startDate,
    this.endDate,
    this.startDateIso,
    this.endDateIso,
    this.searchQuery,
  });

  /// Daftar data tamu yang berhasil diambil.
  final List<GuestItemEntity> guests;

  @override
  final bool isFromCache;

  @override
  final String lastSync;

  /// Apakah masih terdapat data berikutnya di server untuk pagination.
  @override
  final bool hasMore;

  /// Apakah sedang memuat data halaman berikutnya (infinite scroll).
  @override
  final bool isLoadingMore;

  @override
  final AppDateFilterPeriod filterPeriod;

  /// Email pembuat data tamu yang sedang difilter.
  @override
  final String? filterCreatorEmail;

  /// Nama pembuat data tamu yang sedang difilter.
  @override
  final String? filterCreatorName;

  @override
  final bool? filterIsActive;

  @override
  bool get hasActiveStatusFilter => filterIsActive != null;

  /// Accessor seragam untuk presentation layer yang menyajikan data tamu
  /// aktif (filter `created_by` telah diterapkan pada sumber data backend atau
  /// cache offline lokal Isar).
  @override
  List<GuestItemEntity> get displayedGuests => guests;

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
  bool get hasActiveCreatorFilter =>
      filterCreatorEmail != null && filterCreatorEmail!.isNotEmpty;

  @override
  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      hasActiveDateFilter ||
      hasActiveCreatorFilter ||
      hasActiveStatusFilter;

  /// Membuat salinan [GuestLoaded] dengan atribut baru.
  GuestLoaded copyWith({
    List<GuestItemEntity>? guests,
    String? lastSync,
    bool? isFromCache,
    bool? hasMore,
    bool? isLoadingMore,
    AppDateFilterPeriod? filterPeriod,
    String? filterCreatorEmail,
    String? filterCreatorName,
    bool clearCreatorFilter = false,
    bool? filterIsActive,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
    String? searchQuery,
  }) {
    return GuestLoaded(
      guests: guests ?? this.guests,
      lastSync: lastSync ?? this.lastSync,
      isFromCache: isFromCache ?? this.isFromCache,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filterPeriod: filterPeriod ?? this.filterPeriod,
      filterCreatorEmail: clearCreatorFilter
          ? null
          : (filterCreatorEmail ?? this.filterCreatorEmail),
      filterCreatorName: clearCreatorFilter
          ? null
          : (filterCreatorName ?? this.filterCreatorName),
      filterIsActive: filterIsActive ?? this.filterIsActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startDateIso: startDateIso ?? this.startDateIso,
      endDateIso: endDateIso ?? this.endDateIso,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    guests,
    isFromCache,
    lastSync,
    hasMore,
    isLoadingMore,
    filterPeriod,
    filterCreatorEmail,
    filterCreatorName,
    filterIsActive,
    startDate,
    endDate,
    startDateIso,
    endDateIso,
    searchQuery,
  ];
}

/// Keadaan ketika terjadi kegagalan pengambilan data tamu.
class GuestError extends GuestState {
  /// Membuat instance [GuestError].
  const GuestError({
    required this.message,
    this.failure,
    this.cachedGuests = const [],
    this.lastSync = '',
    this.filterPeriod = AppDateFilterPeriod.today,
    this.filterCreatorEmail,
    this.filterCreatorName,
    this.filterIsActive,
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

  /// Data cache tamu sebelumnya (jika ada) agar antarmuka tidak kosong.
  final List<GuestItemEntity> cachedGuests;

  @override
  bool get isFromCache => cachedGuests.isNotEmpty;

  @override
  final String lastSync;

  @override
  final AppDateFilterPeriod filterPeriod;

  @override
  final String? filterCreatorEmail;

  @override
  final String? filterCreatorName;

  @override
  final bool? filterIsActive;

  @override
  bool get hasActiveStatusFilter => filterIsActive != null;

  /// Accessor seragam untuk presentation layer yang menyajikan data tamu
  /// cadangan dari cache offline saat terjadi error.
  @override
  List<GuestItemEntity> get displayedGuests => cachedGuests;

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
  bool get hasActiveCreatorFilter =>
      filterCreatorEmail != null && filterCreatorEmail!.isNotEmpty;

  @override
  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      hasActiveDateFilter ||
      hasActiveCreatorFilter ||
      hasActiveStatusFilter;

  @override
  List<Object?> get props => [
    message,
    failure,
    cachedGuests,
    lastSync,
    filterPeriod,
    filterCreatorEmail,
    filterCreatorName,
    filterIsActive,
    startDate,
    endDate,
    startDateIso,
    endDateIso,
    searchQuery,
  ];
}
