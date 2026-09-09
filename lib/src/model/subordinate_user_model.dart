import 'package:equatable/equatable.dart';

class SubordinateUser extends Equatable {
  final String name;
  final String? avatarUrl;
  final String registerDate;
  final bool isActive;
  final String? userId;
  final String? bindAt;

  const SubordinateUser({
    required this.name,
    this.avatarUrl,
    required this.registerDate,
    required this.isActive,
    this.userId,
    this.bindAt,
  });

  factory SubordinateUser.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt']?.toString();
    String registerDate = '';
    if (createdAt != null) {
      final ts = int.tryParse(createdAt);
      if (ts != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ts);
        registerDate =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    }
    return SubordinateUser(
      name: (json['nickname'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      registerDate: registerDate,
      isActive: json['isValid'] == 1,
      userId: json['inviteeUserId'] as String?,
      bindAt: json['bindAt']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    name,
    avatarUrl,
    registerDate,
    isActive,
    userId,
    bindAt,
  ];
}
