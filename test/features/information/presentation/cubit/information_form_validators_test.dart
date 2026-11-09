import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_validators.dart';

void main() {
  group('InformationFormValidators', () {
    test('validateTitle requires a non-blank value up to 128 chars', () {
      expect(
        InformationFormValidators.validateTitle('  '),
        'Judul informasi wajib diisi',
      );
      expect(
        InformationFormValidators.validateTitle('a' * 129),
        'Judul informasi maksimal 128 karakter.',
      );
      expect(InformationFormValidators.validateTitle('a' * 128), isNull);
    });

    test('validateText and validateEventLocation only enforce max length', () {
      expect(InformationFormValidators.validateText(''), isNull);
      expect(InformationFormValidators.validateText('a' * 1024), isNull);
      expect(
        InformationFormValidators.validateText('a' * 1025),
        'Deskripsi informasi maksimal 1024 karakter.',
      );

      expect(
        InformationFormValidators.validateEventLocation('a' * 128),
        isNull,
      );
      expect(
        InformationFormValidators.validateEventLocation('a' * 129),
        'Nama lokasi maksimal 128 karakter.',
      );
    });

    test('validateFeedType accepts known codes case-insensitively', () {
      expect(InformationFormValidators.validateFeedType('general'), isNull);
      expect(InformationFormValidators.validateFeedType(' EVENT '), isNull);
      expect(
        InformationFormValidators.validateFeedType('UNKNOWN'),
        'Kategori informasi tidak valid.',
      );
      expect(
        InformationFormValidators.validateFeedType(''),
        'Kategori informasi tidak valid.',
      );
    });

    test('validateFeedFile enforces max length', () {
      expect(InformationFormValidators.validateFeedFile('a' * 2048), isNull);
      expect(
        InformationFormValidators.validateFeedFile('a' * 2049),
        'Tautan berkas maksimal 2048 karakter.',
      );
    });

    test('validateGlat accepts blank and values within -90..90', () {
      expect(InformationFormValidators.validateGlat('  '), isNull);
      expect(InformationFormValidators.validateGlat('-6.2'), isNull);
      expect(InformationFormValidators.validateGlat('90'), isNull);
      expect(
        InformationFormValidators.validateGlat('90.1'),
        'Latitude harus berupa angka valid antara -90 dan 90.',
      );
      expect(
        InformationFormValidators.validateGlat('abc'),
        'Latitude harus berupa angka valid antara -90 dan 90.',
      );
      expect(
        InformationFormValidators.validateGlat('1' * 33),
        'Panjang latitude maksimal 32 karakter.',
      );
    });

    test('validateGlong accepts blank and values within -180..180', () {
      expect(InformationFormValidators.validateGlong(''), isNull);
      expect(InformationFormValidators.validateGlong('106.8'), isNull);
      expect(InformationFormValidators.validateGlong('-180'), isNull);
      expect(
        InformationFormValidators.validateGlong('180.5'),
        'Longitude harus berupa angka valid antara -180 dan 180.',
      );
      expect(
        InformationFormValidators.validateGlong('1' * 33),
        'Panjang longitude maksimal 32 karakter.',
      );
    });

    group('validateCoordinates', () {
      test('passes when both are blank or both are valid', () {
        final blank = InformationFormValidators.validateCoordinates('', ' ');
        expect(blank.glat, isNull);
        expect(blank.glong, isNull);

        final both = InformationFormValidators.validateCoordinates(
          '-6.2',
          '106.8',
        );
        expect(both.glat, isNull);
        expect(both.glong, isNull);
      });

      test('requires the missing half of a pair', () {
        final onlyLat = InformationFormValidators.validateCoordinates(
          '-6.2',
          '',
        );
        expect(onlyLat.glat, isNull);
        expect(
          onlyLat.glong,
          'Longitude wajib diisi jika latitude ditentukan.',
        );

        final onlyLong = InformationFormValidators.validateCoordinates(
          '',
          '106.8',
        );
        expect(
          onlyLong.glat,
          'Latitude wajib diisi jika longitude ditentukan.',
        );
        expect(onlyLong.glong, isNull);
      });

      test('keeps the format error over the pairing error', () {
        final result = InformationFormValidators.validateCoordinates('999', '');
        expect(
          result.glat,
          'Latitude harus berupa angka valid antara -90 dan 90.',
        );
        expect(result.glong, 'Longitude wajib diisi jika latitude ditentukan.');
      });
    });
  });
}
