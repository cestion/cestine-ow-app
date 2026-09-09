import 'package:equatable/equatable.dart';

sealed class Result<T> with Equatable {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(ApiError error) = Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiError error) failure,
  }) {
    return switch (this) {
      Success(data: final d) => success(d),
      Failure(error: final e) => failure(e),
    };
  }

  Future<R> whenAsync<R>({
    required Future<R> Function(T data) success,
    required Future<R> Function(ApiError error) failure,
  }) async {
    return switch (this) {
      Success(data: final d) => await success(d),
      Failure(error: final e) => await failure(e),
    };
  }

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success(data: final d) => d,
    Failure() => null,
  };

  ApiError? get errorOrNull => switch (this) {
    Success() => null,
    Failure(error: final e) => e,
  };

  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final d) => Result.success(transform(d)),
      Failure(error: final e) => Result.failure(e),
    };
  }

  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    return switch (this) {
      Success(data: final d) => Result.success(await transform(d)),
      Failure(error: final e) => Result.failure(e),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  List<Object?> get props => [data];

  @override
  String toString() => 'Success(data: $data)';
}

class Failure<T> extends Result<T> {
  final ApiError error;
  const Failure(this.error);

  @override
  List<Object?> get props => [error];

  @override
  String toString() => 'Failure(error: $error)';
}

sealed class ApiError with Equatable {
  const ApiError();

  factory ApiError.network(String message, {Exception? exception}) =
      NetworkError;
  factory ApiError.parse(String message, {Exception? exception}) = ParseError;
  factory ApiError.business(int code, String message) = BusinessError;
  factory ApiError.timeout(String message) = TimeoutError;
  factory ApiError.unauthorized(String message) = UnauthorizedError;
  factory ApiError.unknown(String message, {Exception? exception}) =
      UnknownError;
  factory ApiError.notSupported(String message) = NotSupportedError;
  factory ApiError.rateLimit(String message) = RateLimitError;
  factory ApiError.validation(
    String message, {
    Map<String, String>? fieldErrors,
  }) = ValidationError;
  factory ApiError.notFound(String message) = NotFoundError;
  factory ApiError.forbidden(String message) = ForbiddenError;

  /// Human-readable fallback error message (English).
  /// Use [l10nKey] / [l10nArgs] + [BuildContext.l10nError] for localized
  /// display in the UI layer. This fallback is only used when no
  /// [BuildContext] is available.
  String get userMessage => switch (this) {
    NetworkError(:final message) => 'Network error: $message',
    ParseError() => 'Failed to parse response data',
    BusinessError(:final message) =>
      message.isEmpty ? 'Operation failed' : message,
    TimeoutError() => 'Request timed out, please try again',
    UnauthorizedError() => 'Please log in first',
    UnknownError(:final message) => 'An unknown error occurred: $message',
    NotSupportedError(:final message) => message,
    RateLimitError() => 'Too many requests, please try again later',
    ValidationError(:final message) => message,
    NotFoundError() => 'Resource not found',
    ForbiddenError() => 'Access denied',
  };

  /// Localization key for looking up the error message via [AppLocalizations].
  String get l10nKey => switch (this) {
    NetworkError() => 'errorNetwork',
    ParseError() => 'errorParse',
    BusinessError() => 'errorBusiness',
    TimeoutError() => 'errorTimeout',
    UnauthorizedError() => 'errorUnauthorized',
    UnknownError() => 'errorUnknown',
    NotSupportedError() => 'errorNotSupported',
    RateLimitError() => 'errorRateLimit',
    ValidationError() => 'errorValidation',
    NotFoundError() => 'errorNotFound',
    ForbiddenError() => 'errorForbidden',
  };

  /// Arguments passed to parameterized l10n messages.
  Map<String, String> get l10nArgs => switch (this) {
    NetworkError() => const {},
    ParseError() => const {},
    BusinessError(:final message) => {'message': message},
    TimeoutError() => const {},
    UnauthorizedError() => const {},
    UnknownError(:final message) => {'message': message},
    NotSupportedError(:final message) => {'message': message},
    RateLimitError() => const {},
    ValidationError(:final message, :final fieldErrors) => {
      'message': message,
      if (fieldErrors != null) 'fieldErrors': fieldErrors.toString(),
    },
    NotFoundError() => const {},
    ForbiddenError() => const {},
  };
}

class NetworkError extends ApiError {
  final String message;
  final Exception? exception;
  const NetworkError(this.message, {this.exception});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'NetworkError(message: $message, exception: $exception)';
}

class ParseError extends ApiError {
  final String message;
  final Exception? exception;
  const ParseError(this.message, {this.exception});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ParseError(message: $message, exception: $exception)';
}

class BusinessError extends ApiError {
  final int code;
  final String message;
  const BusinessError(this.code, this.message);

  @override
  List<Object?> get props => [code, message];

  @override
  String toString() => 'BusinessError(code: $code, message: $message)';
}

class TimeoutError extends ApiError {
  final String message;
  const TimeoutError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'TimeoutError(message: $message)';
}

class UnauthorizedError extends ApiError {
  final String message;
  const UnauthorizedError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'UnauthorizedError(message: $message)';
}

class UnknownError extends ApiError {
  final String message;
  final Exception? exception;
  const UnknownError(this.message, {this.exception});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'UnknownError(message: $message, exception: $exception)';
}

class NotSupportedError extends ApiError {
  final String message;
  const NotSupportedError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'NotSupportedError(message: $message)';
}

class RateLimitError extends ApiError {
  final String message;
  const RateLimitError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'RateLimitError(message: $message)';
}

class ValidationError extends ApiError {
  final String message;
  final Map<String, String>? fieldErrors;
  const ValidationError(this.message, {this.fieldErrors});

  @override
  List<Object?> get props => [message, fieldErrors];

  @override
  String toString() =>
      'ValidationError(message: $message, fieldErrors: $fieldErrors)';
}

class NotFoundError extends ApiError {
  final String message;
  const NotFoundError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'NotFoundError(message: $message)';
}

class ForbiddenError extends ApiError {
  final String message;
  const ForbiddenError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ForbiddenError(message: $message)';
}
