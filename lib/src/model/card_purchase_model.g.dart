// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_purchase_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardPurchaseOrderRequest _$CardPurchaseOrderRequestFromJson(
  Map<String, dynamic> json,
) => CardPurchaseOrderRequest(
  walletAddress: json['walletAddress'] as String,
  cardType: json['cardType'] as String,
  quantity: (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$CardPurchaseOrderRequestToJson(
  CardPurchaseOrderRequest instance,
) => <String, dynamic>{
  'walletAddress': instance.walletAddress,
  'cardType': instance.cardType,
  'quantity': instance.quantity,
};

CardPurchaseOrderResponse _$CardPurchaseOrderResponseFromJson(
  Map<String, dynamic> json,
) => CardPurchaseOrderResponse(
  sig: json['sig'] as String?,
  expiresAt: json['expiresAt'] as String?,
  orderNo: json['orderNo'] as String?,
  payload: json['payload'] as String?,
);

Map<String, dynamic> _$CardPurchaseOrderResponseToJson(
  CardPurchaseOrderResponse instance,
) => <String, dynamic>{
  'sig': instance.sig,
  'expiresAt': instance.expiresAt,
  'orderNo': instance.orderNo,
  'payload': instance.payload,
};
