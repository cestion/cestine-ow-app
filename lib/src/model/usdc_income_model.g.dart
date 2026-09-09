// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usdc_income_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsdcIncomeItem _$UsdcIncomeItemFromJson(Map<String, dynamic> json) =>
    UsdcIncomeItem(
      id: json['id'] as String?,
      createdAt: json['createdAt'] as String?,
      type: json['type'] as String?,
      actorCollectionId: json['actorCollectionId'] as String?,
      actorName: json['actorName'] as String?,
      tokenId: json['tokenId'] as String?,
      amount: json['amount'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$UsdcIncomeItemToJson(UsdcIncomeItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt,
      'type': instance.type,
      'actorCollectionId': instance.actorCollectionId,
      'actorName': instance.actorName,
      'tokenId': instance.tokenId,
      'amount': instance.amount,
      'status': instance.status,
    };

UsdcIncomePage _$UsdcIncomePageFromJson(Map<String, dynamic> json) =>
    UsdcIncomePage(
      total: json['total'] as String?,
      mark: json['mark'] as String?,
      pageSize: json['pageSize'] as String?,
      hasMore: json['hasMore'] as bool?,
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => UsdcIncomeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UsdcIncomePageToJson(UsdcIncomePage instance) =>
    <String, dynamic>{
      'total': instance.total,
      'mark': instance.mark,
      'pageSize': instance.pageSize,
      'hasMore': instance.hasMore,
      'list': instance.list?.map((e) => e.toJson()).toList(),
    };
