// FILE: lib/models/user_model.dart
// File ini berisi definisi model data untuk pengguna (user) aplikasi DanLens.
// Model ini merepresentasikan data pengguna yang disimpan di tabel 'users' pada database Supabase.
// Fungsi utama: menyimpan informasi pengguna seperti id, nama, email, peran (role), foto profil, dan waktu pendaftaran.
// Informasi penting: Model ini digunakan di seluruh aplikasi untuk mengelola data pengguna yang sedang login,
// serta untuk mengecek apakah pengguna memiliki hak akses admin.

// Mendefinisikan kelas UserModel sebagai representasi data pengguna.
class UserModel {
  // Identifikasi unik pengguna, biasanya berupa angka dari database.
  final int id;
  // Nama lengkap pengguna.
  final String name;
  // Alamat email pengguna, digunakan untuk login.
  final String email;
  // Peran pengguna dalam sistem: 'admin' atau 'uploader' (bisa null jika belum diatur).
  final String? role;
  // Nama file foto profil yang tersimpan di Supabase Storage (bisa null jika tidak ada foto).
  final String? photo;
  // Waktu pembuatan akun (tanggal dan jam), diambil dari database.
  final DateTime? createdAt;

  // Konstruktor untuk membuat objek UserModel.
  // Parameter wajib: id, name, email. Parameter lainnya opsional (bisa null).
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.photo,
    this.createdAt,
  });

  // Pabrik (factory) untuk membuat UserModel dari peta (Map) JSON yang diterima dari database Supabase.
  // Method ini digunakan saat menerima respons dari API.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      // Jika json['id'] null, gunakan nilai default 0.
      name: json['name'] ?? '',
      // Jika json['name'] null, gunakan string kosong.
      email: json['email'] ?? '',
      // Email: null aman menjadi string kosong.
      role: json['role'],
      // Role boleh null.
      photo: json['photo'],
      // Photo boleh null.
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      // Jika created_at ada, parse menjadi DateTime; jika gagal atau null, hasilnya null.
    );
  }

  // Getter (properti read-only) untuk mengecek apakah pengguna adalah admin.
  // Mengembalikan true jika nilai role sama dengan string 'admin'.
  bool get isAdmin => role == 'admin';

  // Getter untuk menghasilkan URL lengkap foto profil pengguna.
  // URL mengarah ke bucket 'profil' di Supabase Storage.
  // Jika tidak ada foto (photo null atau kosong), mengembalikan string kosong.
  String get photoUrl {
    if (photo == null || photo!.isEmpty) return '';
    // Menggabungkan base URL Supabase dengan nama file foto.
    return 'https://rnafixrgoucrplssoqtm.supabase.co/storage/v1/object/public/profil/$photo';
  }
}