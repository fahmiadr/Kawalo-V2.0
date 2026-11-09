import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_file_tile.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_document_section.dart';
import 'package:mocktail/mocktail.dart';

class MockInformationFormCubit extends MockCubit<InformationFormState>
    implements InformationFormCubit {}

Widget _buildTestApp({
  required InformationFormCubit cubit,
  required VoidCallback onPickDocument,
  required VoidCallback onClearDocument,
  bool isSubmitting = false,
}) {
  return MaterialApp(
    builder: (context, child) =>
        M3ETheme(data: AppTheme.m3eLight(), child: child!),
    home: Scaffold(
      body: SingleChildScrollView(
        child: BlocProvider<InformationFormCubit>.value(
          value: cubit,
          child: InformationDocumentSection(
            isSubmitting: isSubmitting,
            onPickDocument: onPickDocument,
            onClearDocument: onClearDocument,
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockInformationFormCubit mockCubit;

  setUp(() {
    mockCubit = MockInformationFormCubit();
  });

  group('InformationDocumentSection Widget Tests', () {
    testWidgets('renders empty placeholder when no document is attached', (
      tester,
    ) async {
      when(() => mockCubit.state).thenReturn(const InformationFormState());

      var pickCalled = false;
      await tester.pumpWidget(
        _buildTestApp(
          cubit: mockCubit,
          onPickDocument: () => pickCalled = true,
          onClearDocument: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppFormEmptyPlaceholder), findsOneWidget);
      expect(find.text('Belum ada dokumen'), findsOneWidget);
      expect(find.byType(AppFileTile), findsNothing);

      await tester.tap(find.byType(AppFormEmptyPlaceholder));
      await tester.pump();
      expect(pickCalled, isTrue);
    });

    testWidgets('renders AppFileTile and separate right-aligned buttons when '
        'document attached', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const InformationFormState(
          documentMedia: InformationFormMediaItem(
            id: 'doc-1',
            name: 'surat_edaran.pdf',
            path: '/path/to/surat_edaran.pdf',
          ),
        ),
      );

      var pickCalled = false;
      var clearCalled = false;

      await tester.pumpWidget(
        _buildTestApp(
          cubit: mockCubit,
          onPickDocument: () => pickCalled = true,
          onClearDocument: () => clearCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan placeholder kosong tidak tampil
      expect(find.byType(AppFormEmptyPlaceholder), findsNothing);

      // Memastikan AppFileTile tampil dengan nama berkas dan format PDF
      expect(find.byType(AppFileTile), findsOneWidget);
      expect(find.text('surat_edaran.pdf'), findsOneWidget);
      expect(find.text('PDF'), findsWidgets);

      // Memastikan kedua tombol aksi berada di layar
      expect(find.text('Ubah berkas'), findsOneWidget);
      expect(find.text('Hapus berkas'), findsOneWidget);

      // Tes ketukan tombol Ubah berkas
      await tester.tap(find.text('Ubah berkas'));
      await tester.pump();
      expect(pickCalled, isTrue);

      // Tes ketukan tombol Hapus berkas
      await tester.tap(find.text('Hapus berkas'));
      await tester.pump();
      expect(clearCalled, isTrue);
    });

    testWidgets('disables action buttons when isSubmitting is true', (
      tester,
    ) async {
      when(
        () => mockCubit.state,
      ).thenReturn(const InformationFormState(feedFile: 'dokumen_lama.docx'));

      var pickCalled = false;
      var clearCalled = false;

      await tester.pumpWidget(
        _buildTestApp(
          cubit: mockCubit,
          onPickDocument: () => pickCalled = true,
          onClearDocument: () => clearCalled = true,
          isSubmitting: true,
        ),
      );
      await tester.pumpAndSettle();

      final buttons = tester.widgetList<AppButton>(find.byType(AppButton));
      for (final btn in buttons) {
        expect(btn.onPressed, isNull);
      }

      await tester.tap(find.text('Ubah berkas'));
      await tester.tap(find.text('Hapus berkas'));
      await tester.pump();

      expect(pickCalled, isFalse);
      expect(clearCalled, isFalse);
    });

    testWidgets('displays error text when feedFileError is present', (
      tester,
    ) async {
      when(() => mockCubit.state).thenReturn(
        const InformationFormState(
          feedFileError: 'Ukuran berkas melebihi batas 10MB',
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(
          cubit: mockCubit,
          onPickDocument: () {},
          onClearDocument: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ukuran berkas melebihi batas 10MB'), findsOneWidget);
    });
  });
}
