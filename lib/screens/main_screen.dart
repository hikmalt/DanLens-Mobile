// FILE: lib/screens/main_screen.dart
// Halaman utama (root) aplikasi DanLens yang berisi bottom navigation bar.
// Fungsi: Menampilkan 5 halaman utama (HomeScreen, MapScreen, AddTempatScreen, FavoriteScreen, ProfileScreen)
//         dan memungkinkan pengguna berpindah antar halaman melalui bottom navigation bar.
// Informasi penting: Menggunakan IndexedStack agar semua halaman tetap dalam state (tidak di-rebuild ulang)
//         saat berpindah tab. Bottom navigation bar memiliki tombol tengah (tambah) dengan desain khusus (lingkaran gradien).
//         Animasi fade digunakan saat berpindah halaman.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import 'home/home_screen.dart';
import 'map/map_screen.dart';
import 'add_tempat/add_tempat_screen.dart';
import 'favorite/favorite_screen.dart';
import 'profile/profile_screen.dart';

// Kelas MainScreen adalah StatefulWidget karena perlu menyimpan indeks tab aktif.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Indeks halaman yang sedang aktif (0: Beranda, 1: Peta, 2: Tambah, 3: Favorit, 4: Profil).
  int _currentIndex = 0;

  // Daftar widget halaman yang akan ditampilkan sesuai indeks.
  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
    AddTempatScreen(),
    FavoriteScreen(),
    ProfileScreen(),
  ];

  // Daftar item navigasi (ikon dan label) untuk bottom navigation bar.
  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
    _NavItem(icon: Icons.map_rounded, label: 'Peta'),
    _NavItem(icon: Icons.add_circle_rounded, label: 'Tambah', isCenter: true), // Tombol tengah (lingkaran).
    _NavItem(icon: Icons.favorite_rounded, label: 'Favorit'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body menggunakan Animate dengan efek fade saat indeks berubah (agar transisi halus).
      body: Animate(
        key: ValueKey(_currentIndex), // Key berubah setiap indeks berbeda, memicu animasi.
        effects: const [FadeEffect(duration: Duration(milliseconds: 300))],
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      // Bottom navigation bar kustom.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              // Menyebar item secara merata dengan spaceAround.
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _currentIndex == i;

                // Jika item adalah tombol tengah (isCenter = true), tampilkan lingkaran dengan ikon add.
                if (item.isCenter) {
                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 28),
                    ),
                  );
                }

                // Untuk item biasa (bukan tengah), tampilkan ikon dan label dengan animasi latar.
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: selected ? AppColors.primary : AppColors.textGray,
                          size: selected ? 26 : 24, // Ikon sedikit membesar jika dipilih.
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? AppColors.primary : AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// Kelas helper untuk menyimpan data navigasi item.
class _NavItem {
  final IconData icon;
  final String label;
  final bool isCenter; // Apakah tombol ini merupakan tombol tengah (dengan desain khusus).

  const _NavItem({required this.icon, required this.label, this.isCenter = false});
}