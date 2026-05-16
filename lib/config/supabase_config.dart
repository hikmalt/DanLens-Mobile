// FILE: lib/config/supabase_config.dart
// File ini berisi konfigurasi untuk koneksi ke backend Supabase.
// Fungsi utama: menyimpan URL endpoint Supabase, kunci anonim (anon key) untuk autentikasi, nama bucket untuk menyimpan gambar, dan nama tabel-tabel yang digunakan.
// Informasi penting: File ini bersifat statis (const) sehingga nilainya tidak berubah selama aplikasi berjalan. Jangan membagikan anon key ke publik secara sembarangan, meskipun untuk klien mobile sudah aman karena terenkapsulasi dalam kode.

// Mendefinisikan kelas SupabaseConfig dengan semua properti statis.
class SupabaseConfig {
  // URL proyek Supabase yang digunakan.
  // Ini adalah endpoint untuk REST API, Realtime, dan Storage.
  static const String supabaseUrl = 'https://rnafixrgoucrplssoqtm.supabase.co';

  // Kunci anonim (anon key) untuk mengakses Supabase.
  // Kunci ini mengizinkan operasi baca/tulis sesuai dengan aturan Row Level Security (RLS) yang telah diatur.
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuYWZpeHJnb3VjcnBsc3NvcXRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4OTQzNTQsImV4cCI6MjA5MzQ3MDM1NH0.CeBNHCdH4MeyT765eQR0XPqAuzab-T1rZzIjpvGPN_E';

  // Nama bucket di Supabase Storage untuk menyimpan gambar tempat.
  static const String tempatImagesBucket = 'tempat_images';

  // Nama bucket untuk menyimpan foto profil pengguna.
  static const String profileImagesBucket = 'profil';

  // Nama tabel tempat di database Supabase.
  static const String tempatTable = 'tempat';

  // Nama tabel kategori.
  static const String kategoriTable = 'kategori';

  // Nama tabel kecamatan.
  static const String kecamatanTable = 'kecamatan';

  // Nama tabel users (pengguna).
  static const String usersTable = 'users';

  // Fungsi helper untuk menghasilkan URL publik suatu file di Storage.
  // Parameter: bucket (nama bucket), fileName (nama file).
  // Mengembalikan URL lengkap yang dapat diakses publik.
  static String storageUrl(String bucket, String fileName) =>
      '$supabaseUrl/storage/v1/object/public/$bucket/$fileName';
}