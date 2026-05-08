<div align="center">
  <img src="assets/logo/logo.png" alt="DanLens Logo" width="150" />
  <h1>🌿 DanLens</h1>
  <p><strong>Sistem Informasi Geografis (SIG) Kota Medan</strong></p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase&logoColor=white" alt="Supabase" />
    <img src="https://img.shields.io/badge/Firebase-Messaging-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
    <img src="https://img.shields.io/badge/OpenStreetMap-7EBC6F?logo=openstreetmap&logoColor=white" alt="OSM" />
    <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
  </p>
</div>

---

## 📋 Daftar Isi

- [Deskripsi](#-deskripsi)
- [Fitur Utama](#-fitur-utama)
- [Teknologi](#-teknologi)
- [Struktur Proyek](#-struktur-proyek)
- [Dependensi](#-dependensi)
- [Prasyarat & Instalasi](#-prasyarat--instalasi)
- [Setup Database](#-setup-database)
- [Tim Pengembang](#-tim-pengembang)
- [Mata Kuliah](#-mata-kuliah)
- [Dosen Pengampu](#-dosen-pengampu)
- [Lisensi](#-lisensi)

---

## 📖 Deskripsi

**DanLens** adalah aplikasi mobile **Sistem Informasi Geografis (SIG)** berbasis Flutter yang memetakan **ratusan titik lokasi penting di Kota Medan**. Aplikasi ini mencakup tempat **kuliner**, **wisata**, **kesehatan**, **transportasi**, dan **kemasyarakatan** lengkap dengan informasi detail, rating, foto, dan navigasi berbasis lokasi pengguna.

Proyek ini dikembangkan sebagai bagian dari mata kuliah **Praktik Sistem Informasi Geografis** di Politeknik Negeri Medan.

---

## ✨ Fitur Utama

### 🗺️ Peta Interaktif
- Peta digital dengan **OpenStreetMap** (via `flutter_map`)
- **Cluster marker** untuk performa optimal
- **Heatmap** & label kecamatan overlay
- Gaya peta: *standard*, *dark*, *satellite*
- GPS real‑time dengan indikator radius akurasi

### 🔍 Pencarian & Filter
- **Autocomplete** real‑time dengan gambar, nama, jarak, rating
- **Filter multi‑kategori** (Kuliner, Wisata, Kesehatan, dll.)
- Filter lanjutan: **rating**, **jarak maksimal**, **memiliki kontak**, **rating minimal**
- Tombol **"None"** untuk menyembunyikan semua pin

### 📍 Navigasi & Rute
- Animasi **polyline biru** dari posisi pengguna ke tujuan
- Informasi jarak & estimasi waktu
- **AI Route Suggestion** – rekomendasi moda transportasi
- Buka rute langsung di **Google Maps**

### 📸 CRUD Tempat
- **Tambah tempat** lengkap: foto, koordinat, kategori, kontak
- **Edit & hapus** tempat (admin & pemilik)
- Upload gambar ke **Supabase Storage**
- **Validasi duplikasi** saat import

### 👤 Manajemen Pengguna
- **Login / Register** custom (Supabase)
- Role: **Admin** & **Uploader**
- **Admin Panel**: kelola semua tempat, statistik, **Import/Export** (PDF, Excel, SQL)
- **Profil User**: tab **"Tempat Saya"**, riwayat, error log

### ❤️ Favorit & Rekomendasi
- Tambah tempat ke favorit
- Halaman **Rekomendasi**:
  - **Terdekat** (Haversine)
  - **Rating Tertinggi**
  - **Populer per Kategori**

### 🔔 Notifikasi
- Notifikasi lokal saat tempat baru ditambahkan
- **Firebase Cloud Messaging (FCM)** siap untuk push notification

### 📶 Offline & Cache
- Cache data tempat, kategori, kecamatan
- Indikator mode offline

### 🎨 UI/UX Premium
- Splash screen animasi ripple
- Shimmer loading skeleton
- Hero image animation
- Bottom sheet interaktif
- Scroll animation (AOS style)

---

## 🛠️ Teknologi

| Kategori           | Teknologi                                                                 |
|--------------------|---------------------------------------------------------------------------|
| **Framework**      | Flutter 3.0+ (Dart)                                                       |
| **Backend**        | [Supabase](https://supabase.com) (PostgreSQL, Storage, Realtime)          |
| **Push Notification** | Firebase Cloud Messaging                                                 |
| **Peta**           | OpenStreetMap, `flutter_map`, `latlong2`                                  |
| **State Management** | Provider                                                               |
| **Local Storage**  | Shared Preferences, Cache Manager                                         |
| **Export/Import**   | PDF, Excel, SQL                                                           |
| **Lainnya**        | Geolocator, Image Picker, URL Launcher, Shimmer, Flutter Animate, dll.    |

---

## 📁 Struktur Proyek
danlens/
├── assets/
│ ├── fonts/ # Font Poppins
│ ├── images/team/ # Foto tim (webp)
│ └── logo/ # Logo aplikasi & splash
├── lib/
│ ├── config/
│ │ ├── app_routes.dart
│ │ ├── app_theme.dart # Tema & palet warna
│ │ └── supabase_config.dart # Konfigurasi Supabase
│ ├── models/
│ │ ├── kategori_model.dart
│ │ ├── kecamatan_model.dart
│ │ ├── tempat_model.dart
│ │ ├── user_model.dart
│ │ └── models.dart # Barrel export
│ ├── providers/
│ │ ├── auth_provider.dart
│ │ ├── favorite_provider.dart
│ │ ├── map_provider.dart
│ │ └── tempat_provider.dart
│ ├── screens/
│ │ ├── add_tempat/ # Form tambah tempat
│ │ ├── admin/ # Panel admin
│ │ ├── auth/ # Login & register
│ │ ├── data/ # Import/Export
│ │ ├── detail/ # Detail tempat
│ │ ├── favorite/ # Daftar favorit
│ │ ├── home/ # Beranda
│ │ ├── map/ # Peta interaktif
│ │ ├── profile/ # Profil & tempat saya
│ │ ├── recommendation/ # Rekomendasi (terdekat/rating/populer)
│ │ ├── splash/ # Splash screen
│ │ └── main_screen.dart # Bottom navigation
│ ├── services/
│ │ ├── auth_service.dart
│ │ ├── export_service.dart
│ │ ├── fcm_service.dart # Firebase Cloud Messaging
│ │ ├── import_service.dart
│ │ ├── location_service.dart
│ │ ├── notification_service.dart
│ │ ├── realtime_service.dart
│ │ ├── route_service.dart
│ │ ├── storage_service.dart
│ │ ├── supabase_service.dart
│ │ └── tempat_service.dart
│ ├── utils/
│ │ ├── cache_manager.dart
│ │ ├── error_logger.dart
│ │ └── haversine.dart # Formula jarak
│ ├── widgets/
│ │ ├── ai_route_panel.dart
│ │ ├── animated_route.dart # Animasi rute
│ │ ├── bottom_sheet_detail.dart
│ │ ├── carousel_widget.dart
│ │ ├── custom_marker.dart
│ │ ├── error_log_widget.dart
│ │ ├── heatmap_layer.dart
│ │ ├── image_viewer.dart # Zoom gambar fullscreen
│ │ ├── offline_banner.dart
│ │ ├── place_card.dart
│ │ └── skeleton_loader.dart
│ ├── app.dart
│ ├── firebase_options.dart
│ └── main.dart
├── android/ # Konfigurasi Android
├── database_setup.sql # SQL lengkap untuk setup database
├── pubspec.yaml
└── README.md


---

## 📦 Dependensi Utama

Lihat file [`pubspec.yaml`](pubspec.yaml) untuk daftar lengkap. Berikut beberapa dependensi kunci:

- **supabase_flutter** – koneksi ke Supabase
- **provider** – state management
- **flutter_map** + **latlong2** – peta interaktif
- **geolocator** – GPS
- **cached_network_image** – load gambar dari URL
- **image_picker** – ambil foto dari kamera/galeri
- **photo_view** – zoom gambar fullscreen
- **carousel_slider** – slider gambar
- **shimmer** – efek loading skeleton
- **flutter_animate** – animasi ringan
- **url_launcher** – buka link (email, Instagram, Google Maps)
- **pdf**, **excel**, **share_plus**, **file_picker** – export/import
- **firebase_core**, **firebase_messaging** – notifikasi push

---

## ⚙️ Prasyarat & Instalasi

1. **Flutter 3.0+** terinstal
2. Akun [Supabase](https://supabase.com) (proyek gratis)
3. Akun [Firebase](https://console.firebase.google.com) (untuk notifikasi push)
4. Emulator atau perangkat Android/iOS

**Langkah menjalankan:**

```bash
git clone <url-repo>
cd danlens
flutter pub get
flutter run

Catatan: Pastikan file google-services.json (dari Firebase) dan file .env (jika ada) sudah disiapkan.

🗄️ Setup Database
Buka Supabase Dashboard → SQL Editor

Tempelkan seluruh isi file database_setup.sql yang ada di root proyek

Klik Run

File tersebut akan otomatis membuat semua tabel, data awal, relasi, function, dan kebijakan keamanan (RLS).

👨‍💻 Tim Pengembang
Foto	Nama	NIM	Peran
<img src="assets/images/team/alif.webp" width="60">	Alif Faishal Ashary	2305181052	Project Lead & Web Developer
<img src="assets/images/team/hikmal.webp" width="60">	Hikmal Akbar	2305181024	Mobile Developer & Helper
<img src="assets/images/team/ihsan.webp" width="60">	Mhd. Ihsan Harianto H.	2305181096	Mobile Developer & Data Researcher
<img src="assets/images/team/fadil.webp" width="60">	Fadil Givari	2305181044	Mobile Developer & Data Researcher
<img src="assets/images/team/feny.webp" width="60">	Feny Mawarni	2305181020	Database Designer & Documentation
<img src="assets/images/team/putri.webp" width="60">	Putri Yaumi Askira	2305181016	Database Designer & Documentation
Kontak Tim:

📷 Instagram: masing-masing anggota (lihat dalam aplikasi)

📧 Email: tersedia di halaman Profil Tim

🎓 Mata Kuliah
Mata Kuliah: Praktik Sistem Informasi Geografis

Kelas: 6D – Teknologi Rekayasa Perangkat Lunak (TRPL)

Jurusan: Komputer dan Informatika

Politeknik Negeri Medan

👨‍🏫 Dosen Pengampu
Donny Sanjaya, M.Kom

📝 Lisensi

<div align="center"> <sub>Dibuat dengan ❤️ oleh Tim DanLens • &copy; 2026</sub> </div> ```