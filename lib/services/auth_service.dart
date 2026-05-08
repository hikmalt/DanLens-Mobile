// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../utils/error_logger.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  static UserModel? _currentUser;
  static UserModel? get currentUser => _currentUser;

  /// Login with email + password (custom users table, not Supabase Auth)
  static Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();

      if (response == null) return null;

      _currentUser = UserModel.fromJson(response);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', _currentUser!.id);
      await prefs.setString('user_name', _currentUser!.name);
      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_role', _currentUser!.role ?? 'uploader');
      await prefs.setString('user_photo', _currentUser!.photo ?? '');

      ErrorLogger.i('Login success: ${_currentUser!.email}');
      return _currentUser;
    } catch (e, stack) {
      ErrorLogger.e('Login failed', e, stack);
      return null;
    }
  }

  static Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Check if email exists
      final existing = await _client
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Email sudah terdaftar');
      }

      final response = await _client
          .from(SupabaseConfig.usersTable)
          .insert({
            'name': name,
            'email': email,
            'password': password,
            'role': 'uploader',
          })
          .select()
          .single();

      _currentUser = UserModel.fromJson(response);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', _currentUser!.id);
      await prefs.setString('user_name', _currentUser!.name);
      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_role', _currentUser!.role ?? 'uploader');

      ErrorLogger.i('Register success: ${_currentUser!.email}');
      return _currentUser;
    } catch (e, stack) {
      ErrorLogger.e('Register failed', e, stack);
      rethrow;
    }
  }

  static Future<UserModel?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return null;

      final response = await _client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      _currentUser = UserModel.fromJson(response);
      return _currentUser;
    } catch (e, stack) {
      ErrorLogger.e('restoreSession failed', e, stack);
      return null;
    }
  }

  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_photo');
    ErrorLogger.i('Logged out');
  }

  static bool get isLoggedIn => _currentUser != null;
  static bool get isAdmin => _currentUser?.isAdmin ?? false;
}