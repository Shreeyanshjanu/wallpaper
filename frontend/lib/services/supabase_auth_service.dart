import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign up new user
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        return {
          'success': true,
          'message': 'Account created! Please check your email to verify.',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to create account',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': 'Invalid credentials',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Logout user
  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// Get current user
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }
}
