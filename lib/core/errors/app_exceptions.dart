sealed class AppException implements Exception {
  const AppException();
}

final class DatabaseException extends AppException {
  const DatabaseException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  DatabaseException copyWith({String? message, Object? cause}) =>
      DatabaseException(
        message ?? this.message,
        cause ?? this.cause,
      );

  @override
  String toString() => cause != null
      ? 'DatabaseException: $message (caused by: $cause)'
      : 'DatabaseException: $message';
}

final class ParseException extends AppException {
  const ParseException(this.message, this.bankName);

  final String message;
  final String? bankName;

  ParseException copyWith({String? message, String? bankName}) => ParseException(
        message ?? this.message,
        bankName ?? this.bankName,
      );

  @override
  String toString() => bankName != null
      ? 'ParseException[$bankName]: $message'
      : 'ParseException: $message';
}

final class NetworkException extends AppException {
  const NetworkException(this.message, this.statusCode);

  final String message;
  final int? statusCode;

  NetworkException copyWith({String? message, int? statusCode}) =>
      NetworkException(
        message ?? this.message,
        statusCode ?? this.statusCode,
      );

  @override
  String toString() => statusCode != null
      ? 'NetworkException[$statusCode]: $message'
      : 'NetworkException: $message';
}

final class AuthException extends AppException {
  const AuthException(this.message);

  final String message;

  AuthException copyWith({String? message}) =>
      AuthException(message ?? this.message);

  @override
  String toString() => 'AuthException: $message';
}

final class ImportException extends AppException {
  const ImportException(this.message, this.rowIndex);

  final String message;
  final int rowIndex;

  ImportException copyWith({String? message, int? rowIndex}) => ImportException(
        message ?? this.message,
        rowIndex ?? this.rowIndex,
      );

  @override
  String toString() => 'ImportException[row $rowIndex]: $message';
}
