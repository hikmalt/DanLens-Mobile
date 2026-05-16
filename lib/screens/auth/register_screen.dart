// FILE: lib/screens/auth/register_screen.dart
// Halaman pendaftaran user baru.
// Pengguna diminta mengisi nama, email, password, dan dapat memilih foto profil (opsional).
// Foto akan diunggah ke Supabase Storage dan nama file disimpan di tabel users.
// Informasi penting: Foto profil tidak wajib, bisa dikosongkan.

import 'dart:io';
// Mengimpor File untuk menangani gambar profil yang dipilih.

import 'package:flutter/material.dart';
// Paket inti Flutter untuk UI.

import 'package:flutter_animate/flutter_animate.dart';
// Paket untuk animasi widget.

import 'package:image_picker/image_picker.dart';
// Paket untuk memilih gambar dari galeri atau kamera.

import 'package:provider/provider.dart';
// Paket untuk mengakses provider (state management).

import '../../config/app_theme.dart';
// Konfigurasi tema aplikasi (warna, font, dll).

import '../../providers/auth_provider.dart';
// Provider autentikasi untuk memanggil method register.

import '../main_screen.dart';
// Halaman utama setelah registrasi berhasil.

// StatefulWidget karena halaman ini memiliki state (input form, gambar, loading).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller untuk masing-masing field input.
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  
  // Untuk menampilkan/sembunyikan password.
  bool _obscure = true;
  
  // Menandakan proses registrasi sedang berlangsung.
  bool _loading = false;
  
  // File foto profil yang dipilih (null jika tidak memilih).
  File? _profileImage;

  // Membuka galeri untuk memilih gambar profil.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 80,  // Kompresi gambar 80% untuk menghemat ukuran.
    );
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  // Fungsi untuk melakukan registrasi.
  Future<void> _register() async {
    // Validasi: semua field harus diisi.
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showSnack('Semua field wajib diisi', isError: true);
      return;
    }
    // Validasi: password dan konfirmasi harus sama.
    if (_passCtrl.text != _confirmCtrl.text) {
      _showSnack('Password tidak cocok', isError: true);
      return;
    }
    // Validasi: minimal 6 karakter.
    if (_passCtrl.text.length < 6) {
      _showSnack('Password minimal 6 karakter', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      // Memanggil provider register dengan nama, email, password, dan foto profil (opsional).
      final ok = await context.read<AuthProvider>().register(
            _nameCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _passCtrl.text,
            profileImage: _profileImage,  // Bisa null.
          );
      if (!mounted) return;
      if (ok) {
        _showSnack('Akun berhasil dibuat!', isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        // Pindah ke halaman utama.
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        _showSnack(context.read<AuthProvider>().error ?? 'Registrasi gagal', isError: true);
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
    setState(() => _loading = false);
  }

  // Menampilkan pesan snackbar (notifikasi sementara).
  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // Widget field input yang dapat digunakan ulang.
  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false, TextInputType? keyboard, Widget? suffix}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul halaman dengan animasi fade dan slide.
            const Text('Daftar Sekarang', style: AppTextStyles.h2)
                .animate()
                .fade(duration: 400.ms)
                .slideY(begin: -0.2, end: 0),
            const SizedBox(height: 4),
            const Text('Buat akun untuk menambahkan tempat', style: AppTextStyles.small)
                .animate()
                .fade(delay: 100.ms),
            const SizedBox(height: 28),

            // Area untuk memilih foto profil (berbentuk lingkaran).
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary, width: 2),
                  image: _profileImage != null
                      ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _profileImage == null
                    ? const Center(
                        child: Icon(Icons.camera_alt, color: AppColors.primary, size: 36))
                    : null,
              ),
            ).animate().fade(delay: 50.ms).scale(),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _profileImage == null ? 'Tap untuk pilih foto profil' : 'Foto profil terpilih',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textGray),
              ),
            ),
            const SizedBox(height: 20),

            // Field Nama Lengkap.
            _field(_nameCtrl, 'Nama Lengkap', Icons.person_outline)
                .animate()
                .fade(delay: 100.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 14),

            // Field Email.
            _field(_emailCtrl, 'Email', Icons.email_outlined,
                    keyboard: TextInputType.emailAddress)
                .animate()
                .fade(delay: 150.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 14),

            // Field Password (dengan tombol tampilkan/sembunyikan).
            _field(
              _passCtrl,
              'Password',
              Icons.lock_outline,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textGray),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ).animate().fade(delay: 200.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 14),

            // Field Konfirmasi Password.
            _field(_confirmCtrl, 'Konfirmasi Password', Icons.lock_outline,
                    obscure: _obscure)
                .animate()
                .fade(delay: 250.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 32),

            // Tombol Daftar.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Daftar Sekarang'),
              ),
            ).animate().fade(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Bersihkan controller saat halaman ditutup (mencegah memory leak).
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
}