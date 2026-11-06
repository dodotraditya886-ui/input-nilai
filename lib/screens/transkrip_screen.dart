import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/mahasiswa_model.dart';
import '../models/nilai_model.dart';
import '../providers/akademik_provider.dart';
import '../utils/app_theme.dart';
import '../utils/ui_helpers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/ipk_summary_card.dart';
import '../widgets/nilai_tile.dart';
import 'biodata_screen.dart';
import 'input_nilai_screen.dart';

/// Detail & transkrip akademik satu mahasiswa: biodata, ringkasan IPK, dan
/// daftar nilai per semester (lengkap dengan IP semester).
///
/// - Geser kartu nilai ke kiri untuk menghapus, ketuk untuk mengedit.
/// - Seluruh tampilan ter-update otomatis karena membaca dari provider.
class TranskripScreen extends StatelessWidget {
  const TranskripScreen({super.key, required this.mahasiswaId});

  final String mahasiswaId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AkademikProvider>(
      builder: (context, provider, _) {
        final mhs = provider.cariById(mahasiswaId);

        // Mahasiswa sudah dihapus (mis. dari halaman lain): tampilkan kosong.
        if (mhs == null) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundLight,
            body: Column(
              children: const [
                GradientHeader(
                  title: 'Transkrip Akademik',
                  showBackButton: true,
                ),
                Expanded(
                  child: EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Data Tidak Ditemukan',
                    message: 'Mahasiswa ini sudah dihapus.',
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: Column(
            children: [
              GradientHeader(
                title: 'Transkrip Akademik',
                subtitle: mhs.nama,
                showBackButton: true,
                actions: [
                  IconButton(
                    tooltip: 'Edit biodata',
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BiodataScreen(mahasiswa: mhs)),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus mahasiswa',
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                    onPressed: () => _hapusMahasiswa(context, mhs),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  children: [
                    IpkSummaryCard(mahasiswa: mhs),
                    const SizedBox(height: 20),
                    _buildBiodata(mhs),
                    const SizedBox(height: 24),
                    SectionTitle(
                      'Daftar Mata Kuliah',
                      trailing: _badge('${mhs.jumlahMataKuliah} MK • ${mhs.totalSks} SKS'),
                    ),
                    const SizedBox(height: 14),
                    if (mhs.nilai.isEmpty)
                      const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum Ada Nilai',
                        message:
                            'Ketuk "Tambah Nilai" untuk menginput mata kuliah\n'
                            'pertama mahasiswa ini.',
                      )
                    else
                      ..._buildPerSemester(context, mhs),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InputNilaiScreen(mahasiswaId: mhs.id),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Tambah Nilai',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPerSemester(BuildContext context, MahasiswaModel mhs) {
    final widgets = <Widget>[];
    for (final semester in mhs.daftarSemester) {
      final daftar = mhs.nilaiSemester(semester);
      final ip = NilaiModel.hitungIp(daftar);
      final sks = NilaiModel.hitungSks(daftar);

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Row(
            children: [
              Text(
                'Semester $semester',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDeepPurple,
                ),
              ),
              const Spacer(),
              Text(
                '$sks SKS • IP ${ip.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );

      for (final nilai in daftar) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ValueKey(nilai.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white, size: 26),
              ),
              confirmDismiss: (_) => konfirmasi(
                context,
                judul: 'Hapus Nilai?',
                pesan:
                    '${nilai.namaMataKuliah} akan dihapus dan IPK dihitung ulang.',
              ),
              onDismissed: (_) => context
                  .read<AkademikProvider>()
                  .hapusNilai(mhs.id, nilai.id),
              child: NilaiTile(
                nilai: nilai,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InputNilaiScreen(
                      mahasiswaId: mhs.id,
                      nilaiId: nilai.id,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildBiodata(MahasiswaModel mhs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeepPurple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InfoRow(icon: Icons.badge_outlined, label: 'NIM', value: mhs.nim),
          const Divider(),
          InfoRow(
              icon: Icons.school_outlined,
              label: 'Jurusan',
              value: mhs.jurusan),
          const Divider(),
          InfoRow(
              icon: Icons.event_note_outlined,
              label: 'Angkatan',
              value: mhs.angkatan.toString()),
          const Divider(),
          InfoRow(
              icon: Icons.wc_rounded,
              label: 'Jenis Kelamin',
              value: mhs.jenisKelamin),
          const Divider(),
          InfoRow(
              icon: Icons.email_outlined, label: 'Email', value: mhs.email),
          const Divider(),
          InfoRow(
              icon: Icons.phone_outlined, label: 'Telepon', value: mhs.telepon),
          const Divider(),
          InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Alamat',
              value: mhs.alamat),
        ],
      ),
    );
  }

  Widget _badge(String teks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryDeepPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryDeepPurple,
        ),
      ),
    );
  }

  Future<void> _hapusMahasiswa(BuildContext context, MahasiswaModel mhs) async {
    final ya = await konfirmasi(
      context,
      judul: 'Hapus Mahasiswa?',
      pesan: '${mhs.nama} beserta seluruh nilainya akan dihapus permanen.',
    );
    if (!ya || !context.mounted) return;
    final navigator = Navigator.of(context);
    context.read<AkademikProvider>().hapusMahasiswa(mhs.id);
    AppFeedback.sukses(context, '${mhs.nama} dihapus');
    navigator.pop();
  }
}
