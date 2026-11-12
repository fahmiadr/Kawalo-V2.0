import 'package:equatable/equatable.dart';

/// One registration photo of a member's face.
class FacePhotoEntity extends Equatable {
  const FacePhotoEntity({required this.id, this.createdAt});

  final String id;
  final String? createdAt;

  @override
  List<Object?> get props => [id, createdAt];
}
