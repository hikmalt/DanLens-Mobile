// lib/models/tempat_model.dart
class TempatModel {
  final int id;
  final String namaTempat;
  final String? detailTempat;
  final String? jalan;
  final int? kecamatanId;
  final double? latitude;
  final double? longitude;
  final int? kategoriId;
  final double? reviewRating;
  final String? kontak;
  final String? media;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? userId;
 
  // Joined fields
  final String? namaKategori;
  final String? namaKecamatan;
 
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
 
  factory TempatModel.fromJson(Map<String, dynamic> json) {
    return TempatModel(
      id: json['id'] ?? 0,
      namaTempat: json['nama_tempat'] ?? '',
      detailTempat: json['detail_tempat'],
      jalan: json['jalan'],
      kecamatanId: json['kecamatan_id'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      kategoriId: json['kategori_id'],
      reviewRating: (json['review_rating'] as num?)?.toDouble(),
      kontak: json['kontak'],
      media: json['media'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      userId: json['user_id'],
      namaKategori: json['kategori']?['nama_kategori'],
      namaKecamatan: json['kecamatan']?['nama_kecamatan'],
    );
  }
 
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
 
  String get imageUrl {
    if (media == null || media!.isEmpty) return '';
    return 'https://rnafixrgoucrplssoqtm.supabase.co/storage/v1/object/public/tempat_images/$media';
  }
 
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
 