import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';

/// Kumpulan fixture data tamu untuk kebutuhan pengujian otomatis.
class GuestFixtures {
  const GuestFixtures._();

  /// Entitas tamu contoh dengan status keluar (exited).
  static const GuestItemEntity sampleExitedGuest = GuestItemEntity(
    id: '1',
    guestName: 'Bambang Sudarsono',
    guestNumber: 'B 2706 SBX',
    guestCategory: 'Taxi • KTP',
    guestDestination: 'Wisnu wijayadi - Veranda',
    guestToUserName: 'Wisnu wijayadi',
    guestPurpose: 'Jemput Mr Sean',
    guestDt: '2026-09-28T08:14:00.000Z',
    guestAckDt: '2026-09-28T08:15:00.000Z',
    guestOutDt: '2026-09-28T08:17:00.000Z',
    groupName: 'JKN Veranda',
    guestIdentity: 'CT 10713',
    guestIdentityType: 'KTP',
    guestToUserEmail: 'wisnu@veranda.com',
    guestCreatorName: 'Wisnu wijayadi',
    guestCreatorEmail: 'wisnu@veranda.com',
    qrUid: 'QR-VER-2706-SBX',
    guestAddress: 'Jl. Merdeka No. 12, Jakarta Selatan',
    guestType: 'Visitor',
    guestCheckoutByEmail: 'wisnu@veranda.com',
    guestCheckoutByName: 'Satpam Bambang',
  );

  /// Entitas tamu contoh dengan status menunggu (waiting).
  static const GuestItemEntity sampleWaitingGuest = GuestItemEntity(
    id: '2',
    guestName: 'Reni Marsiti',
    guestNumber: 'D 1892 KLP',
    guestCategory: 'Taxi • OTHER',
    guestDestination: 'JKN Veranda',
    guestToUserName: 'Wisnu wijayadi',
    guestPurpose: 'Jemput Anna Depalma',
    guestDt: '2026-09-28T14:01:00.000Z',
    guestAckDt: '2026-09-28T14:03:00.000Z',
    groupName: 'JKN Veranda',
    guestIdentity: 'CT 10822',
    guestIdentityType: 'SIM',
    guestToUserEmail: 'wisnu@veranda.com',
    guestCreatorName: 'Ahmad Subarjo',
    guestCreatorEmail: 'ahmad@kawalo.id',
    qrUid: 'QR-VER-RENI-10822',
    guestAddress: 'Jl. Cempaka Putih Timur No. 4, Jakarta Pusat',
    guestType: 'Visitor',
  );

  /// Entitas tamu contoh yang merepresentasikan spesifikasi desain DetailTamu2.
  static const GuestItemEntity sampleDetailTamu2Guest = GuestItemEntity(
    id: '5',
    guestName: 'Hendra Budiman',
    guestNumber: 'HB 438',
    guestCategory: 'Taxi • KTP',
    guestDestination: 'Wisnu wijayadi - Veranda',
    guestToUserName: 'Wisnu wijayadi',
    guestPurpose: 'Jemput Mr Sean',
    guestDt: '2026-09-28T08:49:00.000Z',
    groupName: 'JKN Veranda',
    guestIdentity: 'B 2438 SUB',
    guestIdentityType: 'KTP',
    guestToUserEmail: 'wisnu@veranda.com',
    guestCreatorName: 'Wisnu wijayadi',
    guestCreatorEmail: 'wisnu@veranda.com',
    qrUid: 'QR-VER-HB-438',
    guestAddress: 'Kompleks Harmoni Indah Blok F3, Tangerang',
    guestType: 'Visitor',
  );

  /// Entitas tamu masa lalu (bukan hari ini) untuk pengujian filter periode.
  static const GuestItemEntity samplePastGuest = GuestItemEntity(
    id: '99',
    guestName: 'Tamu Masa Lalu',
    guestNumber: 'B 9999 OLD',
    guestCategory: 'Umum • KTP',
    guestDestination: 'JKN Veranda',
    guestToUserName: 'Wisnu wijayadi',
    guestPurpose: 'Kunjungan masa lalu',
    guestDt: '2020-01-01T10:00:00.000Z',
    guestOutDt: '2020-01-01T11:00:00.000Z',
    groupName: 'JKN Veranda',
  );

  /// Daftar default entitas tamu untuk pengujian.
  static const List<GuestItemEntity> defaultGuestEntities = [
    sampleExitedGuest,
    sampleWaitingGuest,
    GuestItemEntity(
      id: '3',
      guestName: 'Lestari Logistics',
      guestNumber: 'LL 244',
      guestCategory: 'Ekspedisi • KTP',
      guestDestination: 'JKN Veranda',
      guestToUserName: 'Salam',
      guestPurpose: 'Bertemu dengan Ibu Juju di Kav. B1',
      guestDt: '2026-09-28T10:09:00.000Z',
      guestAckDt: '2026-09-28T10:12:00.000Z',
      guestOutDt: '2026-09-28T10:35:00.000Z',
      groupName: 'JKN Veranda',
      guestIdentity: 'ID 99201',
      guestIdentityType: 'KTP',
      guestToUserEmail: 'salam@jakarta-resident.com',
      guestCreatorName: 'Wisnu wijayadi',
      guestCreatorEmail: 'wisnu@veranda.com',
      qrUid: 'QR-VER-EXP-99201',
      guestAddress: 'Pergudangan Marunda Blok C, Jakarta Utara',
      guestType: 'Delivery',
      guestCheckoutByEmail: 'wisnu@veranda.com',
      guestCheckoutByName: 'Wisnu wijayadi',
    ),
    GuestItemEntity(
      id: '4',
      guestName: 'Blue Bird Taksi',
      guestNumber: 'B 1045 TAZ',
      guestCategory: 'Taxi • KTP',
      guestDestination: 'JKN Veranda',
      guestToUserName: 'Wisnu wijayadi',
      guestPurpose: 'Jemput Mr. Alex',
      guestDt: '2026-09-28T09:15:00.000Z',
      guestAckDt: '2026-09-28T09:18:00.000Z',
      guestOutDt: '2026-09-28T09:40:00.000Z',
      groupName: 'JKN Veranda',
      guestIdentity: 'CT 10540',
      guestIdentityType: 'SIM',
      guestToUserEmail: 'wisnu@veranda.com',
      guestCreatorName: 'Wisnu wijayadi',
      guestCreatorEmail: 'wisnu@veranda.com',
      qrUid: 'QR-VER-TAXI-10540',
      guestAddress: 'Pool Blue Bird Mampang, Jakarta Selatan',
      guestType: 'Taxi',
      guestCheckoutByEmail: 'wisnu@veranda.com',
      guestCheckoutByName: 'Wisnu wijayadi',
    ),
    sampleDetailTamu2Guest,
  ];

  /// Model data tamu untuk pengujian data layer.
  static const GuestModel sampleGuestModel = GuestModel(
    id: '1',
    guestName: 'Bambang Sudarsono',
    guestNumber: 'B 2706 SBX',
    guestCategory: 'Taxi • KTP',
    guestDestination: 'Wisnu wijayadi - Veranda',
    guestToUserName: 'Wisnu wijayadi',
    guestPurpose: 'Jemput Mr Sean',
    guestDt: '2026-09-28T15:21:00.000Z',
  );
}
