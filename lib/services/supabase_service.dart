// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../utils/error_logger.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;

  // ─── TEMPAT ───────────────────────────────────────────────
  static Future<List<TempatModel>> getAllTempat({
    int? kategoriId,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from(SupabaseConfig.tempatTable)
          .select('*, kategori(nama_kategori), kecamatan(nama_kecamatan)');

      if (kategoriId != null) {
        query = query.eq('kategori_id', kategoriId);
      }
      if (search != null && search.isNotEmpty) {
        query = query.ilike('nama_tempat', '%$search%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((e) => TempatModel.fromJson(e)).toList();
    } catch (e, stack) {
      ErrorLogger.e('getAllTempat failed', e, stack);
      return [];
    }
  }

  static Future<List<TempatModel>> getRandomTempat({int limit = 10}) async {
    try {
      final response = await _client
          .from(SupabaseConfig.tempatTable)
          .select('*, kategori(nama_kategori), kecamatan(nama_kecamatan)')
          .not('media', 'is', null)
          .limit(limit);
      final list = (response as List).map((e) => TempatModel.fromJson(e)).toList();
      list.shuffle();
      return list.take(limit).toList();
    } catch (e, stack) {
      ErrorLogger.e('getRandomTempat failed', e, stack);
      return [];
    }
  }

  static Future<TempatModel?> getTempatById(int id) async {
    try {
      final response = await _client
          .from(SupabaseConfig.tempatTable)
          .select('*, kategori(nama_kategori), kecamatan(nama_kecamatan)')
          .eq('id', id)
          .single();
      return TempatModel.fromJson(response);
    } catch (e, stack) {
      ErrorLogger.e('getTempatById failed', e, stack);
      return null;
    }
  }

  static Future<TempatModel?> insertTempat(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(SupabaseConfig.tempatTable)
          .insert(data)
          .select()
          .single();
      return TempatModel.fromJson(response);
    } catch (e, stack) {
      ErrorLogger.e('insertTempat failed', e, stack);
      rethrow;
    }
  }

  static Future<bool> updateTempat(int id, Map<String, dynamic> data) async {
    try {
      await _client.from(SupabaseConfig.tempatTable).update(data).eq('id', id);
      return true;
    } catch (e, stack) {
      ErrorLogger.e('updateTempat failed', e, stack);
      return false;
    }
  }

  static Future<bool> deleteTempat(int id) async {
    try {
      await _client.from(SupabaseConfig.tempatTable).delete().eq('id', id);
      return true;
    } catch (e, stack) {
      ErrorLogger.e('deleteTempat failed', e, stack);
      return false;
    }
  }

  // ─── TEMPAT BY USER ──────────────────────────────────────
  static Future<List<TempatModel>> getTempatByUserId(int userId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.tempatTable)
          .select('*, kategori(nama_kategori), kecamatan(nama_kecamatan)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => TempatModel.fromJson(e)).toList();
    } catch (e, stack) {
      ErrorLogger.e('getTempatByUserId failed', e, stack);
      return [];
    }
  }

  // ─── KATEGORI ─────────────────────────────────────────────
  static Future<List<KategoriModel>> getKategori() async {
    try {
      final response = await _client.from(SupabaseConfig.kategoriTable).select();
      return (response as List).map((e) => KategoriModel.fromJson(e)).toList();
    } catch (e, stack) {
      ErrorLogger.e('getKategori failed', e, stack);
      return [];
    }
  }

  // ─── KECAMATAN ────────────────────────────────────────────
  static Future<List<KecamatanModel>> getKecamatan() async {
    try {
      final response = await _client.from(SupabaseConfig.kecamatanTable).select();
      return (response as List).map((e) => KecamatanModel.fromJson(e)).toList();
    } catch (e, stack) {
      ErrorLogger.e('getKecamatan failed', e, stack);
      return [];
    }
  }

  // ─── NEARBY ───────────────────────────────────────────────
  static Future<List<TempatModel>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    try {
      final all = await getAllTempat(limit: 100);
      return all.where((t) {
        if (t.latitude == null || t.longitude == null) return false;
        final d = _haversine(lat, lng, t.latitude!, t.longitude!);
        return d <= radiusKm;
      }).toList()
        ..sort((a, b) {
          final da = _haversine(lat, lng, a.latitude!, a.longitude!);
          final db = _haversine(lat, lng, b.latitude!, b.longitude!);
          return da.compareTo(db);
        });
    } catch (e, stack) {
      ErrorLogger.e('getNearby failed', e, stack);
      return [];
    }
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * 3.14159265358979 / 180;
    final dLon = (lon2 - lon1) * 3.14159265358979 / 180;
    final a = (dLat / 2) * (dLat / 2) +
        (lat1 * 3.14159265358979 / 180).abs() * 0 +
        (dLon / 2) * (dLon / 2);
    return r * 2 * (a);
  }
}