// lib/screens/add_tempat/add_tempat_screen.dart
import 'dart:io';
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

class AddTempatScreen extends StatefulWidget {
  const AddTempatScreen({super.key});
  @override
  State<AddTempatScreen> createState() => _AddTempatScreenState();
}

class _AddTempatScreenState extends State<AddTempatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  final _jalanCtrl = TextEditingController();
  final _kontakCtrl = TextEditingController();

  File? _imageFile;
  bool _isSubmitting = false;
  KategoriModel? _selectedKategori;
  KecamatanModel? _selectedKecamatan;
  LatLng? _pickedLocation;
  bool _showMapPicker = false;
  bool _loadingLocation = false;
  double? _rating;

  final _mapController = MapController();
  static const LatLng _medanCenter = LatLng(3.5896654, 98.6738261);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = context.read<TempatProvider>();
      if (tp.kategori.isEmpty) tp.loadKategori();
      if (tp.kecamatan.isEmpty) tp.loadKecamatan();
    });
    _getCurrentLocation();
  }

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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: source, maxWidth: 1200, maxHeight: 900, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
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
      // Upload image if picked
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

      final result = await SupabaseService.insertTempat(data);
      if (!mounted) return;

      if (result != null) {
        _showSnack('Tempat berhasil ditambahkan! 🎉', isError: false);
        NotificationService.showNewTempatNotification(result.namaTempat); // ← tambahkan baris ini
        await context.read<TempatProvider>().loadAll();
        _resetForm();
      } else {
        _showSnack('Gagal menyimpan data', isError: true);
      }
    } catch (e, stack) {
      ErrorLogger.e('Submit tempat failed', e, stack);
      _showSnack('Error: ${e.toString()}', isError: true);
    }

    setState(() => _isSubmitting = false);
  }

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
              // Image picker
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

              // Nama
              const _SectionLabel('🏷️ Nama Tempat *'),
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(hintText: 'Contoh: Warung Makan Bu Siti'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama tempat wajib diisi' : null,
              ).animate().fade(delay: 50.ms),

              const SizedBox(height: 14),

              // Kategori
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

              // Kecamatan
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

              // Jalan
              const _SectionLabel('🛣️ Nama Jalan'),
              TextFormField(
                controller: _jalanCtrl,
                decoration: const InputDecoration(hintText: 'Contoh: Jl. Jamin Ginting No.12'),
              ).animate().fade(delay: 140.ms),

              const SizedBox(height: 14),

              // Deskripsi
              const _SectionLabel('📝 Deskripsi'),
              TextFormField(
                controller: _detailCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Ceritakan tentang tempat ini...'),
              ).animate().fade(delay: 160.ms),

              const SizedBox(height: 14),

              // Kontak
              const _SectionLabel('📞 Kontak'),
              TextFormField(
                controller: _kontakCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '08XXXXXXXXXX'),
              ).animate().fade(delay: 180.ms),

              const SizedBox(height: 14),

              // Rating
              const _SectionLabel('⭐ Rating (opsional)'),
              _RatingPicker(
                rating: _rating,
                onChanged: (r) => setState(() => _rating = r),
              ).animate().fade(delay: 200.ms),

              const SizedBox(height: 20),

              // Location picker
              const _SectionLabel('📍 Lokasi di Peta *'),
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

              // Mini map picker
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

              // Submit
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
    _namaCtrl.dispose();
    _detailCtrl.dispose();
    _jalanCtrl.dispose();
    _kontakCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }
}

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