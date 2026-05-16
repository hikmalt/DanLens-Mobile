// FILE: lib/services/kecamatan_service.dart
// File ini berisi layanan untuk mengelola data kecamatan di Supabase.
// Fungsi: Menyediakan method statis untuk operasi CRUD (Create, Read, Update, Delete)
//         pada tabel 'kecamatan' yang menyimpan data polygon wilayah.
// Informasi penting: Data kecamatan mencakup id, nama_kecamatan, dan geojson (string GeoJSON).
//         Menggunakan Supabase client yang sudah diinisialisasi.
//         Semua method mencatat error ke ErrorLogger.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kecamatan_model.dart';
import '../utils/error_logger.dart';

class KecamatanService {
  // Supabase client instance.
  static final _client = Supabase.instance.client;

  // Method untuk mengambil semua data kecamatan (id, nama, geojson) diurutkan berdasarkan nama.
  static Future<List<KecamatanModel>> getAll() async {
    try {
      // Query ke tabel 'kecamatan', ambil kolom id, nama_kecamatan, geojson, lalu urutkan.
      final res = await _client
          .from('kecamatan')
          .select('id, nama_kecamatan, geojson')
          .order('nama_kecamatan');
      // Konversi hasil (List) ke List<KecamatanModel>.
      return (res as List).map((e) => KecamatanModel.fromJson(e)).toList();
    } catch (e, s) {
      // Catat error jika gagal.
      ErrorLogger.e('KecamatanService.getAll', e, s);
      return [];
    }
  }

  // Method untuk menambah kecamatan baru.
  static Future<KecamatanModel?> insert({
    required String namaKecamatan, // Nama kecamatan wajib.
    required String geojson,       // String GeoJSON polygon wajib.
  }) async {
    try {
      // Insert data ke tabel 'kecamatan', lalu ambil kembali data yang baru disisipkan.
      final res = await _client
          .from('kecamatan')
          .insert({'nama_kecamatan': namaKecamatan, 'geojson': geojson})
          .select()
          .single();
      // Konversi ke model.
      return KecamatanModel.fromJson(res);
    } catch (e, s) {
      ErrorLogger.e('KecamatanService.insert', e, s);
      rethrow; // Lempar ulang agar pemanggil bisa menangani.
    }
  }

  // Method untuk memperbarui nama dan GeoJSON kecamatan berdasarkan id.
  static Future<bool> update({
    required int id,
    required String namaKecamatan,
    required String geojson,
  }) async {
    try {
      // Update data.
      await _client
          .from('kecamatan')
          .update({'nama_kecamatan': namaKecamatan, 'geojson': geojson})
          .eq('id', id);
      return true;
    } catch (e, s) {
      ErrorLogger.e('KecamatanService.update', e, s);
      return false;
    }
  }

  // Method khusus untuk memperbarui hanya kolom geojson (tanpa mengubah nama).
  static Future<bool> updateGeoJson({required int id, required String geojson}) async {
    try {
      await _client.from('kecamatan').update({'geojson': geojson}).eq('id', id);
      return true;
    } catch (e, s) {
      ErrorLogger.e('KecamatanService.updateGeoJson', e, s);
      return false;
    }
  }

  // Method untuk menghapus kecamatan berdasarkan id.
  static Future<bool> delete(int id) async {
    try {
      await _client.from('kecamatan').delete().eq('id', id);
      return true;
    } catch (e, s) {
      ErrorLogger.e('KecamatanService.delete', e, s);
      return false;
    }
  }
}