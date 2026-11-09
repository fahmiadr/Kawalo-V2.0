import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/data/models/create_information_model.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_request_model.dart';

void main() {
  group('CreateInformationModel.toJson', () {
    test('keeps only title when optionals are null', () {
      expect(const CreateInformationModel(title: 'T').toJson(), {'title': 'T'});
    });

    test('includes every optional key when set', () {
      expect(
        const CreateInformationModel(
          title: 'T',
          text: 'x',
          feedFile: 'f',
          photos: ['a', 'b'],
          feedType: 'EVENT',
          eventLocation: 'loc',
          glat: '-6.2',
          glong: '106.8',
        ).toJson(),
        {
          'title': 'T',
          'text': 'x',
          'feed_file': 'f',
          'photos': ['a', 'b'],
          'feed_type': 'EVENT',
          'event_location': 'loc',
          'glat': '-6.2',
          'glong': '106.8',
        },
      );
    });

    test('includes only the optional keys that are set', () {
      expect(
        const CreateInformationModel(
          title: 'T',
          photos: [],
          glong: '106.8',
        ).toJson(),
        {'title': 'T', 'photos': <String>[], 'glong': '106.8'},
      );
    });
  });

  test('DeleteBatchInformationRequestModel.toJson wraps ids', () {
    expect(const DeleteBatchInformationRequestModel(ids: ['1', '2']).toJson(), {
      'ids': ['1', '2'],
    });
  });
}
