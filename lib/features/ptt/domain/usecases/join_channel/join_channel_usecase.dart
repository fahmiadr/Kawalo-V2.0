import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/join_channel/join_channel_params.dart';

/// UseCase untuk menginisialisasi koneksi latar belakang dan bergabung ke
/// saluran PTT.
class JoinChannelUseCase implements UseCase<void, JoinChannelParams> {
  const JoinChannelUseCase(this.repository);

  final PttRepository repository;

  @override
  Future<Either<Failure, void>> call(JoinChannelParams params) {
    if (params.channelUrl.trim().isEmpty ||
        params.groupUid.trim().isEmpty ||
        params.token.trim().isEmpty) {
      return Future.value(
        const Left(ServerFailure('Parameter saluran PTT tidak boleh kosong.')),
      );
    }

    return repository.joinChannel(
      channelUrl: params.channelUrl,
      groupUid: params.groupUid,
      token: params.token,
    );
  }
}
