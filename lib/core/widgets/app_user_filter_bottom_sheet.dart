import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_radio.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_selection_tile.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Opsi personil yang dapat dipilih pada [AppUserFilterBottomSheet].
class UserFilterOption extends Equatable {
  /// Membuat instance [UserFilterOption].
  const UserFilterOption({
    required this.email,
    this.name,
    this.profilePic,
  });

  /// Alamat email unik personil.
  final String email;

  /// Nama lengkap personil (opsional).
  final String? name;

  /// URL foto profil personil (opsional).
  final String? profilePic;

  /// Label nama tampilan untuk antarmuka pengguna (fallback ke email).
  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name! : email;

  @override
  List<Object?> get props => [email, name, profilePic];
}

/// Hasil seleksi penyaringan personil dari [AppUserFilterBottomSheet].
class AppUserFilterResult extends Equatable {
  /// Membuat instance [AppUserFilterResult].
  const AppUserFilterResult({
    this.selectedUser,
    this.isReset = false,
  });

  /// Personil terpilih (null jika direset ke seluruh personil).
  final UserFilterOption? selectedUser;

  /// Menandakan apakah modal disubmit dengan pilihan reset.
  final bool isReset;

  /// Apakah terdapat personil yang dipilih.
  bool get hasSelectedUser => selectedUser != null;

  @override
  List<Object?> get props => [selectedUser, isReset];
}

/// Modal bottom sheet untuk memilih personil pembuat data (Kreator / Penulis)
/// pada level filter ADMIN dengan tata letak modal filter responsif.
class AppUserFilterBottomSheet extends StatefulWidget {
  /// Membuat instance [AppUserFilterBottomSheet].
  const AppUserFilterBottomSheet({
    super.key,
    this.users,
    this.onLoadUsers,
    this.selectedEmail,
    this.currentUserSession,
    this.debounceDuration = AppSearchBar.defaultDebounceDuration,
  });

  /// Daftar seluruh personil aktif dalam grup (opsional).
  final List<UserFilterOption>? users;

  /// Callback untuk memuat daftar personil secara asinkron saat modal dibuka.
  ///
  /// Menerima pengembalian bertipe
  /// `Future<Either<Failure, List<UserFilterOption>>>`
  /// atau `Future<List<UserFilterOption>>`.
  final Future<dynamic> Function()? onLoadUsers;

  /// Email personil yang sedang terpilih saat modal dibuka.
  final String? selectedEmail;

  /// Sesi personil aktif saat ini untuk opsi cepat 'Saya'.
  final AuthSessionEntity? currentUserSession;

  /// Durasi jeda pengetikan (debounce) sebelum pencarian diterapkan
  /// (default: [AppSearchBar.defaultDebounceDuration] = 350ms).
  final Duration debounceDuration;

  @override
  State<AppUserFilterBottomSheet> createState() =>
      _AppUserFilterBottomSheetState();
}

class _AppUserFilterBottomSheetState extends State<AppUserFilterBottomSheet> {
  late final TextEditingController _searchController;
  late String? _selectedEmail;
  String _searchQuery = '';
  bool _hasSearchText = false;
  late List<UserFilterOption> _users;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _hasSearchText = _searchController.text.isNotEmpty;
    _selectedEmail = widget.selectedEmail;
    _users = widget.users ?? const [];

    if (widget.onLoadUsers != null && widget.users == null) {
      _isLoading = true;
      _fetchUsers();
    }
  }

  @override
  void didUpdateWidget(covariant AppUserFilterBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.users != oldWidget.users && widget.users != null) {
      _users = widget.users!;
    }
    if (widget.selectedEmail != oldWidget.selectedEmail) {
      _selectedEmail = widget.selectedEmail;
    }
  }

  Future<void> _fetchUsers() async {
    if (widget.onLoadUsers == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onLoadUsers!();
      if (!mounted) return;

      if (result is Either<Failure, List<UserFilterOption>>) {
        result.fold(
          (failure) {
            setState(() {
              _isLoading = false;
              _errorMessage = failure.message;
            });
            if (context.mounted) {
              AppSnackbar.show(
                context,
                message: failure.message,
              );
            }
          },
          (fetched) {
            setState(() {
              _users = fetched;
              _isLoading = false;
              _errorMessage = null;
            });
          },
        );
      } else if (result is List<UserFilterOption>) {
        setState(() {
          _users = result;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } on Object catch (e) {
      if (!mounted) return;
      final message =
          e is Failure ? e.message : 'Gagal memuat daftar personil.';
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: message,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserFilterOption> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    final q = _searchQuery.toLowerCase().trim();
    return _users.where((user) {
      final name = user.name?.toLowerCase() ?? '';
      final email = user.email.toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  void _onSelect(String? email) {
    setState(() {
      _selectedEmail = email;
    });
  }

  UserFilterOption? _resolveSelectedUser() {
    final email = _selectedEmail;
    if (email == null) return null;

    final matched = _users.where((u) => u.email == email).firstOrNull;
    if (matched != null) return matched;

    final session = widget.currentUserSession;
    if (session != null && session.email == email) {
      return UserFilterOption(
        email: session.email,
        name: session.name,
      );
    }
    return UserFilterOption(email: email);
  }

  String? _resolveCurrentUserPic() {
    final session = widget.currentUserSession;
    if (session == null) return null;
    return _users
        .where((u) => u.email == session.email)
        .firstOrNull
        ?.profilePic;
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() {
      _hasSearchText = false;
      _searchQuery = '';
    });
  }

  void _apply() {
    final user = _resolveSelectedUser();
    Navigator.of(context).pop(
      AppUserFilterResult(
        selectedUser: user,
        isReset: _selectedEmail == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final session = widget.currentUserSession;
    final filtered = _filteredUsers;
    final currentUserPic = _resolveCurrentUserPic();

    return AppFilterBottomSheet(
      title: 'Dibuat oleh',
      expand: true,
      isResetEnabled: _selectedEmail != null,
      onReset: () => _onSelect(null),
      resetSemanticLabel: _selectedEmail != null
          ? 'Reset filter'
          : 'Filter dalam kondisi default',
      applySemanticLabel: 'Terapkan filter pembuat data',
      onApply: _apply,
      headerChild: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Kolom Pencarian Personil ───────────────────────────────
          AppSearchBar(
            controller: _searchController,
            hintText: 'Cari nama atau email',
            expandOnFocus: true,
            debounceDuration: widget.debounceDuration,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            leading: AppSvgIcon(
              KawaloVectors.search01,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            trailing: _hasSearchText
                ? [
                    AppIconButton(
                      icon: const AppSvgIcon(
                        KawaloVectors.cancel01,
                        size: 18,
                      ),
                      tooltip: 'Hapus teks pencarian',
                      semanticLabel: 'Hapus teks pencarian',
                      onPressed: _onClearSearch,
                    ),
                  ]
                : null,
            onChanged: (val) {
              final hasText = val.isNotEmpty;
              if (!hasText && _searchQuery.isNotEmpty) {
                setState(() {
                  _hasSearchText = false;
                  _searchQuery = '';
                });
              } else if (hasText != _hasSearchText) {
                setState(() {
                  _hasSearchText = hasText;
                });
              }
            },
            onSearch: (query) {
              if (_searchQuery != query) {
                setState(() {
                  _searchQuery = query;
                });
              }
            },
          ),

          AppSpacing.vGapSm,

          // ── Opsi Cepat: Siapapun (Default) & Saya ──────────────────
          _buildOptionRow(
            label: 'Siapapun',
            radioValue: null,
            onTap: () => _onSelect(null),
          ),
          if (session != null)
            _buildOptionRow(
              label: 'Saya',
              avatar: _buildAvatar(currentUserPic),
              radioValue: session.email,
              onTap: () => _onSelect(session.email),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space150),
            child: AppDivider(),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: AppLoadingIndicator(
                semanticLabel: 'Memuat daftar personil...',
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space200,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgIcon(
                          _errorMessage!.toLowerCase().contains('internet') ||
                                  _errorMessage!
                                      .toLowerCase()
                                      .contains('koneksi')
                              ? KawaloVectors.wifiOff01
                              : KawaloVectors.alertCircle,
                          size: 32,
                          color: colorScheme.error,
                        ),
                        AppSpacing.vGap100,
                        Text(
                          _errorMessage!,
                          style: typeScale.bodyMedium.copyWith(
                            color: colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.vGapSm,
                        AppButton(
                          style: AppButtonColor.tonal,
                          onPressed: _fetchUsers,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space200,
                        ),
                        child: Text(
                          'Tidak ada personil ditemukan.',
                          style: typeScale.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: filtered
                          .map(
                            (user) => _buildOptionRow(
                              label: user.displayName,
                              subtitle: user.email,
                              avatar: _buildAvatar(user.profilePic),
                              radioValue: user.email,
                              onTap: () => _onSelect(user.email),
                            ),
                          )
                          .toList(),
                    ),
    );
  }

  Widget _buildOptionRow({
    required String label,
    required String? radioValue,
    required VoidCallback onTap,
    String? subtitle,
    Widget? avatar,
  }) {
    return AppSelectionTile(
      title: label,
      subtitle: subtitle,
      leading: avatar,
      trailing: AppRadio<String?>(
        value: radioValue,
        groupValue: _selectedEmail,
        onChanged: _onSelect,
      ),
      onTap: onTap,
    );
  }

  static const Widget _avatarFallback = ClipRRect(
    borderRadius: AppRadius.borderMedium,
    child: AppSvgIcon.color(
      KawaloColorVectors.patrol3,
      size: 36,
    ),
  );

  Widget _buildAvatar(String? pic) {
    final isNetworkUrl = pic != null &&
        (pic.startsWith('http://') || pic.startsWith('https://'));

    if (isNetworkUrl) {
      return ClipRRect(
        borderRadius: AppRadius.borderMedium,
        child: CachedNetworkImage(
          imageUrl: pic,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          placeholder: (_, __) => _avatarFallback,
          errorWidget: (_, __, ___) => _avatarFallback,
        ),
      );
    }
    return _avatarFallback;
  }
}

/// Menampilkan bottom sheet pemilih personil pembuat data
/// [UserFilterOption] dengan hasil terstruktur [AppUserFilterResult].
///
/// Jika [onLoadUsers] disediakan, bottom sheet langsung terbuka seketika
/// dan memuat data personil secara asinkron dengan [AppLoadingIndicator].
Future<AppUserFilterResult?> showAppUserFilterBottomSheet({
  required BuildContext context,
  List<UserFilterOption>? users,
  Future<dynamic> Function()? onLoadUsers,
  String? selectedEmail,
  AuthSessionEntity? currentUserSession,
  double maxHeightFactor = 0.85,
  Duration debounceDuration = AppSearchBar.defaultDebounceDuration,
}) {
  return showAppBottomSheet<AppUserFilterResult>(
    context: context,
    maxHeightFactor: maxHeightFactor,
    child: AppUserFilterBottomSheet(
      users: users,
      onLoadUsers: onLoadUsers,
      selectedEmail: selectedEmail,
      currentUserSession: currentUserSession,
      debounceDuration: debounceDuration,
    ),
  );
}
