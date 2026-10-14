/// A backend-neutral error raised by services.
///
/// View models must never catch `FirebaseFunctionsException`,
/// `FirebaseAuthException` or `FirebaseException` by type — that ties the UI to
/// one backend forever. Services translate those into this, keeping the error
/// [code] string, so a view model can still branch on "permission-denied" or
/// "too-many-requests" without importing a Firebase package.
class ServiceException implements Exception {
  /// The backend's error code, e.g. `permission-denied`, `unavailable`,
  /// `failed-precondition`, `too-many-requests`.
  final String code;
  final String? message;

  /// The original error, kept for logging.
  final Object? cause;

  const ServiceException(this.code, {this.message, this.cause});

  /// True when the failure is a connectivity problem rather than a server or
  /// permission fault.
  bool get isUnavailable => code == 'unavailable';

  @override
  String toString() =>
      'ServiceException($code${message == null ? '' : ': $message'})';
}
