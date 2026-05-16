// FILE: lib/utils/cache_manager.dart
// File ini mengelola penyimpanan data offline menggunakan SharedPreferences.
// Fungsi: Menyimpan daftar tempat, kategori, dan kecamatan dalam bentuk JSON
//         agar aplikasi tetap dapat berjalan tanpa koneksi internet.
// Informasi penting: Data disimpan dengan batas waktu 30 menit (freshness).
//                 Hanya data tempat, kategori, kecamatan yang dicache.
//                 Setiap penyimpanan menyertai timestamp untuk pengecekan umur data.
//                 Menggunakan SharedPreferences karena ukuran data tidak besar.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'error_logger.dart';

// Kelas CacheManager menyediakan method statis untuk operasi cache.
class CacheManager {
  // Kunci untuk menyimpan data tempat di SharedPreferences.
  static const _keyTempat = 'cache_tempat';
  // Kunci untuk menyimpan data kategori.
  static const _keyKategori = 'cache_kategori';
  // Kunci untuk menyimpan data kecamatan.
  static const _keyKecamatan = 'cache_kecamatan';
  // Kunci untuk menyimpan timestamp (waktu) cache terakhir.
  static const _keyTimestamp = 'cache_timestamp';
  // Maksimal umur cache dalam menit (30 menit).
  static const _maxAgeMinutes = 30;

  // ------------------------------------------------------------------
  //  METODE PENYIMPANAN (SAVE)
  // ------------------------------------------------------------------

  // Menyimpan daftar tempat ke SharedPreferences dalam format JSON.
  static Future<void> saveTempat(List<TempatModel> list) async {
    try {
      // Dapatkan instance SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      // Konversi setiap objek TempatModel ke Map yang sesuai untuk JSON.
      final json = list
          .map((t) => {
                'id': t.id,
                'nama_tempat': t.namaTempat,
                'detail_tempat': t.detailTempat,
                'jalan': t.jalan,
                'kecamatan_id': t.kecamatanId,
                'latitude': t.latitude,
                'longitude': t.longitude,
                'kategori_id': t.kategoriId,
                'review_rating': t.reviewRating,
                'kontak': t.kontak,
                'media': t.media,
                // Sertakan data kategori dan kecamatan yang digabung (joined) jika ada.
                'kategori': t.namaKategori != null
                    ? {'nama_kategori': t.namaKategori}
                    : null,
                'kecamatan': t.namaKecamatan != null
                    ? {'nama_kecamatan': t.namaKecamatan}
                    : null,
              })
          .toList();
      // Simpan JSON string.
      await prefs.setString(_keyTempat, jsonEncode(json));
      // Simpan timestamp (waktu dalam milidetik).
      await prefs.setInt(
          _keyTimestamp, DateTime.now().millisecondsSinceEpoch);
      // Catat log sukses.
      ErrorLogger.i('Cache saved: ${list.length} tempat');
    } catch (e, s) {
      // Catat error jika gagal.
      ErrorLogger.e('CacheManager.saveTempat failed', e, s);
    }
  }

  // Menyimpan daftar kategori ke cache.
  static Future<void> saveKategori(List<KategoriModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = list.map((k) => {'id': k.id, 'nama_kategori': k.namaKategori}).toList();
      await prefs.setString(_keyKategori, jsonEncode(json));
    } catch (e, s) {
      ErrorLogger.e('CacheManager.saveKategori failed', e, s);
    }
  }

  // Menyimpan daftar kecamatan ke cache.
  static Future<void> saveKecamatan(List<KecamatanModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = list.map((k) => {'id': k.id, 'nama_kecamatan': k.namaKecamatan}).toList();
      await prefs.setString(_keyKecamatan, jsonEncode(json));
    } catch (e, s) {
      ErrorLogger.e('CacheManager.saveKecamatan failed', e, s);
    }
  }

  // ------------------------------------------------------------------
  //  METODE MEMUAT (LOAD)
  // ------------------------------------------------------------------

  // Memuat daftar tempat dari cache. Mengembalikan null jika tidak ada.
  static Future<List<TempatModel>?> loadTempat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyTempat);
      if (raw == null) return null;
      // Decode JSON dan konversi ke List<TempatModel>.
      final list = (jsonDecode(raw) as List)
          .map((e) => TempatModel.fromJson(e as Map<String, dynamic>))
          .toList();
      ErrorLogger.i('Cache loaded: ${list.length} tempat');
      return list;
    } catch (e, s) {
      ErrorLogger.e('CacheManager.loadTempat failed', e, s);
      return null;
    }
  }

  // Memuat daftar kategori dari cache.
  static Future<List<KategoriModel>?> loadKategori() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyKategori);
      if (raw == null) return null;
      return (jsonDecode(raw) as List)
          .map((e) => KategoriModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      ErrorLogger.e('CacheManager.loadKategori failed', e, s);
      return null;
    }
  }

  // Memuat daftar kecamatan dari cache.
  static Future<List<KecamatanModel>?> loadKecamatan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyKecamatan);
      if (raw == null) return null;
      return (jsonDecode(raw) as List)
          .map((e) => KecamatanModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      ErrorLogger.e('CacheManager.loadKecamatan failed', e, s);
      return null;
    }
  }

  // ------------------------------------------------------------------
  //  STATUS DAN MANAJEMEN CACHE
  // ------------------------------------------------------------------

  // Mengecek apakah cache masih segar (belum lebih dari _maxAgeMinutes menit).
  static Future<bool> isFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_keyTimestamp);
      if (ts == null) return false;
      final age =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
      return age.inMinutes < _maxAgeMinutes;
    } catch (_) {
      return false;
    }
  }

  // Menghapus semua data cache.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTempat);
      await prefs.remove(_keyKategori);
      await prefs.remove(_keyKecamatan);
      await prefs.remove(_keyTimestamp);
      ErrorLogger.i('Cache cleared');
    } catch (e, s) {
      ErrorLogger.e('CacheManager.clear failed', e, s);
    }
  }

  // Mengembalikan jumlah entri tempat dalam cache (ukuran cache).
  static Future<int> cacheSize() async {
    try {
      final list = await loadTempat();
      return list?.length ?? 0;
    } catch (_) {
      return 0;
    }
  }
}