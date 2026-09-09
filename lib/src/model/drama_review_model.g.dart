// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drama_review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DramaReview _$DramaReviewFromJson(Map<String, dynamic> json) => DramaReview(
  id: json['id'] as String,
  userId: json['userId'] as String,
  dramaId: json['dramaId'] as String,
  rating: (json['rating'] as num).toInt(),
  reviewText: json['reviewText'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$DramaReviewToJson(DramaReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'dramaId': instance.dramaId,
      'rating': instance.rating,
      'reviewText': instance.reviewText,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
