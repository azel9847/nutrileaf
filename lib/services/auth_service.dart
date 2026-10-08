import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The custom URI scheme used for deep linking on mobile.
/// Must be registered in AndroidManifest.xml and iOS Info.plist,
/// and added to Supabase Dashboard → Authentication → URL Configuration.
const String _kMobileRedirectUrl = 'nutrileaf://login-callback/';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Session State ─────────────────────────────

  User? get currentUser => _supabase.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateStream =>
      _supabase.auth.onAuthStateChange;

  // ─── Email / Password Auth ─────────────────────

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': displayName},
        // On mobile, use the custom URI scheme so the OS intercepts the link
        // and opens the app. On web, use the current page origin.
        emailRedirectTo: kIsWeb ? Uri.base.origin : _kMobileRedirectUrl,
      );

      if (response.user != null && response.session == null) {
        return const AuthResult.success(
          successMessage: 'Check your email to confirm your account.',
        );
      }

      return const AuthResult.success(
        successMessage: 'Account created successfully.',
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('rate limit')) {
        return const AuthResult.error('Too many attempts. Please try again later.');
      }
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Registration failed: $e');
    }
  }

  Future<AuthResult> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return const AuthResult.success();
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        return const AuthResult.unverified(
          'Please verify your email first.',
        );
      }
      if (e.message.toLowerCase().contains('rate limit')) {
        return const AuthResult.error('Too many attempts. Please try again later.');
      }
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Login failed: $e');
    }
  }

  // ─── Google Auth ───────────────────────────────

  Future<AuthResult> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : _kMobileRedirectUrl,
      );

      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Google sign in failed: $e');
    }
  }

  // ─── Password Reset ────────────────────────────

  Future<AuthResult> resetPasswordForEmail({
    required String email,
  }) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? Uri.base.origin : _kMobileRedirectUrl,
      );

      return const AuthResult.success(
        successMessage: 'Recovery email sent. Please check your inbox.',
      );
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Failed to send recovery email: $e');
    }
  }



  Future<AuthResult> updatePassword({
    required String newPassword,
  }) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return const AuthResult.success(
        successMessage: 'Password updated successfully.',
      );
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Update failed: $e');
    }
  }

  // ─── Logout ────────────────────────────────────

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

// ─── Result Model ────────────────────────────────

class AuthResult {
  final bool isSuccess;
  final bool isUnverified;
  final String? errorMessage;
  final String? successMessage;

  const AuthResult.success({this.successMessage})
      : isSuccess = true,
        isUnverified = false,
        errorMessage = null;

  const AuthResult.error(this.errorMessage)
      : isSuccess = false,
        isUnverified = false,
        successMessage = null;

  const AuthResult.unverified(this.errorMessage)
      : isSuccess = false,
        isUnverified = true,
        successMessage = null;
}