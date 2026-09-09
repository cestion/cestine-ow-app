import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'user_profile_model.dart';

part 'login_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class LoginResponse extends Equatable {
  final String? token;
  @JsonKey(fromJson: _userProfileFromJson)
  final UserProfile? userProfile;

  const LoginResponse({this.token, this.userProfile});

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  static UserProfile? _userProfileFromJson(Object? json) {
    if (json == null) return null;
    if (json is UserProfile) return json;
    if (json is Map<String, dynamic>) return UserProfile.fromJson(json);
    return null;
  }

  @override
  List<Object?> get props => [token, userProfile];
}
