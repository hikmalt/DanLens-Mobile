// lib/models/kategori_model.dart
class KategoriModel {
  final int id;
  final String namaKategori;
 
  KategoriModel({required this.id, required this.namaKategori});
 
  factory KategoriModel.fromJson(Map<String, dynamic> json) =>
      KategoriModel(id: json['id'], namaKategori: json['nama_kategori'] ?? '');
 
  String get icon {
    switch (namaKategori.toLowerCase()) {
      case 'kuliner': return '🍽️';
      case 'wisata': return '🏛️';
      case 'kesehatan': return '🏥';
      case 'kemasyarakatan': return '🏢';
      case 'transportasi': return '🚌';
      default: return '📍';
    }
  }
}