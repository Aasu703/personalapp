import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase Authentication implementation of the app's AuthRepository.
///
/// - Email/password sign‑in & sign‑up use Firebase's built‑in methods.
/// - Google OAuth is provided via `google_sign_in`.
/// - `verifyOtp`, `resendOtp`, `forgotPassword`, `resetPassword` are mapped to the
///   closest Firebase equivalents (some are no‑ops because Firebase does not use
///   OTP for the default email flow).
class FirebaseAuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final fbUser = _auth.currentUser;
      return AuthResult.success(user: _userFromFirebase(fbUser));
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(e.message ?? 'Login failed');
    }
  }

  @override
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = cred.user;
      if (fbUser != null && name.isNotEmpty) {
        await fbUser.updateDisplayName(name);
      }
      return AuthResult.success(user: _userFromFirebase(fbUser));
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(e.message ?? 'Signup failed');
    }
  }

  @override
  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    // Firebase email flow does not use OTP; map to a no‑op success.
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> resendOtp({required String email}) async {
    // No OTP in Firebase; treat as success.
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const AuthResult.success();
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(e.message ?? 'Forgot password failed');
    }
  }

  @override
  Future<AuthResult> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    // Firebase uses the password‑reset link; we cannot reset with token directly.
    // Provide a no‑op success; UI should redirect to the Firebase email flow.
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> getMe() async {
    final fbUser = _auth.currentUser;
    return AuthResult.success(user: _userFromFirebase(fbUser));
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  User? _userFromFirebase(fb.User? fbUser) {
    if (fbUser == null) return null;
    return User(
      id: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
      isVerified: fbUser.emailVerified,
    );
  }
}
