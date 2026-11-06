import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/mahasiswa_model.dart';
import '../providers/akademik_provider.dart';
import '../utils/app_theme.dart';
import '../utils/ui_helpers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/mahasiswa_card.dart';
import 'biodata_screen.dart';
import 'input_nilai_screen.dart';
import 'transkrip_screen.dart';

enum _Urutan { nama, ipk, nim }

/// Daftar seluruh mahasiswa beserta status akademiknya (IPK, SKS, total nilai
/// mutu). Mendukung pencarian, pengurutan, dan dua tampilan: kartu & tabel.
class MahasiswaListScreen extends StatefulWidget {
  const MahasiswaListScreen({super.key});

  @override
  State<MahasiswaListScreen> createState() => _MahasiswaListScreenState();
}

class _MahasiswaListScreenState extends State<MahasiswaListScreen> {
  String _query = '';
  bool _tampilTabel = false;
  _Urutan _urutan = _Urutan.nama;

  List<MahasiswaModel> _saring(List<MahasiswaModel> semua) {
    final q = _query.trim().toLowerCase();
    final hasil = q.isEmpty
        ? semua.toList()
        : semua
            .where((m) =>
                m.nama.toLowerCase().contains(q) ||
                m.nim.toLowerCase().contains(q) ||
                m.jurusan.toLowerCase().contains(q))
            .toList();

    switch (_urutan) {
      case _Urutan.nama:
        hasil.sort(
            (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
      case _Urutan.ipk:
        hasil.sort((a, b) => b.ipk.compareTo(a.ipk));
      case _Urutan.nim:
        hasil.sort((a, b) => a.nim.compareTo(b.nim));
    }
    return hasil;
  }

  void _buka(Widget layar) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => layar));

  void _lihat(MahasiswaModel m) => _buka(TranskripScreen(mahasiswaId: m.id));
  void _edit(MahasiswaModel m) => _buka(BiodataScreen(mahasiswa: m));
  void _inputNilai(MahasiswaModel m) =>
      _buka(InputNilaiScreen(mahasiswaId: m.id));

  Future<void> _hapus(MahasiswaModel m) async {
    final ya = await konfirmasi(
      context,
      judul: 'Hapus Mahasiswa?',
      pesan: '${m.nama} beserta ${m.jumlahMataKuliah} nilai mata kuliahnya '
          'akan dihapus permanen.',
    );
    if (!ya || !mounted) return;
    context.read<AkademikProvider>().hapusMahasiswa(m.id);
    AppFeedback.sukses(context, '${m.nama} dihapus');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          const GradientHeader(
            title: 'Data Mahasiswa',
            subtitle: 'Biodata & status akademik seluruh mahasiswa',
            showBackButton: true,
          ),
          Expanded(
            child: Consumer<AkademikProvider>(
              builder: (context, provider, _) {
                final semua = provider.daftarMahasiswa;
                if (semua.isEmpty) {
                  return EmptyState(
                    icon: Icons.groups_2_outlined,
                    title: 'Belum Ada Mahasiswa',
                    message: 'Tambahkan mahasiswa pertama untuk mulai\n'
                        'mengelola data akademik.',
                    action: ElevatedButton.icon(
                      onPressed: () => _buka(const BiodataScreen()),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Tambah Mahasiswa'),
                    ),
                  );
                }

                final tampil = _saring(semua);
                return Column(
                  children: [
                    _buildKontrol(semua.length, tampil.length),
                    Expanded(
                      child: tampil.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Tidak Ditemukan',
                              message:
                                  'Tidak ada mahasiswa yang cocok dengan pencarian.',
                            )
                          : _tampilTabel
                              ? _buildTabel(tampil)
                              : _buildDaftar(tampil),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _buka(const BiodataScreen()),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          'Tambah',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildKontrol(int total, int ditampilkan) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Cari nama, NIM, atau jurusan',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chipUrut('Nama A–Z', _Urutan.nama),
                      const SizedBox(width: 8),
                      _chipUrut('IPK tertinggi', _Urutan.ipk),
                      const SizedBox(width: 8),
                      _chipUrut('NIM', _Urutan.nim),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: _tampilTabel ? 'Tampilan kartu' : 'Tampilan tabel',
                onPressed: () => setState(() => _tampilTabel = !_tampilTabel),
                icon: Icon(
                  _tampilTabel
                      ? Icons.view_agenda_outlined
                      : Icons.table_chart_outlined,
                  color: AppTheme.primaryDeepPurple,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ditampilkan == total
                  ? '$total mahasiswa'
                  : '$ditampilkan dari $total mahasiswa',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipUrut(String label, _Urutan nilai) {
    return ChoiceChip(
      label: Text(label),
      selected: _urutan == nilai,
      showCheckmark: false,
      onSelected: (_) => setState(() => _urutan = nilai),
    );
  }

  Widget _buildDaftar(List<MahasiswaModel> data) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final m = data[i];
        return MahasiswaCard(
          key: ValueKey(m.id),
          mahasiswa: m,
          onTap: () => _lihat(m),
          onEdit: () => _edit(m),
          onInputNilai: () => _inputNilai(m),
          onDelete: () => _hapus(m),
        );
      },
    );
  }

  Widget _buildTabel(List<MahasiswaModel> data) {
    TextStyle gaya([FontWeight w = FontWeight.w500]) => GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: w,
          color: AppTheme.textPrimary,
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDeepPurple.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStatePropertyAll(AppTheme.surfaceColor),
            headingTextStyle: gaya(FontWeight.w800),
            columnSpacing: 22,
            columns: const [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('NIM')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Jurusan')),
              DataColumn(label: Text('SKS'), numeric: true),
              DataColumn(label: Text('Total Nilai Mutu'), numeric: true),
              DataColumn(label: Text('IPK'), numeric: true),
              DataColumn(label: Text('Predikat')),
            ],
            rows: [
              for (var i = 0; i < data.length; i++)
                DataRow(
                  onSelectChanged: (_) => _lihat(data[i]),
                  cells: [
                    DataCell(Text('${i + 1}', style: gaya())),
                    DataCell(Text(data[i].nim, style: gaya())),
                    DataCell(Text(data[i].nama, style: gaya(FontWeight.w700))),
                    DataCell(Text(data[i].jurusan, style: gaya())),
                    DataCell(Text('${data[i].totalSks}', style: gaya())),
                    DataCell(Text(formatAngka(data[i].totalMutu), style: gaya())),
                    DataCell(
                      Text(
                        data[i].nilai.isEmpty
                            ? '–'
                            : data[i].ipk.toStringAsFixed(2),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: data[i].nilai.isEmpty
                              ? AppTheme.textSecondary
                              : AppTheme.warnaIpk(data[i].ipk),
                        ),
                      ),
                    ),
                    DataCell(Text(data[i].predikat, style: gaya())),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
