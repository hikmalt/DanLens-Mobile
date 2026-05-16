// FILE: lib/widgets/offline_banner.dart
// File ini berisi widget untuk menampilkan banner peringatan ketika aplikasi offline (tidak ada koneksi internet).
// Fungsi: Membungkus (wrap) halaman atau widget utama dengan ConnectivityWrapper.
// Jika koneksi hilang, akan muncul banner oranye di bagian atas dengan pesan bahwa data ditampilkan dari cache.
// Informasi penting: Menggunakan package connectivity_plus untuk mendeteksi perubahan status koneksi.
// Banner hanya muncul saat offline, dan akan hilang otomatis saat koneksi kembali.

// Mengimpor package connectivity_plus untuk memeriksa status koneksi internet.
import 'package:connectivity_plus/connectivity_plus.dart';
// Mengimpor widget dasar Flutter.
import 'package:flutter/material.dart';
// Mengimpor package flutter_animate untuk animasi slide banner.
import 'package:flutter_animate/flutter_animate.dart';
// Mengimpor tema aplikasi untuk warna (tidak digunakan langsung, tapi sebagai referensi).
import '../config/app_theme.dart';

// Kelas ConnectivityWrapper adalah StatefulWidget yang membungkus konten utama.
// Fungsinya: memantau koneksi internet dan menampilkan banner offline jika diperlukan.
class ConnectivityWrapper extends StatefulWidget {
  // Widget anak yang akan dibungkus (biasanya halaman utama).
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

// State untuk ConnectivityWrapper.
class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  // Status online (true = online, false = offline).
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    // Cek koneksi pertama kali saat widget dibuat.
    _checkConnectivity();
    // Pasang listener untuk perubahan koneksi.
    Connectivity().onConnectivityChanged.listen((result) {
      // Jika salah satu hasil koneksi bukan none, berarti online.
      final online = !result.contains(ConnectivityResult.none);
      // Jika status berubah dan widget masih aktif, update state.
      if (online != _isOnline && mounted) {
        setState(() => _isOnline = online);
      }
    });
  }

  // Memeriksa koneksi saat ini secara async.
  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      _isOnline = !result.contains(ConnectivityResult.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Jika offline, tampilkan banner dengan animasi slide dari atas.
        if (!_isOnline)
          _OfflineBanner().animate().slideY(begin: -1, end: 0, duration: 300.ms),
        // Widget anak (halaman utama) mengambil sisa ruang.
        Expanded(child: widget.child),
      ],
    );
  }
}

// Kelas _OfflineBanner adalah widget stateless untuk menampilkan banner offline.
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Banner melebar penuh.
      width: double.infinity,
      // Warna latar oranye gelap.
      color: const Color(0xFFE65100),
      // Padding vertikal 7 piksel, horizontal 16.
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: const Row(
        // Konten rata tengah.
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ikon wifi mati putih.
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
          SizedBox(width: 6),
          // Teks pesan offline.
          Text(
            'Tidak ada koneksi — Menampilkan data cache',
            style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Kelas helper untuk menampilkan SnackBar saat terjadi error jaringan.
class NetworkSnackbar {
  // Method static untuk menampilkan snackbar.
  static void show(BuildContext context, String message,
      {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Konten snackbar berupa row dengan ikon dan pesan.
        content: Row(
          children: [
            // Ikon error atau sukses tergantung parameter isError.
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            // Pesan teks dengan font Poppins.
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 13)),
            ),
          ],
        ),
        // Warna latar: merah jika error, hijau jika sukses.
        backgroundColor:
            isError ? AppColors.error : AppColors.success,
        // Snackbar mengapung (floating) di atas konten.
        behavior: SnackBarBehavior.floating,
        // Margin di sekeliling snackbar.
        margin: const EdgeInsets.all(12),
        // Sudut melengkung.
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Durasi tampil 3 detik.
        duration: const Duration(seconds: 3),
      ),
    );
  }
}