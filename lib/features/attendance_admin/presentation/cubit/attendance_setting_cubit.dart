import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_setting_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';

enum AttendanceSettingPhase { loading, loaded, failure }

class AttendanceSettingState extends Equatable {
  const AttendanceSettingState({
    this.phase = AttendanceSettingPhase.loading,
    this.setting,
    this.draft = 0,
    this.saving = false,
    this.errorMessage,
    this.notice,
    this.noticeSeq = 0,
  });

  final AttendanceSettingPhase phase;

  /// Last value known to the server.
  final AttendanceSettingEntity? setting;

  /// Value on the slider; differs from [setting] until saved.
  final int draft;
  final bool saving;
  final String? errorMessage;

  /// One-shot message for a snackbar; [noticeSeq] makes repeats distinct.
  final String? notice;
  final int noticeSeq;

  bool get isDirty =>
      setting != null &&
      phase == AttendanceSettingPhase.loaded &&
      draft != setting!.faceMatchPercent;

  AttendanceSettingState copyWith({
    AttendanceSettingPhase? phase,
    AttendanceSettingEntity? setting,
    int? draft,
    bool? saving,
    String? errorMessage,
    String? notice,
  }) => AttendanceSettingState(
    phase: phase ?? this.phase,
    setting: setting ?? this.setting,
    draft: draft ?? this.draft,
    saving: saving ?? this.saving,
    errorMessage: errorMessage,
    notice: notice,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );

  @override
  List<Object?> get props => [
    phase,
    setting,
    draft,
    saving,
    errorMessage,
    notice,
    noticeSeq,
  ];
}

/// Loads and edits the per-group face match threshold (admin only).
class AttendanceSettingCubit extends Cubit<AttendanceSettingState> {
  AttendanceSettingCubit({required this.repository})
    : super(const AttendanceSettingState());

  static const String savedMessage = 'Pengaturan absensi disimpan';

  final AttendanceAdminRepository repository;

  Future<void> load() async {
    emit(const AttendanceSettingState());
    final result = await repository.getSetting();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        AttendanceSettingState(
          phase: AttendanceSettingPhase.failure,
          errorMessage: failure.message,
        ),
      ),
      (setting) => emit(
        AttendanceSettingState(
          phase: AttendanceSettingPhase.loaded,
          setting: setting,
          draft: setting.faceMatchPercent,
        ),
      ),
    );
  }

  void changeDraft(int percent) {
    final setting = state.setting;
    if (setting == null || state.saving) return;
    emit(
      state.copyWith(
        draft: percent.clamp(setting.minPercent, setting.maxPercent),
      ),
    );
  }

  Future<void> save() => _persist(state.draft);

  Future<void> resetToDefault() => _persist(null);

  Future<void> _persist(int? percent) async {
    if (state.setting == null || state.saving) return;
    emit(state.copyWith(saving: true));
    final result = await repository.saveSetting(percent);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(saving: false, notice: failure.message)),
      (setting) => emit(
        state.copyWith(
          saving: false,
          setting: setting,
          draft: setting.faceMatchPercent,
          notice: savedMessage,
        ),
      ),
    );
  }
}
