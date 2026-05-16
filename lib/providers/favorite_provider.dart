// FILE: lib/providers/favorite_provider.dart
// File ini adalah penyedia data (provider) untuk mengelola daftar favorit pengguna.
// Fungsi utama: menyimpan ID tempat favorit, menyinkronkan dengan penyimpanan lokal (SharedPreferences),
// serta menyediakan operasi tambah/hapus favorit dan sinkronisasi dengan data tempat utama.
// Informasi penting: Data favorit disimpan secara lokal di perangkat menggunakan SharedPreferences,
// sehingga tidak bergantung pada koneksi internet. ID favorit disimpan dalam bentuk Set agar unik dan cepat pengecekan.

import 'package:flutter/foundation.dart';
// Mengimpor ChangeNotifier untuk manajemen state.

import 'package:shared_preferences/shared_preferences.dart';
// Mengimpor SharedPreferences untuk menyimpan data favorit secara lokal.

import '../models/models.dart';
// Mengimpor model TempatModel.

// Kelas provider untuk data favorit.
class FavoriteProvider extends ChangeNotifier {
  // Menyimpan ID tempat favorit dalam bentuk Set (menjamin unik dan cepat pencarian).
  Set<int> _favoriteIds = {};
  
  // Menyimpan objek TempatModel lengkap dari tempat favorit (untuk ditampilkan di halaman favorit).
  List<TempatModel> _favoriteItems = [];

  // Getter untuk mengambil daftar ID favorit (read-only).
  Set<int> get favoriteIds => _favoriteIds;
  
  // Getter untuk mengambil daftar objek tempat favorit.
  List<TempatModel> get favoriteItems => _favoriteItems;
  
  // Getter untuk menghitung jumlah favorit.
  int get count => _favoriteIds.length;

  // Memuat data favorit dari penyimpanan lokal saat aplikasi dimulai.
  Future<void> load() async {
    // Mendapatkan instance SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    // Membaca string list dengan kunci 'favorites', jika null maka gunakan list kosong.
    final ids = prefs.getStringList('favorites') ?? [];
    // Mengonversi setiap string ke integer dan memasukkannya ke dalam Set.
    _favoriteIds = ids.map((e) => int.parse(e)).toSet();
    // Memberi tahu UI bahwa data favorit telah berubah.
    notifyListeners();
  }

  // Mengecek apakah suatu ID tempat termasuk favorit.
  bool isFavorite(int id) => _favoriteIds.contains(id);

  // Menambah atau menghapus favorit (toggle).
  Future<void> toggle(TempatModel tempat) async {
    if (_favoriteIds.contains(tempat.id)) {
      // Jika sudah favorit, hapus ID dari Set.
      _favoriteIds.remove(tempat.id);
      // Hapus objek tempat dari daftar _favoriteItems.
      _favoriteItems.removeWhere((t) => t.id == tempat.id);
    } else {
      // Jika belum favorit, tambahkan ID ke Set.
      _favoriteIds.add(tempat.id);
      // Tambahkan objek tempat ke awal daftar _favoriteItems (agar yang terbaru di atas).
      _favoriteItems.insert(0, tempat);
    }
    // Simpan perubahan ke SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    // Konversi Set ID ke list string lalu simpan dengan kunci 'favorites'.
    await prefs.setStringList('favorites', _favoriteIds.map((e) => e.toString()).toList());
    // Beri tahu UI bahwa data favorit berubah.
    notifyListeners();
  }

  // Menyinkronkan daftar _favoriteItems dengan data tempat terbaru (misal setelah loadAll dari TempatProvider).
  void syncItems(List<TempatModel> allTempat) {
    // Filter semua tempat yang ID-nya ada di _favoriteIds.
    _favoriteItems = allTempat.where((t) => _favoriteIds.contains(t.id)).toList();
    // Beri tahu UI bahwa daftar favorit telah disinkronkan.
    notifyListeners();
  }
}