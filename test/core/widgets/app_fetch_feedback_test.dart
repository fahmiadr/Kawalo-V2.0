import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/widgets/app_fetch_feedback.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';

void main() {
  Widget buildTestHost({
    required Widget child,
    ConnectivityStatus connectivity = ConnectivityStatus.online,
  }) {
    final connectivityCubit = ConnectivityCubit(
      initialState: connectivity,
      autoStart: false,
    );

    return MaterialApp(
      home: BlocProvider<ConnectivityCubit>.value(
        value: connectivityCubit,
        child: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('AppFetchFeedback Tests', () {
    tearDown(AppSnackbar.hideCurrent);

    testWidgets('cancelled and failure do not trigger snackbar',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        buildTestHost(
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      AppFetchFeedback.show(
        capturedContext,
        result: AppFetchResult.cancelled,
        hasData: true,
      );
      await tester.pump();
      expect(find.byType(AppSnackbar), findsNothing);

      AppFetchFeedback.show(
        capturedContext,
        result: AppFetchResult.failure,
        hasData: true,
      );
      await tester.pump();
      expect(find.byType(AppSnackbar), findsNothing);
    });

    testWidgets('success displays successMessage when provided',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        buildTestHost(
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      AppFetchFeedback.show(
        capturedContext,
        result: AppFetchResult.success,
        hasData: true,
        successMessage: 'Data berhasil diperbarui.',
      );
      await tester.pump();

      expect(find.text('Data berhasil diperbarui.'), findsOneWidget);
    });

    testWidgets(
        'cachedFallback when offline shows appropriate message based on data',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        buildTestHost(
          connectivity: ConnectivityStatus.offline,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      AppFetchFeedback.show(
        capturedContext,
        result: AppFetchResult.cachedFallback,
        hasData: true,
      );
      await tester.pump();

      expect(
        find.text('Tidak ada koneksi internet. Menampilkan data tersimpan.'),
        findsOneWidget,
      );

      AppSnackbar.hideCurrent();
      await tester.pump();

      AppFetchFeedback.show(
        capturedContext,
        result: AppFetchResult.cachedFallback,
        hasData: false,
      );
      await tester.pump();

      expect(
        find.text('Tidak ada koneksi internet. Belum ada data tersimpan.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'cachedFallback when online shows server failure message based on data',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        buildTestHost(
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      AppFetchFeedback.show(
        capturedContext,
        result: AppFetchResult.cachedFallback,
        hasData: true,
      );
      await tester.pump();

      expect(
        find.text('Layanan belum dapat merespons. Menampilkan data tersimpan.'),
        findsOneWidget,
      );

      AppSnackbar.hideCurrent();
      await tester.pump();

      AppFetchFeedback.show(
        capturedContext,
        result: AppFetchResult.cachedFallback,
        hasData: false,
      );
      await tester.pump();

      expect(
        find.text('Layanan belum dapat merespons. Belum ada data tersimpan.'),
        findsOneWidget,
      );
    });
  });
}
