// FILE: lib/services/storage_service.dart
// File ini bertugas mengelola unggahan dan penghapusan gambar ke Supabase Storage.
// Ada dua bucket: tempat_images (untuk gambar tempat) dan profil (untuk foto profil user).
// Semua fungsi bersifat statis (langsung dipanggil tanpa membuat objek).

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../utils/error_logger.dart';

class StorageService {
  // Instance Supabase client untuk mengakses storage.
  static final _client = Supabase.instance.client;
  // Pembuat UUID untuk nama file unik.
  static const _uuid = Uuid();

  // --------------------------------------------------------------
  // FUNGSI UNTUK GAMBAR TEMPAT
  // --------------------------------------------------------------

  // Mengunggah gambar tempat ke bucket 'tempat_images'.
  // Parameter: imageFile (file gambar dari galeri/kamera).
  // Mengembalikan: nama file yang tersimpan, atau null jika gagal.
  static Future<String?> uploadTempatImage(File imageFile) async {
    try {
      // Ambil ekstensi file (jpg, png, dll) dari path.
      final ext = imageFile.path.split('.').last.toLowerCase();
      // Buat nama file unik menggunakan UUID + ekstensi.
      final fileName = '${_uuid.v4()}.$ext';

      // Lakukan unggah ke Supabase Storage.
      await _client.storage
          .from(SupabaseConfig.tempatImagesBucket)
          .upload(fileName, imageFile, fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: false, // Tidak menimpa file jika sudah ada (karena nama unik).
          ));

      // Catat log sukses.
      ErrorLogger.i('Image uploaded: $fileName');
      return fileName;
    } catch (e, stack) {
      // Catat error jika gagal.
      ErrorLogger.e('uploadTempatImage failed', e, stack);
      return null;
    }
  }

  // Menghapus gambar tempat berdasarkan nama file.
  // Parameter: fileName (nama file yang akan dihapus).
  // Mengembalikan: true jika berhasil, false jika gagal.
  static Future<bool> deleteTempatImage(String fileName) async {
    try {
      await _client.storage
          .from(SupabaseConfig.tempatImagesBucket)
          .remove([fileName]); // Hapus file dari bucket.
      return true;
    } catch (e, stack) {
      ErrorLogger.e('deleteTempatImage failed', e, stack);
      return false;
    }
  }

  // Mendapatkan URL publik gambar tempat.
  // Parameter: fileName (nama file yang sudah diunggah).
  // Mengembalikan: string URL lengkap yang dapat diakses publik.
  static String getTempatImageUrl(String fileName) {
    return _client.storage
        .from(SupabaseConfig.tempatImagesBucket)
        .getPublicUrl(fileName);
  }

  // Mendaftar semua file gambar tempat yang ada di bucket.
  // Mengembalikan: daftar nama file (List<String>), atau daftar kosong jika gagal.
  static Future<List<String>> listTempatImages() async {
    try {
      final files = await _client.storage
          .from(SupabaseConfig.tempatImagesBucket)
          .list(); // Ambil daftar file.
      return files.map((f) => f.name).toList();
    } catch (e, stack) {
      ErrorLogger.e('listTempatImages failed', e, stack);
      return [];
    }
  }

  // --------------------------------------------------------------
  // FUNGSI UNTUK FOTO PROFIL
  // --------------------------------------------------------------

  // Mengunggah foto profil ke bucket 'profil'.
  // Parameter: imageFile (file gambar).
  // Mengembalikan: nama file yang tersimpan, atau null jika gagal.
  static Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${_uuid.v4()}.$ext';

      await _client.storage
          .from(SupabaseConfig.profileImagesBucket)
          .upload(fileName, imageFile, fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true, // Jika nama file sama, timpa (karena UUID unik, sebenarnya tidak perlu upsert).
          ));

      ErrorLogger.i('Profile image uploaded: $fileName');
      return fileName;
    } catch (e, stack) {
      ErrorLogger.e('uploadProfileImage failed', e, stack);
      return null;
    }
  }

  // Menghapus foto profil lama.
  // Parameter: fileName (nama file yang akan dihapus).
  // Mengembalikan: true jika berhasil, false jika gagal.
  static Future<bool> deleteProfileImage(String fileName) async {
    try {
      await _client.storage
          .from(SupabaseConfig.profileImagesBucket)
          .remove([fileName]);
      return true;
    } catch (e, stack) {
      ErrorLogger.e('deleteProfileImage failed', e, stack);
      return false;
    }
  }

  // Mendapatkan URL publik foto profil.
  // Parameter: fileName (nama file).
  // Mengembalikan: string URL lengkap.
  static String getProfileImageUrl(String fileName) {
    return _client.storage
        .from(SupabaseConfig.profileImagesBucket)
        .getPublicUrl(fileName);
  }
}