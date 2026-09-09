// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DramaTag _$DramaTagFromJson(Map<String, dynamic> json) => DramaTag(
  id: asString(json['id']),
  code: json['code'] as String?,
  name: json['name'] as String?,
);

Map<String, dynamic> _$DramaTagToJson(DramaTag instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
};
