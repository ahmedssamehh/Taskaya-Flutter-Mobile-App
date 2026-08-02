import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

class _StoredUser {
  _StoredUser({required this.user, required this.password});
  final AppUser user;
  final String password;
}

/// In-memory + SharedPreferences mock auth for Phase 1.
///
/// Phase 2 swaps this for a FirebaseAuthRepository behind the same
/// [AuthRepository] interface — no screen changes required.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    _seed();
  }

  static const _sessionEmailKey = 'taskaya_session_email';

  final Map<String, _StoredUser> _usersByEmail = {};
  final _uuid = const Uuid();

  void _seed() {
    final demo = AppUser(
      id: _uuid.v4(),
      name: 'Demo User',
      email: 'demo@taskaya.app',
    );
    _usersByEmail[demo.email] = _StoredUser(user: demo, password: 'demo123');
  }

  Future<void> _simulateLatency() =>
      Future.delayed(const Duration(milliseconds: 600));

  @override
  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionEmailKey);
    if (email == null) return null;
    return _usersByEmail[email]?.user;
  }

  @override
  Future<AppUser> login(String email, String password) async {
    await _simulateLatency();
    final normalized = email.trim().toLowerCase();
    final stored = _usersByEmail[normalized];
    if (stored == null || stored.password != password) {
      throw AuthException('Incorrect email or password');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionEmailKey, normalized);
    return stored.user;
  }

  @override
  Future<AppUser> signup(String name, String email, String password) async {
    await _simulateLatency();
    final normalized = email.trim().toLowerCase();
    if (_usersByEmail.containsKey(normalized)) {
      throw AuthException('That email is already registered');
    }
    final user = AppUser(id: _uuid.v4(), name: name.trim(), email: normalized);
    _usersByEmail[normalized] = _StoredUser(user: user, password: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionEmailKey, normalized);
    return user;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionEmailKey);
  }
}
