import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
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
    final tones = KawaloTones.of(context);
    final canSend =
        !widget.isPosting &&
        !widget.draftPhotos.any((p) => p.isUploading) &&
        (widget.draftMessage.trim().isNotEmpty ||
            widget.draftPhotos.isNotEmpty);
    final canAddPhoto = widget.draftPhotos.length < 2 && !widget.isPosting;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tones.background,
        border: Border(top: BorderSide(color: tones.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.draftPhotos.isNotEmpty)
              IncidentAttachmentPreview(
                photos: widget.draftPhotos,
                onRemove: widget.onRemovePhoto,
                onRetry: widget.onRetryPhoto,
                showWaiting: widget.isPosting,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    iconSize: 24,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    tooltip: 'Ambil foto lampiran (maksimal 2 foto)',
                    icon: Icon(
                      Icons.photo_camera_outlined,
                      color: canAddPhoto ? tones.ink : tones.ink3,
                    ),
                    onPressed: canAddPhoto ? _openCamera : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        maxHeight: 120,
                      ),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: tones.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: tones.line, width: 1.5),
                      ),
                      child: TextField(
                        controller: _textController,
                        enabled: !widget.isPosting,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: tones.ink, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Tulis balasan…',
                          hintStyle: TextStyle(color: tones.ink3, fontSize: 16),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: widget.onMessageChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    enabled: canSend,
                    label: 'Kirim pesan balasan',
                    excludeSemantics: true,
                    child: Material(
                      color: canSend ? tones.inc.color : tones.surface2,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: canSend ? widget.onSend : null,
                        child: SizedBox.square(
                          dimension: 48,
                          child: Center(
                            child: widget.isPosting
                                ? SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: tones.ink3,
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    size: 22,
                                    color: canSend ? tones.inc.on : tones.ink3,
                                  ),
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
