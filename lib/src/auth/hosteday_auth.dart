import 'dart:async';
import 'dart:convert';

import '../config/hosteday_config.dart';
import '../exceptions/hosteday_exception.dart';
import '../http/hosteday_http_client.dart';
import 'hosteday_auth_exception.dart';
import 'hosteday_auth_storage.dart';
import 'hosteday_session.dart';
import 'hosteday_user.dart';
import 'hosteday_user_credential.dart';

/// Provides Firebase-style authentication methods for HosteDay.
///
/// Supports:
/// - Email/password sign-in
/// - Email/password registration
/// - Session restoration
/// - Current user access
/// - Auth state streams
/// - Password reset requests
/// - User reload and profile update
/// - Sign-out
class HosteDayAuth {
  /// API configuration that defines auth endpoints.
  final HosteDayConfig config;

  /// HTTP client used for authentication requests.
  final HosteDayHttpClient http;

  /// Persistent storage for the authenticated session.
  final HosteDayAuthStorage storage;

  /// Called after the local user session has been removed.
  ///
  /// HosteDayClient uses this to disconnect realtime safely on sign-out.
  final Future<void> Function()? _onSessionCleared;

  final StreamController<HosteDayUser?> _authStateController =
      StreamController<HosteDayUser?>.broadcast();

  final StreamController<HosteDayUser?> _idTokenController =
      StreamController<HosteDayUser?>.broadcast();

  final StreamController<HosteDayUser?> _userController =
      StreamController<HosteDayUser?>.broadcast();

  HosteDaySession? _currentSession;
  bool _initialized = false;
  bool _disposed = false;

  /// Creates a HosteDay auth service.
  HosteDayAuth({
    required this.config,
    required this.http,
    required this.storage,
    Future<void> Function()? onSessionCleared,
  }) : _onSessionCleared = onSessionCleared;

  /// Whether the local session has been restored from storage.
  bool get isInitialized => _initialized;

  /// Returns the active HosteDay user, or null when signed out.
  HosteDayUser? get currentUser => _currentSession?.user;

  /// Returns the active authenticated session, or null when signed out.
  HosteDaySession? get currentSession => _currentSession;

  /// Restores the saved session after SDK initialization.
  ///
  /// Expired or invalid local sessions are removed automatically.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final serializedSession = await storage.read(
      HosteDayAuthStorageKeys.session,
    );

    if (serializedSession != null && serializedSession.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(serializedSession);

        if (decoded is! Map) {
          throw const FormatException(
            'Stored HosteDay session is not a JSON object.',
          );
        }

        final session = HosteDaySession.fromJson(
          Map<String, dynamic>.from(decoded),
        );

        if (session.isExpired) {
          await _removePersistedSession();
        } else {
          _currentSession = session;
        }
      } on FormatException {
        await _removePersistedSession();
      }
    }

    _initialized = true;
  }

  /// Emits the current auth state immediately, then emits on sign-in/sign-out.
  Stream<HosteDayUser?> authStateChanges() {
    return _streamWithInitialValue(
      _authStateController.stream,
      currentUser,
    );
  }

  /// Emits the current user immediately, then emits on auth or token changes.
  Stream<HosteDayUser?> idTokenChanges() {
    return _streamWithInitialValue(
      _idTokenController.stream,
      currentUser,
    );
  }

  /// Emits the current user immediately, then emits on auth or user changes.
  Stream<HosteDayUser?> userChanges() {
    return _streamWithInitialValue(
      _userController.stream,
      currentUser,
    );
  }

  /// Returns the current access token, or null when signed out.
  Future<String?> getAccessToken() async {
    await _ensureInitialized();

    return _currentSession?.accessToken;
  }

  /// Signs in an existing user using email and password.
  Future<HosteDayUserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    _validateEmailAndPassword(
      email: email,
      password: password,
    );

    return _authenticate(
      path: config.loginPathPost,
      body: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
      isNewUser: false,
    );
  }

  /// Creates a new user and signs that user in.
  ///
  /// Pass fields such as `name`, `phone`, or tenant data through
  /// [additionalData].
  Future<HosteDayUserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    Map<String, dynamic> additionalData = const <String, dynamic>{},
  }) {
    _validateEmailAndPassword(
      email: email,
      password: password,
    );

    return _authenticate(
      path: config.registerPathPost,
      body: <String, dynamic>{
        ...additionalData,
        'email': email.trim(),
        'password': password,
        'password_confirmation': password,
      },
      isNewUser: true,
    );
  }

  /// Requests a password-reset email.
  Future<void> sendPasswordResetEmail({
    required String email,
    Map<String, dynamic> additionalData = const <String, dynamic>{},
  }) async {
    if (email.trim().isEmpty) {
      throw const HosteDayAuthException(
        "An email address is required.",
        code: 'invalid-email',
      );
    }

    try {
      await http.post(
        config.forgotPasswordPathPost,
        body: <String, dynamic>{
          ...additionalData,
          'email': email.trim(),
        },
      );
    } on HosteDayException catch (error) {
      throw HosteDayAuthException.fromHosteDayException(error);
    }
  }

  /// Resets a password using the reset token delivered by email.
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
    Map<String, dynamic> additionalData = const <String, dynamic>{},
  }) async {
    if (email.trim().isEmpty) {
      throw const HosteDayAuthException(
        'An email address is required.',
        code: 'invalid-email',
      );
    }

    if (token.trim().isEmpty) {
      throw const HosteDayAuthException(
        'A password reset token is required.',
        code: 'invalid-action-code',
      );
    }

    if (newPassword.isEmpty) {
      throw const HosteDayAuthException(
        'A new password is required.',
        code: 'weak-password',
      );
    }

    try {
      await http.post(
        config.resetPasswordPathPost,
        body: <String, dynamic>{
          ...additionalData,
          'email': email.trim(),
          'token': token.trim(),
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );
    } on HosteDayException catch (error) {
      throw HosteDayAuthException.fromHosteDayException(error);
    }
  }

  /// Reloads the authenticated user's profile from the HosteDay API.
  Future<HosteDayUser> reload() async {
    await _ensureInitialized();
    _requireSignedInUser();

    try {
      final response = await http.get(
        config.userShowPathGet,
        withAuth: true,
      );

      final user = HosteDayUser.fromJson(
        _extractUserPayload(response),
      );

      await _replaceCurrentUser(user);

      return user;
    } on HosteDayException catch (error) {
      throw HosteDayAuthException.fromHosteDayException(error);
    }
  }

  /// Updates the authenticated user's profile.
  ///
  /// The exact accepted fields are defined by the HosteDay Laravel backend.
  Future<HosteDayUser> updateProfile(
    Map<String, dynamic> data,
  ) async {
    await _ensureInitialized();
    _requireSignedInUser();

    try {
      final response = await http.put(
        config.userUpdatePathPut,
        withAuth: true,
        body: data,
      );

      final userPayload = _tryExtractUserPayload(response);

      if (userPayload == null) {
        return reload();
      }

      final user = HosteDayUser.fromJson(userPayload);

      await _replaceCurrentUser(user);

      return user;
    } on HosteDayException catch (error) {
      throw HosteDayAuthException.fromHosteDayException(error);
    }
  }

  /// Requests an email verification message for the current user.
  Future<void> sendEmailVerification() async {
    await _ensureInitialized();
    _requireSignedInUser();

    try {
      await http.post(
        config.emailVerifyPathPost,
        withAuth: true,
      );
    } on HosteDayException catch (error) {
      throw HosteDayAuthException.fromHosteDayException(error);
    }
  }

  /// Signs out locally and attempts to invalidate the remote Laravel session.
  ///
  /// The local session is always cleared, even when the remote logout endpoint
  /// fails due to network issues.
  Future<void> signOut() async {
    await _ensureInitialized();

    Object? remoteError;

    if (_currentSession != null) {
      try {
        await http.post(
          config.logoutPathPost,
          withAuth: true,
        );
      } catch (error) {
        remoteError = error;
      }
    }

    await _clearLocalSession(
      emitEvents: true,
    );

    if (remoteError is HosteDayException) {
      throw HosteDayAuthException.fromHosteDayException(remoteError);
    }

    if (remoteError != null) {
      throw remoteError;
    }
  }

  /// Releases stream resources without deleting the persisted session.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    await _authStateController.close();
    await _idTokenController.close();
    await _userController.close();
  }

  Future<HosteDayUserCredential> _authenticate({
    required String path,
    required Map<String, dynamic> body,
    required bool isNewUser,
  }) async {
    await _ensureInitialized();

    try {
      final response = await http.post(
        path,
        body: body,
      );

      final session = HosteDaySession.fromAuthResponse(response);

      await _activateSession(
        session,
        emitAuthState: true,
        emitIdToken: true,
        emitUser: true,
      );

      return HosteDayUserCredential(
        user: session.user,
        session: session,
        isNewUser: isNewUser,
      );
    } on HosteDayException catch (error) {
      throw HosteDayAuthException.fromHosteDayException(error);
    } on FormatException catch (error) {
      throw HosteDayAuthException(
        error.message.toString(),
        code: 'malformed-auth-response',
        error: error,
      );
    }
  }

  Future<void> _activateSession(
    HosteDaySession session, {
    required bool emitAuthState,
    required bool emitIdToken,
    required bool emitUser,
  }) async {
    await _persistSession(session);

    _currentSession = session;

    if (emitAuthState) {
      _authStateController.add(session.user);
    }

    if (emitIdToken) {
      _idTokenController.add(session.user);
    }

    if (emitUser) {
      _userController.add(session.user);
    }
  }

  Future<void> _replaceCurrentUser(
    HosteDayUser user,
  ) async {
    final session = _currentSession;

    if (session == null) {
      throw const HosteDayAuthException(
        'No authenticated user is available.',
        code: 'no-current-user',
      );
    }

    final updatedSession = session.copyWith(
      user: user,
    );

    await _persistSession(updatedSession);

    _currentSession = updatedSession;

    _userController.add(user);
  }

  Future<void> _clearLocalSession({
    required bool emitEvents,
  }) async {
    final hadSession = _currentSession != null;

    await _removePersistedSession();

    _currentSession = null;

    if (emitEvents && hadSession) {
      _authStateController.add(null);
      _idTokenController.add(null);
      _userController.add(null);
    }

    if (hadSession) {
      await _onSessionCleared?.call();
    }
  }

  Future<void> _persistSession(
    HosteDaySession session,
  ) async {
    await storage.write(
      HosteDayAuthStorageKeys.session,
      jsonEncode(session.toJson()),
    );

    await storage.write(
      HosteDayAuthStorageKeys.accessToken,
      session.accessToken,
    );
  }

  Future<void> _removePersistedSession() async {
    await storage.delete(
      HosteDayAuthStorageKeys.session,
    );

    await storage.delete(
      HosteDayAuthStorageKeys.accessToken,
    );
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  void _requireSignedInUser() {
    if (_currentSession == null) {
      throw const HosteDayAuthException(
        'This operation requires an authenticated user.',
        code: 'no-current-user',
      );
    }
  }

  void _validateEmailAndPassword({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty) {
      throw const HosteDayAuthException(
        'An email address is required.',
        code: 'invalid-email',
      );
    }

    if (password.isEmpty) {
      throw const HosteDayAuthException(
        'A password is required.',
        code: 'wrong-password',
      );
    }
  }

  Stream<T> _streamWithInitialValue<T>(
    Stream<T> source,
    T initialValue,
  ) {
    return Stream<T>.multi(
      (controller) {
        controller.add(initialValue);

        final subscription = source.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );

        controller.onCancel = subscription.cancel;
      },
      isBroadcast: true,
    );
  }

  static Map<String, dynamic> _extractUserPayload(
    Map<String, dynamic> response,
  ) {
    final result = _tryExtractUserPayload(response);

    if (result == null) {
      throw const FormatException(
        'User response does not include a user object.',
      );
    }

    return result;
  }

  static Map<String, dynamic>? _tryExtractUserPayload(
    Map<String, dynamic> response,
  ) {
    final root = Map<String, dynamic>.from(response);
    final data = _asMap(root['data']);

    return _asMap(root['user']) ??
        _asMap(data?['user']) ??
        (_looksLikeUser(data) ? data : null) ??
        (_looksLikeUser(root) ? root : null);
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static bool _looksLikeUser(
    Map<String, dynamic>? value,
  ) {
    if (value == null) {
      return false;
    }

    return value.containsKey('id') ||
        value.containsKey('user_id') ||
        value.containsKey('uuid');
  }
}
