import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/mappers/guest_local_mapper.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_local_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';

void main() {
  group('GuestLocalMapper Tests', () {
    const testModel = GuestModel(
      id: 'guest_101',
      groupName: 'Cluster Edelweiss',
      guestName: 'Budi Santoso',
      guestNumber: 'B 1234 CD',
      guestIdentity: '3201234567890001',
      guestIdentityType: 'KTP',
      guestPhoto: 'https://example.com/photo.jpg',
      guestDt: '2026-09-10T07:10:00.000Z',
      guestAckDt: '2026-09-10T07:15:00.000Z',
      guestOutDt: '2026-09-10T12:00:00.000Z',
      guestPurpose: 'Kunjungan Saudara',
      guestDestination: 'Blok A1 No 5',
      guestToUserEmail: 'joko@kawalo.id',
      guestToUserName: 'Joko Widodo',
      guestCreatorEmail: 'satpam1@kawalo.id',
      guestCreatorName: 'Satpam Agus',
      guestCategory: 'Tamu Reguler',
      qrUid: 'QR-999',
      guestAddress: 'Jl. Merdeka No. 1, Jakarta',
      guestType: 'Warga/Tamu',
      guestCheckoutByEmail: 'satpam2@kawalo.id',
      guestCheckoutByName: 'Satpam Bambang',
    );

    test('toLocal maps GuestModel to GuestLocalModel', () {
      final collection = GuestLocalMapper.toLocal(testModel);

      expect(collection, isA<GuestLocalModel>());
      expect(collection.id, testModel.id);
      expect(collection.groupName, testModel.groupName);
      expect(collection.guestName, testModel.guestName);
      expect(collection.guestNumber, testModel.guestNumber);
      expect(collection.guestIdentity, testModel.guestIdentity);
      expect(collection.guestIdentityType, testModel.guestIdentityType);
      expect(collection.guestPhoto, testModel.guestPhoto);
      expect(collection.guestDt, testModel.guestDt);
      expect(collection.guestAckDt, testModel.guestAckDt);
      expect(collection.guestOutDt, testModel.guestOutDt);
      expect(collection.guestPurpose, testModel.guestPurpose);
      expect(collection.guestDestination, testModel.guestDestination);
      expect(collection.guestToUserEmail, testModel.guestToUserEmail);
      expect(collection.guestToUserName, testModel.guestToUserName);
      expect(collection.guestCreatorEmail, testModel.guestCreatorEmail);
      expect(collection.guestCreatorName, testModel.guestCreatorName);
      expect(collection.guestCategory, testModel.guestCategory);
      expect(collection.qrUid, testModel.qrUid);
      expect(collection.guestAddress, testModel.guestAddress);
      expect(collection.guestType, testModel.guestType);
      expect(collection.guestCheckoutByEmail, testModel.guestCheckoutByEmail);
      expect(collection.guestCheckoutByName, testModel.guestCheckoutByName);
    });

    test('fromLocal maps GuestLocalModel to GuestModel', () {
      final collection = GuestLocalMapper.toLocal(testModel);
      final model = GuestLocalMapper.fromLocal(collection);

      expect(model.id, testModel.id);
      expect(model.groupName, testModel.groupName);
      expect(model.guestName, testModel.guestName);
      expect(model.guestNumber, testModel.guestNumber);
      expect(model.guestIdentity, testModel.guestIdentity);
      expect(model.guestPurpose, testModel.guestPurpose);
      expect(model.guestDestination, testModel.guestDestination);
      expect(model.guestToUserEmail, testModel.guestToUserEmail);
      expect(model.guestToUserName, testModel.guestToUserName);
      expect(model.guestCreatorEmail, testModel.guestCreatorEmail);
      expect(model.guestCategory, testModel.guestCategory);
      expect(model.qrUid, testModel.qrUid);
      expect(model.guestType, testModel.guestType);
    });

    test('toLocalList and fromLocalList map collections round-trip', () {
      final collections = GuestLocalMapper.toLocalList([testModel]);
      expect(collections.length, 1);
      expect(collections.first.id, testModel.id);

      final models = GuestLocalMapper.fromLocalList(collections);
      expect(models.length, 1);
      expect(models.first.id, testModel.id);
    });

    test('toLocal and fromLocal sanitize dirty data correctly', () {
      const dirtyModel = GuestModel(
        id: '  GUEST-DIRTY  ',
        groupName: '   ',
        guestName: '  John Doe  ',
        guestNumber: '  B 9999 ZZ  ',
        guestIdentity: ' - ',
        guestIdentityType: 'null',
        guestPhoto: 'N/A',
        guestDt: '0000-00-00 00:00:00',
        guestAckDt: '1970-01-01T00:00:00.000Z',
        guestOutDt: '   ',
        guestPurpose: '  Keperluan Rahasia  ',
        guestDestination: 'null',
        guestToUserEmail: '  JOHN.DOE@KAWALO.ID  ',
        guestToUserName: '  John Resident  ',
        guestCreatorEmail: '  CREATOR@KAWALO.ID  ',
        guestCreatorName: ' - ',
        guestCategory: '  Kurir  ',
        qrUid: 'null',
        guestAddress: '  ',
        guestType: '  Kurir Paket  ',
        guestCheckoutByEmail: 'N/A',
        guestCheckoutByName: '  Satpam Sore  ',
      );

      final local = GuestLocalMapper.toLocal(dirtyModel);
      expect(local.id, 'GUEST-DIRTY');
      expect(local.groupName, isNull);
      expect(local.guestName, 'John Doe');
      expect(local.guestNumber, 'B 9999 ZZ');
      expect(local.guestIdentity, isNull);
      expect(local.guestIdentityType, isNull);
      expect(local.guestPhoto, isNull);
      expect(local.guestDt, isNull);
      expect(local.guestAckDt, isNull);
      expect(local.guestOutDt, isNull);
      expect(local.guestPurpose, 'Keperluan Rahasia');
      expect(local.guestDestination, isNull);
      expect(local.guestToUserEmail, 'john.doe@kawalo.id');
      expect(local.guestToUserName, 'John Resident');
      expect(local.guestCreatorEmail, 'creator@kawalo.id');
      expect(local.guestCreatorName, isNull);
      expect(local.guestCategory, 'Kurir');
      expect(local.qrUid, isNull);
      expect(local.guestAddress, isNull);
      expect(local.guestType, 'Kurir Paket');
      expect(local.guestCheckoutByEmail, isNull);
      expect(local.guestCheckoutByName, 'Satpam Sore');

      final roundTrip = GuestLocalMapper.fromLocal(local);
      expect(roundTrip.id, 'GUEST-DIRTY');
      expect(roundTrip.guestName, 'John Doe');
      expect(roundTrip.guestNumber, 'B 9999 ZZ');
      expect(roundTrip.guestToUserEmail, 'john.doe@kawalo.id');
      expect(roundTrip.guestPurpose, 'Keperluan Rahasia');
    });
  });
}
