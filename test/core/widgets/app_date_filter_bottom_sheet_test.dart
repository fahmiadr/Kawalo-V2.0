import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_date_picker.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_radio.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

void main() {
  group('AppDateFilterBottomSheet Widget Tests', () {
    testWidgets('renders custom title, options, and applies selection',
        (tester) async {
      AppDateFilterResult? appliedResult;

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    appliedResult = await showAppDateFilterBottomSheet(
                      context: context,
                      title: 'Filter kustom',
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

      expect(find.text('Filter kustom'), findsOneWidget);
      expect(find.text('Rentang waktu'), findsOneWidget);
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Pekan ini'), findsOneWidget);
      expect(find.text('Bulan ini'), findsOneWidget);
      expect(find.text('Rentang khusus'), findsOneWidget);
      expect(find.text('Terapkan'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      await tester.tap(find.text('Pekan ini'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(appliedResult, isNotNull);
      expect(appliedResult!.period, AppDateFilterPeriod.thisWeek);
      expect(appliedResult!.isDefault, isFalse);
    });

    testWidgets('bottom sheet height hugs content instead of filling maxHeight',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAppDateFilterBottomSheet(
                    context: context,
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

      final sheetFinder = find.byType(AppDateFilterBottomSheet);
      expect(sheetFinder, findsOneWidget);
      final optionsSize = tester.getSize(sheetFinder);
      expect(optionsSize.height, lessThan(450.0));
      expect(optionsSize.height, greaterThan(300.0));

      // Transition to custom range view
      await tester.tap(find.text('Rentang khusus'));
      await tester.pumpAndSettle();

      final customRangeSize = tester.getSize(sheetFinder);
      expect(customRangeSize.height, lessThan(300.0));
      expect(customRangeSize.height, greaterThan(200.0));
    });

    testWidgets('renders custom subtitle when provided', (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAppDateFilterBottomSheet(
                    context: context,
                    title: 'Tanggal',
                    subtitle: 'Rentang waktu',
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

      expect(find.text('Tanggal'), findsOneWidget);
      expect(find.text('Rentang waktu'), findsOneWidget);
    });

    testWidgets('transitions to custom date range view and back',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAppDateFilterBottomSheet(
                    context: context,
                    title: 'Filter kustom',
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

      await tester.tap(find.text('Rentang khusus'));
      await tester.pumpAndSettle();

      expect(find.text('Atur rentang waktu'), findsOneWidget);
      expect(find.text('Dari'), findsOneWidget);
      expect(find.text('Ke'), findsOneWidget);
      expect(find.text('Pasang'), findsOneWidget);

      final backButton = find.byWidgetPredicate(
        (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.arrowLeft02,
      );
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Filter kustom'), findsOneWidget);
    });

    testWidgets('renders AppRadio<AppDateFilterPeriod> correctly',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: AppDateFilterBottomSheet(
              initialPeriod: AppDateFilterPeriod.thisMonth,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppRadio<AppDateFilterPeriod>), findsNWidgets(4));
    });

    test('AppDateFilterScope resolves rolling dynamic bounds correctly', () {
      final fixedDate = DateTime(2026, 9, 11, 15, 30);

      // Generic: now.year - 100 s/d now.year + 100
      expect(
        AppDateFilterScope.generic.resolveFirstDate(fixedDate),
        equals(DateTime(1926)),
      );
      expect(
        AppDateFilterScope.generic.resolveLastDate(fixedDate),
        equals(DateTime(2126, 12, 31)),
      );

      // PastOnly: now.year - 100 s/d today end of day
      expect(
        AppDateFilterScope.pastOnly.resolveFirstDate(fixedDate),
        equals(DateTime(1926)),
      );
      expect(
        AppDateFilterScope.pastOnly.resolveLastDate(fixedDate),
        equals(DateTime(2026, 9, 11, 23, 59, 59)),
      );

      // FutureOnly: today start of day s/d now.year + 100
      expect(
        AppDateFilterScope.futureOnly.resolveFirstDate(fixedDate),
        equals(DateTime(2026, 9, 11)),
      );
      expect(
        AppDateFilterScope.futureOnly.resolveLastDate(fixedDate),
        equals(DateTime(2126, 12, 31)),
      );

      // Custom explicit overrides take precedence
      final customFirst = DateTime(2010);
      final customLast = DateTime(2040);
      expect(
        AppDateFilterScope.pastOnly.resolveFirstDate(
          fixedDate,
          customFirstDate: customFirst,
        ),
        equals(customFirst),
      );
      expect(
        AppDateFilterScope.pastOnly.resolveLastDate(
          fixedDate,
          customLastDate: customLast,
        ),
        equals(customLast),
      );
    });

    testWidgets('pastOnly scope initializes endDate to today instead of future',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: AppDateFilterBottomSheet(
              scope: AppDateFilterScope.pastOnly,
              startInCustomRange: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Atur rentang waktu'), findsOneWidget);
      expect(find.text('Dari'), findsOneWidget);
      expect(find.text('Ke'), findsOneWidget);
      expect(find.text('Pasang'), findsOneWidget);
    });

    testWidgets('tapping Dari in modal bottom sheet opens date picker dialog',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          locale: const Locale('id', 'ID'),
          supportedLocales: const [
            Locale('id', 'ID'),
            Locale('id'),
            Locale('en', 'US'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => M3ETheme(
            data: AppTheme.m3eLight(),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAppDateFilterBottomSheet(
                  context: context,
                  scope: AppDateFilterScope.pastOnly,
                  startInCustomRange: true,
                ),
                child: const Text('Open Modal Filter'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Atur rentang waktu'), findsOneWidget);

      await tester.tap(find.text('Dari'));
      await tester.pumpAndSettle();

      expect(find.byType(AppDatePickerDialog), findsOneWidget);
    });

    testWidgets('scrolls gracefully without overflow on constrained viewport',
        (tester) async {
      tester.view.physicalSize = const Size(360, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          localizationsDelegates: AppTheme.localizationsDelegates,
          supportedLocales: AppTheme.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAppDateFilterBottomSheet(
                  context: context,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
      // Verify no overflow error and content can scroll down to Terapkan
      await tester.drag(find.text('Rentang waktu'), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('Terapkan'), findsOneWidget);
    });

    testWidgets('renders AppDivider between date range and additional sections',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          localizationsDelegates: AppTheme.localizationsDelegates,
          supportedLocales: AppTheme.supportedLocales,
          home: const Scaffold(
            body: AppDateFilterBottomSheet(
              additionalSections: [
                Text('Section 1: Status'),
                Text('Section 2: Kategori'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rentang waktu'), findsOneWidget);
      expect(find.text('Section 1: Status'), findsOneWidget);
      expect(find.text('Section 2: Kategori'), findsOneWidget);

      // 1 divider after date range, 1 divider between section 1 and 2
      expect(find.byType(AppDivider), findsNWidgets(2));
    });

    testWidgets(
        'formats custom date range subtitle without repeating same month/year',
        (tester) async {
      // 1. Same day
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          localizationsDelegates: AppTheme.localizationsDelegates,
          supportedLocales: AppTheme.supportedLocales,
          home: Scaffold(
            body: AppDateFilterBottomSheet(
              key: const ValueKey('case1'),
              initialPeriod: AppDateFilterPeriod.custom,
              initialStartDate: DateTime(2026, 10),
              initialEndDate: DateTime(2026, 10),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('01 Okt 2026'), findsOneWidget);

      // 2. Same month and year
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          localizationsDelegates: AppTheme.localizationsDelegates,
          supportedLocales: AppTheme.supportedLocales,
          home: Scaffold(
            body: AppDateFilterBottomSheet(
              key: const ValueKey('case2'),
              initialPeriod: AppDateFilterPeriod.custom,
              initialStartDate: DateTime(2026, 10),
              initialEndDate: DateTime(2026, 10, 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('01–03 Okt 2026'), findsOneWidget);

      // 3. Same year, different month
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          localizationsDelegates: AppTheme.localizationsDelegates,
          supportedLocales: AppTheme.supportedLocales,
          home: Scaffold(
            body: AppDateFilterBottomSheet(
              key: const ValueKey('case3'),
              initialPeriod: AppDateFilterPeriod.custom,
              initialStartDate: DateTime(2026, 9),
              initialEndDate: DateTime(2026, 10, 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('01 Sep – 03 Okt 2026'), findsOneWidget);

      // 4. Different year
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          localizationsDelegates: AppTheme.localizationsDelegates,
          supportedLocales: AppTheme.supportedLocales,
          home: Scaffold(
            body: AppDateFilterBottomSheet(
              key: const ValueKey('case4'),
              initialPeriod: AppDateFilterPeriod.custom,
              initialStartDate: DateTime(2025, 9),
              initialEndDate: DateTime(2026, 10, 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('01 Sep 2025 – 03 Okt 2026'), findsOneWidget);
    });

    testWidgets(
        'shows date range label when today, thisWeek, or thisMonth is selected',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          localizationsDelegates: AppTheme.localizationsDelegates,
          supportedLocales: AppTheme.supportedLocales,
          home: const Scaffold(
            body: AppDateFilterBottomSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final todayStr = AppDateFormat.formatDateRange(
        now,
        now,
        useLeadingZero: true,
      );
      expect(find.text(todayStr), findsOneWidget);

      await tester.tap(find.text('Pekan ini'));
      await tester.pumpAndSettle();

      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final weekStr = AppDateFormat.formatDateRange(
        startOfWeek,
        endOfWeek,
        useLeadingZero: true,
      );
      expect(find.text(weekStr), findsOneWidget);

      await tester.tap(find.text('Bulan ini'));
      await tester.pumpAndSettle();

      final startOfMonth = DateTime(now.year, now.month);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      final monthStr = AppDateFormat.formatDateRange(
        startOfMonth,
        endOfMonth,
        useLeadingZero: true,
      );
      expect(find.text(monthStr), findsOneWidget);
    });
  });
}
