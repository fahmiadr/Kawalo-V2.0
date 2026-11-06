import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/mappers/guest_mapper.dart';
import 'package:kawalo_mobile/features/guest/data/models/delete_batch_guest_response_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/delete_batch_result.dart';

void main() {
  group('GuestMapper Tests', () {
    const tGuestModel = GuestModel(
      id: 'guest_1',
      guestName: 'Budi Santoso',
      guestNumber: 'B 1234 CD',
      guestIdentity: '3201234567890001',
      guestIdentityType: 'KTP',
      guestPhoto: 'https://example.com/photo.jpg',
      guestCategory: 'Tamu',
      guestDestination: 'Pos 1',
      guestPurpose: 'Meeting',
      guestDt: '2026-09-10T08:00:00.000Z',
      guestAckDt: '2026-09-10T08:05:00.000Z',
      guestOutDt: '2026-09-10T10:00:00.000Z',
      groupName: 'Cluster A',
      guestToUserName: 'Pak Joko',
      guestToUserEmail: 'joko@kawalo.id',
      guestCreatorName: 'Satpam Agus',
      guestCreatorEmail: 'agus@kawalo.id',
      qrUid: 'QR-12345',
      guestAddress: 'Jl. Merdeka No. 1',
      guestType: 'Warga/Tamu',
      guestCheckoutByEmail: 'bambang@kawalo.id',
      guestCheckoutByName: 'Satpam Bambang',
    );

    test('toEntity accurately maps all fields from Model to Entity', () {
      final entity = GuestMapper.toEntity(tGuestModel);

      expect(entity, isA<GuestItemEntity>());
      expect(entity.id, tGuestModel.id);
      expect(entity.groupName, tGuestModel.groupName);
      expect(entity.guestName, tGuestModel.guestName);
      expect(entity.guestNumber, tGuestModel.guestNumber);
      expect(entity.guestIdentity, tGuestModel.guestIdentity);
      expect(entity.guestIdentityType, tGuestModel.guestIdentityType);
      expect(entity.guestPhoto, tGuestModel.guestPhoto);
      expect(entity.guestDt, tGuestModel.guestDt);
      expect(entity.guestAckDt, tGuestModel.guestAckDt);
      expect(entity.guestOutDt, tGuestModel.guestOutDt);
      expect(entity.guestPurpose, tGuestModel.guestPurpose);
      expect(entity.guestDestination, tGuestModel.guestDestination);
      expect(entity.guestToUserEmail, tGuestModel.guestToUserEmail);
      expect(entity.guestToUserName, tGuestModel.guestToUserName);
      expect(entity.guestCreatorEmail, tGuestModel.guestCreatorEmail);
      expect(entity.guestCreatorName, tGuestModel.guestCreatorName);
      expect(entity.guestCategory, tGuestModel.guestCategory);
      expect(entity.qrUid, tGuestModel.qrUid);
      expect(entity.guestAddress, tGuestModel.guestAddress);
      expect(entity.guestType, tGuestModel.guestType);
      expect(entity.guestCheckoutByEmail, tGuestModel.guestCheckoutByEmail);
      expect(entity.guestCheckoutByName, tGuestModel.guestCheckoutByName);
    });

    test('toEntityList correctly maps a list of models', () {
      final entities = GuestMapper.toEntityList([tGuestModel]);

      expect(entities.length, 1);
      expect(entities.first.id, tGuestModel.id);
    });

    test('toEntity properly sanitizes dirty data from backend DTO', () {
      const dirtyModel = GuestModel(
        id: '  GUEST-DIRTY-99  ',
        guestName: '  John Doe  ',
        guestNumber: '  B 9999 ZZ  ',
        guestCategory: '   ',
        guestDestination: 'null',
        guestPurpose: ' - ',
        guestDt: '0000-00-00 00:00:00',
        guestAckDt: '1970-01-01T00:00:00.000Z',
        guestOutDt: 'N/A',
        groupName: '  Cluster Melati  ',
        guestToUserName: '  John Resident  ',
        guestToUserEmail: '  JOHN.DOE@KAWALO.ID  ',
        guestCreatorName: ' - ',
        guestCreatorEmail: '  CREATOR@KAWALO.ID  ',
        guestIdentity: 'N/A',
        guestIdentityType: 'null',
        guestPhoto: '   ',
        qrUid: 'null',
        guestAddress: '  ',
        guestType: '  Kurir Paket  ',
        guestCheckoutByEmail: 'N/A',
        guestCheckoutByName: '  Satpam Sore  ',
      );

      final entity = GuestMapper.toEntity(dirtyModel);

      expect(entity.id, 'GUEST-DIRTY-99');
      expect(entity.guestName, 'John Doe');
      expect(entity.guestNumber, 'B 9999 ZZ');
      expect(entity.guestCategory, isNull);
      expect(entity.guestDestination, isNull);
      expect(entity.guestPurpose, isNull);
      expect(entity.guestDt, isNull);
      expect(entity.guestAckDt, isNull);
      expect(entity.guestOutDt, isNull);
      expect(entity.groupName, 'Cluster Melati');
      expect(entity.guestToUserName, 'John Resident');
      expect(entity.guestToUserEmail, 'john.doe@kawalo.id');
      expect(entity.guestCreatorName, isNull);
      expect(entity.guestCreatorEmail, 'creator@kawalo.id');
      expect(entity.guestIdentity, isNull);
      expect(entity.guestIdentityType, isNull);
      expect(entity.guestPhoto, isNull);
      expect(entity.qrUid, isNull);
      expect(entity.guestAddress, isNull);
      expect(entity.guestType, 'Kurir Paket');
      expect(entity.guestCheckoutByEmail, isNull);
      expect(entity.guestCheckoutByName, 'Satpam Sore');
    });

    test(
      'toDeleteBatchResult accurately maps deletedCount from DTO '
      'to Value Object',
      () {
        const dto = DeleteBatchGuestResponseModel(deletedCount: 5);
        final entity = GuestMapper.toDeleteBatchResult(dto);

        expect(entity, isA<DeleteBatchResult>());
        expect(entity.deletedCount, 5);
      },
    );
  });
}
