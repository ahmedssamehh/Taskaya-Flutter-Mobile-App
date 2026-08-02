import '../models/app_user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}

abstract class AuthRepository {
  Future<AppUser?> restoreSession();
  Future<AppUser> login(String email, String password);
  Future<AppUser> signup(String name, String email, String password);
  Future<void> logout();
}
