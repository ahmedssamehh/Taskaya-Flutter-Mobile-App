import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

/// Firebase Email/Password implementation of [AuthRepository].
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Future<AppUser?> restoreSession() async {
    try {
      // Waiting for the first auth-state event (rather than reading
      // `currentUser` synchronously) avoids a race where Firebase hasn't
      // finished restoring the persisted session yet.
      final user = await _auth.authStateChanges().first;
      return user == null ? null : _toAppUser(user);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw AuthException(_genericError);
      return _toAppUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(_genericError);
    }
  }

  @override
  Future<AppUser> signup(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw AuthException(_genericError);
      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
      }
      return _toAppUser(user, fallbackName: trimmedName);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(_genericError);
    }
  }

  @override
  Future<AppUser> loginWithGoogle() async {
    try {
      final googleAccount = await GoogleSignIn.instance.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null) throw AuthException(_genericError);
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw AuthException(_genericError);
      return _toAppUser(user, fallbackName: googleAccount.displayName);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Sign-in was cancelled.');
      }
      throw AuthException(_genericError);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(_genericError);
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in via Google — nothing to clear.
    }
  }

  static const _genericError = 'Something went wrong. Please try again.';

  AppUser _toAppUser(User user, {String? fallbackName}) {
    final displayName = user.displayName;
    final name = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (fallbackName != null && fallbackName.isNotEmpty)
        ? fallbackName
        : (user.email?.split('@').first ?? 'User');
    return AppUser(id: user.uid, name: name, email: user.email ?? '');
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Choose a stronger password (8+ characters, with a letter and a number).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'internal-error':
        return 'A server error occurred. Please try again in a moment.';
      default:
        return _genericError;
    }
  }
}
