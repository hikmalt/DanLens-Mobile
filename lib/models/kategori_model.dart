// FILE: lib/models/kategori_model.dart
// File ini berisi model data untuk kategori tempat (kuliner, wisata, kesehatan, dll).
// Fungsi utama: merepresentasikan data kategori yang disimpan di tabel 'kategori' pada database Supabase.
// Informasi penting: Model ini digunakan untuk dropdown filter, menampilkan ikon kategori, dan relasi dengan tabel tempat.
// Setiap kategori memiliki id unik dan nama, serta method untuk mendapatkan ikon sederhana berdasarkan nama kategori.

// Mendefinisikan kelas KategoriModel.
class KategoriModel {
  // Identifikasi unik kategori (angka dari database).
  final int id;
  // Nama kategori, misal 'Kuliner', 'Wisata', dll.
  final String namaKategori;

  // Konstruktor untuk membuat objek KategoriModel.
  // Parameter wajib: id dan namaKategori.
  KategoriModel({required this.id, required this.namaKategori});

  // Pabrik (factory) untuk membuat KategoriModel dari JSON (respons Supabase).
  // Method ini digunakan saat menerima data dari API.
  factory KategoriModel.fromJson(Map<String, dynamic> json) =>
      KategoriModel(
        id: json['id'],
        // Mengambil nilai 'id' dari JSON, jika tidak ada akan null tapi karena id selalu ada di database, aman.
        namaKategori: json['nama_kategori'] ?? '',
        // Jika 'nama_kategori' null, gunakan string kosong.
      );

  // Getter (properti read-only) untuk mendapatkan ikon sederhana berupa karakter/emoji.
  // Ikon ini digunakan untuk tampilan cepat (misal di marker peta, chip filter, atau label).
  String get icon {
    // Nama kategori diubah menjadi huruf kecil untuk perbandingan case-insensitive.
    switch (namaKategori.toLowerCase()) {
      case 'kuliner':
        return '🍽️';   // Ikon untuk kategori Kuliner (pisau dan garpu).
      case 'wisata':
        return '🏛️';   // Ikon untuk kategori Wisata (bangunan klasik).
      case 'kesehatan':
        return '🏥';   // Ikon untuk kategori Kesehatan (rumah sakit).
      case 'kemasyarakatan':
        return '🏢';   // Ikon untuk kategori Kemasyarakatan (gedung/instansi).
      case 'transportasi':
        return '🚌';   // Ikon untuk kategori Transportasi (bus).
      default:
        return '📍';   // Ikon default jika kategori tidak dikenali (penanda lokasi).
    }
  }
}