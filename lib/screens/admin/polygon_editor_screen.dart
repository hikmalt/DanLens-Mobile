// FILE: lib/screens/admin/polygon_editor_screen.dart
// Halaman untuk admin menggambar polygon kecamatan langsung pada peta.
// Fungsi: Membuat atau mengedit polygon kecamatan dengan menambahkan titik-titik pada peta,
//         mengimpor GeoJSON, atau memasukkan koordinat manual. Polygon disimpan ke kolom 'geojson'
//         pada tabel kecamatan di Supabase.
// Informasi penting: Tidak mengubah struktur tabel (kolom geojson sudah ada).
//         Menampilkan luas sementara selama proses penggambaran.
//         Mendukung tiga mode input: gambar langsung di peta, manual koordinat, dan impor GeoJSON.

// ignore: unused_import - jsonEncode tidak dipakai secara langsung, namun mungkin diperlukan untuk debugging.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_theme.dart';
import '../../models/kecamatan_model.dart';
import '../../services/kecamatan_service.dart';
import '../../utils/error_logger.dart';
import 'dart:math'; // Untuk perhitungan luas polygon (cos, pi).

// Halaman editor polygon.
class PolygonEditorScreen extends StatefulWidget {
  // Jika tidak null, berarti sedang mengedit polygon yang sudah ada.
  final KecamatanModel? existingKecamatan;

  const PolygonEditorScreen({super.key, this.existingKecamatan});

  @override
  State<PolygonEditorScreen> createState() => _PolygonEditorScreenState();
}

class _PolygonEditorScreenState extends State<PolygonEditorScreen> {
  // Controller untuk peta.
  final _mapController = MapController();
  // Controller untuk input nama kecamatan.
  final _namaCtrl = TextEditingController();
  // Controller untuk input manual (koordinat atau GeoJSON).
  final _manualCtrl = TextEditingController();

  // Daftar titik-titik polygon yang sedang digambar.
  List<LatLng> _points = [];
  // Status sedang menyimpan.
  bool _saving = false;
  // Mode gambar (true = tap untuk tambah titik, false = pan peta).
  bool _drawMode = true;
  // Tab aktif: 0 = gambar, 1 = manual, 2 = impor GeoJSON.
  int _inputTab = 0;

  // Koordinat pusat Medan sebagai default.
  static const LatLng _medanCenter = LatLng(3.5896654, 98.6738261);

  @override
  void initState() {
    super.initState();
    // Jika sedang mengedit, muat polygon yang sudah ada.
    if (widget.existingKecamatan != null) {
      _namaCtrl.text = widget.existingKecamatan!.namaKecamatan;
      final rings = widget.existingKecamatan!.polygonRings;
      if (rings.isNotEmpty) {
        _points = List.from(rings.first);
        // Hapus titik terakhir jika sama dengan titik pertama (karena polygon tertutup).
        if (_points.isNotEmpty && _points.first == _points.last) {
          _points.removeLast();
        }
      }
    }
  }

  // Menyimpan polygon ke Supabase.
  Future<void> _save() async {
    // Validasi nama tidak boleh kosong.
    if (_namaCtrl.text.trim().isEmpty) {
      _snack('Nama kecamatan wajib diisi', isError: true);
      return;
    }
    // Validasi minimal 3 titik.
    if (_points.length < 3) {
      _snack('Minimal 3 titik untuk membentuk polygon', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      // Konversi titik-titik ke format GeoJSON.
      final geo = KecamatanModel.buildGeoJson(_points);

      if (widget.existingKecamatan != null) {
        // Update polygon yang sudah ada.
        await KecamatanService.updateGeoJson(
            id: widget.existingKecamatan!.id, geojson: geo);
        _snack('Polygon berhasil diperbarui!', isError: false);
      } else {
        // Simpan polygon baru.
        await KecamatanService.insert(
            namaKecamatan: _namaCtrl.text.trim(), geojson: geo);
        _snack('Kecamatan berhasil disimpan!', isError: false);
      }

      // Tunggu sebentar agar snackbar terbaca, lalu tutup halaman.
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } catch (e, s) {
      ErrorLogger.e('PolygonEditor._save', e, s);
      _snack('Gagal menyimpan: ${e.toString()}', isError: true);
    }
    setState(() => _saving = false);
  }

  // Memproses input manual (koordinat per baris atau GeoJSON).
  void _parseManualInput() {
    final text = _manualCtrl.text.trim();
    if (text.isEmpty) return;

    try {
      // Coba parsing sebagai GeoJSON terlebih dahulu.
      if (text.startsWith('{')) {
        // Buat objek KecamatanModel sementara untuk memanfaatkan parser polygonRings.
        final dummy = KecamatanModel(id: 0, namaKecamatan: '', geojson: text);
        final rings = dummy.polygonRings;
        if (rings.isNotEmpty) {
          setState(() {
            _points = List.from(rings.first);
            // Hapus titik terakhir jika duplikat dengan titik pertama.
            if (_points.isNotEmpty && _points.first == _points.last) {
              _points.removeLast();
            }
          });
          _fitBounds(); // Sesuaikan tampilan peta agar semua titik terlihat.
          _snack('GeoJSON berhasil diimpor (${_points.length} titik)',
              isError: false);
          return;
        }
      }

      // Jika bukan GeoJSON, coba parsing sebagai baris-baris "latitude, longitude".
      final lines = text.split('\n');
      final parsed = <LatLng>[];
      for (final line in lines) {
        final parts = line.trim().split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            parsed.add(LatLng(lat, lng));
          }
        }
      }
      if (parsed.length >= 3) {
        setState(() => _points = parsed);
        _fitBounds();
        _snack('${parsed.length} titik berhasil diparsing', isError: false);
      } else {
        _snack('Format tidak valid. Gunakan "lat,lng" per baris atau GeoJSON',
            isError: true);
      }
    } catch (e) {
      _snack('Gagal parsing: $e', isError: true);
    }
  }

  // Menyesuaikan tampilan peta agar semua titik polygon terlihat.
  void _fitBounds() {
    if (_points.isEmpty) return;
    try {
      final bounds = LatLngBounds.fromPoints(_points);
      _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)));
    } catch (_) {}
  }

  // Menghitung luas sementara polygon dalam km persegi (untuk tampilan di UI).
  double _calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    // Tutup polygon dengan menambahkan titik pertama ke akhir.
    final ring = [...points, points.first];
    // Rata-rata lintang untuk koreksi panjang bujur.
    final avgLat = ring.map((p) => p.latitude).reduce((a, b) => a + b) / ring.length;
    // Faktor konversi derajat ke meter (1 derajat lintang ≈ 111320 m).
    final lonFactor = 111320 * cos(avgLat * pi / 180);
    const latFactor = 111320;
    double area = 0;
    // Rumus shoelace untuk menghitung luas.
    for (int i = 0; i < ring.length - 1; i++) {
      area += ring[i].longitude * lonFactor * ring[i + 1].latitude * latFactor;
      area -= ring[i + 1].longitude * lonFactor * ring[i].latitude * latFactor;
    }
    area = area.abs() / 2.0;
    return area / 1000000; // Konversi dari meter persegi ke km persegi.
  }

  // Menghapus titik terakhir (undo).
  void _undoLast() {
    if (_points.isEmpty) return;
    setState(() => _points.removeLast());
  }

  // Menghapus semua titik.
  void _clearAll() {
    setState(() => _points = []);
  }

  // Menyalin GeoJSON ke clipboard.
  void _copyGeoJson() {
    if (_points.length < 3) {
      _snack('Minimal 3 titik', isError: true);
      return;
    }
    final geo = KecamatanModel.buildGeoJson(_points);
    Clipboard.setData(ClipboardData(text: geo));
    _snack('GeoJSON disalin ke clipboard', isError: false);
  }

  // Menampilkan snackbar pesan.
  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingKecamatan != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Polygon' : 'Tambah Kecamatan'),
        actions: [
          // Tombol salin GeoJSON jika ada minimal 3 titik.
          if (_points.length >= 3)
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Salin GeoJSON',
              onPressed: _copyGeoJson,
            ),
          // Tombol simpan.
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded),
            tooltip: 'Simpan',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector (Gambar, Manual, Import).
          Container(
            color: AppColors.white,
            child: Row(
              children: [
                _TabBtn(label: '✏️ Gambar', index: 0, current: _inputTab,
                    onTap: () => setState(() => _inputTab = 0)),
                _TabBtn(label: '📋 Manual', index: 1, current: _inputTab,
                    onTap: () => setState(() => _inputTab = 1)),
                _TabBtn(label: '📥 Import', index: 2, current: _inputTab,
                    onTap: () => setState(() => _inputTab = 2)),
              ],
            ),
          ),

          // Form nama kecamatan.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _namaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Kecamatan *',
                prefixIcon: Icon(Icons.location_city_rounded,
                    color: AppColors.primary),
                hintText: 'Contoh: Medan Johor',
                isDense: true,
              ),
            ),
          ),

          // Konten sesuai tab yang dipilih.
          if (_inputTab == 0) ...[
            // Kontrol gambar (toggle mode, undo, clear, fit bounds).
            _DrawControls(
              pointCount: _points.length,
              drawMode: _drawMode,
              onToggleDraw: () => setState(() => _drawMode = !_drawMode),
              onUndo: _undoLast,
              onClear: _clearAll,
              onFit: _fitBounds,
            ),
            // Peta untuk menggambar.
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _points.isNotEmpty
                          ? _points.first
                          : _medanCenter,
                      initialZoom: 12,
                      onTap: _drawMode
                          ? (_, latlng) {
                              setState(() => _points.add(latlng));
                            }
                          : null,
                    ),
                    children: [
                      // Layer tile OSM.
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.danlens.app',
                      ),
                      // Polygon sementara (jika sudah ≥3 titik).
                      if (_points.length >= 3)
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: [..._points, _points.first],
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderColor: AppColors.primary,
                              borderStrokeWidth: 2.5,
                              isFilled: true,
                            ),
                          ],
                        ),
                      // Garis polyline sementara (jika ≥2 titik).
                      if (_points.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _points,
                              color: AppColors.primary,
                              strokeWidth: 2,
                              isDotted: true,
                            ),
                          ],
                        ),
                      // Marker setiap titik (dapat dihapus dengan tap).
                      MarkerLayer(
                        markers: _points.asMap().entries.map((e) {
                          final i = e.key;
                          final p = e.value;
                          return Marker(
                            point: p,
                            width: 28,
                            height: 28,
                            child: GestureDetector(
                              onTap: () => setState(() => _points.removeAt(i)),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? AppColors.success
                                      : AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  // Petunjuk mode gambar.
                  if (_drawMode)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _points.isEmpty
                                ? '👆 Tap peta untuk tambah titik polygon'
                                : '${_points.length} titik · Tap titik untuk hapus',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else if (_inputTab == 1) ...[
            // Tab manual koordinat.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Format: latitude, longitude (satu titik per baris)\nContoh:\n3.5789, 98.6712\n3.5812, 98.6893\n3.5734, 98.6801',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _manualCtrl,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        hintText: '3.5789, 98.6712\n3.5812, 98.6893\n...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _parseManualInput,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Parse Koordinat'),
                    ),
                    if (_points.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        color: AppColors.surface,
                        child: Text('✅ ${_points.length} titik siap'),
                      ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Tab impor GeoJSON.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Tempel GeoJSON Polygon di bawah:\n\n{"type":"Polygon","coordinates":[[[lng,lat],[lng,lat],...]]}',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _manualCtrl,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        hintText: '{"type":"Polygon","coordinates":[...]}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _parseManualInput,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Import GeoJSON'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Bottom bar (menampilkan jumlah titik dan luas sementara, serta tombol simpan).
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16,
                MediaQuery.of(context).padding.bottom + 10),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _points.length < 3
                            ? '${_points.length}/3 titik minimum'
                            : '${_points.length} titik siap disimpan ✅',
                        style: TextStyle(
                            color: _points.length >= 3
                                ? AppColors.success
                                : AppColors.textGray),
                      ),
                      // Tampilkan luas sementara jika titik cukup.
                      if (_points.length >= 3)
                        Text(
                          '📐 Luas sementara: ${_calculateArea(_points).toStringAsFixed(2)} km²',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary),
                        ),
                    ],
                  ),
                ),
                // Tombol simpan.
                ElevatedButton.icon(
                  onPressed: (_saving || _points.length < 3) ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(isEdit ? 'Update' : 'Simpan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _manualCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────
// Tombol tab (Gambar, Manual, Import).
class _TabBtn extends StatelessWidget {
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: sel ? AppColors.primary : Colors.transparent,
                    width: 2.5)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  color: sel ? AppColors.primary : AppColors.textGray)),
        ),
      ),
    );
  }
}

// Kontrol untuk mode gambar (toggle, undo, clear, fit).
class _DrawControls extends StatelessWidget {
  final int pointCount;
  final bool drawMode;
  final VoidCallback onToggleDraw;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onFit;

  const _DrawControls({
    required this.pointCount,
    required this.drawMode,
    required this.onToggleDraw,
    required this.onUndo,
    required this.onClear,
    required this.onFit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Tombol toggle mode gambar/pan.
          GestureDetector(
            onTap: onToggleDraw,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: drawMode ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(drawMode ? Icons.edit_rounded : Icons.pan_tool_rounded,
                      size: 14,
                      color: drawMode ? Colors.white : AppColors.textGray),
                  const SizedBox(width: 4),
                  Text(drawMode ? 'Mode Gambar' : 'Mode Pan',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: drawMode ? Colors.white : AppColors.textGray)),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Tombol fit bounds.
          _CtrlBtn(icon: Icons.fit_screen_rounded, onTap: onFit, tip: 'Fit'),
          const SizedBox(width: 4),
          // Tombol undo.
          _CtrlBtn(
              icon: Icons.undo_rounded,
              onTap: pointCount > 0 ? onUndo : null,
              tip: 'Undo'),
          const SizedBox(width: 4),
          // Tombol hapus semua.
          _CtrlBtn(
              icon: Icons.delete_outline_rounded,
              color: AppColors.error,
              onTap: pointCount > 0 ? onClear : null,
              tip: 'Hapus semua'),
        ],
      ),
    ).animate().fade(duration: 300.ms);
  }
}

// Tombol kontrol bulat (fit, undo, clear).
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tip;
  final Color color;

  const _CtrlBtn({
    required this.icon,
    required this.onTap,
    required this.tip,
    this.color = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.35 : 1,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surface),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}