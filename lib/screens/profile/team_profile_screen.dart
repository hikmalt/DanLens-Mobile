// FILE: lib/screens/profile/team_profile_screen.dart
// File ini menampilkan halaman profil tim pengembang aplikasi DanLens.
// Fungsi: Menampilkan daftar anggota tim dengan foto, nama, NIM, peran, bio, serta tombol link ke Instagram dan Email.
// Informasi penting: Data tim disimpan dalam konstanta di dalam file ini. Foto tim diambil dari folder assets/images/team/.
// Saat foto diklik, akan muncul dialog dengan foto yang lebih besar (Hero animation).
// Tombol sosial media menggunakan package url_launcher untuk membuka aplikasi eksternal.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';

// ──────────────────────────────────────────────
// DATA TEAM — Edit sesuai anggota tim Anda
// ──────────────────────────────────────────────
// Daftar anggota tim (konstanta). Setiap anggota memiliki nama, NIM, peran, path foto, Instagram, email, dan bio.
const List<TeamMember> _team = [
  TeamMember(
    name: 'Alif Faishal Ashary',
    nim: '2305181052',
    role: 'Project Lead & Web Developer',
    photo: 'assets/images/team/alif.webp',
    instagram: 'https://www.instagram.com/alf.ryy',
    email: 'aliffaishalashary456@gmail.com',
    bio: 'duku goreng',
  ),
  TeamMember(
    name: 'Hikmal Akbar',
    nim: '2305181024',
    role: 'Mobile Developer & Helper',
    photo: 'assets/images/team/hikmal.webp',
    instagram: 'https://www.instagram.com/hikmalakbaaar_',
    email: 'hikmalakbarid@gmail.com',
    bio: 'bismillah sekolah rakyat',
  ),
  TeamMember(
    name: 'Mhd. Ihsan Harianto Harahap',
    nim: '2305181096',
    role: 'Mobile Developer & Data Researcher',
    photo: 'assets/images/team/ihsan.webp',
    instagram: 'https://www.instagram.com/26ihsann',
    email: 'ihsanharahap0@gmail.com',
    bio: 'aktif',
  ),
  TeamMember(
    name: 'Fadil Givari',
    nim: '2305181044',
    role: 'Mobile Developer & Data Researcher',
    photo: 'assets/images/team/fadil.webp',
    instagram: 'https://www.instagram.com/gvryy_',
    email: 'givarifadil@gmail.com',
    bio: 'FG',
  ),
  TeamMember(
    name: 'Feny Mawarni',
    nim: '2305181020',
    role: 'Database Designer & Documentation',
    photo: 'assets/images/team/feny.webp',
    instagram: 'https://www.instagram.com/fenymawarnii_',
    email: 'fenymawarni@gmail.com',
    bio: '- blessed.',
  ),
  TeamMember(
    name: 'Putri Yaumi Askira',
    nim: '2305181016',
    role: 'Database Designer & Documentation',
    photo: 'assets/images/team/putri.webp',
    instagram: 'https://www.instagram.com/putriyaumii',
    email: 'putriyaumi7766@gmail.com',
    bio: 'be carefull with all the things',
  ),
  
];

// Kelas model untuk menyimpan data satu anggota tim.
class TeamMember {
  final String name;
  final String nim;
  final String role;
  final String photo;
  final String? instagram;
  final String? email;
  final String bio;

  const TeamMember({
    required this.name,
    required this.nim,
    required this.role,
    required this.photo,
    this.instagram,
    this.email,
    required this.bio,
  });
}

// Halaman utama profil tim.
class TeamProfileScreen extends StatelessWidget {
  const TeamProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Warna latar belakang dari tema.
      body: CustomScrollView(
        slivers: [
          // AppBar yang dapat diciutkan (collapsible) dengan gradien hijau.
          SliverAppBar(
            pinned: true, // Tetap di atas saat scroll.
            expandedHeight: 140, // Tinggi saat membesar.
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tim DanLens',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text('Para pengembang di balik DanLens',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Daftar anggota tim dengan padding.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _TeamCard(member: _team[i], index: i), // Bangun kartu untuk setiap anggota.
                childCount: _team.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Kartu untuk satu anggota tim (Stateful karena ada animasi saat foto diklik).
class _TeamCard extends StatefulWidget {
  final TeamMember member;
  final int index; // Indeks untuk animasi bertahap.

  const _TeamCard({required this.member, required this.index});

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  bool _photoTapped = false; // Status apakah foto sedang ditekan (untuk efek animasi).

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14), // Jarak antar kartu.
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Baris header: foto dan nama.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto dengan efek tap (zoom out sementara saat ditekan, lalu buka dialog).
                GestureDetector(
                  onTap: () {
                    setState(() => _photoTapped = true); // Mulai animasi zoom out.
                    _showPhotoOverlay(context, widget.member); // Tampilkan dialog foto besar.
                    Future.delayed(const Duration(milliseconds: 300),
                        () => setState(() => _photoTapped = false)); // Kembalikan ukuran setelah dialog.
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.diagonal3Values(_photoTapped ? 0.95 : 1.0, _photoTapped ? 0.95 : 1.0, 1.0), // Skala 0.95 saat ditekan.
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            spreadRadius: _photoTapped ? 4 : 0, // Bayangan membesar saat ditekan.
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          widget.member.photo, // Gambar dari folder assets.
                          fit: BoxFit.cover,
                          width: 76,
                          height: 76,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: Center(
                              child: Text(
                                widget.member.name.substring(0, 1), // Inisial nama jika gambar gagal dimuat.
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Informasi teks (nama, NIM, peran).
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.member.name,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(widget.member.nim,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textGray)),
                      const SizedBox(height: 6),
                      // Chip peran.
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                           color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.member.role,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bio anggota tim.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              widget.member.bio,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textGray,
                  height: 1.6),
            ),
          ),

          // Garis pemisah.
          const Divider(height: 1, color: AppColors.surface),

          // Tombol media sosial (Instagram dan Email).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Tombol Instagram jika ada.
                if (widget.member.instagram != null)
                  _SocialButton(
                    label: 'Instagram',
                    icon: Icons.camera_alt_outlined,
                    color: const Color(0xFFE1306C),
                    onTap: () => _launchUrl(widget.member.instagram!),
                  ),
                // Spacer jika kedua tombol ada.
                if (widget.member.instagram != null && widget.member.email != null)
                  const SizedBox(width: 8),
                // Tombol Email jika ada.
                if (widget.member.email != null)
                  _SocialButton(
                    label: 'Email',
                    icon: Icons.email_outlined,
                    color: AppColors.primary,
                    onTap: () => _launchUrl('mailto:${widget.member.email}'), // Buka aplikasi email.
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        // Animasi masuk: fade + slide dari bawah, dengan jeda berdasarkan indeks.
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fade(duration: 450.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }

  // Menampilkan dialog dengan foto besar (Hero animation).
  void _showPhotoOverlay(BuildContext context, TeamMember member) {
    showDialog(
      context: context,
      barrierColor:  Colors.black.withValues(alpha: 0.75), // Latar belakang gelap transparan.
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'team_${member.nim}', // Tag Hero yang sama dengan foto di kartu.
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                )],
                ),
                child: ClipOval(
                  child: Image.asset(
                    member.photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primary,
                      child: Center(
                        child: Text(member.name.substring(0, 1),
                            style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(member.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 20)),
            Text(member.role,
                style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                    fontSize: 13)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  // Membuka URL (Instagram atau mailto) menggunakan url_launcher.
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication); // Buka di aplikasi eksternal.
    } catch (e) {
       if (!mounted) return;      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka link: $url'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// Tombol sosial media (Instagram / Email) dengan ikon dan label.
class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), // Warna latar transparan sesuai warna tombol.
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color)),
          ],
        ),
      ),
    );
  }
}