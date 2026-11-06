import 'package:equatable/equatable.dart';

/// Command object parameter untuk operasi join channel PTT.
class JoinChannelParams extends Equatable {
  const JoinChannelParams({
    required this.channelUrl,
    required this.groupUid,
    required this.token,
  });

  final String channelUrl;
  final String groupUid;
  final String token;

  @override
  List<Object?> get props => [channelUrl, groupUid, token];
}
