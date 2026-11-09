import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';

/// Offline guard, confirmation, delete call and result snackbar shared by the
/// "delete selected" action of list screens. [noun] is the lower-case
/// Indonesian name of the records, e.g. "data tamu".
///
/// [delete] runs after confirmation; its context reads happen at call time.
/// [onDeleting] and [onDone] are where the screen flips its deleting flag and
/// clears the selection; [onDone] is skipped when the screen is gone.
Future<void> runListBatchDelete({
  required BuildContext context,
  required Set<String> ids,
  required String noun,
  required Future<Either<Failure, Object?>> Function() delete,
  required VoidCallback onDeleting,
  required VoidCallback onDone,
}) async {
  if (ids.isEmpty) return;

  final isDeviceOffline =
      context.read<ConnectivityCubit?>()?.state == ConnectivityStatus.offline;
  if (isDeviceOffline) {
    AppSnackbar.show(
      context,
      message: 'Tidak dapat menghapus $noun saat offline.',
    );
    return;
  }

  final count = ids.length;
  final confirmed = await showAppConfirmationDialog(
    context: context,
    title: 'Hapus $count $noun?',
    message: '$count $noun terpilih akan dihapus secara permanen.',
  );

  if (!(confirmed ?? false) || !context.mounted) return;

  onDeleting();
  final result = await delete();
  if (!context.mounted) return;
  onDone();

  result.fold(
    (failure) {
      AppSnackbar.show(context, message: failure.message);
    },
    (_) {
      AppSnackbar.show(context, message: '$count $noun berhasil dihapus.');
    },
  );
}
