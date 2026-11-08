/// Domain failures shared by features. Messages are user-facing and never
/// contain secrets, terminal bytes or payloads.
library;

abstract class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The server presented a different host key than the pinned one. This is a
/// hard stop: no UI may offer "continue anyway".
final class HostKeyMismatchFailure extends AppFailure {
  const HostKeyMismatchFailure({required this.expected, required this.actual})
    : super('Host key changed. The connection was blocked.');
  final String expected;
  final String actual;

  bool get overridable => false;
}

final class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'The host rejected this device key.']);
}

final class ConnectionFailure extends AppFailure {
  const ConnectionFailure([super.message = 'Could not reach the host.']);
}

final class UserCancelledFailure extends AppFailure {
  const UserCancelledFailure([super.message = 'Unlock was cancelled.']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class HookFailure extends AppFailure {
  const HookFailure(this.code, String message) : super(message);
  final String code;
}

final class PairingFailure extends AppFailure {
  const PairingFailure(super.message);
}

final class PushFailure extends AppFailure {
  const PushFailure(super.message);
}
