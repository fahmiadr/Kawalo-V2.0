import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';

void main() {
  group('GuestUiExtension Tests', () {
    const tGuest = GuestItemEntity(
      id: 'GUEST-1',
      groupName: 'Cluster Edelweiss',
      guestName: 'Budi Santoso',
      guestNumber: 'B 1234 CD',
      guestIdentity: '3201234567890001',
      guestIdentityType: 'KTP',
      guestPhoto: 'https://example.com/photo.jpg',
      guestDt: '2026-09-10T08:00:00.000Z',
      guestAckDt: '2026-09-10T08:05:00.000Z',
      guestOutDt: '2026-09-10T10:00:00.000Z',
      guestPurpose: 'Kunjungan Saudara',
      guestDestination: 'Blok A1 No 5',
      guestToUserEmail: 'joko@kawalo.id',
      guestToUserName: 'Joko Widodo - Blok A1',
      guestCreatorEmail: 'satpam1@kawalo.id',
      guestCreatorName: 'Satpam Agus',
      guestCategory: 'Tamu Reguler',
      qrUid: 'QR-999',
      guestAddress: 'Jl. Merdeka No. 1, Jakarta',
      guestType: 'Visitor',
      guestCheckoutByEmail: 'satpam2@kawalo.id',
      guestCheckoutByName: 'Satpam Bambang',
    );

    test('display getters return correct non-empty values', () {
      expect(tGuest.identifier, 'Budi Santoso');
      expect(tGuest.displayGuestName, 'Budi Santoso');
      expect(tGuest.displayName, 'Budi Santoso');
      expect(tGuest.displayGuestNumber, 'B 1234 CD');
      expect(tGuest.displayIdentityType, 'KTP');
      expect(tGuest.displayGuestType, 'Visitor');
      expect(tGuest.displayAddress, 'Jl. Merdeka No. 1, Jakarta');
      expect(tGuest.displayQrUid, 'QR-999');
      expect(tGuest.displayCheckoutByEmail, 'satpam2@kawalo.id');
      expect(tGuest.displayCheckoutByName, 'Satpam Bambang');
      expect(tGuest.displayGroupName, 'Cluster Edelweiss');
      expect(tGuest.displayIdNumber, '3201234567890001');
      expect(tGuest.displayDestination, 'Blok A1 No 5');
      expect(tGuest.displayCategory, 'Tamu Reguler');
      expect(tGuest.displayPurpose, 'Kunjungan Saudara');
      expect(tGuest.displayGuestToUserName, 'Joko Widodo');
      expect(tGuest.displayGuestToUserEmail, 'joko@kawalo.id');
      expect(tGuest.displayRecordedBy, 'Satpam Agus');
      expect(tGuest.displayRecorderEmail, 'satpam1@kawalo.id');
      expect(tGuest.isConfirmed, isTrue);
      expect(tGuest.isExited, isTrue);
      expect(tGuest.hasCheckout, isTrue);
      expect(tGuest.latestStatusLabel, 'Keluar');
      expect(tGuest.latestStatusTime, tGuest.displayExitTime);
    });

    test('display getters return "-" on empty/null values', () {
      const emptyGuest = GuestItemEntity(id: 'EMPTY');

      expect(emptyGuest.identifier, '-');
      expect(emptyGuest.displayGuestName, '—');
      expect(emptyGuest.displayName, '-');
      expect(emptyGuest.displayGuestNumber, '-');
      expect(emptyGuest.displayIdentityType, '-');
      expect(emptyGuest.displayGuestType, '-');
      expect(emptyGuest.displayAddress, '-');
      expect(emptyGuest.displayQrUid, '-');
      expect(emptyGuest.displayCheckoutByEmail, '-');
      expect(emptyGuest.displayCheckoutByName, '-');
      expect(emptyGuest.displayGroupName, '-');
      expect(emptyGuest.displayIdNumber, '-');
      expect(emptyGuest.displayDestination, '-');
      expect(emptyGuest.displayCategory, '-');
      expect(emptyGuest.displayPurpose, '-');
      expect(emptyGuest.displayGuestToUserName, '-');
      expect(emptyGuest.displayGuestToUserEmail, '-');
      expect(emptyGuest.displayRecordedBy, '-');
      expect(emptyGuest.displayRecorderEmail, '-');
      expect(emptyGuest.displayEntryTime, '-');
      expect(emptyGuest.displayConfirmationTime, '-');
      expect(emptyGuest.displayExitTime, '-');
      expect(emptyGuest.isConfirmed, isFalse);
      expect(emptyGuest.isExited, isFalse);
      expect(emptyGuest.hasCheckout, isFalse);
      expect(emptyGuest.latestStatusLabel, 'Masuk');
    });

    test('identifier falls back to guestNumber when guestName is null', () {
      const guestWithNumberOnly = GuestItemEntity(
        id: 'NUM-1',
        guestNumber: 'B 9999 ZZ',
      );
      expect(guestWithNumberOnly.identifier, 'B 9999 ZZ');
    });

    test('status label returns Konfirmasi when confirmed but not exited', () {
      const confirmedGuest = GuestItemEntity(
        id: 'CONF-1',
        guestDt: '2026-09-10T08:00:00.000Z',
        guestAckDt: '2026-09-10T08:05:00.000Z',
      );
      expect(confirmedGuest.isConfirmed, isTrue);
      expect(confirmedGuest.isExited, isFalse);
      expect(confirmedGuest.latestStatusLabel, 'Konfirmasi');
      expect(
        confirmedGuest.latestStatusTime,
        confirmedGuest.displayConfirmationTime,
      );
    });

    test('isConfirmed and hasCheckout return true when valid data exists', () {
      expect(tGuest.isConfirmed, isTrue);
      expect(tGuest.hasCheckout, isTrue);
    });

    test('isConfirmed and hasCheckout return false when data is absent or "-"',
        () {
      const guestHyphen = GuestItemEntity(
        id: 'HYPHEN',
        guestAckDt: '-',
        guestCheckoutByEmail: '-',
        guestCheckoutByName: '-',
      );
      expect(guestHyphen.isConfirmed, isFalse);
      expect(guestHyphen.hasCheckout, isFalse);
    });
  });
}
