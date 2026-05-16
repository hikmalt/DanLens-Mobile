// FILE: lib/models/models.dart
// File ini adalah pusat ekspor (barrel file) untuk semua model data yang digunakan di aplikasi DanLens.
// Dengan adanya file ini, kita cukup mengimpor 'package:danlens/models/models.dart' untuk mengakses semua model,
// tanpa perlu mengimpor setiap file model satu per satu.
// Model yang diekspor: TempatModel, KategoriModel, KecamatanModel, UserModel.

// Mengekspor file tempat_model.dart yang berisi kelas TempatModel (data tempat/lokasi).
export 'tempat_model.dart';

// Mengekspor file kategori_model.dart yang berisi kelas KategoriModel (data kategori tempat).
export 'kategori_model.dart';

// Mengekspor file kecamatan_model.dart yang berisi kelas KecamatanModel (data kecamatan dan polygon).
export 'kecamatan_model.dart';

// Mengekspor file user_model.dart yang berisi kelas UserModel (data pengguna dan autentikasi).
export 'user_model.dart';