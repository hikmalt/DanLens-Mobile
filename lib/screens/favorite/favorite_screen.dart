// FILE: lib/screens/favorite/favorite_screen.dart
// Halaman untuk menampilkan daftar tempat favorit pengguna.
// Fungsi: Menampilkan semua tempat yang telah ditandai sebagai favorit oleh pengguna.
// Pengguna dapat menghapus satu per satu dengan gestur swipe (geser ke kiri) atau menghapus semua sekaligus.
// Informasi penting: Data favorit disimpan di SharedPreferences (lewat FavoriteProvider) dan disinkronkan dengan data tempat dari TempatProvider.
// Tidak memerlukan koneksi internet karena data favorit bersifat lokal.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/tempat_provider.dart';
import '../../widgets/place_card.dart';

// Kelas FavoriteScreen adalah StatefulWidget karena memerlukan state untuk menampilkan dialog konfirmasi dan refresh tampilan.
class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});
  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  void initState() {
    super.initState();
    // Setelah widget pertama kali dibangun, sinkronkan daftar favorit dengan data tempat yang tersedia.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fav = context.read<FavoriteProvider>();
      final tempat = context.read<TempatProvider>();
      // Memastikan daftar favorit hanya berisi tempat yang masih ada di database.
      fav.syncItems(tempat.allTempat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit Saya'),
        automaticallyImplyLeading: false, // Menghilangkan tombol back otomatis.
        actions: [
          // Tombol "Hapus Semua" hanya muncul jika ada item favorit.
          if (fav.favoriteItems.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, fav),
              child: const Text('Hapus Semua',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            ),
        ],
      ),
      body: fav.favoriteItems.isEmpty
          ? _EmptyFavorite() // Tampilkan pesan kosong jika tidak ada favorit.
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header jumlah favorit.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '${fav.count} tempat favorit',
                    style: AppTextStyles.small,
                  ).animate().fade(), // Animasi fade-in.
                ),
                // Daftar favorit dengan swipe-to-delete.
                Expanded(
                  child: ListView.builder(
                    itemCount: fav.favoriteItems.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (_, i) => Dismissible(
                      // Key unik berdasarkan ID tempat.
                      key: Key('fav_${fav.favoriteItems[i].id}'),
                      // Hanya arah swipe ke kanan? (endToStart = dari kanan ke kiri).
                      direction: DismissDirection.endToStart,
                      // Latar belakang yang muncul saat diswipe (seperti tombol hapus).
                      background: Container(
                        alignment: Alignment.centerRight,
                        color: AppColors.error,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white, size: 28),
                      ),
                      // Saat di-swipe, hapus dari favorit.
                      onDismissed: (_) => fav.toggle(fav.favoriteItems[i]),
                      child: PlaceListTile(
                          tempat: fav.favoriteItems[i], index: i),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Menampilkan dialog konfirmasi sebelum menghapus semua favorit.
  void _confirmClearAll(BuildContext context, FavoriteProvider fav) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Semua Favorit',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        content: const Text('Yakin hapus semua tempat favorit?',
            style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          // Tombol batal.
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal',
                  style: TextStyle(fontFamily: 'Poppins', color: AppColors.textGray))),
          // Tombol hapus semua.
          ElevatedButton(
            onPressed: () {
              // Loop untuk menghapus setiap item favorit.
              for (final t in [...fav.favoriteItems]) {
                fav.toggle(t); // toggle akan menghapus jika sudah ada.
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

// Widget untuk menampilkan pesan ketika daftar favorit kosong.
class _EmptyFavorite extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikon hati kosong.
          Icon(Icons.favorite_border_rounded,
              size: 72, color: AppColors.surface),
          SizedBox(height: 16),
          Text('Belum ada favorit', style: AppTextStyles.h3),
          SizedBox(height: 8),
          Text('Jelajahi tempat dan tambahkan ke favorit!',
              style: AppTextStyles.small),
        ],
      )
          .animate()
          .fade(duration: 400.ms)
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)), // Animasi skala dan fade.
    );
  }
}