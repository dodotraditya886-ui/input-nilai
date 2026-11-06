import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/katalog_mata_kuliah.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Dashboard Mata Kuliah: katalog mata kuliah beserta SKS, dipisah per jurusan
/// lalu dikelompokkan per semester.
class MataKuliahScreen extends StatefulWidget {
  const MataKuliahScreen({super.key, this.jurusanAwal});

  /// Jurusan yang langsung terpilih saat dibuka (opsional).
  final String? jurusanAwal;

  @override
  State<MataKuliahScreen> createState() => _MataKuliahScreenState();
}

class _MataKuliahScreenState extends State<MataKuliahScreen> {
  late String _jurusan;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final daftar = KatalogMataKuliah.daftarJurusan;
    _jurusan = daftar.contains(widget.jurusanAwal)
        ? widget.jurusanAwal!
        : daftar.first;
  }

  @override
  Widget build(BuildContext context) {
    final semua = KatalogMataKuliah.untuk(_jurusan);
    final q = _query.trim().toLowerCase();
    final tampil = q.isEmpty
        ? semua
        : semua
            .where((mk) =>
                mk.nama.toLowerCase().contains(q) ||
                mk.kode.toLowerCase().contains(q))
            .toList();

    final semesters = (tampil.map((mk) => mk.semester).toSet().toList()..sort());

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          const GradientHeader(
            title: 'Dashboard Mata Kuliah',
            subtitle: 'Daftar mata kuliah & SKS per jurusan',
            showBackButton: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                const SectionTitle('Pilih Jurusan'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: KatalogMataKuliah.daftarJurusan
                      .map(
                        (j) => ChoiceChip(
                          label: Text(j),
                          selected: j == _jurusan,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _jurusan = j),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                _buildRingkasan(semua),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Cari kode atau nama mata kuliah',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                if (tampil.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Tidak Ditemukan',
                    message: 'Tidak ada mata kuliah yang cocok.',
                  )
                else
                  for (final s in semesters) ..._buildSemester(s, tampil),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasan(List<MataKuliahKatalog> semua) {
    final totalSks = semua.fold(0, (sum, mk) => sum + mk.sks);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentIndigo.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _jurusan,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('Mata Kuliah', semua.length.toString()),
              _stat('Total SKS', totalSks.toString()),
              _stat('Semester', '8'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSemester(int semester, List<MataKuliahKatalog> semua) {
    final daftar = semua.where((mk) => mk.semester == semester).toList();
    final sks = daftar.fold(0, (sum, mk) => sum + mk.sks);

    return [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Row(
          children: [
            Text(
              'Semester $semester',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDeepPurple,
              ),
            ),
            const Spacer(),
            Text(
              '${daftar.length} MK • $sks SKS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      for (final mk in daftar)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDeepPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mk.kode,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDeepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mk.nama,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${mk.sks} SKS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentIndigo,
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}
