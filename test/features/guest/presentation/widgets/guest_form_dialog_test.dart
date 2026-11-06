import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_params.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_master_guest_types/get_master_guest_types_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_master_guest_types/get_master_guest_types_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form_dialog.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateGuestUseCase extends Mock implements CreateGuestUseCase {}

class MockUpdateGuestUseCase extends Mock implements UpdateGuestUseCase {}

class MockGetMasterGuestTypesUseCase extends Mock
    implements GetMasterGuestTypesUseCase {}

class MockGetGroupMembersUseCase extends Mock
    implements GetGroupMembersUseCase {}

class MockMediaPickerService extends Mock implements MediaPickerService {}

void main() {
  late MockCreateGuestUseCase mockCreateGuestUseCase;
  late MockUpdateGuestUseCase mockUpdateGuestUseCase;
  late MockGetMasterGuestTypesUseCase mockGetMasterTypesUseCase;
  late MockGetGroupMembersUseCase mockGetGroupMembersUseCase;
  late MockMediaPickerService mockMediaPicker;

  const sampleMasterTypes = [
    MasterGuestTypeEntity(id: '1', uid: 'uid-1', name: 'TAMU'),
    MasterGuestTypeEntity(id: '2', uid: 'uid-2', name: 'KURIR'),
  ];

  const sampleGroupMembers = [
    GroupMemberEntity(
      name: 'Wisnu Wijayadi',
      email: 'wisnu@kawalo.id',
    ),
  ];

  const sampleGuest = GuestItemEntity(
    id: '101',
    guestName: 'Hendra Budiman',
    guestDestination: 'Blok B1 No. 3',
    guestType: 'TAMU',
    guestIdentity: '3201987654320001',
    guestIdentityType: 'KTP',
    guestNumber: 'B 9999 ZZ',
    guestPurpose: 'Bertamu',
    guestAddress: 'Bandung',
    guestToUserEmail: 'wisnu@kawalo.id',
  );

  setUpAll(() {
    registerFallbackValue(
      const CreateGuestParams(
        guestName: 'Dummy',
        guestDestination: 'Dummy Dest',
        guestType: 'TAMU',
      ),
    );
    registerFallbackValue(
      const UpdateGuestParams(
        id: '101',
      ),
    );
    registerFallbackValue(
      const GetMasterGuestTypesParams(),
    );
    registerFallbackValue(
      const GetGroupMembersParams(),
    );
  });

  setUp(() {
    mockCreateGuestUseCase = MockCreateGuestUseCase();
    mockUpdateGuestUseCase = MockUpdateGuestUseCase();
    mockGetMasterTypesUseCase = MockGetMasterGuestTypesUseCase();
    mockGetGroupMembersUseCase = MockGetGroupMembersUseCase();
    mockMediaPicker = MockMediaPickerService();

    when(() => mockGetMasterTypesUseCase(any()))
        .thenAnswer((_) async => const Right(sampleMasterTypes));
    when(() => mockGetGroupMembersUseCase(any()))
        .thenAnswer((_) async => const Right(sampleGroupMembers));
  });

  GuestFormCubit buildCubit({GuestItemEntity? initialItem}) {
    return GuestFormCubit(
      createGuestUseCase: mockCreateGuestUseCase,
      updateGuestUseCase: mockUpdateGuestUseCase,
      getMasterGuestTypesUseCase: mockGetMasterTypesUseCase,
      getGroupMembersUseCase: mockGetGroupMembersUseCase,
      initialItem: initialItem,
    );
  }

  Widget buildTestWidget({
    GuestFormCubit? cubit,
    GuestItemEntity? initialItem,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      builder: (context, child) => M3ETheme(
        data: AppTheme.m3eLight(),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              if (initialItem != null) {
                GuestFormDialog.showUpdate(
                  context,
                  item: initialItem,
                  formCubit: cubit,
                  mediaPickerService: mockMediaPicker,
                );
              } else {
                GuestFormDialog.showCreate(
                  context,
                  formCubit: cubit,
                  mediaPickerService: mockMediaPicker,
                );
              }
            },
            child: const Text('Buka Formulir'),
          ),
        ),
      ),
    );
  }

  group('GuestFormDialog Widget Tests', () {
    testWidgets('renders create form with Tambah tamu title and all sections',
        (tester) async {
      final cubit = buildCubit();

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.tap(find.text('Buka Formulir'));
      await tester.pumpAndSettle();

      expect(find.byType(GuestFormDialog), findsOneWidget);
      expect(find.text('Tambah tamu'), findsOneWidget);
      expect(find.text('Informasi tamu & identitas'), findsOneWidget);
      expect(find.text('Tujuan & detail kunjungan'), findsOneWidget);
      expect(find.text('Dokumentasi foto tamu'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders update form with Edit data tamu title and values',
        (tester) async {
      final cubit = buildCubit(initialItem: sampleGuest);

      await tester.pumpWidget(
        buildTestWidget(
          cubit: cubit,
          initialItem: sampleGuest,
        ),
      );
      await tester.tap(find.text('Buka Formulir'));
      await tester.pumpAndSettle();

      expect(find.byType(GuestFormDialog), findsOneWidget);
      expect(find.text('Edit data tamu'), findsOneWidget);
      expect(find.text('Hendra Budiman'), findsOneWidget);
      expect(find.text('Blok B1 No. 3'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('tapping Close button pops dialog when not dirty',
        (tester) async {
      final cubit = buildCubit();

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.tap(find.text('Buka Formulir'));
      await tester.pumpAndSettle();

      expect(find.byType(GuestFormDialog), findsOneWidget);

      final closeButton = find.bySemanticsLabel('Tutup');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(GuestFormDialog), findsNothing);

      await cubit.close();
    });

    testWidgets('shows confirmation dialog on close when dirty',
        (tester) async {
      final cubit = buildCubit();

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.tap(find.text('Buka Formulir'));
      await tester.pumpAndSettle();

      // Enter name to make form dirty
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Nama tamu*'),
        'Nama Baru',
      );
      await tester.pumpAndSettle();

      // Tap close button
      await tester.tap(find.bySemanticsLabel('Tutup'));
      await tester.pumpAndSettle();

      // Expect confirmation dialog
      expect(find.byType(AppConfirmationDialog), findsOneWidget);
      expect(find.text('Buang perubahan?'), findsOneWidget);

      // Tap cancel -> dialog stays open
      await tester.tap(find.text('Lanjut mengisi'));
      await tester.pumpAndSettle();

      expect(find.byType(GuestFormDialog), findsOneWidget);

      // Tap close again and confirm discard
      await tester.tap(find.bySemanticsLabel('Tutup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buang'));
      await tester.pumpAndSettle();

      expect(find.byType(GuestFormDialog), findsNothing);

      await cubit.close();
    });

    testWidgets('submitting in create mode calls createGuest and closes',
        (tester) async {
      when(() => mockCreateGuestUseCase(any()))
          .thenAnswer((_) async => const Right(sampleGuest));

      final cubit = buildCubit();

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.tap(find.text('Buka Formulir'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AppTextField, 'Nama tamu*'),
        'Hendra Budiman',
      );
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Destinasi tujuan *'),
        'Blok B1 No. 3',
      );

      // Select guest type from dropdown
      cubit.onGuestTypeChanged('TAMU');
      await tester.pumpAndSettle();

      // Tap Simpan
      await tester.tap(find.widgetWithText(AppButton, 'Simpan'));
      await tester.pumpAndSettle();

      verify(() => mockCreateGuestUseCase(any())).called(1);
      expect(find.byType(GuestFormDialog), findsNothing);

      await cubit.close();
    });

    testWidgets(
        'chip selection adheres to one selection and shows Tanpa Identitas '
        'as selected initially', (tester) async {
      final cubit = buildCubit();

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.tap(find.text('Buka Formulir'));
      await tester.pumpAndSettle();

      // Initially, Tanpa Identitas should be selected
      final initialTanpaIdChip = tester.widget<AppChip>(
        find.widgetWithText(AppChip, 'Tanpa Identitas'),
      );
      final initialKtpChip = tester.widget<AppChip>(
        find.widgetWithText(AppChip, 'KTP'),
      );
      expect(initialTanpaIdChip.selected, isTrue);
      expect(initialKtpChip.selected, isFalse);

      // Tap KTP
      await tester.tap(find.text('KTP'));
      await tester.pumpAndSettle();

      final ktpChipAfterTap = tester.widget<AppChip>(
        find.widgetWithText(AppChip, 'KTP'),
      );
      final tanpaIdChipAfterTap = tester.widget<AppChip>(
        find.widgetWithText(AppChip, 'Tanpa Identitas'),
      );
      expect(ktpChipAfterTap.selected, isTrue);
      expect(tanpaIdChipAfterTap.selected, isFalse);
      expect(cubit.state.identityType, 'KTP');

      // Tap KTP again -> should NOT deselect (One Selection behavior)
      await tester.tap(find.text('KTP'));
      await tester.pumpAndSettle();

      final ktpChipAfterSecondTap = tester.widget<AppChip>(
        find.widgetWithText(AppChip, 'KTP'),
      );
      expect(ktpChipAfterSecondTap.selected, isTrue);
      expect(cubit.state.identityType, 'KTP');

      // Enter identity number
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Nomor identitas (KTP) *'),
        '12345678',
      );
      await tester.pumpAndSettle();
      expect(cubit.state.identityNumber, '12345678');

      // Tap Tanpa Identitas sentinel -> selects Tanpa Identitas & clears number
      await tester.tap(find.text('Tanpa Identitas'));
      await tester.pumpAndSettle();

      final finalTanpaIdChip = tester.widget<AppChip>(
        find.widgetWithText(AppChip, 'Tanpa Identitas'),
      );
      final finalKtpChip = tester.widget<AppChip>(
        find.widgetWithText(AppChip, 'KTP'),
      );
      expect(finalTanpaIdChip.selected, isTrue);
      expect(finalKtpChip.selected, isFalse);
      expect(cubit.state.identityType, isNull);
      expect(cubit.state.identityNumber, isEmpty);

      await cubit.close();
    });

    testWidgets(
        'dropdown menus do not contain sentinel and support clearing selection',
        (tester) async {
      final cubit = buildCubit();

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.tap(find.text('Buka Formulir'));
      await tester.pumpAndSettle();

      // Ensure 'Tanpa Tuan Rumah' sentinel option does not exist
      expect(find.text('Tanpa Tuan Rumah'), findsNothing);

      // Verify selecting guest type and clearing
      cubit.onGuestTypeChanged('TAMU');
      await tester.pumpAndSettle();
      expect(cubit.state.guestType, 'TAMU');

      cubit.onGuestTypeChanged('');
      await tester.pumpAndSettle();
      expect(cubit.state.guestType, isEmpty);

      // Verify selecting host and clearing
      cubit.onHostEmailChanged('wisnu@veranda.com');
      await tester.pumpAndSettle();
      expect(cubit.state.hostEmail, 'wisnu@veranda.com');

      cubit.onHostEmailChanged(null);
      await tester.pumpAndSettle();
      expect(cubit.state.hostEmail, isNull);

      await cubit.close();
    });

    testWidgets('renders safely under 200% dynamic text scaling',
        (tester) async {
      final cubit = buildCubit();

      await tester.pumpWidget(
        buildTestWidget(cubit: cubit, textScale: 2),
      );
      await tester.tap(find.text('Buka Formulir'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GuestFormDialog), findsOneWidget);

      await cubit.close();
    });
  });
}
