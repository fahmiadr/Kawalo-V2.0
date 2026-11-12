import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/face_photo_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/face_photos_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements AttendanceAdminRepository {}

void main() {
  late MockRepository repository;
  late FacePhotosCubit cubit;

  setUp(() {
    repository = MockRepository();
    cubit = FacePhotosCubit(repository: repository, email: 'siti@kawalo.id');
    when(() => repository.discardPhoto(any())).thenAnswer((_) async {});
  });

  test('downloads every photo and deletes the files on close', () async {
    when(() => repository.getFacePhotos('siti@kawalo.id')).thenAnswer(
      (_) async =>
          const Right([FacePhotoEntity(id: 'a'), FacePhotoEntity(id: 'b')]),
    );
    when(
      () => repository.downloadFacePhoto(
        email: 'siti@kawalo.id',
        photoId: any(named: 'photoId'),
      ),
    ).thenAnswer((i) async => Right('/tmp/${i.namedArguments[#photoId]}.jpg'));

    await cubit.load();
    expect(cubit.state.phase, FacePhotosPhase.loaded);
    expect(cubit.state.paths, ['/tmp/a.jpg', '/tmp/b.jpg']);

    await cubit.close();
    verify(() => repository.discardPhoto('/tmp/a.jpg')).called(1);
    verify(() => repository.discardPhoto('/tmp/b.jpg')).called(1);
  });

  test('an empty registration is loaded, not an error', () async {
    when(
      () => repository.getFacePhotos(any()),
    ).thenAnswer((_) async => const Right([]));

    await cubit.load();

    expect(cubit.state.phase, FacePhotosPhase.loaded);
    expect(cubit.state.paths, isEmpty);
    await cubit.close();
  });

  test('a failed listing is reported', () async {
    when(
      () => repository.getFacePhotos(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('Terlarang')));

    await cubit.load();

    expect(cubit.state.phase, FacePhotosPhase.failure);
    expect(cubit.state.errorMessage, 'Terlarang');
    await cubit.close();
  });
}
