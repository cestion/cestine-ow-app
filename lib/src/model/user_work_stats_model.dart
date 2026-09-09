import 'package:equatable/equatable.dart';

import 'json_converters.dart';

class UserWorkStats extends Equatable {
  final int workCount;
  final int dramaCount;
  final int shortVideoCount;
  final int collectionCount;
  final int totalLikeCount;

  const UserWorkStats({
    this.workCount = 0,
    this.dramaCount = 0,
    this.shortVideoCount = 0,
    this.collectionCount = 0,
    this.totalLikeCount = 0,
  });

  factory UserWorkStats.fromJson(Map<String, dynamic> json) {
    return UserWorkStats(
      workCount: asInt(json['workCount']) ?? 0,
      dramaCount: asInt(json['dramaCount']) ?? 0,
      shortVideoCount: asInt(json['shortVideoCount']) ?? 0,
      collectionCount: asInt(json['collectionCount']) ?? 0,
      totalLikeCount: asInt(json['totalLikeCount']) ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    workCount,
    dramaCount,
    shortVideoCount,
    collectionCount,
    totalLikeCount,
  ];
}
