// FILE: lib/providers/auth_provider.dart
// Provider ini bertanggung jawab untuk mengelola seluruh proses autentikasi pengguna.
// Fungsi utama: login, register (dengan foto profil opsional), logout, dan memulihkan session.
// Informasi penting: Menggunakan ChangeNotifier agar UI dapat merespon perubahan state autentikasi.
// Data user disimpan di sini dan dapat diakses dari seluruh halaman aplikasi.

import 'dart:io';
// Mengimpor File untuk menangani gambar profil yang dipilih pengguna.

import 'package:flutter/foundation.dart';
// Mengimpor ChangeNotifier untuk manajemen state.

import '../models/models.dart';
// Mengimpor model UserModel untuk menyimpan data pengguna.

import '../services/auth_service.dart';
// Mengimpor layanan autentikasi yang menangani komunikasi dengan backend Supabase dan penyimpanan session.

// Kelas provider untuk autentikasi pengguna.
class AuthProvider extends ChangeNotifier {
  // Menyimpan data pengguna yang sedang login. Null jika belum login.
  UserModel? _user;
  
  // Menandakan apakah sedang dalam proses autentikasi (misal login atau register).
  bool _isLoading = false;
  
  // Menyimpan pesan error terakhir jika terjadi kegagalan autentikasi.
  String? _error;

  // Getter untuk mengakses data pengguna dari luar.
  UserModel? get user => _user;
  
  // Getter untuk mengetahui status loading.
  bool get isLoading => _isLoading;
  
  // Getter untuk mengambil pesan error.
  String? get error => _error;
  
  // Getter untuk mengecek apakah ada pengguna yang sedang login.
  bool get isLoggedIn => _user != null;
  
  // Getter untuk mengecek apakah pengguna yang login memiliki peran admin.
  bool get isAdmin => _user?.isAdmin ?? false;

  // Memulihkan session yang tersimpan di SharedPreferences (misal setelah aplikasi dibuka kembali).
  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    // Memanggil service untuk mengambil data user dari session yang tersimpan.
    _user = await AuthService.restoreSession();
    _isLoading = false;
    notifyListeners();
  }

  // Melakukan login dengan email dan password.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Memanggil service login, mengembalikan UserModel jika berhasil.
      _user = await AuthService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      // Menangkap error, menyimpan pesan, dan mengembalikan false.
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mendaftarkan pengguna baru dengan nama, email, password, dan opsional foto profil.
  // Parameter profileImage bersifat opsional (bisa null).
  Future<bool> register(
    String name, 
    String email, 
    String password, 
    {File? profileImage}
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Memanggil service register, meneruskan file foto profil jika ada.
      _user = await AuthService.register(
        name: name,
        email: email,
        password: password,
        profileImage: profileImage,
      );
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      // Menangkap error, menghilangkan awalan 'Exception: ' jika ada.
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Melakukan logout, menghapus session, dan mengosongkan data user.
  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }
}