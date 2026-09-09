import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/result.dart';
import 'package:story_app/src/core/upload_failure.dart';

void main() {
  group('multipart business codes', () {
    test('121012 maps to fileTypeNotAllowed', () {
      final failure = UploadFailure.fromApiError(
        const BusinessError(121012, 'FILE_TYPE_NOT_ALLOWED'),
      );
      expect(failure.kind, UploadFailureKind.fileTypeNotAllowed);
      expect(failure.diagnosticCode, contains('UP-FILE-TYPE'));
    });

    test('121013 maps to fileSizeExceeded', () {
      final failure = UploadFailure.fromApiError(
        const BusinessError(121013, 'FILE_SIZE_EXCEEDED'),
      );
      expect(failure.kind, UploadFailureKind.fileSizeExceeded);
      expect(failure.diagnosticCode, contains('UP-FILE-SIZE'));
    });

    test('121026 maps to multipartInvalid', () {
      final failure = UploadFailure.fromApiError(
        const BusinessError(121026, 'MULTIPART_UPLOAD_INVALID'),
      );
      expect(failure.kind, UploadFailureKind.multipartInvalid);
      expect(failure.diagnosticCode, contains('UP-MULTIPART'));
      expect(failure.diagnosticCode, contains('SVC 121026'));
    });

    test('new kinds round-trip through encoded/tryParse', () {
      for (final kind in [
        UploadFailureKind.fileTypeNotAllowed,
        UploadFailureKind.fileSizeExceeded,
        UploadFailureKind.multipartInvalid,
      ]) {
        final encoded = UploadFailure(kind, detailCode: 121026).encoded;
        final parsed = UploadFailure.tryParse(encoded);
        expect(parsed?.kind, kind);
        expect(parsed?.detailCode, 121026);
      }
    });

    test('unknown business codes still fall back to rejected', () {
      final failure = UploadFailure.fromApiError(
        const BusinessError(199999, 'UNEXPECTED'),
      );
      expect(failure.kind, UploadFailureKind.rejected);
    });
  });
}
