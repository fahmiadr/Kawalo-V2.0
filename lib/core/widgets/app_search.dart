import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_shape.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3ESearchAnchor,
        M3ESearchBar,
        M3ESearchBarTheme,
        M3ESearchController,
        M3ESearchSuggestionsBuilder,
        M3ESearchViewTheme;

/// Alias untuk [M3ESearchAnchor] Material 3 Expressive.
typedef AppSearchAnchor = M3ESearchAnchor;

/// Alias untuk [M3ESearchController] Material 3 Expressive.
typedef AppSearchController = M3ESearchController;

/// Alias untuk builder saran pencarian Material 3 Expressive.
typedef AppSearchSuggestionsBuilder = M3ESearchSuggestionsBuilder;

/// Komponen Search Bar Material 3 Expressive untuk aplikasi Kawalo.
///
/// Membungkus [M3ESearchBar] secara murni (pure M3E) dengan parameter resmi:
/// - Menggunakan token bentuk bawaan [AppShape.full] dan latar
///   `surfaceContainerHigh`.
/// - Integrasi logika pencarian terpadu [onSearch] yang menangani debounce
///   otomatis, pembatalan saat Enter/Clear, dan deduplikasi query.
/// - Validasi dan sanitasi seketika (real-time) untuk mencegah spasi di awal
///   (leading whitespace) serta spasi ganda/berulang (consecutive whitespaces).
class AppSearchBar extends StatefulWidget {
  /// Membuat instance [AppSearchBar].
  const AppSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Cari...',
    this.leading,
    this.trailing,
    this.onTap,
    this.onTapOutside,
    this.onChanged,
    this.onSubmitted,
    this.onSearch,
    this.debounceDuration = defaultDebounceDuration,
    this.constraints,
    this.elevation,
    this.backgroundColor,
    this.shadowColor,
    this.surfaceTintColor,
    this.overlayColor,
    this.side,
    this.shape,
    this.padding,
    this.textStyle,
    this.hintStyle,
    this.enabled = true,
    this.autoFocus = false,
    this.readOnly = false,
    this.expandOnFocus = false,
    this.expandRestPadding,
    this.alignment,
    this.textInputAction,
    this.keyboardType,
  });

  /// Durasi debounce default untuk [onSearch] (350 milidetik).
  static const Duration defaultDebounceDuration = Duration(milliseconds: 350);

  /// Controller untuk teks pencarian.
  final TextEditingController? controller;

  /// Focus node untuk mengendalikan fokus input pencarian.
  final FocusNode? focusNode;

  /// Teks petunjuk saat kolom pencarian kosong.
  final String? hintText;

  /// Widget awalan di sebelah kiri kolom input (opsional, pure M3E).
  final Widget? leading;

  /// Kumpulan widget akhiran di sebelah kanan kolom input (opsional, pure M3E).
  final Iterable<Widget>? trailing;

  /// Callback saat bar pencarian ditekan.
  final GestureTapCallback? onTap;

  /// Callback saat area di luar bar pencarian ditekan.
  final TapRegionCallback? onTapOutside;

  /// Callback saat teks pencarian berubah.
  final ValueChanged<String>? onChanged;

  /// Callback saat pengguna menekan tombol selesai/submit pada keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Callback terpadu saat pencarian siap diproses.
  ///
  /// Dipicu secara otomatis:
  /// 1. Setelah jeda [debounceDuration] sejak pengetikan berhenti.
  /// 2. Seketika saat pengguna menekan tombol Enter/Search pada keyboard
  ///    (membatalkan debounce).
  ///
  /// Mendukung deduplikasi query otomatis: jika query yang dihasilkan sama
  /// persis dengan query terakhir yang dikirim, callback ini tidak akan
  /// dipanggil ulang.
  final ValueChanged<String>? onSearch;

  /// Durasi debounce pengetikan sebelum [onSearch] dipicu (default: 350ms).
  final Duration debounceDuration;

  /// Batasan ukuran bar pencarian.
  final BoxConstraints? constraints;

  /// Elevasi permukaan bar pencarian (default: 0).
  final WidgetStateProperty<double?>? elevation;

  /// Warna latar belakang bar pencarian (default: surfaceContainerHigh).
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Warna bayangan bar pencarian.
  final WidgetStateProperty<Color?>? shadowColor;

  /// Warna tint permukaan bar pencarian.
  final WidgetStateProperty<Color?>? surfaceTintColor;

  /// Warna overlay saat status hover/pressed.
  final WidgetStateProperty<Color?>? overlayColor;

  /// Border sisi bar pencarian.
  final WidgetStateProperty<BorderSide?>? side;

  /// Bentuk kontainer bar pencarian (default: pill).
  final WidgetStateProperty<OutlinedBorder?>? shape;

  /// Padding internal bar pencarian.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Gaya teks input pencarian.
  final TextStyle? textStyle;

  /// Gaya teks petunjuk pencarian.
  final TextStyle? hintStyle;

  /// Status aktif / non-aktif bar pencarian.
  final bool enabled;

  /// Fokus otomatis saat widget pertama kali dirender.
  final bool autoFocus;

  /// Status hanya-baca (read-only) untuk input teks.
  final bool readOnly;

  /// Apakah bar pencarian menganimasikan inset margin horizontal saat fokus.
  ///
  /// Secara default bernilai `false` untuk mencegah timbulnya margin/padding
  /// ekstra di dalam AppHomeAppBar atau layout kustom.
  final bool expandOnFocus;

  /// Inset padding horizontal saat status tidak fokus (resting).
  final double? expandRestPadding;

  /// Perataan konten teks/hint saat bar dalam status diam/kosong.
  final AlignmentGeometry? alignment;

  /// Aksi keyboard untuk input pencarian (misal: TextInputAction.search).
  final TextInputAction? textInputAction;

  /// Tipe keyboard untuk input teks.
  final TextInputType? keyboardType;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  TextEditingController? _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  Timer? _debounceTimer;
  String _lastDispatchedQuery = '';

  static final RegExp _multiSpaceRegex = RegExp(r'\s+');

  static String _sanitize(String query) {
    if (query.isEmpty) return '';
    final trimmed = query.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll(_multiSpaceRegex, ' ').toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _lastDispatchedQuery = _sanitize(_effectiveController.text);
    _effectiveController.addListener(_handleTextChange);
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      if (oldWidget.controller == null && _internalController != null) {
        _internalController!.removeListener(_handleTextChange);
        _internalController!.dispose();
        _internalController = null;
      }
      _lastDispatchedQuery = _sanitize(_effectiveController.text);
      _effectiveController.addListener(_handleTextChange);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      if (oldWidget.focusNode == null && _internalFocusNode != null) {
        _internalFocusNode!.removeListener(_handleFocusChange);
        _internalFocusNode!.dispose();
        _internalFocusNode = null;
      }
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller != null) {
      widget.controller!.removeListener(_handleTextChange);
    } else {
      _internalController?.removeListener(_handleTextChange);
      _internalController?.dispose();
    }
    if (widget.focusNode != null) {
      widget.focusNode!.removeListener(_handleFocusChange);
    } else {
      _internalFocusNode?.removeListener(_handleFocusChange);
      _internalFocusNode?.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_effectiveFocusNode.hasFocus) {
      final text = _effectiveController.text;
      final trimmedTrailing = text.trimRight();
      if (text != trimmedTrailing) {
        _effectiveController.value = TextEditingValue(
          text: trimmedTrailing,
          selection: TextSelection.collapsed(offset: trimmedTrailing.length),
        );
      }
    }
  }

  void _handleTextChange() {
    final text = _effectiveController.text;

    // 1. Validasi Real-time: Cegah spasi di awal string (leading whitespace)
    if (text.startsWith(' ')) {
      final trimmedLeading = text.trimLeft();
      final spacesRemoved = text.length - trimmedLeading.length;
      final currentOffset = _effectiveController.selection.baseOffset;
      final newOffset = currentOffset >= 0
          ? (currentOffset - spacesRemoved).clamp(0, trimmedLeading.length)
          : trimmedLeading.length;

      _effectiveController.value = TextEditingValue(
        text: trimmedLeading,
        selection: TextSelection.collapsed(offset: newOffset),
      );
      return;
    }

    // 2. Validasi Real-time: Cegah spasi ganda berturut-turut
    // (multi-whitespace)
    if (text.contains('  ')) {
      final collapsed = text.replaceAll(_multiSpaceRegex, ' ');
      final spacesRemoved = text.length - collapsed.length;
      final currentOffset = _effectiveController.selection.baseOffset;
      final newOffset = currentOffset >= 0
          ? (currentOffset - spacesRemoved).clamp(0, collapsed.length)
          : collapsed.length;

      _effectiveController.value = TextEditingValue(
        text: collapsed,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
  }

  void _dispatchSearch(String query, {bool cancelDebounce = true}) {
    if (cancelDebounce) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
    }
    if (query == _lastDispatchedQuery) {
      return;
    }
    if (query.isEmpty && _lastDispatchedQuery.isEmpty) {
      return;
    }
    _lastDispatchedQuery = query;
    widget.onSearch?.call(query);
  }

  void _handleChanged(String value) {
    final sanitized = _sanitize(value);
    widget.onChanged?.call(sanitized);

    if (widget.onSearch != null) {
      _debounceTimer?.cancel();
      if (sanitized == _lastDispatchedQuery) {
        return;
      }
      if (sanitized.isEmpty && _lastDispatchedQuery.isEmpty) {
        return;
      }
      _debounceTimer = Timer(widget.debounceDuration, () {
        _dispatchSearch(sanitized, cancelDebounce: false);
      });
    }
  }

  void _handleSubmitted(String value) {
    final sanitized = _sanitize(value);
    // Pangkas trailing whitespace seketika saat submit pada controller
    if (_effectiveController.text != sanitized) {
      _effectiveController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
    widget.onSubmitted?.call(sanitized);

    if (widget.onSearch != null) {
      _dispatchSearch(sanitized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBg = widget.backgroundColor ??
        WidgetStatePropertyAll<Color?>(colorScheme.surfaceContainerHigh);

    final effectiveShape = widget.shape ??
        const WidgetStatePropertyAll<OutlinedBorder?>(
          AppShape.full,
        );

    final effectiveElevation =
        widget.elevation ?? const WidgetStatePropertyAll<double?>(0);

    final effectiveTextStyle = widget.textStyle != null
        ? WidgetStatePropertyAll<TextStyle?>(widget.textStyle)
        : null;

    final effectiveHintStyle = widget.hintStyle != null
        ? WidgetStatePropertyAll<TextStyle?>(widget.hintStyle)
        : null;

    return M3ESearchBar(
      controller: _effectiveController,
      focusNode: _effectiveFocusNode,
      hintText: widget.hintText,
      leading: widget.leading,
      trailing: widget.trailing,
      onTap: widget.enabled ? widget.onTap : null,
      onTapOutside: widget.onTapOutside,
      onChanged: (widget.onChanged != null || widget.onSearch != null)
          ? _handleChanged
          : null,
      onSubmitted: (widget.onSubmitted != null || widget.onSearch != null)
          ? _handleSubmitted
          : null,
      constraints: widget.constraints,
      elevation: effectiveElevation,
      backgroundColor: effectiveBg,
      shadowColor: widget.shadowColor,
      surfaceTintColor: widget.surfaceTintColor,
      overlayColor: widget.overlayColor,
      side: widget.side,
      shape: effectiveShape,
      padding: widget.padding,
      textStyle: effectiveTextStyle,
      hintStyle: effectiveHintStyle,
      enabled: widget.enabled,
      autoFocus: widget.autoFocus,
      readOnly: widget.readOnly,
      expandOnFocus: widget.expandOnFocus,
      expandRestPadding: widget.expandRestPadding,
      alignment: widget.alignment ?? AlignmentDirectional.centerStart,
      textInputAction: widget.textInputAction,
      keyboardType: widget.keyboardType,
    );
  }
}
