import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/post_incident_reply/post_incident_reply_params.dart';

/// Use case untuk mengirimkan pesan balasan atau foto pada thread insiden.
class PostIncidentReplyUseCase
    implements UseCase<IncidentReplyEntity, PostIncidentReplyParams> {
  /// Membuat instance [PostIncidentReplyUseCase].
  const PostIncidentReplyUseCase(this.repository);

  /// Repositori insiden.
  final IncidentRepository repository;

  @override
  Future<Either<Failure, IncidentReplyEntity>> call(
    PostIncidentReplyParams params,
  ) async {
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Diskusi telah ditutup atau Anda tidak memiliki akses ke insiden '
          'ini.',
        ),
      );
    }

    if (params.message.trim().isEmpty && params.photos.isEmpty) {
      return const Left(
        ValidationFailure('Pesan balasan atau foto lampiran wajib diisi.'),
      );
    }

    return await repository.postIncidentReply(params.toRepositoryData());
  }
}
