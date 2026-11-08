import 'hosteday_session.dart';
import 'hosteday_user.dart';

/// Returned after a successful Hosteday authentication operation.
class HostedayUserCredential {
  /// The authenticated user.
  final HostedayUser user;

  /// The newly created authenticated session.
  final HostedaySession session;

  /// Indicates whether this credential originated from registration.
  final bool isNewUser;

  /// Creates a Hosteday authentication result.
  const HostedayUserCredential({
    required this.user,
    required this.session,
    required this.isNewUser,
  });
}

/// Deprecated spelling of [HostedayUserCredential].
@Deprecated('Use HostedayUserCredential instead.')
typedef HosteDayUserCredential = HostedayUserCredential;
