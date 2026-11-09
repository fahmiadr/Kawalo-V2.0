import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/widgets/app_form_chip_group.dart';
import 'package:kawalo_mobile/core/widgets/app_form_section.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_feed_type.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';

/// Organism seksi detail publikasi (Judul, Kategori FeedType, Deskripsi isi).
class InformationPublicationSection extends StatelessWidget {
  /// Membuat instance [InformationPublicationSection].
  const InformationPublicationSection({
    required this.titleController,
    required this.textController,
    required this.titleFocusNode,
    required this.textFocusNode,
    required this.isSubmitting,
    required this.onTitleChanged,
    required this.onTextChanged,
    required this.onFeedTypeChanged,
    super.key,
  });

  /// Controller untuk input teks judul.
  final TextEditingController titleController;

  /// Controller untuk input teks deskripsi.
  final TextEditingController textController;

  /// FocusNode untuk input teks judul.
  final FocusNode titleFocusNode;

  /// FocusNode untuk input teks deskripsi.
  final FocusNode textFocusNode;

  /// Status proses submit formulir.
  final bool isSubmitting;

  /// Callback saat judul berubah.
  final ValueChanged<String> onTitleChanged;

  /// Callback saat isi deskripsi berubah.
  final ValueChanged<String> onTextChanged;

  /// Callback saat kategori feed berubah.
  final ValueChanged<String> onFeedTypeChanged;

  @override
  Widget build(BuildContext context) {
    return AppFormSection(
      title: 'Detail publikasi',
      subtitle: 'Judul, kategori, dan deskripsi isi informasi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input Judul
          BlocSelector<InformationFormCubit, InformationFormState, String?>(
            selector: (state) => state.titleError,
            builder: (context, titleError) {
              return AppTextField(
                label: 'Judul informasi',
                isRequired: true,
                variant: AppTextFieldVariant.outlined,
                controller: titleController,
                focusNode: titleFocusNode,
                enabled: !isSubmitting,
                errorText: titleError,
                textInputAction: TextInputAction.next,
                maxLength: 128,
                onChanged: onTitleChanged,
                onSubmitted: (_) => textFocusNode.requestFocus(),
              );
            },
          ),
          AppSpacing.vGap200,

          // Pemilihan Kategori FeedType
          _buildFeedTypeSelector(context),
          AppSpacing.vGap200,

          // Input Deskripsi Teks
          BlocSelector<InformationFormCubit, InformationFormState, String?>(
            selector: (state) => state.textError,
            builder: (context, textError) {
              return AppTextField(
                label: 'Isi informasi',
                variant: AppTextFieldVariant.outlined,
                controller: textController,
                focusNode: textFocusNode,
                enabled: !isSubmitting,
                errorText: textError,
                minLines: 3,
                maxLines: 6,
                maxLength: 1024,
                onChanged: onTextChanged,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTypeSelector(BuildContext context) {
    return BlocSelector<
      InformationFormCubit,
      InformationFormState,
      ({String activeType, String? error})
    >(
      selector: (state) =>
          (activeType: state.feedType, error: state.feedTypeError),
      builder: (context, data) {
        return AppFormChipGroup<String>(
          label: 'Kategori informasi',
          layout: AppFormChipGroupLayout.wrap,
          items: InformationFeedType.values.map((type) {
            return AppFormChipItem<String>(
              value: type.code,
              label: type.label,
              selected: data.activeType == type.code,
            );
          }).toList(),
          onSelected: isSubmitting ? null : onFeedTypeChanged,
          errorText: data.error,
        );
      },
    );
  }
}
