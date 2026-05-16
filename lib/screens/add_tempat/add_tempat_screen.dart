// FILE: lib/screens/add_tempat/add_tempat_screen.dart
// Halaman untuk menambahkan tempat baru oleh pengguna yang sudah login (uploader atau admin).
// Fungsi: Mengumpulkan data tempat (nama, kategori, kecamatan, alamat, deskripsi, kontak, rating, foto, lokasi).
// Data disimpan ke Supabase melalui SupabaseService, dan gambar diunggah ke Storage.
// Informasi penting: Hanya pengguna yang sudah login yang dapat mengakses halaman ini.
// Lokasi dapat diambil dari GPS atau dipilih langsung pada peta mini.

import 'dart:io'; // Untuk mengakses file gambar yang dipilih.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tempat_provider.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_logger.dart';
import '../../services/notification_service.dart';

// Halaman form tambah tempat (stateful karena ada form dan preview peta).
class AddTempatScreen extends StatefulWidget {
  const AddTempatScreen({super.key});

  @override
  State<AddTempatScreen> createState() => _AddTempatScreenState();
}

class _AddTempatScreenState extends State<AddTempatScreen> {
  // Key untuk validasi form.
  final _formKey = GlobalKey<FormState>();
  // Controller untuk input teks.
  final _namaCtrl = TextEditingController();     // Nama tempat.
  final _detailCtrl = TextEditingController();   // Deskripsi.
  final _jalanCtrl = TextEditingController();    // Nama jalan.
  final _kontakCtrl = TextEditingController();   // Nomor kontak.

  // Data yang akan dikirim.
  File? _imageFile;                      // File gambar yang dipilih.
  bool _isSubmitting = false;            // Status sedang menyimpan.
  KategoriModel? _selectedKategori;      // Kategori yang dipilih.
  KecamatanModel? _selectedKecamatan;    // Kecamatan yang dipilih.
  LatLng? _pickedLocation;               // Koordinat lokasi (dari GPS atau peta).
  bool _showMapPicker = false;           // Apakah peta mini ditampilkan.
  bool _loadingLocation = false;         // Status mengambil lokasi GPS.
  double? _rating;                       // Rating bintang (1-5).

  // Controller untuk peta mini.
  final _mapController = MapController();
  // Koordinat pusat Medan.
  static const LatLng _medanCenter = LatLng(3.5896654, 98.6738261);

  @override
  void initState() {
    super.initState();
    // Setelah frame pertama, muat data kategori dan kecamatan jika belum ada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = context.read<TempatProvider>();
      if (tp.kategori.isEmpty) tp.loadKategori();
      if (tp.kecamatan.isEmpty) tp.loadKecamatan();
    });
    // Ambil lokasi saat ini sebagai default.
    _getCurrentLocation();
  }

  // Mengambil lokasi GPS pengguna.
  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _pickedLocation = LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
    } else {
      setState(() => _loadingLocation = false);
    }
  }

  // Membuka galeri/kamera untuk memilih gambar.
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: source, maxWidth: 1200, maxHeight: 900, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  // Mengirim data tempat ke Supabase.
  Future<void> _submit() async {
    // Validasi form.
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategori == null) {
      _showSnack('Pilih kategori tempat', isError: true);
      return;
    }
    if (_pickedLocation == null) {
      _showSnack('Pilih lokasi pada peta', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Unggah gambar jika ada.
      String? mediaFileName;
      if (_imageFile != null) {
        _showSnack('Mengupload gambar...');
        mediaFileName = await StorageService.uploadTempatImage(_imageFile!);
        if (mediaFileName == null) {
          _showSnack('Gagal mengupload gambar', isError: true);
          setState(() => _isSubmitting = false);
          return;
        }
      }

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      // Siapkan data untuk disimpan.
      final data = {
        'nama_tempat': _namaCtrl.text.trim(),
        'detail_tempat': _detailCtrl.text.trim().isEmpty
            ? null
            : _detailCtrl.text.trim(),
        'jalan': _jalanCtrl.text.trim().isEmpty ? null : _jalanCtrl.text.trim(),
        'kecamatan_id': _selectedKecamatan?.id,
        'kategori_id': _selectedKategori!.id,
        'latitude': _pickedLocation!.latitude,
        'longitude': _pickedLocation!.longitude,
        'review_rating': _rating,
        'kontak': _kontakCtrl.text.trim().isEmpty ? null : _kontakCtrl.text.trim(),
        'media': mediaFileName,
        'user_id': auth.user?.id,
      };

      // Simpan ke Supabase.
      final result = await SupabaseService.insertTempat(data);
      if (!mounted) return;

      if (result != null) {
        _showSnack('Tempat berhasil ditambahkan!', isError: false);
        // Kirim notifikasi bahwa tempat baru ditambahkan (untuk pengguna lain).
        NotificationService.showNewTempatNotification(result.namaTempat);
        // Refresh data tempat di provider.
        await context.read<TempatProvider>().loadAll();
        _resetForm(); // Reset form setelah sukses.
      } else {
        _showSnack('Gagal menyimpan data', isError: true);
      }
    } catch (e, stack) {
      ErrorLogger.e('Submit tempat failed', e, stack);
      _showSnack('Error: ${e.toString()}', isError: true);
    }

    setState(() => _isSubmitting = false);
  }

  // Reset semua field form setelah berhasil submit.
  void _resetForm() {
    _namaCtrl.clear();
    _detailCtrl.clear();
    _jalanCtrl.clear();
    _kontakCtrl.clear();
    setState(() {
      _imageFile = null;
      _selectedKategori = null;
      _selectedKecamatan = null;
      _pickedLocation = null;
      _rating = null;
    });
  }

  // Menampilkan snackbar pesan.
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tempat = context.watch<TempatProvider>();

    // Jika belum login, tampilkan pesan akses ditolak.
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tambah Tempat')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 64, color: AppColors.textGray),
              const SizedBox(height: 16),
              const Text('Login diperlukan', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              const Text('Masuk untuk menambahkan tempat',
                  style: AppTextStyles.small),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Masuk Sekarang'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Tempat Baru')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian pemilihan foto (dapat diklik).
              const _SectionLabel('📷 Foto Tempat'),
              GestureDetector(
                onTap: () => _showImageSourceSheet(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 180,
                  decoration: BoxDecoration(
                    color: _imageFile != null ? null : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _imageFile != null
                            ? AppColors.primary
                            : AppColors.surface,
                        width: 2),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.primary, size: 40),
                            SizedBox(height: 8),
                            Text('Tap untuk tambah foto',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textGray,
                                    fontSize: 13)),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => setState(() => _imageFile = null),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                ),
              ).animate().fade(duration: 400.ms),

              const SizedBox(height: 20),

              // Nama tempat (wajib).
              const _SectionLabel('🏷️ Nama Tempat *'),
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(hintText: 'Contoh: Warung Makan Bu Siti'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama tempat wajib diisi' : null,
              ).animate().fade(delay: 50.ms),

              const SizedBox(height: 14),

              // Kategori (wajib).
              const _SectionLabel('📂 Kategori *'),
              DropdownButtonFormField<KategoriModel>(
                initialValue: _selectedKategori,
                decoration: const InputDecoration(hintText: 'Pilih kategori'),
                items: tempat.kategori
                    .map((k) => DropdownMenuItem(
                          value: k,
                          child: Text('${k.icon} ${k.namaKategori}',
                              style: const TextStyle(fontFamily: 'Poppins')),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedKategori = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ).animate().fade(delay: 100.ms),

              const SizedBox(height: 14),

              // Kecamatan (opsional).
              const _SectionLabel('🏘️ Kecamatan'),
              DropdownButtonFormField<KecamatanModel>(
                initialValue: _selectedKecamatan,
                decoration: const InputDecoration(hintText: 'Pilih kecamatan'),
                items: tempat.kecamatan
                    .map((k) => DropdownMenuItem(
                          value: k,
                          child: Text(k.namaKecamatan,
                              style: const TextStyle(fontFamily: 'Poppins')),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedKecamatan = v),
              ).animate().fade(delay: 120.ms),

              const SizedBox(height: 14),

              // Nama jalan (opsional).
              const _SectionLabel('🛣️ Nama Jalan'),
              TextFormField(
                controller: _jalanCtrl,
                decoration: const InputDecoration(hintText: 'Contoh: Jl. Jamin Ginting No.12'),
              ).animate().fade(delay: 140.ms),

              const SizedBox(height: 14),

              // Deskripsi (opsional).
              const _SectionLabel('📝 Deskripsi'),
              TextFormField(
                controller: _detailCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Ceritakan tentang tempat ini...'),
              ).animate().fade(delay: 160.ms),

              const SizedBox(height: 14),

              // Kontak (opsional).
              const _SectionLabel('📞 Kontak'),
              TextFormField(
                controller: _kontakCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '08XXXXXXXXXX'),
              ).animate().fade(delay: 180.ms),

              const SizedBox(height: 14),

              // Rating (opsional, berupa 5 bintang).
              const _SectionLabel('⭐ Rating (opsional)'),
              _RatingPicker(
                rating: _rating,
                onChanged: (r) => setState(() => _rating = r),
              ).animate().fade(delay: 200.ms),

              const SizedBox(height: 20),

              // Pemilihan lokasi di peta.
              const _SectionLabel('📍 Lokasi di Peta *'),
              // Menampilkan koordinat jika sudah dipilih.
              if (_pickedLocation != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Lat: ${_pickedLocation!.latitude.toStringAsFixed(6)}, '
                          'Lng: ${_pickedLocation!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ),

              // Dua tombol: Lokasi Saya dan Pilih di Peta.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: _loadingLocation
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location_rounded, size: 16),
                      label: const Text('Lokasi Saya'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _showMapPicker = !_showMapPicker),
                      icon: const Icon(Icons.pin_drop_rounded, size: 16),
                      label: const Text('Pilih di Peta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

              // Peta mini (opsional, muncul jika tombol Pilih di Peta ditekan).
              if (_showMapPicker) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 240,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _pickedLocation ?? _medanCenter,
                            initialZoom: 14,
                            onTap: (_, latlng) {
                              setState(() => _pickedLocation = latlng);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.danlens.app',
                            ),
                            // Marker lokasi yang dipilih.
                            if (_pickedLocation != null)
                              MarkerLayer(markers: [
                                Marker(
                                  point: _pickedLocation!,
                                  width: 40,
                                  height: 48,
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on_rounded,
                                          color: AppColors.error, size: 36),
                                    ],
                                  ),
                                ),
                              ]),
                          ],
                        ),
                        // Petunjuk di tengah peta.
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 32),
                            child: Text('Tap peta untuk pilih lokasi',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Colors.black54,
                                    backgroundColor: Colors.white70)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Tombol simpan.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSubmitting ? 'Menyimpan...' : 'Simpan Tempat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ).animate().fade(delay: 300.ms),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // Menampilkan bottom sheet untuk memilih sumber gambar (kamera / galeri).
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Handle (garis tipis).
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Kamera', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Galeri', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Bersihkan controller saat widget dihancurkan.
    _namaCtrl.dispose();
    _detailCtrl.dispose();
    _jalanCtrl.dispose();
    _kontakCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }
}

// Label bagian formulir (teks tebal).
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textDark)),
    );
  }
}

// Pemilih rating bintang (1-5).
class _RatingPicker extends StatelessWidget {
  final double? rating;
  final Function(double) onChanged;
  const _RatingPicker({this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () => onChanged(star.toDouble()),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              star <= (rating ?? 0) ? Icons.star_rounded : Icons.star_border_rounded,
              color: Colors.amber,
              size: 32,
            ),
          ),
        );
      }),
    );
  }
}