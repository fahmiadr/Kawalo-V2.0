import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/presentation/utils/attachment_file_info.dart';

void main() {
  group('attachmentFileName', () {
    test('strips directories and query', () {
      expect(
        attachmentFileName('https://x.id/files/sop.pdf?token=a/b'),
        'sop.pdf',
      );
    });

    test('returns input when there is no slash', () {
      expect(attachmentFileName('sop.pdf'), 'sop.pdf');
    });

    test('returns input when it ends with a slash', () {
      expect(attachmentFileName('a/b/'), 'a/b/');
    });
  });

  group('attachmentFileExtension', () {
    test('lowercases and ignores query', () {
      expect(attachmentFileExtension('a/Data.XLSX?v=1.2'), 'xlsx');
    });

    test('is empty without a dot or with trailing dot', () {
      expect(attachmentFileExtension('README'), '');
      expect(attachmentFileExtension('file.'), '');
      expect(attachmentFileExtension(''), '');
    });
  });

  group('attachmentFormatLabel', () {
    test('maps known extensions', () {
      expect(attachmentFormatLabel('a.pdf'), 'PDF');
      expect(attachmentFormatLabel('a.docx'), 'Word');
      expect(attachmentFormatLabel('a.xls'), 'Excel');
      expect(attachmentFormatLabel('a.pptx'), 'PowerPoint');
      expect(attachmentFormatLabel('a.csv'), 'CSV');
      expect(attachmentFormatLabel('a.txt'), 'Text');
      expect(attachmentFormatLabel('a.json'), 'JSON');
      expect(attachmentFormatLabel('a.webp'), 'Image');
      expect(attachmentFormatLabel('a.7z'), 'Archive');
    });

    test('uppercases unknown extension and falls back to Dokumen', () {
      expect(attachmentFormatLabel('a.xyz'), 'XYZ');
      expect(attachmentFormatLabel('a'), 'Dokumen');
    });
  });
}
