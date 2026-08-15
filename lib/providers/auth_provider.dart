import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import '../services/local_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository, {this.notificationService});

  final AuthRepository _repository;
  final LocalNotificationService? notificationService;

  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isRestoring = true;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;

  Future<void> restoreSession() async {
    _isRestoring = true;
    notifyListeners();
    try {
      _currentUser = await _repository.restoreSession();
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _repository.login(email, password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signup(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _repository.signup(name, email, password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _repository.loginWithGoogle();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Clear this account's pending OS reminders before signing out, so they
    // can't fire for whoever signs in next on this device.
    await notificationService?.cancelAll();
    await _repository.logout();
    _currentUser = null;
    notifyListeners();
  }
}
