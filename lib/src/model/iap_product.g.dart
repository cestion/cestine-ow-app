// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iap_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IapProduct _$IapProductFromJson(Map<String, dynamic> json) => IapProduct(
  productId: json['id'] as String,
  grantedAmount: IapProduct._amountFromJson(json['amount']),
  priceUsd: IapProduct._priceFromJson(json['price']),
  currency: json['currency'] as String?,
  active: json['active'] as bool? ?? true,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$IapProductToJson(IapProduct instance) =>
    <String, dynamic>{
      'id': instance.productId,
      'amount': instance.grantedAmount,
      'price': instance.priceUsd,
      'currency': instance.currency,
      'active': instance.active,
      'sortOrder': instance.sortOrder,
    };
