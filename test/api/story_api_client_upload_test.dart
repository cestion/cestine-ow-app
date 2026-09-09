import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/api/story_api_client.dart';
import 'package:story_app/src/api/upload_cancel_token.dart';
import 'package:story_app/src/core/result.dart';

void main() {
  late HttpServer server;
  late StoryApiClient client;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = StoryApiClient(baseUrl: 'http://localhost', maxRetries: 0);
  });

  tearDown(() async {
    client.dispose();
    await server.close(force: true);
  });

  Stream<List<int>> byteStreamOf(List<int> bytes, {int chunkSize = 4}) async* {
    for (var i = 0; i < bytes.length; i += chunkSize) {
      yield bytes.sublist(
        i,
        (i + chunkSize).clamp(0, bytes.length),
      );
      // Yield to the event loop so streamed chunks interleave realistically.
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('uploadBytes', () {
    test('streams the body, applies headers and reports progress', () async {
      final body = List<int>.generate(64, (i) => i);
      late HttpRequest received;
      final progressCalls = <int>[];
      server.listen((request) async {
        received = request;
        await request.drain<void>();
        request.response.statusCode = 200;
        await request.response.close();
      });

      final result = await client.uploadBytes(
        url: 'http://localhost:${server.port}/object',
        byteStream: byteStreamOf(body),
        contentLength: body.length,
        headers: {'x-amz-acl': 'public-read', 'Content-Type': 'video/mp4'},
        onProgress: (sent, total) => progressCalls.add(sent),
      );

      expect(result.isSuccess, isTrue);
      expect(received.headers.value('x-amz-acl'), 'public-read');
      expect(received.headers.contentType?.mimeType, 'video/mp4');
      expect(progressCalls, isNotEmpty);
      expect(progressCalls.last, body.length);
    });

    test('returns network failure for non-2xx status', () async {
      server.listen((request) async {
        await request.drain<void>();
        request.response.statusCode = 403;
        await request.response.close();
      });

      final result = await client.uploadBytes(
        url: 'http://localhost:${server.port}/object',
        byteStream: byteStreamOf([1, 2, 3]),
        contentLength: 3,
      );

      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('fails fast when the cancel token is already canceled', () async {
      final token = UploadCancelToken()..cancel();

      final result = await client.uploadBytes(
        url: 'http://localhost:${server.port}/object',
        byteStream: byteStreamOf([1, 2, 3]),
        contentLength: 3,
        cancelToken: token,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<UnknownError>());
    });
  });

  group('uploadPart', () {
    test('returns the ETag response header on success', () async {
      var receivedBytes = 0;
      server.listen((request) async {
        await for (final chunk in request) {
          receivedBytes += chunk.length;
        }
        request.response.statusCode = 200;
        request.response.headers.set(HttpHeaders.etagHeader, '"abc123"');
        await request.response.close();
      });

      final part = List<int>.generate(32, (i) => i);
      var lastSent = 0;
      final result = await client.uploadPart(
        url: 'http://localhost:${server.port}/object?partNumber=1',
        byteStream: byteStreamOf(part),
        contentLength: part.length,
        onProgress: (sent, total) {
          lastSent = sent;
          expect(total, part.length);
        },
      );

      expect(result.dataOrNull, '"abc123"');
      expect(receivedBytes, part.length);
      expect(lastSent, part.length);
    });

    test('fails with a parse error when ETag is missing', () async {
      server.listen((request) async {
        await request.drain<void>();
        request.response.statusCode = 200;
        await request.response.close();
      });

      final result = await client.uploadPart(
        url: 'http://localhost:${server.port}/object?partNumber=1',
        byteStream: byteStreamOf([1, 2, 3]),
        contentLength: 3,
      );

      expect(result.errorOrNull, isA<ParseError>());
    });
  });
}
