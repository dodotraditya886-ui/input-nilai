import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/akademik_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'biodata_screen.dart';
import 'input_nilai_screen.dart';
import 'mahasiswa_list_screen.dart';
import 'mata_kuliah_screen.dart';
import 'profile_screen.dart';

/// Screen 3: Dashboard / Home Screen
///
/// Menampilkan:
/// - Banner sambutan
/// - Ringkasan statistik seluruh data (jumlah mahasiswa, rata-rata IPK, MK)
/// - Grid menu navigasi ke seluruh fitur
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Consumer<AkademikProvider>(
        builder: (context, provider, _) {
          final jumlahMhs = provider.jumlahMahasiswa;
          final rataIpk = provider.rataRataIpk;
          final totalMk = provider.totalMataKuliah;

          return CustomScrollView(
            slivers: [
              // Header dengan gradient
              SliverToBoxAdapter(
                child: _buildHeader(context, jumlahMhs),
              ),
              // Statistik akademik
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildStatsSection(context, jumlahMhs, rataIpk, totalMk),
                ),
              ),
              // Grid menu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildMenuGrid(context),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int jumlahMhs) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeepPurple.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dekorasi lingkaran background
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👋 Halo,',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Admin Akademik',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$jumlahMhs mahasiswa terdata',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar profil
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
      BuildContext context, int jumlahMhs, double rataIpk, int totalMk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Akademik',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Mahasiswa',
                value: jumlahMhs.toString(),
                icon: Icons.groups_rounded,
                color: AppTheme.primaryDeepPurple,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: StatCard(
                label: 'Rerata IPK',
                value: rataIpk.toStringAsFixed(2),
                icon: Icons.trending_up_rounded,
                color: AppTheme.accentIndigo,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: StatCard(
                label: 'Nilai MK',
                value: totalMk.toString(),
                icon: Icons.class_outlined,
                color: const Color(0xFF00897B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _buka(BuildContext context, Widget layar) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => layar));

  Widget _buildMenuGrid(BuildContext context) {
    // Daftar menu navigasi
    // Tambahkan atau ubah ke sini jika ingin menambah fitur baru
    final menus = [
      _MenuItem(
        icon: Icons.groups_rounded,
        label: 'Data\nMahasiswa',
        color: AppTheme.primaryDeepPurple,
        onTap: () => _buka(context, const MahasiswaListScreen()),
      ),
      _MenuItem(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Tambah\nMahasiswa',
        color: const Color(0xFF00897B),
        onTap: () => _buka(context, const BiodataScreen()),
      ),
      _MenuItem(
        icon: Icons.menu_book_rounded,
        label: 'Dashboard\nMata Kuliah',
        color: const Color(0xFF8E24AA),
        onTap: () => _buka(context, const MataKuliahScreen()),
      ),
      _MenuItem(
        icon: Icons.add_chart_rounded,
        label: 'Dashboard\nInput Nilai',
        color: AppTheme.accentIndigo,
        onTap: () => _buka(context, const InputNilaiScreen()),
      ),
      _MenuItem(
        icon: Icons.account_circle_outlined,
        label: 'Profil &\nKelompok',
        color: const Color(0xFFE65100),
        onTap: () => _buka(context, const ProfileScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Utama',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        // Lebar kartu dibatasi agar tetap proporsional di layar lebar (web/tablet)
        GridView.extent(
          maxCrossAxisExtent: 190,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
          children: menus
              .map((m) => MenuGridItem(
                    icon: m.icon,
                    label: m.label,
                    color: m.color,
                    onTap: m.onTap,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// Data class untuk item menu (private, hanya dipakai di file ini)
class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
