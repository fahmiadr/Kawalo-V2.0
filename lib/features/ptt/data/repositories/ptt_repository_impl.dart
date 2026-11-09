import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_native_platform_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/mappers/ptt_mapper.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_event_dto.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';

class PttRepositoryImpl implements PttRepository {
  PttRepositoryImpl({required this.dataSource});

  final PttNativePlatformDataSource dataSource;

  @override
  Future<Either<Failure, void>> joinChannel({
    required String channelUrl,
    required String groupUid,
    required String token,
  }) async {
    try {
      await dataSource.joinChannel(
        channelUrl: channelUrl,
        groupUid: groupUid,
        token: token,
      );
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal bergabung ke saluran PTT'));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> leaveChannel() async {
    try {
      await dataSource.leaveChannel();
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal keluar dari saluran PTT'));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startTransmission({
    required String requestId,
  }) async {
    try {
      await dataSource.startTransmission(requestId: requestId);
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memulai transmisi PTT'));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopTransmission() async {
    try {
      await dataSource.stopTransmission();
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(
        ServerFailure(e.message ?? 'Gagal menghentikan transmisi PTT'),
      );
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAuthToken(String token) async {
    try {
      await dataSource.updateAuthToken(token);
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(
        ServerFailure(e.message ?? 'Gagal memperbarui token autentikasi PTT'),
      );
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<bool> hasRecordAudioPermission() async {
    try {
      return await dataSource.hasRecordAudioPermission();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> requestRecordAudioPermission() async {
    try {
      return await dataSource.requestRecordAudioPermission();
    } on Object {
      return false;
    }
  }

  @override
  Stream<PttFloorStateEntity> watchFloorState() {
    return dataSource.eventStream
        .where((event) => event.eventType == 'floorStateChanged')
        .map((event) {
          final dto = PttFloorStateDto.fromMap(event.rawMap);
          return PttMapper.toFloorStateEntity(dto);
        });
  }

  @override
  Stream<PttConnectionStatus> watchConnectionStatus() {
    return dataSource.eventStream
        .where((event) => event.eventType == 'connectionStatusChanged')
        .map((event) {
          final statusStr =
              event.rawMap['status']?.toString() ?? 'DISCONNECTED';
          return PttMapper.toConnectionStatus(statusStr);
        });
  }

  @override
  Stream<int> watchMemberCount() {
    return dataSource.eventStream
        .where((event) => event.eventType == 'memberCountChanged')
        .map((event) {
          return (event.rawMap['memberCount'] as num?)?.toInt() ?? 1;
        });
  }

  @override
  Stream<Map<String, dynamic>> watchTransmissionEvents() {
    return dataSource.eventStream
        .where((event) => event.eventType == 'transmissionStateChanged')
        .map((event) => Map<String, dynamic>.from(event.rawMap));
  }
}
