import 'package:equatable/equatable.dart';

import 'json_converters.dart';

/// Credentials returned by the platform API for a Centrifugo connection.
///
/// The token is intentionally kept in memory only. [userId] is the trusted
/// server-side identity used to build user-restricted channel names.
class CentrifugoConnectionInfo extends Equatable {
  final String token;
  final String userId;

  const CentrifugoConnectionInfo({required this.token, required this.userId});

  factory CentrifugoConnectionInfo.fromJson(Map<String, dynamic> json) =>
      CentrifugoConnectionInfo(
        token: asString(json['token'])?.trim() ?? '',
        userId: asString(json['userId'])?.trim() ?? '',
      );

  bool get isValid => token.isNotEmpty && userId.isNotEmpty;

  @override
  List<Object?> get props => [token, userId];
}
