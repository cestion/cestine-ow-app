import 'dart:io';

/// Cooperative cancellation handle for foreground object-storage uploads.
///
/// The current transport uses [HttpClientRequest]. Future native background
/// transports can implement cancellation behind the same coordinator API.
class UploadCancelToken {
  bool _isCanceled = false;
  HttpClientRequest? _request;

  bool get isCanceled => _isCanceled;

  void attach(HttpClientRequest request) {
    _request = request;
    if (_isCanceled) {
      request.abort(const UploadCanceledException());
    }
  }

  void detach(HttpClientRequest request) {
    if (identical(_request, request)) _request = null;
  }

  void cancel() {
    if (_isCanceled) return;
    _isCanceled = true;
    _request?.abort(const UploadCanceledException());
    _request = null;
  }
}

class UploadCanceledException implements Exception {
  const UploadCanceledException();

  @override
  String toString() => 'Upload canceled';
}
