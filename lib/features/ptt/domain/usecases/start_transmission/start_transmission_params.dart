import 'package:equatable/equatable.dart';

/// Command object parameter untuk operasi mulai transmisi PTT.
class StartTransmissionParams extends Equatable {
  const StartTransmissionParams({required this.requestId});

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}
