import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';

/// Button that downloads one protected photo and opens it in the shared image
/// viewer, deleting the temporary file afterwards.
class AttendancePhotoButton extends StatefulWidget {
  const AttendancePhotoButton({
    required this.label,
    required this.load,
    required this.discard,
    super.key,
  });

  final String label;

  /// Returns the local file path of the downloaded photo.
  final Future<Either<Failure, String>> Function() load;

  final Future<void> Function(String path) discard;

  @override
  State<AttendancePhotoButton> createState() => _AttendancePhotoButtonState();
}

class _AttendancePhotoButtonState extends State<AttendancePhotoButton> {
  bool _isLoading = false;

  Future<void> _open() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final result = await widget.load();
    if (!mounted) {
      final stale = result.toNullable();
      if (stale != null) await widget.discard(stale);
      return;
    }
    setState(() => _isLoading = false);
    await result.fold(
      (failure) async => AppSnackbar.show(context, message: failure.message),
      (path) async {
        await AppImageViewer.show(context, imageUrls: [path]);
        await widget.discard(path);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      style: AppButtonColor.tonal,
      shape: AppButtonShape.square,
      onPressed: _isLoading ? null : _open,
      child: Text(_isLoading ? 'Memuat foto...' : widget.label),
    );
  }
}
