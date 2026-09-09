import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'tag_model.g.dart';

@JsonSerializable()
class DramaTag extends Equatable {
  @JsonKey(fromJson: asString)
  final String? id;
  final String? code;
  final String? name;

  const DramaTag({this.id, this.code, this.name});

  factory DramaTag.fromJson(Map<String, dynamic> json) =>
      _$DramaTagFromJson(json);

  Map<String, dynamic> toJson() => _$DramaTagToJson(this);

  @override
  List<Object?> get props => [id, code, name];
}
