// lib/config/supabase_config.dart

class SupabaseConfig {
  static const String supabaseUrl = 'https://rnafixrgoucrplssoqtm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuYWZpeHJnb3VjcnBsc3NvcXRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4OTQzNTQsImV4cCI6MjA5MzQ3MDM1NH0.CeBNHCdH4MeyT765eQR0XPqAuzab-T1rZzIjpvGPN_E';

  // Bucket names
  static const String tempatImagesBucket = 'tempat_images';
  static const String profileImagesBucket = 'profil';

  // Table names
  static const String tempatTable = 'tempat';
  static const String kategoriTable = 'kategori';
  static const String kecamatanTable = 'kecamatan';
  static const String usersTable = 'users';

  // Storage base URL
  static String storageUrl(String bucket, String fileName) =>
      '$supabaseUrl/storage/v1/object/public/$bucket/$fileName';
}