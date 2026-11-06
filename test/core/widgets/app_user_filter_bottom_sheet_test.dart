import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Left, Right;
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_user_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';

void main() {
  group('AppUserFilterBottomSheet Widget Tests', () {
    tearDown(AppSnackbar.hideCurrent);
    const testUsers = [
      GroupMemberEntity(
        email: 'budi@kawalo.id',
        name: 'Budi Santoso',
      ),
      GroupMemberEntity(
        email: 'siti@kawalo.id',
        name: 'Siti Rahmawati',
      ),
    ];

    const testSession = AuthSessionEntity(
      userId: 'usr-1',
      email: 'admin@kawalo.id',
      name: 'Admin Utama',
      allowAdmin: true,
      allowPatrol: true,
      allowMonPatrol: true,
      role: 'ADMIN',
    );

    testWidgets('renders users and returns selected user on apply',
        (tester) async {
      AppUserFilterResult? selected;

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    selected = await showAppUserFilterBottomSheet(
                      context: context,
                      users: testUsers,
                      currentUserSession: testSession,
                    );
                  },
                  child: const Text('Buka'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(find.text('Dibuat oleh'), findsOneWidget);
      expect(find.text('Siapapun'), findsOneWidget);
      expect(find.text('Saya'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Rahmawati'), findsOneWidget);

      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.isReset, isFalse);
      expect(selected!.hasSelectedUser, isTrue);
      expect(selected!.selectedUser!.email, 'budi@kawalo.id');
    });

    testWidgets('filters list by search query', (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: AppUserFilterBottomSheet(
              users: testUsers,
              currentUserSession: testSession,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Rahmawati'), findsOneWidget);

      await tester.enterText(find.byType(AppSearchBar), 'siti');
      await tester.pumpAndSettle();

      expect(find.text('Siapapun'), findsOneWidget);
      expect(find.text('Saya'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Siti Rahmawati'), findsOneWidget);
    });

    testWidgets('debounces search input before filtering user list',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: AppUserFilterBottomSheet(
              users: testUsers,
              currentUserSession: testSession,
              debounceDuration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Rahmawati'), findsOneWidget);

      await tester.enterText(find.byType(AppSearchBar), 'siti');

      // Sebelum durasi debounce selesai (100ms < 300ms): kedua user masih ada
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Rahmawati'), findsOneWidget);

      // Setelah durasi debounce terlewati: filter diterapkan
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Siti Rahmawati'), findsOneWidget);
    });

    testWidgets('resets selection when reset link is tapped', (tester) async {
      AppUserFilterResult? appliedResult;

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    appliedResult = await showAppUserFilterBottomSheet(
                      context: context,
                      users: testUsers,
                      selectedEmail: 'budi@kawalo.id',
                      currentUserSession: testSession,
                    );
                  },
                  child: const Text('Buka'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(find.text('Reset'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(appliedResult, isNotNull);
      expect(appliedResult!.isReset, isTrue);
      expect(appliedResult!.hasSelectedUser, isFalse);
      expect(appliedResult!.selectedUser, isNull);
    });

    testWidgets('selects "Saya" option and applies current session user',
        (tester) async {
      AppUserFilterResult? appliedResult;

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    appliedResult = await showAppUserFilterBottomSheet(
                      context: context,
                      users: testUsers,
                      currentUserSession: testSession,
                    );
                  },
                  child: const Text('Buka'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saya'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(appliedResult, isNotNull);
      expect(appliedResult!.isReset, isFalse);
      expect(appliedResult!.hasSelectedUser, isTrue);
      expect(appliedResult!.selectedUser!.email, 'admin@kawalo.id');
    });

    testWidgets('clears search text via clear button in search bar',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: AppUserFilterBottomSheet(
              users: testUsers,
              currentUserSession: testSession,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Siapapun'), findsOneWidget);
      expect(find.text('Saya'), findsOneWidget);

      await tester.enterText(find.byType(AppSearchBar), 'siti');
      await tester.pumpAndSettle();

      expect(find.text('Siapapun'), findsOneWidget);
      expect(find.text('Saya'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Siti Rahmawati'), findsOneWidget);

      final clearButton = find.byType(AppIconButton);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Siapapun'), findsOneWidget);
      expect(find.text('Saya'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('shows loading indicator when onLoadUsers is fetching',
        (tester) async {
      final completer = Completer<List<GroupMemberEntity>>();

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAppUserFilterBottomSheet(
                    context: context,
                    onLoadUsers: () => completer.future,
                    currentUserSession: testSession,
                  ),
                  child: const Text('Buka'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pump(); // Sheet dibuka seketika, proses load mulai

      expect(find.byType(AppLoadingIndicator), findsOneWidget);

      completer.complete(testUsers);
      await tester.pumpAndSettle();

      expect(find.byType(AppLoadingIndicator), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Rahmawati'), findsOneWidget);
    });

    testWidgets(
      'shows AppSnackbar and error view when onLoadUsers returns '
      'Left(NoInternetFailure)',
      (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAppUserFilterBottomSheet(
                    context: context,
                    onLoadUsers: () async =>
                        const Left<Failure, List<GroupMemberEntity>>(
                      NoInternetFailure('Koneksi internet tidak tersedia.'),
                    ),
                    currentUserSession: testSession,
                  ),
                  child: const Text('Buka'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      // Snackbar umpan balik muncul dengan pesan kegagalan internet
      expect(find.byType(AppSnackbar), findsOneWidget);
      expect(find.text('Koneksi internet tidak tersedia.'), findsWidgets);

      // Tampilan error di dalam bottom sheet beserta tombol Coba lagi
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets(
      'shows AppSnackbar and error view when onLoadUsers returns '
      'Left(ServerFailure)',
      (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAppUserFilterBottomSheet(
                    context: context,
                    onLoadUsers: () async =>
                        const Left<Failure, List<GroupMemberEntity>>(
                      ServerFailure('Terjadi kendala pada server.'),
                    ),
                    currentUserSession: testSession,
                  ),
                  child: const Text('Buka'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(find.byType(AppSnackbar), findsOneWidget);
      expect(find.text('Terjadi kendala pada server.'), findsWidgets);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('retries fetching users when "Coba lagi" is tapped',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var callCount = 0;

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAppUserFilterBottomSheet(
                    context: context,
                    onLoadUsers: () async {
                      callCount++;
                      if (callCount == 1) {
                        return const Left<Failure, List<GroupMemberEntity>>(
                          NoInternetFailure(),
                        );
                      }
                      return const Right<Failure, List<GroupMemberEntity>>(
                        testUsers,
                      );
                    },
                    currentUserSession: testSession,
                  ),
                  child: const Text('Buka'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(callCount, equals(1));
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);

      // Dismiss snackbar agar tidak menutupi tombol interaktif
      AppSnackbar.hideCurrent();
      await tester.pumpAndSettle();

      // Tekan tombol coba lagi
      await tester.ensureVisible(find.text('Coba lagi'));
      await tester.tap(
        find.widgetWithText(AppButton, 'Coba lagi'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(callCount, equals(2));
      expect(find.text('Coba lagi'), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Rahmawati'), findsOneWidget);
    });

    testWidgets('shows AppSnackbar when onLoadUsers throws unhandled exception',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAppUserFilterBottomSheet(
                    context: context,
                    onLoadUsers: () async =>
                        throw Exception('Koneksi terputus tiba-tiba'),
                    currentUserSession: testSession,
                  ),
                  child: const Text('Buka'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(find.byType(AppSnackbar), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets(
        'renders default app filter bottom sheet within max height constraint',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAppUserFilterBottomSheet(
                    context: context,
                    users: testUsers,
                    currentUserSession: testSession,
                  ),
                  child: const Text('Buka'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      final sheetInitialSize = tester.getSize(
        find.byKey(const ValueKey('app_bottom_sheet_constrained_box')),
      );
      expect(sheetInitialSize.height, lessThanOrEqualTo(850.0));
      expect(find.text('Terapkan'), findsOneWidget);
    });

    testWidgets(
      'keeps search bar and quick options sticky while scrolling users list',
      (tester) async {
        final manyUsers = List.generate(
          20,
          (i) => GroupMemberEntity(
            email: 'user$i@kawalo.id',
            name: 'User Ke-$i',
          ),
        );

        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () => showAppUserFilterBottomSheet(
                      context: context,
                      users: manyUsers,
                      currentUserSession: testSession,
                    ),
                    child: const Text('Buka'),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Buka'));
        await tester.pumpAndSettle();

        // Verifikasi posisi awal widget sticky
        final searchBarInitialTop =
            tester.getTopLeft(find.byType(AppSearchBar)).dy;
        final siapapunInitialTop =
            tester.getTopLeft(find.text('Siapapun')).dy;
        final sayaInitialTop = tester.getTopLeft(find.text('Saya')).dy;

        // Scroll daftar pengguna ke atas
        await tester.drag(find.text('User Ke-0'), const Offset(0, -200));
        await tester.pumpAndSettle();

        // Pastikan SearchBar, "Siapapun", dan "Saya" tetap di posisi yang sama
        expect(
          tester.getTopLeft(find.byType(AppSearchBar)).dy,
          equals(searchBarInitialTop),
        );
        expect(
          tester.getTopLeft(find.text('Siapapun')).dy,
          equals(siapapunInitialTop),
        );
        expect(
          tester.getTopLeft(find.text('Saya')).dy,
          equals(sayaInitialTop),
        );
      },
    );

    testWidgets(
      'bottom sheet height remains fixed and does not change when filtered or '
      'empty',
      (tester) async {
        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () => showAppUserFilterBottomSheet(
                      context: context,
                      users: testUsers,
                      currentUserSession: testSession,
                      debounceDuration: Duration.zero,
                    ),
                    child: const Text('Buka'),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Buka'));
        await tester.pumpAndSettle();

        final initialHeight = tester
            .getSize(
              find.byKey(const ValueKey('app_bottom_sheet_constrained_box')),
            )
            .height;

        // Filter to 1 user
        await tester.enterText(find.byType(AppSearchBar), 'Budi');
        await tester.pumpAndSettle();

        final filteredHeight = tester
            .getSize(
              find.byKey(const ValueKey('app_bottom_sheet_constrained_box')),
            )
            .height;
        expect(filteredHeight, equals(initialHeight));

        // Filter to 0 users (empty)
        await tester.enterText(find.byType(AppSearchBar), 'NonExistentName');
        await tester.pumpAndSettle();

        expect(find.text('Tidak ada personil ditemukan.'), findsOneWidget);
        final emptyHeight = tester
            .getSize(
              find.byKey(const ValueKey('app_bottom_sheet_constrained_box')),
            )
            .height;
        expect(emptyHeight, equals(initialHeight));
      },
    );
  });
}
