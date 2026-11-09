import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/features/information/data/datasources/information_remote_data_source.dart';
import 'package:kawalo_mobile/features/information/data/models/create_information_model.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_request_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_id_params_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_query_model.dart';
import 'package:kawalo_mobile/features/information/data/models/update_information_model.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late InformationRemoteDataSourceImpl dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = InformationRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  group('InformationRemoteDataSourceImpl Tests', () {
    test(
      'getInformation executes GET and returns list of InformationModel',
      () async {
        when(
          () => mockApiClient.get(
            '/v1/information',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => {
            'success': true,
            'message': 'Daftar data informasi berhasil diambil',
            'data': [
              {
                'id': '101',
                'title': 'Judul Info',
                'text': 'Deskripsi Info',
                'feed_dt': '2026-09-01T10:00:00.000Z',
                'photos': <String>[],
              },
            ],
          },
        );

        final result = await dataSource.getInformation(
          query: const InformationQueryModel(search: 'Judul'),
        );

        expect(result.length, 1);
        expect(result.first.id, '101');
        expect(result.first.title, 'Judul Info');
        verify(
          () => mockApiClient.get(
            '/v1/information',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).called(1);
      },
    );

    test('createInformation calls POST /v1/information and returns '
        'InformationModel', () async {
      const tModel = CreateInformationModel(
        title: 'Posko Siaga',
        text: 'Posko siaga 24 jam.',
        feedType: 'GENERAL',
      );

      when(
        () => mockApiClient.post(
          '/v1/information',
          body: any<dynamic>(named: 'body'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'message': 'Data informasi berhasil dibuat',
          'data': {
            'id': '99',
            'title': 'Posko Siaga',
            'text': 'Posko siaga 24 jam.',
            'feed_type': 'GENERAL',
            'photos': <String>[],
          },
        },
      );

      final result = await dataSource.createInformation(data: tModel);

      expect(result.id, '99');
      expect(result.title, 'Posko Siaga');
      expect(result.feedType, 'GENERAL');
      verify(
        () => mockApiClient.post('/v1/information', body: tModel.toJson()),
      ).called(1);
    });

    test('updateInformation calls PUT /v1/information/:id and returns '
        'InformationModel', () async {
      const tParams = InformationIdParamsModel(id: '99');
      const tModel = UpdateInformationModel(
        title: 'Posko Siaga Diperbarui',
        text: 'Posko siaga buka mulai jam 18:00.',
        feedType: 'GENERAL',
      );

      when(
        () => mockApiClient.put(
          '/v1/information/99',
          body: any<dynamic>(named: 'body'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'message': 'Data informasi berhasil diperbarui',
          'data': {
            'id': '99',
            'title': 'Posko Siaga Diperbarui',
            'text': 'Posko siaga buka mulai jam 18:00.',
            'feed_type': 'GENERAL',
            'photos': <String>[],
          },
        },
      );

      final result = await dataSource.updateInformation(
        params: tParams,
        data: tModel,
      );

      expect(result.id, '99');
      expect(result.title, 'Posko Siaga Diperbarui');
      expect(result.feedType, 'GENERAL');
      verify(
        () => mockApiClient.put('/v1/information/99', body: tModel.toJson()),
      ).called(1);
    });

    test(
      'deleteInformation calls DELETE /v1/information/:id with proper path',
      () async {
        const tId = '42';
        final cancelToken = DioCancellationToken();

        when(
          () => mockApiClient.delete(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => {
            'success': true,
            'message': 'Data informasi berhasil dihapus',
            'data': null,
          },
        );

        await dataSource.deleteInformation(
          params: const InformationIdParamsModel(id: tId),
          cancelToken: cancelToken,
        );

        verify(
          () => mockApiClient.delete(
            '/v1/information/42',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      },
    );

    test('deleteBatchInformation calls DELETE /v1/information with body and '
        'returns DeleteBatchInformationResponseModel', () async {
      final cancelToken = DioCancellationToken();
      const params = DeleteBatchInformationRequestModel(ids: ['1', '2']);

      when(
        () => mockApiClient.delete(
          '/v1/information',
          body: any<dynamic>(named: 'body'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'message': '2 data informasi berhasil dihapus',
          'data': {'deleted_count': 2},
        },
      );

      final result = await dataSource.deleteBatchInformation(
        params: params,
        cancelToken: cancelToken,
      );

      expect(result.deletedCount, 2);
      verify(
        () => mockApiClient.delete(
          '/v1/information',
          body: const {
            'ids': ['1', '2'],
          },
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });
  });
}
