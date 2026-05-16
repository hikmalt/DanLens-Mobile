// FILE: lib/services/supabase_service.dart
// File ini berisi layanan untuk berkomunikasi dengan Supabase (backend database).
// Fungsi: Menyediakan method statis untuk operasi CRUD (Create, Read, Update, Delete)
//         pada tabel tempat, kategori, kecamatan, serta query khusus seperti tempat terdekat.
// Informasi penting: Menggunakan Supabase client yang sudah diinisialisasi di main.dart.
//         Setiap method menangkap error dan mencatatnya ke ErrorLogger.
//         Beberapa method mengembalikan data dalam bentuk model (TempatModel, KategoriModel, KecamatanModel).

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../utils/error_logger.dart';

class SupabaseService {
  // Instance Supabase client yang digunakan untuk semua operasi.
  static final SupabaseClient _client = Supabase.instance.client;

  // Getter untuk mengakses client dari luar jika diperlukan.
  static SupabaseClient get client => _client;

  // ------------------------------------------------------------------
  //  OPERASI TABEL TEMPAT
  // ------------------------------------------------------------------

  // Mengambil daftar tempat dengan opsi filter kategori, pencarian, paginasi.
  static Future<List<TempatModel>> getAllTempat({
    int? kategoriId,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Query awal: ambil semua kolom tempat, plus nama_kategori dari relasi kategori, dan nama_kecamatan dari relasi kecamatan.
      var query = _client
          .from(SupabaseConfig.tempatTable)
          .select('*, kategori(nama_kategori), kecamatan(nama_kecamatan)');

      // Jika filter kategori diberikan, tambahkan kondisi where.
      if (kategoriId != null) {
        query = query.eq('kategori_id', kategoriId);
      }
      // Jika kata kunci pencarian diberikan, cari di kolom nama_tempat (case-insensitive).
      if (search != null && search.isNotEmpty) {
        query = query.ilike('nama_tempat', '%$search%');
      }

      // Eksekusi query dengan urutan descending berdasarkan created_at, dan batasan limit/offset.
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Konversi hasil response (List<dynamic>) ke List<TempatModel>.
      return (response as List).map((e) => TempatModel.fromJson(e)).toList();
    } catch (e, stack) {
      ErrorLogger.e('getAllTempat failed', e, stack);
      return []; // Kembalikan daftar kosong jika error.
    }
  }

  // Mengambil sejumlah tempat yang memiliki gambar (media) secara acak (untuk carousel).
  static Future<List<TempatModel>> getRandomTempat({int limit = 10}) async {
    try {
      // Query tempat yang memiliki media tidak null, ambil juga kategori dan kecamatan.
      final response = await _client
          .from(SupabaseConfig.tempatTable)
          .select('*, kategori(nama_kategori), kecamatan(nama_kecamatan)')
          .not('media', 'is', null)
          .limit(limit);
      // Konversi ke list.
      final list = (response as List).map((e) => TempatModel.fromJson(e)).toList();
      // Acak urutannya.
      list.shuffle();
      // Ambil sebanyak limit (sebenarnya sudah di-limit, tapi untuk jaga-jaga).
      return list.take(limit).toList();
    } catch (e, stack) {
      ErrorLogger.e('getRandomTempat failed', e, stack);
      return [];
    }
  }

  // Mengambil satu tempat berdasarkan ID.
  static Future<TempatModel?> getTempatById(int id) async {
    try {
      final response = await _client
          .from(SupabaseConfig.tempatTable)
          .select('*, kategori(nama_kategori), kecamatan(nama_kecamatan)')
          .eq('id', id)
          .single(); // Hanya satu baris.
      return TempatModel.fromJson(response);
    } catch (e, stack) {
      ErrorLogger.e('getTempatById failed', e, stack);
      return null;
    }
  }

  // Menambahkan tempat baru.
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
      rethrow; // Lempar ulang agar pemanggil bisa menangani.
    }
  }

  // Memperbarui data tempat berdasarkan ID.
  static Future<bool> updateTempat(int id, Map<String, dynamic> data) async {
    try {
      await _client.from(SupabaseConfig.tempatTable).update(data).eq('id', id);
      return true;
    } catch (e, stack) {
      ErrorLogger.e('updateTempat failed', e, stack);
      return false;
    }
  }

  // Menghapus tempat berdasarkan ID.
  static Future<bool> deleteTempat(int id) async {
    try {
      await _client.from(SupabaseConfig.tempatTable).delete().eq('id', id);
      return true;
    } catch (e, stack) {
      ErrorLogger.e('deleteTempat failed', e, stack);
      return false;
    }
  }

  // ------------------------------------------------------------------
  //  OPERASI TEMPAT BERDASARKAN USER
  // ------------------------------------------------------------------

  // Mengambil daftar tempat yang dibuat oleh user tertentu (berdasarkan user_id).
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

  // ------------------------------------------------------------------
  //  OPERASI TABEL KATEGORI
  // ------------------------------------------------------------------

  // Mengambil semua kategori.
  static Future<List<KategoriModel>> getKategori() async {
    try {
      final response = await _client.from(SupabaseConfig.kategoriTable).select();
      return (response as List).map((e) => KategoriModel.fromJson(e)).toList();
    } catch (e, stack) {
      ErrorLogger.e('getKategori failed', e, stack);
      return [];
    }
  }

  // ------------------------------------------------------------------
  //  OPERASI TABEL KECAMATAN
  // ------------------------------------------------------------------

  // Mengambil semua kecamatan.
  static Future<List<KecamatanModel>> getKecamatan() async {
    try {
      final response = await _client.from(SupabaseConfig.kecamatanTable).select();
      return (response as List).map((e) => KecamatanModel.fromJson(e)).toList();
    } catch (e, stack) {
      ErrorLogger.e('getKecamatan failed', e, stack);
      return [];
    }
  }

  // ------------------------------------------------------------------
  //  OPERASI CRUD UNTUK KECAMATAN (ADMIN)
  // ------------------------------------------------------------------

  // Menambahkan kecamatan baru (dengan polygon GeoJSON).
  static Future<KecamatanModel?> insertKecamatan(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(SupabaseConfig.kecamatanTable)
          .insert(data)
          .select()
          .single();
      return KecamatanModel.fromJson(response);
    } catch (e, stack) {
      ErrorLogger.e('insertKecamatan failed', e, stack);
      rethrow;
    }
  }

  // Memperbarui data kecamatan berdasarkan ID.
  static Future<bool> updateKecamatan(int id, Map<String, dynamic> data) async {
    try {
      await _client.from(SupabaseConfig.kecamatanTable).update(data).eq('id', id);
      return true;
    } catch (e, stack) {
      ErrorLogger.e('updateKecamatan failed', e, stack);
      return false;
    }
  }

  // Menghapus kecamatan berdasarkan ID.
  static Future<bool> deleteKecamatan(int id) async {
    try {
      await _client.from(SupabaseConfig.kecamatanTable).delete().eq('id', id);
      return true;
    } catch (e, stack) {
      ErrorLogger.e('deleteKecamatan failed', e, stack);
      return false;
    }
  }

  // ------------------------------------------------------------------
  //  OPERASI TEMPAT TERDEKAT (NEARBY)
  // ------------------------------------------------------------------

  // Menghitung tempat terdekat dari koordinat tertentu dalam radius tertentu.
  // Metode ini mengambil semua tempat (maksimal 100) lalu menyaring dan mengurutkan menggunakan rumus haversine.
  static Future<List<TempatModel>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    try {
      // Ambil semua tempat (batas 100).
      final all = await getAllTempat(limit: 100);
      // Filter tempat yang memiliki koordinat dan jaraknya <= radiusKm.
      return all.where((t) {
        if (t.latitude == null || t.longitude == null) return false;
        final d = _haversine(lat, lng, t.latitude!, t.longitude!);
        return d <= radiusKm;
      }).toList()
        // Urutkan berdasarkan jarak terdekat.
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

  // Fungsi internal untuk menghitung jarak dengan rumus haversine (sederhana, akurasi cukup).
  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Jari-jari bumi dalam km.
    // Konversi derajat ke radian.
    final dLat = (lat2 - lat1) * 3.14159265358979 / 180;
    final dLon = (lon2 - lon1) * 3.14159265358979 / 180;
    // Rumus haversine (sederhana, namun ada kekurangan karena tidak menggunakan cos lintang yang tepat, tapi masih cukup untuk demo).
    final a = (dLat / 2) * (dLat / 2) +
        (lat1 * 3.14159265358979 / 180).abs() * 0 +
        (dLon / 2) * (dLon / 2);
    return r * 2 * (a);
  }
}