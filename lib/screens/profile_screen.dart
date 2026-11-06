import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/akademik_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

/// Screen 7: Profil & Informasi Kelompok / Tentang Aplikasi
///
/// Menampilkan:
/// - Ringkasan data akademik yang dikelola (jumlah mahasiswa, rerata IPK)
/// - Informasi anggota kelompok UTS
/// - Deskripsi & versi aplikasi
/// - Tombol Logout yang kembali ke LoginScreen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ==========================================================================
  // DATA KELOMPOK UTS
  // Ganti nama, NPM, dan peran sesuai kelompok Anda
  // ==========================================================================
  static const List<Map<String, String>> _anggotaKelompok = [
    {
      'nama': 'Raditia Arfa Narajuna Fatiha',
      'npm': '5240411060',
      'peran': 'Ketua Kelompok',
      'inisial': 'RA',
    },
    {
      'nama': 'Indrawan Abdan Sukrillah',
      'npm': '5240411212',
      'peran': 'Anggota Kelompok',
      'inisial': 'IS',
    },
    {
      'nama': 'Mukhtar Fadlurrahman',
      'npm': '5240411242',
      'peran': 'Anggota Kelompok',
      'inisial': 'MF',
    },
    {
      'nama': 'Ananda Dila Listy',
      'npm': '22510003',
      'peran': 'Frontend Developer / Routing',
      'inisial': 'BS',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          GradientHeader(
            title: 'Profil & Kelompok',
            subtitle: 'Informasi akun & tim pengembang',
            showBackButton: true,
          ),
          Expanded(
            child: Consumer<AkademikProvider>(
              builder: (context, provider, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Ringkasan data akademik
                      _buildRingkasanCard(provider),
                      const SizedBox(height: 20),
                      // Informasi kelompok
                      _buildSectionHeader(
                        'Anggota Kelompok UTS',
                        Icons.group_rounded,
                      ),
                      const SizedBox(height: 14),
                      ..._anggotaKelompok.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAnggotaCard(entry.value, entry.key),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tentang Aplikasi
                      _buildSectionHeader(
                        'Tentang Aplikasi',
                        Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                      _buildAboutCard(),
                      const SizedBox(height: 24),
                      // Tombol Logout
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleLogout(context),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppTheme.errorRed,
                          ),
                          label: Text(
                            'Keluar (Logout)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.errorRed,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppTheme.errorRed,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasanCard(AkademikProvider provider) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeepPurple.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDeepPurple.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Admin Akademik',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),
          InfoRow(
            icon: Icons.groups_rounded,
            label: 'Jumlah Mahasiswa',
            value: provider.jumlahMahasiswa.toString(),
          ),
          const Divider(height: 20),
          InfoRow(
            icon: Icons.trending_up_rounded,
            label: 'Rata-rata IPK',
            value: provider.rataRataIpk.toStringAsFixed(2),
          ),
          const Divider(height: 20),
          InfoRow(
            icon: Icons.class_outlined,
            label: 'Total Nilai Mata Kuliah Tercatat',
            value: provider.totalMataKuliah.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryDeepPurple, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAnggotaCard(Map<String, String> anggota, int index) {
    // 1. Hapus array colors[] dan logika rotasinya
    // 2. Langsung tetapkan satu warna saja untuk semua anggota
    final color = AppTheme.primaryDeepPurple;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar inisial
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                anggota['inisial']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anggota['nama']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'NPM: ${anggota['npm']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  anggota['peran']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: color, // Teks peran akan ikut berwarna ungu
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Badge nomor anggota
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentIndigo.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AkademikKu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Versi 1.0.0',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 16),
          Text(
            'Tentang Aplikasi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AkademikKu adalah aplikasi manajemen akademik mahasiswa yang dibangun menggunakan Flutter dengan desain Material 3. '
            'Aplikasi ini memudahkan mahasiswa dalam mengelola biodata, mencatat nilai mata kuliah, serta memantau perkembangan IPK secara real-time.\n\n'
            'Dikembangkan sebagai Proyek UTS Mata Kuliah Pemrograman Mobile.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip(Icons.flutter_dash, 'Flutter 3.x'),
              const SizedBox(width: 10),
              _infoChip(Icons.palette_outlined, 'Material 3'),
              const SizedBox(width: 10),
              _infoChip(Icons.layers_outlined, 'Provider'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.accentIndigo),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentIndigo,
            ),
          ),
        ],
      ),
    );
  }

  /// Proses logout: update provider & navigasi balik ke LoginScreen
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Logout',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Update state provider → user dianggap sudah logout
              context.read<AuthProvider>().logout();
              // ============================================================
              // NAVIGASI LOGOUT:
              // Bersihkan seluruh stack navigasi, lalu push ke LoginScreen
              // ============================================================
              Navigator.of(ctx).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
