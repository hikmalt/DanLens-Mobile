// lib/utils/cache_manager.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'error_logger.dart';

/// Simple JSON-based offline cache using SharedPreferences.
/// Stores full list of TempatModel so the app can work without internet.
class CacheManager {
  static const _keyTempat = 'cache_tempat';
  static const _keyKategori = 'cache_kategori';
  static const _keyKecamatan = 'cache_kecamatan';
  static const _keyTimestamp = 'cache_timestamp';
  static const _maxAgeMinutes = 30;

  // ── Save ──────────────────────────────────────────────────────
  static Future<void> saveTempat(List<TempatModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
                'kategori': t.namaKategori != null
                    ? {'nama_kategori': t.namaKategori}
                    : null,
                'kecamatan': t.namaKecamatan != null
                    ? {'nama_kecamatan': t.namaKecamatan}
                    : null,
              })
          .toList();
      await prefs.setString(_keyTempat, jsonEncode(json));
      await prefs.setInt(
          _keyTimestamp, DateTime.now().millisecondsSinceEpoch);
      ErrorLogger.i('Cache saved: ${list.length} tempat');
    } catch (e, s) {
      ErrorLogger.e('CacheManager.saveTempat failed', e, s);
    }
  }

  static Future<void> saveKategori(List<KategoriModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = list.map((k) => {'id': k.id, 'nama_kategori': k.namaKategori}).toList();
      await prefs.setString(_keyKategori, jsonEncode(json));
    } catch (e, s) {
      ErrorLogger.e('CacheManager.saveKategori failed', e, s);
    }
  }

  static Future<void> saveKecamatan(List<KecamatanModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = list.map((k) => {'id': k.id, 'nama_kecamatan': k.namaKecamatan}).toList();
      await prefs.setString(_keyKecamatan, jsonEncode(json));
    } catch (e, s) {
      ErrorLogger.e('CacheManager.saveKecamatan failed', e, s);
    }
  }

  // ── Load ──────────────────────────────────────────────────────
  static Future<List<TempatModel>?> loadTempat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyTempat);
      if (raw == null) return null;
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

  // ── Cache status ──────────────────────────────────────────────
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

  static Future<int> cacheSize() async {
    try {
      final list = await loadTempat();
      return list?.length ?? 0;
    } catch (_) {
      return 0;
    }
  }
}