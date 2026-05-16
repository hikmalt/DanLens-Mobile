// FILE: lib/services/tempat_service.dart
// File ini merupakan lapisan service (layanan) untuk mengelola data tempat.
// Fungsi: Menyediakan method-method statis yang memanggil SupabaseService untuk operasi CRUD tempat,
//         serta operasi tambahan seperti mengambil tempat terdekat, rating tertinggi, pencarian, dll.
// Informasi penting: Service ini bersifat wrapper (pembungkus) di atas SupabaseService.
//         Tujuannya agar kode lebih terstruktur dan memisahkan logika bisnis dengan akses data langsung.
//         Semua error ditangkap dan dicatat ke ErrorLogger.

import '../models/models.dart';
import '../services/supabase_service.dart';
import '../utils/error_logger.dart';

// Kelas TempatService berisi method statis untuk operasi data tempat.
class TempatService {
  // Method untuk mengambil semua tempat dengan filter kategori, pencarian, limit, offset.
  static Future<List<TempatModel>> getAll({
    int? kategoriId,   // ID kategori untuk filter (opsional).
    String? search,    // Kata kunci pencarian (opsional).
    int limit = 50,    // Batas jumlah data yang diambil.
    int offset = 0,    // Offset untuk paginasi.
  }) async {
    try {
      // Delegasikan ke SupabaseService.
      return await SupabaseService.getAllTempat(
        kategoriId: kategoriId,
        search: search,
        limit: limit,
        offset: offset,
      );
    } catch (e, stack) {
      // Catat error jika terjadi.
      ErrorLogger.e('TempatService.getAll failed', e, stack);
      return []; // Kembalikan daftar kosong.
    }
  }

  // Method untuk mengambil tempat secara acak (biasanya untuk carousel).
  static Future<List<TempatModel>> getRandom({int limit = 8}) async {
    return await SupabaseService.getRandomTempat(limit: limit);
  }

  // Method untuk mengambil satu tempat berdasarkan ID.
  static Future<TempatModel?> getById(int id) async {
    return await SupabaseService.getTempatById(id);
  }

  // Method untuk menambahkan tempat baru.
  static Future<TempatModel?> insert(Map<String, dynamic> data) async {
    return await SupabaseService.insertTempat(data);
  }

  // Method untuk memperbarui data tempat berdasarkan ID.
  static Future<bool> update(int id, Map<String, dynamic> data) async {
    return await SupabaseService.updateTempat(id, data);
  }

  // Method untuk menghapus tempat berdasarkan ID.
  static Future<bool> delete(int id) async {
    return await SupabaseService.deleteTempat(id);
  }

  // Method untuk mengambil tempat terdekat dari koordinat tertentu menggunakan rumus Haversine.
  static Future<List<TempatModel>> getNearby({
    required double lat,      // Lintang titik referensi.
    required double lng,      // Bujur titik referensi.
    double radiusKm = 5.0,    // Radius pencarian dalam kilometer.
  }) async {
    return await SupabaseService.getNearby(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
  }

  // Method untuk mengambil tempat dengan rating tertinggi.
  static Future<List<TempatModel>> getTopRated({
    int limit = 10,   // Jumlah maksimal tempat yang diambil.
  }) async {
    // Ambil semua tempat (maksimal 100 data).
    final all = await getAll(limit: 100);
    // Urutkan berdasarkan rating tertinggi ke terendah.
    all.sort((a, b) => (b.reviewRating ?? 0).compareTo(a.reviewRating ?? 0));
    // Ambil sejumlah `limit` pertama.
    return all.take(limit).toList();
  }

  // Method untuk mengambil tempat berdasarkan kategori (wrapper dari getAll).
  static Future<List<TempatModel>> getByCategory(int kategoriId) async {
    return await getAll(kategoriId: kategoriId);
  }

  // Method untuk mencari tempat berdasarkan nama atau alamat (wrapper dari getAll dengan search).
  static Future<List<TempatModel>> search(String query) async {
    return await getAll(search: query);
  }
}