// lib/models/kecamatan_model.dart
class KecamatanModel {
  final int id;
  final String namaKecamatan;
 
  KecamatanModel({required this.id, required this.namaKecamatan});
 
  factory KecamatanModel.fromJson(Map<String, dynamic> json) =>
      KecamatanModel(id: json['id'], namaKecamatan: json['nama_kecamatan'] ?? '');
}