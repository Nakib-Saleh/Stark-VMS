import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../providers/vehicle_providers.dart';

/// The Hive box holding the saved session. Opened in main() before the app starts, so reading
/// it is synchronous and the app never flashes a signed-out screen for a signed-in user.
final sessionBoxProvider = Provider<Box<dynamic>>((ref) => throw UnimplementedError('opened in main()'));

enum AuthStatus { signedOut, signedIn }

class AuthState {
  const AuthState.signedOut({this.notice})
      : status = AuthStatus.signedOut,
        token = null,
        username = null,
        expiresAt = null;

  const AuthState.signedIn({required this.token, required this.username, required this.expiresAt, this.notice})
      : status = AuthStatus.signedIn;

  final AuthStatus status;
  final String? token;
  final String? username;
  final DateTime? expiresAt;

  /// A one-line message for the next screen ("Signed out", "Your session ended…").
  final String? notice;

  bool get isSignedIn => status == AuthStatus.signedIn;
}

/// Signing in and out (ADR-0005). The token is kept in the browser so a reload keeps you signed in.
class AuthController extends Notifier<AuthState> {
  static const _tokenKey = 'token';
  static const _userKey = 'username';
  static const _expiresKey = 'expiresAt';
  static const sessionEndedNotice = 'Your session ended. Sign in again to continue.';

  Box<dynamic> get _box => ref.read(sessionBoxProvider);

  @override
  AuthState build() {
    final token = _box.get(_tokenKey) as String?;
    final username = _box.get(_userKey) as String?;
    final expires = DateTime.tryParse(_box.get(_expiresKey) as String? ?? '');
    if (token == null || username == null || expires == null) {
      return const AuthState.signedOut();
    }
    if (!expires.isAfter(DateTime.now())) {
      _clear();
      return const AuthState.signedOut(notice: sessionEndedNotice);
    }
    return AuthState.signedIn(token: token, username: username, expiresAt: expires);
  }

  /// Returns null on success, otherwise a message to show above the form.
  Future<String?> signIn(String username, String password) async {
    try {
      final response = await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username.trim(), 'password': password},
      );
      final body = response.data!;
      final expires = DateTime.parse(body['expiresAt'] as String).toLocal();
      await _box.putAll({
        _tokenKey: body['token'],
        _userKey: body['username'],
        _expiresKey: expires.toIso8601String(),
      });
      state = AuthState.signedIn(
          token: body['token'] as String, username: body['username'] as String, expiresAt: expires);
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return "Can't reach the server. Check your connection and try again.";
    }
  }

  Future<void> signOut() async {
    await _clear();
    state = const AuthState.signedOut(notice: 'Signed out');
  }

  /// The server refused our token (expired, or the server restarted with a new key).
  Future<void> sessionEnded() async {
    if (!state.isSignedIn) return;
    await _clear();
    state = const AuthState.signedOut(notice: sessionEndedNotice);
  }

  void clearNotice() {
    if (state.notice == null) return;
    state = state.isSignedIn
        ? AuthState.signedIn(token: state.token!, username: state.username!, expiresAt: state.expiresAt!)
        : const AuthState.signedOut();
  }

  Future<void> _clear() => _box.deleteAll([_tokenKey, _userKey, _expiresKey]);
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
