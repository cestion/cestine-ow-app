import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'drama_review_model.g.dart';

@JsonSerializable()
class DramaReview extends Equatable {
  final String id;
  final String userId;
  final String dramaId;
  final int rating;
  final String? reviewText;
  final String? createdAt;
  final String? updatedAt;

  const DramaReview({
    required this.id,
    required this.userId,
    required this.dramaId,
    required this.rating,
    this.reviewText,
    this.createdAt,
    this.updatedAt,
  });

  factory DramaReview.fromJson(Map<String, dynamic> json) =>
      _$DramaReviewFromJson(json);

  Map<String, dynamic> toJson() => _$DramaReviewToJson(this);

  @override
  List<Object?> get props => [
    id,
    userId,
    dramaId,
    rating,
    reviewText,
    createdAt,
    updatedAt,
  ];
}
