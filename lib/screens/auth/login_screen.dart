// FILE: lib/screens/auth/login_screen.dart
// Halaman login (masuk) untuk aplikasi DanLens.
// Fungsi: Menampilkan form email dan password untuk autentikasi pengguna.
// Setelah login berhasil, pengguna diarahkan ke halaman utama (MainScreen).
// Informasi penting: Menggunakan AuthProvider untuk komunikasi dengan Supabase Auth.
// Tampilan memiliki gradien hijau di bagian atas dan kartu putih di bagian bawah.
// Terdapat petunjuk kredensial demo untuk memudahkan pengujian.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../main_screen.dart';
import 'register_screen.dart';

// Kelas LoginScreen (StatefulWidget) karena ada state loading dan toggle visibility password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk input email.
  final _emailCtrl = TextEditingController();
  // Controller untuk input password.
  final _passCtrl = TextEditingController();
  // Status untuk menampilkan atau menyembunyikan teks password.
  bool _obscure = true;
  // Status sedang memproses login (menampilkan indikator loading).
  bool _loading = false;

  // Fungsi untuk melakukan proses login.
  Future<void> _login() async {
    // Validasi: email dan password tidak boleh kosong.
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showSnack('Email dan password wajib diisi');
      return;
    }
    setState(() => _loading = true); // Mulai loading.
    // Panggil method login dari AuthProvider.
    final ok = await context.read<AuthProvider>().login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    setState(() => _loading = false); // Selesai loading.
    if (!mounted) return;
    if (ok) {
      // Jika berhasil, ganti halaman ke MainScreen dan hapus riwayat sebelumnya.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      // Jika gagal, tampilkan pesan error dari provider.
      _showSnack(context.read<AuthProvider>().error ?? 'Email atau password salah');
    }
  }

  // Menampilkan snackbar pesan error atau informasi.
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Latar belakang gradien hijau (primary ke primaryDeep).
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              // Tinggi disamakan dengan tinggi layar agar kolom dapat menggunakan Expanded.
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  // ── HEADER (bagian atas dengan logo dan judul) ──
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lingkaran putih dengan ikon lokasi.
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              size: 44, color: AppColors.primary),
                        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut), // Animasi scale elastis.
                        const SizedBox(height: 16),
                        // Nama aplikasi.
                        const Text('DanLens',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white))
                            .animate()
                            .fade(delay: 200.ms) // Animasi fade.
                            .slideY(begin: 0.3, end: 0), // Geser dari bawah.
                        const SizedBox(height: 4),
                        // Subjudul.
                        const Text('Masuk untuk melanjutkan',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xCCFFFFFF),
                                fontSize: 13))
                            .animate()
                            .fade(delay: 400.ms),
                      ],
                    ),
                  ),

                  // ── FORM CARD (bagian bawah dengan form login) ──
                  Expanded(
                    flex: 3,
                    child: Container(
                      // Latar belakang putih dengan sudut melengkung di atas.
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selamat Datang! 👋',
                              style: AppTextStyles.h2),
                          const SizedBox(height: 4),
                          const Text('Masukkan akun Anda',
                              style: AppTextStyles.small),
                          const SizedBox(height: 24),

                          // Input email.
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                            ),
                          ).animate().fade(delay: 200.ms).slideX(begin: -0.1, end: 0),

                          const SizedBox(height: 14),

                          // Input password dengan toggle visibility.
                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                                    color: AppColors.textGray),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ).animate().fade(delay: 300.ms).slideX(begin: -0.1, end: 0),

                          const SizedBox(height: 28),

                          // Tombol login.
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Masuk'),
                            ),
                          ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 16),

                          // Link ke halaman register.
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: const Text.rich(TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(color: AppColors.textGray, fontFamily: 'Poppins'),
                                children: [
                                  TextSpan(
                                    text: 'Daftar',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600),
                                  )
                                ],
                              )),
                            ),
                          ).animate().fade(delay: 500.ms),

                          const SizedBox(height: 8),

                          // Petunjuk kredensial demo (untuk memudahkan pengujian).
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                                '💡 Demo :\nadmin@gmail.com / 123456\nuser@gmail.com / 123456',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.primaryDark),
                              textAlign: TextAlign.center,
                            ),
                          ).animate().fade(delay: 600.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Bersihkan controller untuk mencegah memory leak.
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}