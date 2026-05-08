// lib/screens/profile/team_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';

// ──────────────────────────────────────────────
// DATA TEAM — Edit sesuai anggota tim Anda
// ──────────────────────────────────────────────
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
    bio: 'www.instagram.com/rajaalbaroni04',
  ),
  
];

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

class TeamProfileScreen extends StatelessWidget {
  const TeamProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _TeamCard(member: _team[i], index: i),
                childCount: _team.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatefulWidget {
  final TeamMember member;
  final int index;

  const _TeamCard({required this.member, required this.index});

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  bool _photoTapped = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // Card Header - Photo + Name
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo with tap overlay effect
                GestureDetector(
                  onTap: () {
                    setState(() => _photoTapped = true);
                    _showPhotoOverlay(context, widget.member);
                    Future.delayed(const Duration(milliseconds: 300),
                        () => setState(() => _photoTapped = false));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.diagonal3Values(_photoTapped ? 0.95 : 1.0, _photoTapped ? 0.95 : 1.0, 1.0),
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
                            spreadRadius: _photoTapped ? 4 : 0,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          widget.member.photo,
                          fit: BoxFit.cover,
                          width: 76,
                          height: 76,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: Center(
                              child: Text(
                                widget.member.name.substring(0, 1),
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

                // Info
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

          // Bio
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

          // Divider
          const Divider(height: 1, color: AppColors.surface),

          // Social buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (widget.member.instagram != null)
                  _SocialButton(
                    label: 'Instagram',
                    icon: Icons.camera_alt_outlined,
                    color: const Color(0xFFE1306C),
                    onTap: () => _launchUrl(widget.member.instagram!),
                  ),
                if (widget.member.instagram != null && widget.member.email != null)
                  const SizedBox(width: 8),
                if (widget.member.email != null)
                  _SocialButton(
                    label: 'Email',
                    icon: Icons.email_outlined,
                    color: AppColors.primary,
                    onTap: () => _launchUrl('mailto:${widget.member.email}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fade(duration: 450.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }

  void _showPhotoOverlay(BuildContext context, TeamMember member) {
    showDialog(
      context: context,
      barrierColor:  Colors.black.withValues(alpha: 0.75),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'team_${member.nim}',
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

  //void _launchUrl(String url) async {
      //final uri = Uri.parse(url);
      //if (await canLaunchUrl(uri)) {
        //await launchUrl(uri, mode: LaunchMode.externalApplication);
      //}
    //}
  //}

    void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

// ═══ WIDGET SOCIAL BUTTON (di luar _TeamCardState) ═══
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
          color: color.withValues(alpha: 0.08),
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