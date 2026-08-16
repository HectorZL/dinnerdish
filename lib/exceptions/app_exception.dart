abstract class AppException implements Exception {
  final String message;
  final String code;

  const AppException(this.message, this.code);

  /// User-facing aliases shared by forms, SnackBars and inline messages.
  String get errorText => message;
  String get snackBarText => message;

  @override
  String toString() => '[$code] $message';
}
