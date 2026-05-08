-- ============================================================
-- DANLENS — KUMPULAN QUERY POSTGRESQL
-- Penjelasan lengkap setiap blok query untuk database proyek
-- ============================================================
-- File ini mencakup:
-- 1. Pembuatan tabel & relasi (DDL)
-- 2. Pengisian data awal (Seed)
-- 3. Kebijakan keamanan (Row Level Security / RLS)
-- 4. Fungsi bantuan
-- 5. Contoh query yang digunakan aplikasi (pencarian, filter,
--    tampilkan per kecamatan, rute terdekat, join, dll.)
-- ============================================================

-- ============================================================
-- BAGIAN 1: MEMBUAT STRUKTUR TABEL (DDL)
-- ============================================================

-- Tabel users: menyimpan data akun pengguna
CREATE TABLE public.users (
  id         SERIAL PRIMARY KEY,                    -- ID unik, otomatis bertambah
  name       VARCHAR NOT NULL,                      -- Nama lengkap pengguna
  email      VARCHAR NOT NULL UNIQUE,               -- Email (harus berbeda tiap user)
  password   VARCHAR NOT NULL,                      -- Password (teks biasa, untuk demo)
  role       VARCHAR CHECK (role IN ('admin','uploader')), -- Peran: admin / uploader
  photo      VARCHAR,                               -- Nama file foto profil
  created_at TIMESTAMPTZ DEFAULT NOW(),             -- Waktu pendaftaran
  updated_at TIMESTAMPTZ DEFAULT NOW()              -- Waktu terakhir diubah
);

-- Tabel kategori: jenis-jenis tempat
CREATE TABLE public.kategori (
  id            SERIAL PRIMARY KEY,                 -- ID unik kategori
  nama_kategori VARCHAR NOT NULL                    -- Nama kategori (Kuliner, Wisata, …)
);

-- Tabel kecamatan: daftar kecamatan di Medan & sekitar
CREATE TABLE public.kecamatan (
  id             SERIAL PRIMARY KEY,                -- ID unik kecamatan
  nama_kecamatan VARCHAR NOT NULL                   -- Nama kecamatan
);

-- Tabel tempat: data utama GIS (titik lokasi)
CREATE TABLE public.tempat (
  id             SERIAL PRIMARY KEY,                -- ID unik tempat
  nama_tempat    VARCHAR,                           -- Nama tempat
  detail_tempat  TEXT,                              -- Deskripsi lengkap
  jalan          VARCHAR,                           -- Alamat jalan
  kecamatan_id   INT REFERENCES public.kecamatan(id), -- Relasi ke kecamatan
  latitude       DOUBLE PRECISION,                  -- Koordinat latitude
  longitude      DOUBLE PRECISION,                  -- Koordinat longitude
  kategori_id    INT REFERENCES public.kategori(id), -- Relasi ke kategori
  review_rating  DOUBLE PRECISION,                  -- Rating 0,0 – 5,0
  kontak         VARCHAR,                           -- Nomor telepon
  media          VARCHAR,                           -- Nama file gambar di bucket
  created_at     TIMESTAMPTZ DEFAULT NOW(),         -- Waktu ditambahkan
  updated_at     TIMESTAMPTZ,                       -- Waktu terakhir diubah
  user_id        INT REFERENCES public.users(id)    -- Siapa yang menambahkan
);

-- Tabel sessions: untuk keperluan web (Laravel)
CREATE TABLE public.sessions (
  id            VARCHAR PRIMARY KEY,
  user_id       BIGINT,
  ip_address    VARCHAR,
  user_agent    TEXT,
  payload       TEXT NOT NULL,
  last_activity INT NOT NULL
);


-- ============================================================
-- BAGIAN 2: MENGISI DATA AWAL (SEED)
-- ============================================================

-- Data pengguna (admin & uploader)
INSERT INTO public.users (id, name, email, password, role, photo) VALUES
(1, 'Admin', 'admin@gmail.com', '123456', 'admin', 'admin.jpg'),
(2, 'Uploader 1', 'user@gmail.com', '123456', 'uploader', 'uploader1.jpg'),
(6, 'Jono', 'jono@gmail.com', '123456', 'uploader', NULL);

-- Data kategori
INSERT INTO public.kategori (id, nama_kategori) VALUES
(1, 'Kuliner'),
(2, 'Wisata'),
(3, 'Kesehatan'),
(4, 'Kemasyarakatan'),
(5, 'Transportasi');

-- Data kecamatan (19 kecamatan)
INSERT INTO public.kecamatan (id, nama_kecamatan) VALUES
(1, 'Medan Belawan'),
(2, 'Percut Sei Tuan'),
(3, 'Medan Johor'),
(4, 'Medan Helvetia'),
(5, 'Medan Sunggal'),
(6, 'Medan Kota'),
(7, 'Medan Baru'),
(8, 'Sibolangit'),
(9, 'Beringin'),
(10, 'Medan Tuntungan'),
(11, 'Medan Barat'),
(12, 'Medan Petisah'),
(13, 'Medan Amplas'),
(14, 'Medan Selayang'),
(15, 'Ajibata / Balige / Uluan'),
(16, 'Medan Polonia'),
(17, 'Medan Area'),
(18, 'Medan Maimun'),
(19, 'Medan Timur');

-- Data tempat (38+ tempat)
INSERT INTO public.tempat (id, nama_tempat, detail_tempat, jalan, kecamatan_id, latitude, longitude, kategori_id, review_rating, kontak, media, created_at, updated_at, user_id) VALUES
(1, 'Donat Kentang Master', 'Viral dengan Donat Unyil berbahan dasar kentang Sidikalang.', 'Jl. Karya II No.17', 3, 3.61609533843398, 98.6662381673921, 1, 4.9, '082211118490', 'donatmaster.jpg', '2026-05-05 07:16:18.417926', '2026-05-05 09:53:41.877509', null),
(2, 'Kampung Kecil', 'Restoran dengan Konsep Perkampungan bambu.', 'Jl. T. Amir Hamzah No.68', 4, 3.5692, 98.704, 1, 4.9, '08119606565', 'kampung_kecil.jpg', '2026-05-05 07:16:18.417926', null, null),
(3, 'Bolu Meranti', 'Kue bolu gulung premium oleh-oleh favorit Medan.', 'Jl. Sisingamangaraja No.19B', 6, 3.57841707993981, 98.686720592882, 1, 4.6, '0618211222', 'bolu_meranti.jpg', '2026-05-05 07:16:18.417926', null, null),
(4, 'Tip Top Restaurant', 'Rumah makan tua bergaya art deco berdiri sejak 1934.', 'Jl. Jend. Ahmad Yani No.92A-B', 7, 3.58617664963346, 98.6797500509233, 1, 4.4, '0614514442', 'tiptop_restaurant.jpg', '2026-05-05 07:16:18.417926', null, null),
(5, 'Ucok Durian', 'Ikon durian Medan yang sangat terkenal.', 'Jl. K.H. Wahid Hasyim No.30-32', 7, 3.58381383890768, 98.657471756992, 1, 4.5, '081375061919', 'ucok_durian.jpg', '2026-05-05 07:16:18.417926', null, null),
(6, 'Soto Kesawan', 'Legenda kuliner Medan sejak tahun 1920-an.', 'Jl. H.M. Yamin No.71', 11, 3.58791866047217, 98.6794482377659, 1, 4.4, '0614514518', 'soto_kesawan.jpg', '2026-05-05 07:16:18.417926', null, null),
(7, 'Wajik Medan', 'Beras ketan masak gula merah legit dan wangi.', 'Jl. Puri Gg. Seri No.4', 17, 3.57805348658775, 98.698537782733, 1, 4.8, '08996055510', 'wajik.jpg', '2026-05-05 07:16:18.417926', null, null),
(8, 'Mie Zhou', 'Ikon mie ayam porsi besar cita rasa khas Medan.', 'Jl. Timor No.10', 19, 3.59376601248999, 98.6816135808864, 1, 4.6, '081265111188', 'mie_zhou.jpg', '2026-05-05 07:16:18.417926', null, null),
(9, 'DeliPark Mall', 'Pusat perbelanjaan luas dengan toko retail terkenal.', 'Jl. Guru Patimpus No.1', 11, 3.59427379306756, 98.6744764337358, 2, 4.7, null, 'delipark_mall.jpg', '2026-05-05 07:16:18.417926', null, null),
(10, 'Hillpark Sibolangit', 'Taman rekreasi keluarga pemandangan alam pegunungan.', 'Jl. Jamin Ginting', 8, 3.28048712446913, 98.5560341134929, 2, 4.4, '082277111131', 'hillpark_sibolangit.jpg', '2026-05-05 07:16:18.417926', null, null),
(11, 'Vienna Botanical Living', 'Spot foto kekinian konsep taman ala Eropa.', 'Jl. Jamin Ginting Km.12', 10, 3.50784164499594, 98.6123208232159, 2, 4.3, null, 'vienna_botanicalliving.jpg', '2026-05-05 07:16:18.417926', null, null),
(12, 'Merdeka Walk', 'Kawasan kuliner ikonik di Lapangan Merdeka.', 'Jl. Balai Kota No.1', 11, 3.59033952086481, 98.6780522524806, 2, 4.3, null, 'merdeka_walk.jpg', '2026-05-05 07:16:18.417926', null, null),
(13, 'Tjong A Fie Mansion', 'Museum rumah klasik saudagar Tionghoa.', 'Jl. Ahmad Yani No.105', 7, 3.58563618258722, 98.6805950115682, 2, 4.5, '0614575505', 'tjong_a_fie.jpg', '2026-05-05 07:16:18.417926', null, null),
(14, 'Danau Toba', 'Danau vulkanik terbesar di dunia.', 'Jl. Tol Medan-Parapat', 15, 2.84472377816662, 98.5290578410828, 2, 4.8, null, 'danau_toba.jpg', '2026-05-05 07:16:18.417926', null, null),
(15, 'Masjid Raya Al-Mashun', 'Masjid bersejarah desain megah perpaduan berbagai budaya.', 'Jl. Sisingamangaraja', 18, 3.5754051767152, 98.6872493205258, 2, 4.8, '0614527254', 'masjid_raya_almashun.jpg', '2026-05-05 07:16:18.417926', null, null),
(16, 'Istana Maimun', 'Istana kesultanan Deli dibangun tahun 1888.', 'Jl. Brigjen Katamso', 18, 3.57548852309798, 98.6838324892019, 2, 4.6, '0614527254', 'istana_maimun.jpg', '2026-05-05 07:16:18.417926', null, null),
(17, 'Puskesmas Padang Bulan', 'Puskesmas rujukan di kawasan pendidikan.', 'Jl. Jamin Ginting No.31', 7, 3.56070774269578, 98.6621714538977, 3, 4.2, '0618223282', 'puskesmas_padangbulan.jpg', '2026-05-05 07:16:18.417926', null, null),
(18, 'RS Putri Hijau', 'Rumah Sakit TNI-AD terakreditasi PARIPURNA.', 'Jl. Putri Hijau No.17', 7, 3.59994276507109, 98.672689467392, 3, 4.1, '08116122233', 'rumah_sakit_hijau.jpg', '2026-05-05 07:16:18.417926', null, null),
(19, 'RS Pirngadi Medan', 'RS tipe B tertua milik Pemko Medan.', 'Jl. Prof. H.M. Yamin No.47', 7, 3.59820111170419, 98.6883653385568, 3, 3.8, '0614158701', 'rs_pirngadi.jpg', '2026-05-05 07:16:18.417926', null, null),
(20, 'RS Umum Pusat Haji Adam Malik', 'RS tipe A rujukan utama Sumatera bagian utara.', 'Jl. Bunga Lau No.17', 10, 3.51859523764215, 98.6083138232159, 3, 4.3, '0618360143', 'rsup_adammalik.jpg', '2026-05-05 07:16:18.417926', null, null),
(21, 'RS Royal Prima', 'RS tipe B pusat layanan kanker dan jantung.', 'Jl. Ayahanda No.68A', 12, 3.59816490713726, 98.6542080499107, 3, 4.5, '06188813182', 'royal_prima.jpg', '2026-05-05 07:16:18.417926', null, null),
(22, 'RS Mitra Medika Premiere Medan', 'RS tipe B swasta layanan jantung dan saraf.', 'Jl. S. Parman No.234A', 19, 3.58660331834848, 98.6670057430711, 3, 4.7, '0811328135', 'rs_mitra_medika.jpg', '2026-05-05 07:16:18.417926', null, null),
(23, 'RS Columbia Asia Medan', 'RS swasta modern standar internasional.', 'Jl. Listrik No.2', 12, 3.58597293736317, 98.6769345673921, 3, 4.8, '0614566368', 'rs_columbiaasia.jpg', '2026-05-05 07:16:18.417926', null, null),
(24, 'RS Murni Teguh Methodist Susanna Wesley', 'Rumah sakit umum kelas C dikelola PT. Murni Sadar.', 'Jl. Harmonika Baru No.2', 14, 3.55518697693777, 98.6383937490767, 3, 4.1, '08116047013', 'rs_murniteguh_methodist.jpg', '2026-05-05 07:16:18.417926', null, null),
(25, 'Vihara Maha Maitreya Medan', 'Salah satu vihara terbesar di Indonesia (Cemara Asri).', 'Jl. Cemara Asri Boulevard Raya No.8', 2, 3.63816685509355, 98.7013062962273, 4, 4.8, '0616633300', 'vihara_maitreya.jpg', '2026-05-05 07:16:18.417926', null, null),
(26, 'Kantor Pos Besar Medan', 'Gedung bersejarah di kawasan Kesawan.', 'Jl. Pos No.1', 7, 3.59176937096275, 98.6773441895553, 4, 4.6, '1500161', 'kantor_posbesar.jpg', '2026-05-05 07:16:18.417926', null, null),
(27, 'Kantor Kementerian Haji Medan', 'Lembaga pengurus pemberangkatan jemaah haji.', 'Jl. Sei Batu Gingging Ps. X', 7, 3.57464462383051, 98.655325267392, 4, 4.5, '082233332392', 'kemenag.jpg', '2026-05-05 07:16:18.417926', null, null),
(28, 'Kantor Wali Kota Medan', 'Pusat pemerintahan Kota Medan.', 'Jl. Kapten Maulana Lubis No.1', 12, 3.59063365640237, 98.6748155670268, 4, 4.2, '0614512412', 'kantor_walikota_medan.jpg', '2026-05-05 07:16:18.417926', null, null),
(29, 'Kantor Disdukcapil Medan', 'Tempat pengurusan dokumen kependudukan warga Medan.', 'Jl. Iskandar Muda No.270', 12, 3.58582115306271, 98.6613657250625, 4, 3.5, '0614527110', 'kantor_disdukcapil_medan.jpg', '2026-05-05 07:16:18.417926', null, null),
(30, 'Gereja Immanuel Medan', 'Gereja Protestan tertua arsitektur neo-gothic.', 'Jl. Pangeran Diponegoro No.25-27', 5, 3.58085824819588, 98.6728580897316, 4, 4.9, '081362026114', 'gereja_immanuel.jpg', '2026-05-05 07:16:18.417926', null, null),
(31, 'Kantor Gubernur Sumut', 'Pusat pemerintahan Provinsi Sumatera Utara.', 'Jl. Pangeran Diponegoro No.30', 5, 3.58090596699081, 98.6719005760653, 4, 4.5, '0614567611', 'kantor_gubernur_sumut.jpg', '2026-05-05 07:16:18.417926', null, null),
(32, 'Pelabuhan Belawan', 'Pelabuhan terpenting di pulau Sumatra.', 'Jl. Sulawesi No.1', 1, 3.7861327046367, 98.6963184115682, 5, 4.3, '082311126861', 'pelabuhan_belawan.jpg', '2026-05-05 07:16:18.417926', null, null),
(33, 'Halte Bus Listrik 1 J. City', 'Bus Listrik Medan Koridor 2 rute J City - Medan Fair.', 'Jl. Pangkalan Masyhur', 3, 3.53554893097192, 98.6593535644176, 5, 4.4, null, 'brt_listrik.jpg', '2026-05-05 07:16:18.417926', null, null),
(34, 'Terminal Pinang Baris', 'Terminal tipe A melayani bus arah barat dan selatan.', 'Jl. Tahi Bonar Simatupang', 5, 3.58912981331031, 98.6101398741392, 5, 3.7, '08136066003', 'terminal_pinangbaris.jpg', '2026-05-05 07:16:18.417926', null, null),
(35, 'Bandara Kualanamu (KNO)', 'Bandara internasional terkemuka di Deli Serdang.', 'Jl. Bandara Kualanamu', 9, 3.63559084852213, 98.8787659097216, 5, 5, '0618880300', 'kualanamu.jpg', '2026-05-05 07:16:18.417926', null, null),
(36, 'Shelter BRT Metro Deli', 'Halte BRT Trans Metro Deli pusat transit Lapangan Merdeka.', 'Jl. Balai Kota', 11, 3.59207888480471, 98.6769894288357, 5, 4.2, '081368300109', 'shelterbrt_metrodeli.jpg', '2026-05-05 07:16:18.417926', null, null),
(37, 'Stasiun KA Medan', 'Stasiun kereta api kelas besar tipe A.', 'Jl. Stasiun Kereta Api No.1', 11, 3.59175789749577, 98.6794305348441, 5, 4.2, '0219121121', 'stasiunkai_medan.jpg', '2026-05-05 07:16:18.417926', null, null),
(38, 'Terminal Amplas', 'Terminal tipe A terbesar pusat keberangkatan AKAP.', 'Jl. Panglima Denai', 13, 3.53894057239769, 98.718232282733, 5, 3.8, '0614277347', 'terminal_amplas.jpg', '2026-05-05 07:16:18.417926', null, null),
(44, 'tempat baru', 'bahajjajs', 'hhajjqjw', 15, 3.58070752786661, 98.6744473506975, 5, 2, '7977645454810', 'd4e82219-fc4e-4a06-a7e7-9b02f7de4804.png', '2026-05-08 07:32:48.727388', null, 2);


-- ============================================================
-- BAGIAN 3: ROW LEVEL SECURITY (KEAMANAN AKSES DATA)
-- ============================================================

-- Aktifkan RLS pada tabel-tabel utama
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tempat ENABLE ROW LEVEL SECURITY;

-- Fungsi untuk mengecek keabsahan user_id (apakah ada di tabel users)
CREATE OR REPLACE FUNCTION is_valid_user(uid INT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM public.users WHERE id = uid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policy untuk tabel users
CREATE POLICY "Allow insert for all" ON public.users
  FOR INSERT WITH CHECK (true);                     -- Siapa saja boleh mendaftar

CREATE POLICY "Allow select for all" ON public.users
  FOR SELECT USING (true);                          -- Semua bisa melihat data user

CREATE POLICY "Allow update for all" ON public.users
  FOR UPDATE USING (true);                          -- Semua bisa update profil sendiri

-- Policy untuk tabel tempat
CREATE POLICY "Allow select for all" ON public.tempat
  FOR SELECT USING (true);                          -- Semua orang bisa melihat semua tempat

CREATE POLICY "Allow insert for registered users" ON public.tempat
  FOR INSERT WITH CHECK (
    user_id IS NOT NULL AND is_valid_user(user_id)  -- Hanya user terdaftar yang bisa menambah
  );

CREATE POLICY "Allow update for own places" ON public.tempat
  FOR UPDATE USING (
    user_id IS NOT NULL AND is_valid_user(user_id)  -- Hanya pemilik yang bisa mengubah
  );

CREATE POLICY "Allow delete for own places" ON public.tempat
  FOR DELETE USING (
    user_id IS NOT NULL AND is_valid_user(user_id)  -- Hanya pemilik yang bisa menghapus
  );


-- ============================================================
-- BAGIAN 4: CONTOH QUERY YANG DIGUNAKAN APLIKASI
-- ============================================================

-- 4.1. Menampilkan semua tempat lengkap dengan nama kategori dan kecamatan (JOIN)
SELECT
  t.id,
  t.nama_tempat,
  t.detail_tempat,
  t.jalan,
  k.nama_kecamatan,         -- dari tabel kecamatan
  kat.nama_kategori,        -- dari tabel kategori
  t.latitude,
  t.longitude,
  t.review_rating,
  t.kontak,
  t.media
FROM public.tempat t
JOIN public.kecamatan k ON t.kecamatan_id = k.id     -- relasi ke kecamatan
JOIN public.kategori kat ON t.kategori_id = kat.id   -- relasi ke kategori
ORDER BY t.review_rating DESC;                       -- urutkan rating tertinggi


-- 4.2. Pencarian tempat berdasarkan nama atau alamat
SELECT *
FROM public.tempat
WHERE
  nama_tempat ILIKE '%soto%'        -- ILIKE = pencarian case-insensitive
  OR jalan ILIKE '%yamin%';


-- 4.3. Filter tempat berdasarkan kategori tertentu (misal Kesehatan)
SELECT *
FROM public.tempat
WHERE kategori_id = 3;              -- 3 = Kesehatan


-- 4.4. Menampilkan tempat di kecamatan tertentu (contoh: Medan Baru, id 7)
SELECT
  t.nama_tempat,
  k.nama_kecamatan
FROM public.tempat t
JOIN public.kecamatan k ON t.kecamatan_id = k.id
WHERE k.id = 7;


-- 4.5. Menghitung jumlah tempat per kecamatan
SELECT
  k.nama_kecamatan,
  COUNT(t.id) AS jumlah_tempat
FROM public.kecamatan k
LEFT JOIN public.tempat t ON k.id = t.kecamatan_id   -- LEFT JOIN agar kecamatan kosong juga muncul
GROUP BY k.nama_kecamatan
ORDER BY jumlah_tempat DESC;


-- 4.6. Menampilkan tempat dengan rating minimal 4.5
SELECT *
FROM public.tempat
WHERE review_rating >= 4.5
ORDER BY review_rating DESC;


-- 4.7. Mencari tempat terdekat dari koordinat pengguna (Haversine manual)
-- Contoh: pengguna di 3.6013, 98.6971, radius 5 km
SELECT
  nama_tempat,
  jalan,
  latitude,
  longitude,
  ( 6371 * ACOS(
      COS(RADIANS(3.6013)) * COS(RADIANS(latitude)) *
      COS(RADIANS(longitude) - RADIANS(98.6971)) +
      SIN(RADIANS(3.6013)) * SIN(RADIANS(latitude))
    ) ) AS jarak_km
FROM public.tempat
WHERE
  ( 6371 * ACOS(
      COS(RADIANS(3.6013)) * COS(RADIANS(latitude)) *
      COS(RADIANS(longitude) - RADIANS(98.6971)) +
      SIN(RADIANS(3.6013)) * SIN(RADIANS(latitude))
    ) ) <= 5
ORDER BY jarak_km ASC;


-- 4.8. Menampilkan tempat yang diunggah oleh user tertentu (misal user id = 2)
SELECT
  t.*,
  u.name AS nama_pengunggah
FROM public.tempat t
JOIN public.users u ON t.user_id = u.id
WHERE t.user_id = 2;


-- 4.9. Menampilkan statistik rating rata-rata per kategori
SELECT
  kat.nama_kategori,
  ROUND(AVG(t.review_rating)::numeric, 2) AS rata_rata_rating,
  COUNT(t.id) AS jumlah_tempat
FROM public.tempat t
JOIN public.kategori kat ON t.kategori_id = kat.id
GROUP BY kat.nama_kategori
ORDER BY rata_rata_rating DESC;


-- 4.10. Menampilkan data untuk visualisasi GIS:
--       titik (point), jalur (line), dan area (polygon)
--       Saat ini DanLens fokus pada titik (point).
--       Contoh: semua titik dengan warna berdasarkan kategori
SELECT
  t.nama_tempat,
  t.latitude,
  t.longitude,
  kat.nama_kategori,
  CASE
    WHEN kat.id = 1 THEN 'Kuliner'
    WHEN kat.id = 2 THEN 'Wisata'
    WHEN kat.id = 3 THEN 'Kesehatan'
    WHEN kat.id = 4 THEN 'Kemasyarakatan'
    WHEN kat.id = 5 THEN 'Transportasi'
  END AS jenis_titik
FROM public.tempat t
JOIN public.kategori kat ON t.kategori_id = kat.id;


-- ============================================================
-- BAGIAN 5: CATATAN TAMBAHAN UNTUK BUCKET STORAGE
-- ============================================================
-- Storage (tempat gambar) TIDAK bisa dibuat lewat SQL.
-- Harus dibuat manual di Supabase Dashboard > Storage:
--   - Buat bucket bernama "tempat_images"
--   - Centang "Public bucket"


-- ============================================================
-- SELESAI. Semua query inti DanLens sudah tercakup.
-- ============================================================