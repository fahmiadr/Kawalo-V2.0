import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_action_tile.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_option_tile.dart';
import 'package:kawalo_mobile/core/widgets/app_user_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_location_source_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_photo_action_bottom_sheet.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_photo_source_bottom_sheet.dart';

Widget _buildTestApp({
  required Widget child,
}) {
  return M3EMaterialApp(
    data: AppTheme.m3eLight(),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('Consistent Bottom Spacing Tests Across All 5 Bottom Sheets', () {
    setUp(resetAppBottomSheetActiveForTesting);
    tearDown(resetAppBottomSheetActiveForTesting);

    const testUsers = [
      UserFilterOption(email: 'user@kawalo.id', name: 'User Test'),
    ];

    const testSession = AuthSessionEntity(
      userId: 'usr-1',
      email: 'admin@kawalo.id',
      name: 'Admin',
      allowAdmin: true,
      allowPatrol: true,
      allowMonPatrol: true,
      role: 'ADMIN',
    );

    const testMediaItem = InformationFormMediaItem(
      id: 'photo-1',
      name: 'Dokumentasi.jpg',
      path: '/path/to/photo.jpg',
      fileSize: 1024,
    );

    void configureView(WidgetTester tester, {double bottomInset = 34.0}) {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = FakeViewPadding(bottom: bottomInset);
      tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
      addTearDown(() => tester.view.reset());
    }

    testWidgets(
      'InformationLocationSourceBottomSheet has 24dp gap to safe area '
      'and 58dp to screen edge',
      (tester) async {
        configureView(tester);

        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    InformationLocationSourceBottomSheet.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // The last element is the second AppOptionTile ("Pilih di peta")
        final lastOptionFinder =
            find.widgetWithText(AppOptionTile, 'Pilih di peta');
        expect(lastOptionFinder, findsOneWidget);

        final lastElementBottom = tester.getBottomLeft(lastOptionFinder).dy;
        const screenHeight = 800.0;
        const bottomInset = 34.0;
        const safeAreaBottom = screenHeight - bottomInset;

        // Gap from last element to safe area line must be space300 (24dp)
        final gapToSafeArea = safeAreaBottom - lastElementBottom;
        expect(gapToSafeArea, closeTo(AppSpacing.space300, 0.5));

        // Gap from last element to physical screen edge: 24dp + 34dp = 58dp
        final gapToScreenEdge = screenHeight - lastElementBottom;
        expect(
          gapToScreenEdge,
          closeTo(AppSpacing.space300 + bottomInset, 0.5),
        );
      },
    );

    testWidgets(
      'InformationPhotoSourceBottomSheet has 24dp gap to safe area '
      'and 58dp to screen edge',
      (tester) async {
        configureView(tester);

        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    InformationPhotoSourceBottomSheet.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // The last element is the second AppOptionTile ("Galeri")
        final lastOptionFinder = find.widgetWithText(AppOptionTile, 'Galeri');
        expect(lastOptionFinder, findsOneWidget);

        final lastElementBottom = tester.getBottomLeft(lastOptionFinder).dy;
        const screenHeight = 800.0;
        const bottomInset = 34.0;
        const safeAreaBottom = screenHeight - bottomInset;

        final gapToSafeArea = safeAreaBottom - lastElementBottom;
        expect(gapToSafeArea, closeTo(AppSpacing.space300, 0.5));

        final gapToScreenEdge = screenHeight - lastElementBottom;
        expect(
          gapToScreenEdge,
          closeTo(AppSpacing.space300 + bottomInset, 0.5),
        );
      },
    );

    testWidgets(
      'InformationPhotoActionBottomSheet has 24dp gap to safe area '
      'and 58dp to screen edge',
      (tester) async {
        configureView(tester);

        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => InformationPhotoActionBottomSheet.show(
                  context,
                  item: testMediaItem,
                  index: 0,
                  totalPhotos: 1,
                  onViewPhoto: () {},
                  onMakePrimary: () {},
                  onMoveLeft: () {},
                  onMoveRight: () {},
                  onDelete: () {},
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // The last element is the destructive AppActionTile ("Hapus foto ini")
        final lastActionFinder =
            find.widgetWithText(AppActionTile, 'Hapus foto ini');
        expect(lastActionFinder, findsOneWidget);

        final lastElementBottom = tester.getBottomLeft(lastActionFinder).dy;
        const screenHeight = 800.0;
        const bottomInset = 34.0;
        const safeAreaBottom = screenHeight - bottomInset;

        final gapToSafeArea = safeAreaBottom - lastElementBottom;
        expect(gapToSafeArea, closeTo(AppSpacing.space300, 0.5));

        final gapToScreenEdge = screenHeight - lastElementBottom;
        expect(
          gapToScreenEdge,
          closeTo(AppSpacing.space300 + bottomInset, 0.5),
        );
      },
    );

    testWidgets(
      'AppUserFilterBottomSheet has identical 24dp gap to safe area '
      'and 58dp to screen edge',
      (tester) async {
        configureView(tester);

        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAppUserFilterBottomSheet(
                  context: context,
                  users: testUsers,
                  currentUserSession: testSession,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // The last element is the sticky AppButton ("Terapkan")
        final applyButtonFinder = find.widgetWithText(AppButton, 'Terapkan');
        expect(applyButtonFinder, findsOneWidget);

        final lastElementBottom = tester.getBottomLeft(applyButtonFinder).dy;
        const screenHeight = 800.0;
        const bottomInset = 34.0;
        const safeAreaBottom = screenHeight - bottomInset;

        final gapToSafeArea = safeAreaBottom - lastElementBottom;
        expect(gapToSafeArea, closeTo(AppSpacing.space300, 0.5));

        final gapToScreenEdge = screenHeight - lastElementBottom;
        expect(
          gapToScreenEdge,
          closeTo(AppSpacing.space300 + bottomInset, 0.5),
        );
      },
    );

    testWidgets(
      'AppDateFilterBottomSheet has identical 24dp gap to safe area '
      'and 58dp to screen edge',
      (tester) async {
        configureView(tester);

        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAppDateFilterBottomSheet(
                  context: context,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // The last element is the sticky AppButton ("Terapkan")
        final applyButtonFinder = find.widgetWithText(AppButton, 'Terapkan');
        expect(applyButtonFinder, findsOneWidget);

        final lastElementBottom = tester.getBottomLeft(applyButtonFinder).dy;
        const screenHeight = 800.0;
        const bottomInset = 34.0;
        const safeAreaBottom = screenHeight - bottomInset;

        final gapToSafeArea = safeAreaBottom - lastElementBottom;
        expect(gapToSafeArea, closeTo(AppSpacing.space300, 0.5));

        final gapToScreenEdge = screenHeight - lastElementBottom;
        expect(
          gapToScreenEdge,
          closeTo(AppSpacing.space300 + bottomInset, 0.5),
        );
      },
    );
  });
}
