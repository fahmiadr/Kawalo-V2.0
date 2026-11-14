import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_composer_bar.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<IncidentMediaItem> photos,
    bool isPosting = false,
    ValueChanged<String>? onRetryPhoto,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(
          bottomNavigationBar: IncidentComposerBar(
            draftMessage: 'Sudah ditangani',
            draftPhotos: photos,
            isPosting: isPosting,
            onMessageChanged: (_) {},
            onAddPhoto: (_) {},
            onRemovePhoto: (_) {},
            onRetryPhoto: onRetryPhoto,
            onSend: () {},
          ),
        ),
      ),
    );
  }

  InkWell sendButton(WidgetTester tester) => tester.widget<InkWell>(
    find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Kirim pesan balasan',
      ),
      matching: find.byType(InkWell),
    ),
  );

  const uploading = IncidentMediaItem(
    id: 'a',
    name: 'a.jpg',
    path: 'missing.jpg',
    uploadStatus: IncidentUploadStatus.uploading,
    uploadProgress: 0.5,
  );

  const failed = IncidentMediaItem(
    id: 'b',
    name: 'b.jpg',
    path: 'missing.jpg',
    uploadStatus: IncidentUploadStatus.failed,
    uploadError: 'Koneksi terputus.',
  );

  testWidgets('send is disabled while a draft photo is uploading', (
    tester,
  ) async {
    await pump(tester, photos: [uploading]);

    expect(sendButton(tester).onTap, isNull);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('send is enabled with an idle draft', (tester) async {
    await pump(tester, photos: const []);

    expect(sendButton(tester).onTap, isNotNull);
  });

  testWidgets('tapping a failed draft photo retries its upload', (
    tester,
  ) async {
    String? retried;
    await pump(tester, photos: [failed], onRetryPhoto: (id) => retried = id);

    expect(find.text('Gagal\nCoba lagi'), findsOneWidget);
    await tester.tap(find.text('Gagal\nCoba lagi'));
    expect(retried, 'b');
  });
}
