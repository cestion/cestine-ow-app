import 'package:equatable/equatable.dart';

import '../core/json_helpers.dart';

/// A successfully uploaded multipart slice, persisted with its owning
/// `UploadTask` so an interrupted upload can resume from the last part.
///
/// `eTag` comes from the S3 presigned-PUT response header and is required by
/// the backend when submitting the merge (complete) request.
class UploadedPart extends Equatable {
  final int partNumber;
  final String eTag;
  final int size;

  const UploadedPart({
    required this.partNumber,
    required this.eTag,
    required this.size,
  });

  Map<String, dynamic> toMap() => {
        'partNumber': partNumber,
        'eTag': eTag,
        'size': size,
      };

  static UploadedPart? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final partNumber = asIntOrNull(map['partNumber']);
    final eTag = asStringOrNull(map['eTag']);
    if (partNumber == null || partNumber < 1 || eTag == null || eTag.isEmpty) {
      return null;
    }
    return UploadedPart(
      partNumber: partNumber,
      eTag: eTag,
      size: asIntOrNull(map['size']) ?? 0,
    );
  }

  @override
  List<Object?> get props => [partNumber, eTag, size];
}
