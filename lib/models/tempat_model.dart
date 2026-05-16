// FILE: lib/models/tempat_model.dart
// File ini berisi definisi model data untuk tempat (tempat wisata, kuliner, dll) di aplikasi DanLens.
// Model ini merepresentasikan data tempat yang disimpan di tabel 'tempat' pada database Supabase.
// Fungsi utama: menyimpan informasi lengkap tentang suatu lokasi seperti nama, alamat, koordinat (latitude/longitude),
// kategori, rating, kontak, gambar, serta relasi ke kecamatan dan pengguna (user_id).
// Informasi penting: Model ini juga menyertakan field hasil join (namaKategori, namaKecamatan) yang diisi saat query
// dengan relasi, sehingga tidak perlu melakukan query terpisah untuk menampilkan nama kategori/kecamatan.

// Mendefinisikan kelas TempatModel sebagai representasi data tempat.
class TempatModel {
  // Identifikasi unik tempat, biasanya berupa angka dari database.
  final int id;
  // Nama tempat (wajib).
  final String namaTempat;
  // Deskripsi detail tempat (opsional).
  final String? detailTempat;
  // Nama jalan atau alamat singkat (opsional).
  final String? jalan;
  // ID kecamatan (foreign key ke tabel kecamatan), digunakan untuk relasi.
  final int? kecamatanId;
  // Koordinat lintang (latitude) untuk pemetaan.
  final double? latitude;
  // Koordinat bujur (longitude) untuk pemetaan.
  final double? longitude;
  // ID kategori (foreign key ke tabel kategori), misal kuliner, wisata, dll.
  final int? kategoriId;
  // Rating ulasan pengguna (skala 0.0 - 5.0).
  final double? reviewRating;
  // Nomor kontak (telepon/WA) tempat (opsional).
  final String? kontak;
  // Nama file gambar/media yang disimpan di Supabase Storage (opsional).
  final String? media;
  // Waktu pembuatan data (tanggal dan jam), dari database.
  final DateTime? createdAt;
  // Waktu terakhir data diperbarui, dari database.
  final DateTime? updatedAt;
  // ID pengguna yang menambahkan tempat (foreign key ke tabel users).
  final int? userId;

  // Field hasil join (tidak tersimpan langsung di tabel tempat, tetapi diisi saat query dengan relasi).
  final String? namaKategori;
  // Nama kategori dari tabel kategori (misal 'Kuliner').
  final String? namaKecamatan;
  // Nama kecamatan dari tabel kecamatan.

  // Konstruktor untuk membuat objek TempatModel.
  // Parameter wajib: id dan namaTempat. Parameter lainnya opsional (bisa null).
  TempatModel({
    required this.id,
    required this.namaTempat,
    this.detailTempat,
    this.jalan,
    this.kecamatanId,
    this.latitude,
    this.longitude,
    this.kategoriId,
    this.reviewRating,
    this.kontak,
    this.media,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.namaKategori,
    this.namaKecamatan,
  });

  // Pabrik (factory) untuk membuat TempatModel dari peta (Map) JSON yang diterima dari Supabase.
  // Method ini digunakan saat menerima respons dari API.
  factory TempatModel.fromJson(Map<String, dynamic> json) {
    return TempatModel(
      id: json['id'] ?? 0,
      // Jika id null, default 0.
      namaTempat: json['nama_tempat'] ?? '',
      // Nama tempat default string kosong.
      detailTempat: json['detail_tempat'],
      // Bisa null.
      jalan: json['jalan'],
      kecamatanId: json['kecamatan_id'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      // Konversi dari num ke double, aman untuk null.
      longitude: (json['longitude'] as num?)?.toDouble(),
      kategoriId: json['kategori_id'],
      reviewRating: (json['review_rating'] as num?)?.toDouble(),
      kontak: json['kontak'],
      media: json['media'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      // Jika ada, parse string menjadi DateTime; jika gagal atau null, hasil null.
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      userId: json['user_id'],
      namaKategori: json['kategori']?['nama_kategori'],
      // Mengambil field nama_kategori dari objek relasi kategori (jika ada).
      namaKecamatan: json['kecamatan']?['nama_kecamatan'],
      // Mengambil field nama_kecamatan dari objek relasi kecamatan (jika ada).
    );
  }

  // Mengonversi objek TempatModel ke peta (Map) untuk dikirim ke Supabase (misal saat insert atau update).
  // Field yang dikirim hanya field yang ada di tabel tempat (tidak termasuk hasil join).
  Map<String, dynamic> toJson() {
    return {
      'nama_tempat': namaTempat,
      'detail_tempat': detailTempat,
      'jalan': jalan,
      'kecamatan_id': kecamatanId,
      'latitude': latitude,
      'longitude': longitude,
      'kategori_id': kategoriId,
      'review_rating': reviewRating,
      'kontak': kontak,
      'media': media,
      'user_id': userId,
    };
  }

  // Getter untuk menghasilkan URL lengkap gambar tempat dari Supabase Storage.
  // Jika tidak ada media (null atau string kosong), mengembalikan string kosong.
  String get imageUrl {
    if (media == null || media!.isEmpty) return '';
    return 'https://rnafixrgoucrplssoqtm.supabase.co/storage/v1/object/public/tempat_images/$media';
  }

  // Getter untuk menghasilkan ikon sederhana (berupa karakter) berdasarkan nama kategori.
  // Ikon digunakan untuk tampilan marker atau label cepat.
  String get categoryIcon {
    switch (namaKategori?.toLowerCase()) {
      case 'kuliner': return '🍽️';
      case 'wisata': return '🏛️';
      case 'kesehatan': return '🏥';
      case 'kemasyarakatan': return '🏢';
      case 'transportasi': return '🚌';
      default: return '📍';
    }
  }
}