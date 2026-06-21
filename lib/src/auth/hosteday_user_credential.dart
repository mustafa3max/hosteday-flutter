import 'hosteday_session.dart';
import 'hosteday_user.dart';

/// Returned after a successful HosteDay authentication operation.
class HosteDayUserCredential {
  /// The authenticated user.
  final HosteDayUser user;

  /// The newly created authenticated session.
  final HosteDaySession session;

  /// Indicates whether this credential originated from registration.
  final bool isNewUser;

  /// Creates a HosteDay authentication result.
  const HosteDayUserCredential({
    required this.user,
    required this.session,
    required this.isNewUser,
  });
}
