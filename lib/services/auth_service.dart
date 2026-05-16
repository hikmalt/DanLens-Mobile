// FILE: lib/services/auth_service.dart
// File ini mengelola proses login, register, dan session pengguna (user) pada aplikasi DanLens.
// Fungsi: Menangani autentikasi menggunakan tabel 'users' di database Supabase (bukan auth bawaan Supabase).
//         Menyimpan data user ke SharedPreferences untuk mempertahankan session setelah aplikasi ditutup.
//         Mendukung upload foto profil ke storage bucket 'profil'.
// Informasi penting: Tidak menggunakan Supabase Auth (email/password bawaan). Password disimpan dalam teks biasa (plain text)
//         karena hanya untuk demo. Pada aplikasi nyata, sebaiknya gunakan hashing dan Supabase Auth.
//         Foto profil diupload via StorageService, nama file disimpan di kolom 'photo'.

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../utils/error_logger.dart';
import 'storage_service.dart';

// Kelas AuthService menyediakan method statis untuk autentikasi.
class AuthService {
  // Instance Supabase client.
  static final _client = Supabase.instance.client;

  // User saat ini yang sedang login (disimpan dalam memori).
  static UserModel? _currentUser;
  static UserModel? get currentUser => _currentUser;

  // Melakukan login dengan email dan password (mencocokkan di tabel 'users').
  static Future<UserModel?> login(String email, String password) async {
    try {
      // Query ke tabel users: cari email dan password yang cocok.
      final response = await _client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle(); // maybeSingle mengembalikan null jika tidak ditemukan.

      // Jika tidak ditemukan, kembalikan null.
      if (response == null) return null;

      // Konversi response ke UserModel.
      _currentUser = UserModel.fromJson(response);

      // Simpan data user ke SharedPreferences untuk restore session nanti.
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

  // Mendaftar user baru, termasuk upload foto profil (opsional).
  static Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    File? profileImage,   // File gambar profil (opsional).
  }) async {
    try {
      // Cek apakah email sudah terdaftar.
      final existing = await _client
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Email sudah terdaftar');
      }

      String? photoFileName;
      // Jika ada file gambar, upload ke storage bucket 'profil'.
      if (profileImage != null) {
        photoFileName = await StorageService.uploadProfileImage(profileImage);
        if (photoFileName == null) {
          throw Exception('Gagal mengupload foto profil');
        }
      }

      // Insert data user baru (role default 'uploader').
      final response = await _client
          .from(SupabaseConfig.usersTable)
          .insert({
            'name': name,
            'email': email,
            'password': password,
            'role': 'uploader',
            'photo': photoFileName,
          })
          .select()
          .single();

      _currentUser = UserModel.fromJson(response);

      // Simpan session ke SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', _currentUser!.id);
      await prefs.setString('user_name', _currentUser!.name);
      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_role', _currentUser!.role ?? 'uploader');
      await prefs.setString('user_photo', _currentUser!.photo ?? '');

      ErrorLogger.i('Register success: ${_currentUser!.email}');
      return _currentUser;
    } catch (e, stack) {
      ErrorLogger.e('Register failed', e, stack);
      rethrow; // Lempar exception agar widget dapat menangani error.
    }
  }

  // Memulihkan session dari SharedPreferences (setelah aplikasi dibuka kembali).
  static Future<UserModel?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return null;

      // Ambil data user dari database berdasarkan id.
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

  // Logout: hapus semua data session dari memori dan SharedPreferences.
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

  // Getter status login.
  static bool get isLoggedIn => _currentUser != null;
  static bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Memperbarui foto profil user (misal untuk fitur ganti foto).
  static Future<bool> updateProfilePhoto(int userId, String photoFileName) async {
    try {
      // Update kolom photo di database.
      await _client
          .from(SupabaseConfig.usersTable)
          .update({'photo': photoFileName})
          .eq('id', userId);

      // Perbarui _currentUser jika yang sedang login.
      if (_currentUser != null && _currentUser!.id == userId) {
        _currentUser = UserModel(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          role: _currentUser!.role,
          photo: photoFileName,
          createdAt: _currentUser!.createdAt,
        );
        // Update SharedPreferences juga.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_photo', photoFileName);
      }
      return true;
    } catch (e, stack) {
      ErrorLogger.e('updateProfilePhoto failed', e, stack);
      return false;
    }
  }
}