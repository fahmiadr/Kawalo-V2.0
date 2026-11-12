import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/repositories/schedule_admin_repository.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/schedule_repeat.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_state.dart';

/// `error_code` of the "other shift that day" conflict that
/// [ScheduleFormState.canOverwrite] keys on (409 and bulk skip entries).
const otherShiftErrorCode = 'SCHEDULE_OTHER_SHIFT';

/// Loads the pickers and saves one schedule, an edit, or a repeated batch.
class ScheduleFormCubit extends Cubit<ScheduleFormState> {
  ScheduleFormCubit({required this.repository, required this.groupRepository})
    : super(const ScheduleFormState());

  final ScheduleAdminRepository repository;
  final GroupRepository groupRepository;

  Future<void> loadOptions() async {
    emit(const ScheduleFormState());
    final (members, shifts) = await (
      groupRepository.getMembers(),
      repository.getShifts(),
    ).wait;
    if (isClosed) return;
    final failure =
        members.fold<Failure?>((f) => f, (_) => null) ??
        shifts.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      emit(
        state.copyWith(
          status: ScheduleFormStatus.optionsError,
          message: failure.message,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: ScheduleFormStatus.ready,
        members: members.getOrElse((_) => const []),
        shifts: shifts.getOrElse((_) => const []),
      ),
    );
  }

  /// Creates [entries] (one request when there is one, bulk otherwise), or
  /// moves the row [editingId] to the single entry. [overwrite] replaces a
  /// different shift on the same day; the screen sets it only after the admin
  /// confirmed.
  Future<void> submit(
    List<ScheduleEntry> entries, {
    String? editingId,
    bool overwrite = false,
  }) async {
    if (entries.isEmpty) return;
    if (entries.length > maxBulkItems) {
      emit(
        state.copyWith(
          status: ScheduleFormStatus.failed,
          message: 'Maksimal $maxBulkItems jadwal sekali simpan.',
        ),
      );
      return;
    }
    emit(state.copyWith(status: ScheduleFormStatus.saving));

    final Either<Failure, BulkScheduleResult?> outcome;
    if (editingId != null) {
      outcome = (await repository.update(
        editingId,
        entries.first,
      )).map((_) => null);
    } else if (entries.length == 1) {
      outcome = (await repository.create(
        entries.first,
        overwrite: overwrite,
      )).map((_) => null);
    } else {
      outcome = await repository.createBulk(entries, overwrite: overwrite);
    }
    if (isClosed) return;

    outcome.fold(
      (failure) => emit(
        state.copyWith(
          status: ScheduleFormStatus.failed,
          message: failure.message,
          canOverwrite:
              editingId == null &&
              failure.statusCode == 409 &&
              failure.errorCode == otherShiftErrorCode,
        ),
      ),
      (bulk) => emit(
        state.copyWith(
          status: ScheduleFormStatus.saved,
          message: bulk == null ? 'Jadwal disimpan.' : bulkSummary(bulk),
          result: bulk,
        ),
      ),
    );
  }
}

/// "12 jadwal dibuat, 2 dilewati karena sudah ada."
String bulkSummary(BulkScheduleResult r) {
  final parts = <String>[
    '${r.created} jadwal dibuat',
    if (r.replaced > 0) '${r.replaced} jadwal lama diganti',
  ];
  final text = parts.join(', ');
  if (r.skipped == 0) return '$text.';
  return '$text, ${r.skipped} dilewati karena sudah ada atau bentrok.';
}

extension BulkScheduleResultX on BulkScheduleResult {
  /// Items left out because the person already works another shift that day.
  int get otherShiftSkips =>
      skippedItems.where((s) => s.code == otherShiftErrorCode).length;
}
