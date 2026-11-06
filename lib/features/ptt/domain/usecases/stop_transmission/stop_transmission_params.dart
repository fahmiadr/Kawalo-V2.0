import 'package:equatable/equatable.dart';

/// Command object parameter untuk operasi penghentian transmisi PTT.
class StopTransmissionParams extends Equatable {
  const StopTransmissionParams({this.reason = 'BUTTON_RELEASED'});

  final String reason;

  @override
  List<Object?> get props => [reason];
}
