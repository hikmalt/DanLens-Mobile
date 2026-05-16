// FILE: lib/models/kecamatan_model.dart
// File ini berisi model data untuk kecamatan yang mendukung penyimpanan polygon (GeoJSON) di database Supabase.
// Fungsi utama: merepresentasikan data kecamatan termasuk batas wilayah dalam format GeoJSON, mengurai GeoJSON menjadi titik-titik koordinat (LatLng) untuk digambar di peta, menghitung titik pusat, menghitung luas wilayah, serta membuat GeoJSON dari titik-titik yang digambar admin.
// Informasi penting: Kolom 'geojson' di tabel kecamatan sudah ada. Model ini menyediakan method untuk parsing GeoJSON, perhitungan luas (dengan proyeksi meter), dan pembuatan GeoJSON untuk input poligon oleh admin.

import 'dart:convert';
// Mengimpor library untuk encoding/decoding JSON (digunakan untuk mengurai string GeoJSON).

import 'package:latlong2/latlong.dart';
// Mengimpor kelas LatLng untuk merepresentasikan koordinat geografis.

import 'dart:math';
// Mengimpor fungsi matematika seperti cos, pi, dan kelas Point untuk perhitungan luas.

// Kelas model untuk kecamatan.
class KecamatanModel {
  // Identifikasi unik kecamatan.
  final int id;
  // Nama kecamatan (wajib).
  final String namaKecamatan;
  // String GeoJSON yang berisi polygon batas wilayah (bisa null jika belum ada).
  final String? geojson;

  // Konstruktor untuk membuat objek KecamatanModel.
  // Parameter wajib: id dan namaKecamatan. geojson opsional.
  KecamatanModel({
    required this.id,
    required this.namaKecamatan,
    this.geojson,
  });

  // Pabrik untuk membuat KecamatanModel dari JSON (respons Supabase).
  factory KecamatanModel.fromJson(Map<String, dynamic> json) => KecamatanModel(
        id: json['id'] ?? 0,
        namaKecamatan: json['nama_kecamatan'] ?? '',
        geojson: json['geojson'],
      );

  // Mengonversi objek ke JSON untuk dikirim ke Supabase (misal insert atau update).
  Map<String, dynamic> toJson() => {
        'id': id,
        'nama_kecamatan': namaKecamatan,
        'geojson': geojson,
      };

  // Getter untuk mengurai GeoJSON menjadi daftar ring polygon (list of list of LatLng).
  // Berguna untuk digambar menggunakan flutter_map PolygonLayer.
  List<List<LatLng>> get polygonRings {
    // Jika geojson null atau kosong, kembalikan list kosong.
    if (geojson == null || geojson!.isEmpty) return [];
    try {
      // Decode string JSON menjadi Map.
      final geo = jsonDecode(geojson!) as Map<String, dynamic>;
      // Ambil tipe GeoJSON (Polygon atau MultiPolygon).
      final type = geo['type'] as String?;
      // Ambil koordinat.
      final coords = geo['coordinates'];

      // Jika tipe Polygon dan koordinat adalah List.
      if (type == 'Polygon' && coords is List) {
        // Kembalikan satu ring (polygon pertama) dengan mengonversi setiap titik dari [lng, lat] ke LatLng(lat, lng).
        return (coords).map<List<LatLng>>((ring) {
          return (ring as List).map<LatLng>((pt) {
            return LatLng((pt[1] as num).toDouble(), (pt[0] as num).toDouble());
          }).toList();
        }).toList();
      } 
      // Jika tipe MultiPolygon (beberapa polygon terpisah).
      else if (type == 'MultiPolygon' && coords is List) {
        final result = <List<LatLng>>[];
        for (final poly in coords) {
          for (final ring in poly as List) {
            result.add((ring as List).map<LatLng>((pt) {
              return LatLng((pt[1] as num).toDouble(), (pt[0] as num).toDouble());
            }).toList());
          }
        }
        return result;
      }
    } catch (_) {
      // Jika parsing gagal (misal format tidak valid), kembalikan list kosong.
    }
    return [];
  }

  // Getter untuk mengecek apakah kecamatan memiliki polygon (geojson valid dan tidak kosong).
  bool get hasPolygon => polygonRings.isNotEmpty;

  // Getter untuk menghitung perkiraan titik pusat (centroid) dari ring polygon pertama.
  // Digunakan untuk meletakkan marker atau label di tengah wilayah.
  LatLng? get center {
    final ring = polygonRings.isNotEmpty ? polygonRings.first : null;
    if (ring == null || ring.isEmpty) return null;
    double lat = 0, lng = 0;
    for (final p in ring) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / ring.length, lng / ring.length);
  }

  // Menghitung luas polygon dalam kilometer persegi (km²) menggunakan rumus Shoelace.
  // Proyeksi sederhana: 1 derajat lintang = 111320 meter, 1 derajat bujur dikoreksi dengan cos(lat).
  // Akurasi sekitar ±5% untuk area kurang dari 100 km².
  double getAreaInKm2() {
    final ring = polygonRings.isNotEmpty ? polygonRings.first : null;
    if (ring == null || ring.length < 3) return 0.0;
    
    // Hitung rata-rata lintang untuk faktor koreksi bujur.
    final avgLat = ring.map((p) => p.latitude).reduce((a,b)=>a+b) / ring.length;
    // Faktor konversi bujur (meter per derajat) tergantung lintang.
    final lonFactor = 111320 * cos(avgLat * pi / 180);
    // Faktor konversi lintang tetap (meter per derajat).
    const latFactor = 111320;
    
    // Konversi setiap titik ke koordinat meter (proyeksi planar sederhana).
    final pointsMeter = ring.map((p) => Point(
      p.longitude * lonFactor,
      p.latitude * latFactor,
    )).toList();
    
    double area = 0;
    // Rumus Shoelace.
    for (int i = 0; i < pointsMeter.length; i++) {
      final j = (i + 1) % pointsMeter.length;
      area += pointsMeter[i].x * pointsMeter[j].y;
      area -= pointsMeter[j].x * pointsMeter[i].y;
    }
    area = area.abs() / 2.0;
    // Konversi dari meter persegi ke kilometer persegi.
    return area / 1000000;
  }

  // Membangun string GeoJSON dari daftar titik (LatLng) yang digambar admin.
  // Digunakan saat admin membuat poligon baru melalui editor peta.
  static String buildGeoJson(List<LatLng> points) {
    if (points.length < 3) throw Exception('Minimal 3 titik untuk polygon');
    // Tutup poligon dengan menambahkan titik pertama di akhir.
    final closed = [...points, points.first];
    // Format koordinat: [lng, lat] sesuai standar GeoJSON.
    final coords = closed.map((p) => '[${p.longitude}, ${p.latitude}]').join(', ');
    return '{"type":"Polygon","coordinates":[[$coords]]}';
  }
}