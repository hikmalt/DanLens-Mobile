// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showSnack('Semua field wajib diisi', isError: true);
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _showSnack('Password tidak cocok', isError: true);
      return;
    }
    if (_passCtrl.text.length < 6) {
      _showSnack('Password minimal 6 karakter', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await context.read<AuthProvider>().register(
            _nameCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _passCtrl.text,
          );
      if (!mounted) return;
      if (ok) {
        _showSnack('Akun berhasil dibuat!', isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
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

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

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
            const Text('Daftar Sekarang', style: AppTextStyles.h2)
                .animate()
                .fade(duration: 400.ms)
                .slideY(begin: -0.2, end: 0),
            const SizedBox(height: 4),
            const Text('Buat akun untuk menambahkan tempat', style: AppTextStyles.small)
                .animate()
                .fade(delay: 100.ms),
            const SizedBox(height: 28),

            _field(_nameCtrl, 'Nama Lengkap', Icons.person_outline)
                .animate()
                .fade(delay: 100.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 14),

            _field(_emailCtrl, 'Email', Icons.email_outlined,
                    keyboard: TextInputType.emailAddress)
                .animate()
                .fade(delay: 150.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 14),

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

            _field(_confirmCtrl, 'Konfirmasi Password', Icons.lock_outline,
                    obscure: _obscure)
                .animate()
                .fade(delay: 250.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 32),

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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
}