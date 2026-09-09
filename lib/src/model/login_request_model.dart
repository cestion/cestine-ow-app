import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'login_request_model.g.dart';

/// Values for [LoginRequest.deviceType] (`WEB` / `APP`).
abstract final class LoginDeviceType {
  static const web = 'WEB';
  static const app = 'APP';
}

@JsonSerializable()
class LoginRequest extends Equatable {
  final String privyToken;
  final String? inviteCode;

  /// 设备类型：WEB / APP；App 端固定传 [LoginDeviceType.app]。
  final String deviceType;

  const LoginRequest({
    required this.privyToken,
    required this.deviceType,
    this.inviteCode,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  @override
  List<Object?> get props => [privyToken, inviteCode, deviceType];
}
