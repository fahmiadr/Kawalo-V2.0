import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/camera/app_multi_shot_camera_screen.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_attachment_preview.dart';

/// Bilah input pesan (composer bar) pada bagian bawah layar detail insiden.
///
/// Menyediakan tombol kamera multi-shot (maksimal 2 foto), input teks elastis,
/// dan tombol kirim dengan target sentuh minimal 48x48dp, mematuhi standar M3
/// serta serasi dengan komponen input Kawalo Mobile.
class IncidentComposerBar extends StatefulWidget {
  /// Membuat instance [IncidentComposerBar].
  const IncidentComposerBar({
    required this.draftMessage,
    required this.draftPhotos,
    required this.isPosting,
    required this.onMessageChanged,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onSend,
    this.onRetryPhoto,
    super.key,
  });

  /// Teks draf aktif.
  final String draftMessage;

  /// Daftar foto lampiran draf aktif.
  final List<IncidentMediaItem> draftPhotos;

  /// Penanda status sedang mengirim pesan ke server.
  final bool isPosting;

  /// Callback saat teks berubah.
  final ValueChanged<String> onMessageChanged;

  /// Callback saat foto baru ditambahkan.
  final ValueChanged<IncidentMediaItem> onAddPhoto;

  /// Callback saat foto dihapus berdasarkan ID.
  final ValueChanged<String> onRemovePhoto;

  /// Callback saat tombol kirim ditekan.
  final VoidCallback onSend;

  /// Callback untuk mengunggah ulang foto draf yang gagal berdasarkan ID.
  final ValueChanged<String>? onRetryPhoto;

  @override
  State<IncidentComposerBar> createState() => _IncidentComposerBarState();
}

class _IncidentComposerBarState extends State<IncidentComposerBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.draftMessage);
  }

  @override
  void didUpdateWidget(covariant IncidentComposerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftMessage != widget.draftMessage &&
        _textController.text != widget.draftMessage) {
      _textController.text = widget.draftMessage;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final alreadyCount = widget.draftPhotos.length;
    if (alreadyCount >= 2) return;

    final captured = await AppMultiShotCameraScreen.show(
      context,
      maxPhotos: 2,
      alreadyAttachedCount: alreadyCount,
    );

    for (final file in captured) {
      widget.onAddPhoto(IncidentMediaItem.fromAppMediaFile(file));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    final canSend =
        !widget.isPosting &&
        !widget.draftPhotos.any((p) => p.isUploading) &&
        (widget.draftMessage.trim().isNotEmpty ||
            widget.draftPhotos.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pratinjau foto lampiran sebelum dikirimkan
            if (widget.draftPhotos.isNotEmpty)
              IncidentAttachmentPreview(
                photos: widget.draftPhotos,
                onRemove: widget.onRemovePhoto,
                onRetry: widget.onRetryPhoto,
                showWaiting: widget.isPosting,
              ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space200,
                vertical: AppSpacing.space100,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Tombol Kamera Lampiran
                  Semantics(
                    button: true,
                    label:
                        'Ambil foto lampiran untuk balasan (maksimal 2 foto)',
                    child: SizedBox(
                      width: AppStateLayer.minTouchTarget,
                      height: AppStateLayer.minTouchTarget,
                      child: Center(
                        child: IconButton(
                          icon: AppSvgIcon(
                            KawaloVectors.camera01,
                            size: 24,
                            color: widget.draftPhotos.length >= 2
                                ? colorScheme.onSurface.withValues(
                                    alpha: AppStateLayer.disabledOpacity,
                                  )
                                : colorScheme.primary,
                          ),
                          tooltip: 'Ambil Foto',
                          onPressed:
                              widget.draftPhotos.length >= 2 || widget.isPosting
                              ? null
                              : _openCamera,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.hGapXs,

                  // Bidang Input Teks
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: AppRadius.borderMedium,
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        enabled: !widget.isPosting,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        style: typeScale.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tulis tanggapan atau koordinasi...',
                          hintStyle: typeScale.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space150,
                            vertical: AppSpacing.space100,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: widget.onMessageChanged,
                      ),
                    ),
                  ),
                  AppSpacing.hGapXs,

                  // Tombol Kirim Pesan
                  Semantics(
                    button: true,
                    label: 'Kirim pesan balasan',
                    child: SizedBox(
                      width: AppStateLayer.minTouchTarget,
                      height: AppStateLayer.minTouchTarget,
                      child: Center(
                        child: widget.isPosting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: AppLoadingIndicator(),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: canSend
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(
                                          alpha: AppStateLayer
                                              .disabledContainerOpacity,
                                        ),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: AppSvgIcon(
                                    KawaloVectors.arrowUp01Filled,
                                    size: 20,
                                    color: canSend
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurface.withValues(
                                            alpha:
                                                AppStateLayer.disabledOpacity,
                                          ),
                                  ),
                                  onPressed: canSend ? widget.onSend : null,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
