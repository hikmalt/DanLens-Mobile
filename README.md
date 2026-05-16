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
  
  <p>
    <a href="https://github.com/hikmalt/DanLens-Mobile">📱 Mobile GitHub</a> •
    <a href="https://github.com/alifashary15/danlens-web">🌐 Web GitHub</a> •
    <a href="https://danlens-web.onrender.com/">🚀 Web Demo</a> •
    <a href="https://github.com/hikmalt/DanLens-Mobile/releases/download/v1.0.0/app-release.apk">📦 Download APK</a> •
    <a href="https://docs.google.com/document/d/19pKNud7Bx2TBaPxOIJcRvszvQwT15qZU/edit">📄 Laporan Proyek</a>
  </p>
</div>

---

## 📋 Daftar Isi

- [Deskripsi](#-deskripsi)
- [Fitur Utama](#-fitur-utama)
- [Apa yang Bisa Dilakukan Admin dan User?](#-apa-yang-bisa-dilakukan-admin-dan-user)
- [Teknologi](#-teknologi)
- [Struktur Proyek](#-struktur-proyek)
- [Prasyarat & Instalasi](#-prasyarat--instalasi)
- [Cara Menjalankan Aplikasi](#-cara-menjalankan-aplikasi)
- [Setup Database](#-setup-database)
- [Referensi](#-referensi)
- [Tim Pengembang](#-tim-pengembang)
- [Mata Kuliah & Dosen](#-mata-kuliah--dosen)
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

## 👥 Apa yang Bisa Dilakukan Admin dan User?

### 🔐 Semua Pengguna (Login/Non‑login)
- Melihat peta dan titik lokasi
- Mencari tempat (search & filter)
- Membuka detail tempat (foto, deskripsi, kontak, rating)
- Menghitung jarak dari GPS ke suatu tempat
- Mendapatkan saran rute AI
- Membuka navigasi ke Google Maps

### 👤 User (Login)
- Menambahkan tempat baru (sebagai uploader)
- Mengedit / menghapus tempat yang ditambahkan sendiri
- Melihat daftar "Tempat Saya" di profil
- Menambahkan / menghapus favorit
- Melihat riwayat tempat yang pernah dikunjungi
- Import/Export data tempat (format Excel, SQL, JSON, PDF)
- Melihat error log aplikasi

### 👑 Admin (Login dengan role admin)
- Semua fitur user
- **Admin Panel** terintegrasi:
  - Kelola **semua tempat** (edit/hapus milik siapa pun)
  - **Statistik** (jumlah tempat per kategori, rating tertinggi, distribusi)
  - **Import/Export data tempat** (PDF, Excel, SQL) untuk backup/migrasi
- **Manajemen Kecamatan**:
  - Tambah, edit, hapus poligon kecamatan
  - Menggambar poligon langsung di peta (mode gambar)
  - Input manual koordinat atau import GeoJSON
  - Ekspor data kecamatan (JSON, Excel, SQL)
  - Lihat luas setiap kecamatan (dalam km²)
- **Layer polygon** di peta dapat difilter dan diaktifkan/dinonaktifkan

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

```
danlens/
├── assets/
│   ├── fonts/               # Font Poppins
│   ├── images/team/         # Foto tim (webp)
│   └── logo/                # Logo aplikasi & splash
├── lib/
│   ├── config/
│   │   ├── app_routes.dart
│   │   ├── app_theme.dart   # Tema & palet warna
│   │   └── supabase_config.dart
│   ├── models/
│   │   ├── kategori_model.dart
│   │   ├── kecamatan_model.dart
│   │   ├── tempat_model.dart
│   │   ├── user_model.dart
│   │   └── models.dart       # Barrel export
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── favorite_provider.dart
│   │   ├── map_provider.dart
│   │   └── tempat_provider.dart
│   ├── screens/
│   │   ├── add_tempat/       # Form tambah tempat
│   │   ├── admin/            # Panel admin & manajemen kecamatan
│   │   ├── auth/             # Login & register
│   │   ├── data/             # Import/Export
│   │   ├── detail/           # Detail tempat
│   │   ├── favorite/         # Daftar favorit
│   │   ├── home/             # Beranda
│   │   ├── map/              # Peta interaktif
│   │   ├── profile/          # Profil & tempat saya
│   │   ├── recommendation/   # Rekomendasi
│   │   ├── splash/           # Splash screen
│   │   └── main_screen.dart  # Bottom navigation
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── export_service.dart
│   │   ├── fcm_service.dart
│   │   ├── import_service.dart
│   │   ├── location_service.dart
│   │   ├── notification_service.dart
│   │   ├── realtime_service.dart
│   │   ├── route_service.dart
│   │   ├── storage_service.dart
│   │   ├── supabase_service.dart
│   │   └── tempat_service.dart
│   ├── utils/
│   │   ├── cache_manager.dart
│   │   ├── error_logger.dart
│   │   └── haversine.dart
│   ├── widgets/
│   │   ├── ai_route_panel.dart
│   │   ├── animated_route.dart
│   │   ├── bottom_sheet_detail.dart
│   │   ├── carousel_widget.dart
│   │   ├── custom_marker.dart
│   │   ├── error_log_widget.dart
│   │   ├── heatmap_layer.dart
│   │   ├── image_viewer.dart
│   │   ├── offline_banner.dart
│   │   ├── place_card.dart
│   │   └── skeleton_loader.dart
│   ├── app.dart
│   ├── firebase_options.dart
│   └── main.dart
├── android/                  # Konfigurasi Android
├── database_setup.sql        # SQL lengkap untuk setup database
├── pubspec.yaml
└── README.md
```

---

## ⚙️ Prasyarat & Instalasi

1. **Flutter 3.0+** terinstal ([panduan resmi](https://docs.flutter.dev/get-started/install))
2. Akun [Supabase](https://supabase.com) (proyek gratis)
3. Akun [Firebase](https://console.firebase.google.com) (untuk notifikasi push – opsional, tidak menghalangi fitur lain)
4. Emulator atau perangkat Android/iOS

**Langkah menjalankan:**

```bash
git clone https://github.com/hikmalt/DanLens-Mobile.git
cd danlens
flutter pub get
flutter run
```

> **Catatan:** Pastikan file `google-services.json` (dari Firebase) dan file `.env` (jika ada) sudah disiapkan. Untuk penggunaan dasar, Firebase FCM bisa diabaikan (notifikasi lokal tetap berfungsi).

---

## 🚀 Cara Menjalankan Aplikasi

### Instalasi langsung (APK)
1. Unduh APK dari link: [Download DanLens v1.0.0](https://github.com/hikmalt/DanLens-Mobile/releases/download/v1.0.0/app-release.apk)
2. Pindahkan ke perangkat Android, lalu buka file dan instal.
3. Izin lokasi diperlukan untuk fitur GPS.

### Build dari source
#### 1. Persiapan Environment
- Install Flutter SDK dan Android Studio / VS Code.
- Setup emulator atau sambungkan perangkat fisik (USB debugging aktif).

#### 2. Konfigurasi Supabase
- Buat proyek di Supabase.
- Jalankan script `database_setup.sql` pada SQL Editor Supabase.
- Salin `url` dan `anon key` ke `lib/config/supabase_config.dart`.
- Pastikan tabel `kecamatan` memiliki kolom `geojson` (sudah disediakan script).

#### 3. Konfigurasi Firebase (opsional)
- Buat proyek Firebase.
- Unduh `google-services.json` dan letakkan di `android/app/`.
- Untuk iOS, unduh `GoogleService-Info.plist` dan letakkan di `ios/Runner/`.

#### 4. Menjalankan
```bash
flutter clean
flutter pub get
flutter run
```

Aplikasi akan terbuka pada perangkat/emulator. Anda dapat login dengan akun demo:
- **Admin:** `admin@gmail.com` / `123456`
- **User:** `user@gmail.com` / `123456`

---

## 🗄️ Setup Database

File `database_setup.sql` di root proyek berisi:
- Pembuatan tabel `kategori`, `kecamatan`, `tempat`, `users`, `sessions`
- Data awal (5 kategori, 19 kecamatan dengan GeoJSON, 38 tempat, 2 user)
- Relasi foreign key
- Row Level Security (RLS) policy untuk keamanan

**Cara menjalankan:**
1. Buka [Supabase Dashboard](https://app.supabase.com)
2. Pilih proyek Anda → SQL Editor
3. Salin seluruh isi `database_setup.sql`
4. Klik **Run**

Setelah berhasil, database siap digunakan.

---

## 🔗 Referensi

- **Mobile Repository:** [DanLens-Mobile](https://github.com/hikmalt/DanLens-Mobile)
- **Web Repository:** [danlens-web](https://github.com/alifashary15/danlens-web)
- **Web Demo (Live):** [https://danlens-web.onrender.com/](https://danlens-web.onrender.com/)
- **APK Download:** [app-release.apk](https://github.com/hikmalt/DanLens-Mobile/releases/download/v1.0.0/app-release.apk)
- **Laporan Projek:** [Google Docs](https://docs.google.com/document/d/19pKNud7Bx2TBaPxOIJcRvszvQwT15qZU/edit)
- **Sumber Data Poligon Kecamatan:** [Overpass Turbo](https://overpass-turbo.eu/)

---

## 👨‍💻 Tim Pengembang

| Foto | Nama | NIM | Peran |
|------|------|-----|-------|
| <img src="assets/images/team/alif.webp" width="60"> | Alif Faishal Ashary | 2305181052 | Project Lead & Web Developer |
| <img src="assets/images/team/hikmal.webp" width="60"> | Hikmal Akbar | 2305181024 | Mobile Developer & Helper |
| <img src="assets/images/team/ihsan.webp" width="60"> | Mhd. Ihsan Harianto Harahap | 2305181096 | Mobile Developer & Data Researcher |
| <img src="assets/images/team/fadil.webp" width="60"> | Fadil Givari | 2305181044 | Mobile Developer & Data Researcher |
| <img src="assets/images/team/feny.webp" width="60"> | Feny Mawarni | 2305181020 | Database Designer & Documentation |
| <img src="assets/images/team/putri.webp" width="60"> | Putri Yaumi Askira | 2305181016 | Database Designer & Documentation |

**Kontak Tim:**
- 📷 Instagram: lihat dalam aplikasi (halaman Profil Tim)
- 📧 Email: tersedia di aplikasi

---

## 🎓 Mata Kuliah & Dosen

- **Mata Kuliah:** Praktik Sistem Informasi Geografis
- **Kelas:** 6D – Teknologi Rekayasa Perangkat Lunak (TRPL)
- **Jurusan:** Komputer dan Informatika
- **Politeknik Negeri Medan**
- **Dosen Pengampu:** Donny Sanjaya, M.Kom

---

## 📝 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).

---

<div align="center">
  <sub>Dibuat dengan ❤️ oleh Tim DanLens • &copy; 2026</sub>
</div>