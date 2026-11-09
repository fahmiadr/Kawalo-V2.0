import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/cubit/list_fetch_cubit.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';

/// Keadaan dasar untuk fitur daftar insiden.
abstract class IncidentState extends Equatable implements ListFilterState {
  /// Membuat instance [IncidentState].
  const IncidentState();

  /// Accessor seragam untuk presentation layer yang menyajikan daftar entitas
  /// insiden aktif, baik dari respons server maupun fallback cadangan.
  List<IncidentEntity> get displayedIncidents => const [];

  /// Periode filter waktu yang sedang aktif (default:
  /// [AppDateFilterPeriod.today]).
  @override
  AppDateFilterPeriod get filterPeriod => AppDateFilterPeriod.today;

  /// Filter status siklus hidup insiden ('OPEN', 'RESOLVED').
  IncidentStatus? get selectedFilter => null;

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

  /// Apakah terdapat filter status insiden yang aktif.
  bool get hasActiveStatusFilter => false;

  /// Apakah terdapat filter pencarian, tanggal, atau status yang sedang aktif.
  bool get hasActiveFilter => false;

  /// Penanda apakah data bersumber dari cache/cadangan lokal.
  bool get isFromCache => false;

  @override
  List<Object?> get props => [];
}

/// Alias kompatibilitas tipe bagi [IncidentState].
typedef IncidentListState = IncidentState;

/// Keadaan awal saat modul insiden belum memuat data apa pun.
class IncidentInitial extends IncidentState {
  /// Membuat instance [IncidentInitial].
  const IncidentInitial({this.lastSync = ''});

  @override
  final String lastSync;

  @override
  List<Object?> get props => [lastSync];
}

/// Keadaan ketika sedang memuat data insiden pertama kali.
class IncidentLoading extends IncidentState {
  /// Membuat instance [IncidentLoading].
  const IncidentLoading({this.lastSync = ''});

  @override
  final String lastSync;

  @override
  List<Object?> get props => [lastSync];
}

/// Keadaan ketika data insiden berhasil dimuat.
class IncidentLoaded extends IncidentState implements ListLoadedState {
  /// Membuat instance [IncidentLoaded].
  const IncidentLoaded({
    required this.incidents,
    required this.lastSync,
    this.isFromCache = false,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.filterPeriod = AppDateFilterPeriod.today,
    this.selectedFilter,
    this.startDate,
    this.endDate,
    this.startDateIso,
    this.endDateIso,
    this.searchQuery,
  });

  /// Daftar data insiden yang berhasil diambil.
  final List<IncidentEntity> incidents;

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

  @override
  final IncidentStatus? selectedFilter;

  @override
  List<IncidentEntity> get displayedIncidents => incidents;

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
  bool get hasActiveStatusFilter => selectedFilter != null;

  @override
  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      hasActiveDateFilter ||
      hasActiveStatusFilter;

  /// Membuat salinan [IncidentLoaded] dengan atribut baru.
  IncidentLoaded copyWith({
    List<IncidentEntity>? incidents,
    String? lastSync,
    bool? isFromCache,
    bool? hasMore,
    bool? isLoadingMore,
    AppDateFilterPeriod? filterPeriod,
    IncidentStatus? selectedFilter,
    bool clearStatusFilter = false,
    DateTime? startDate,
    DateTime? endDate,
    String? startDateIso,
    String? endDateIso,
    String? searchQuery,
  }) {
    return IncidentLoaded(
      incidents: incidents ?? this.incidents,
      lastSync: lastSync ?? this.lastSync,
      isFromCache: isFromCache ?? this.isFromCache,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filterPeriod: filterPeriod ?? this.filterPeriod,
      selectedFilter: clearStatusFilter
          ? null
          : (selectedFilter ?? this.selectedFilter),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startDateIso: startDateIso ?? this.startDateIso,
      endDateIso: endDateIso ?? this.endDateIso,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    incidents,
    isFromCache,
    lastSync,
    hasMore,
    isLoadingMore,
    filterPeriod,
    selectedFilter,
    startDate,
    endDate,
    startDateIso,
    endDateIso,
    searchQuery,
  ];
}

/// Keadaan ketika terjadi kegagalan pengambilan data insiden.
class IncidentError extends IncidentState {
  /// Membuat instance [IncidentError].
  const IncidentError({
    required this.message,
    this.failure,
    this.cachedIncidents = const [],
    this.lastSync = '',
    this.filterPeriod = AppDateFilterPeriod.today,
    this.selectedFilter,
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

  /// Data cache/cadangan insiden sebelumnya agar antarmuka tidak kosong.
  final List<IncidentEntity> cachedIncidents;

  @override
  bool get isFromCache => cachedIncidents.isNotEmpty;

  @override
  final String lastSync;

  @override
  final AppDateFilterPeriod filterPeriod;

  @override
  final IncidentStatus? selectedFilter;

  @override
  List<IncidentEntity> get displayedIncidents => cachedIncidents;

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
  bool get hasActiveStatusFilter => selectedFilter != null;

  @override
  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      hasActiveDateFilter ||
      hasActiveStatusFilter;

  @override
  List<Object?> get props => [
    message,
    failure,
    cachedIncidents,
    lastSync,
    filterPeriod,
    selectedFilter,
    startDate,
    endDate,
    startDateIso,
    endDateIso,
    searchQuery,
  ];
}
