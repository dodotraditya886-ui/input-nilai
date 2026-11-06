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
import '../widgets/mahasiswa_picker_sheet.dart';
import '../widgets/nilai_form_card.dart';
import '../widgets/nilai_tile.dart';
import 'biodata_screen.dart';

/// Dashboard Input Nilai.
///
/// Alur: (1) pilih mahasiswa → (2) lihat ringkasan IPK → (3) tambah / edit
/// mata kuliah beserta nilainya → (4) daftar nilai mahasiswa tersebut.
///
/// Seluruh data dibaca dari [AkademikProvider] lewat `Consumer`, sehingga
/// ringkasan IPK & daftar nilai langsung ter-update setiap kali nilai
/// ditambah, diubah, atau dihapus.
class InputNilaiScreen extends StatefulWidget {
  const InputNilaiScreen({super.key, this.mahasiswaId, this.nilaiId});

  /// Mahasiswa yang langsung terpilih saat halaman dibuka (opsional).
  final String? mahasiswaId;

  /// Nilai yang langsung dibuka dalam mode edit (opsional).
  final String? nilaiId;

  @override
  State<InputNilaiScreen> createState() => _InputNilaiScreenState();
}

class _InputNilaiScreenState extends State<InputNilaiScreen> {
  final _formAnchor = GlobalKey();

  String? _mahasiswaId;
  String? _nilaiEditId;

  @override
  void initState() {
    super.initState();
    _mahasiswaId = widget.mahasiswaId;
    _nilaiEditId = widget.nilaiId;
    if (_nilaiEditId != null) _gulirKeForm();
  }

  void _gulirKeForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _formAnchor.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pilihMahasiswa() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MahasiswaPickerSheet(selectedId: _mahasiswaId),
    );
    if (id == null || !mounted) return;
    setState(() {
      _mahasiswaId = id;
      _nilaiEditId = null;
    });
  }

  void _mulaiEdit(NilaiModel nilai) {
    setState(() => _nilaiEditId = nilai.id);
    _gulirKeForm();
  }

  Future<void> _hapusNilai(MahasiswaModel mhs, NilaiModel nilai) async {
    final ya = await konfirmasi(
      context,
      judul: 'Hapus Nilai?',
      pesan: '${nilai.namaMataKuliah} akan dihapus dari ${mhs.nama}. '
          'IPK akan dihitung ulang.',
    );
    if (!ya || !mounted) return;
    context.read<AkademikProvider>().hapusNilai(mhs.id, nilai.id);
    if (_nilaiEditId == nilai.id) setState(() => _nilaiEditId = null);
    AppFeedback.sukses(context, 'Nilai berhasil dihapus');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          const GradientHeader(
            title: 'Dashboard Input Nilai',
            subtitle: 'Pilih mahasiswa, lalu input nilai mata kuliah',
            showBackButton: true,
          ),
          Expanded(
            child: Consumer<AkademikProvider>(
              builder: (context, provider, _) {
                final mhs = provider.cariById(_mahasiswaId);
                NilaiModel? nilaiEdit;
                if (mhs != null && _nilaiEditId != null) {
                  for (final n in mhs.nilai) {
                    if (n.id == _nilaiEditId) nilaiEdit = n;
                  }
                }

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('1 · Pilih Mahasiswa'),
                      const SizedBox(height: 12),
                      _buildSelector(mhs, provider.jumlahMahasiswa),
                      const SizedBox(height: 22),
                      if (provider.jumlahMahasiswa == 0)
                        _buildBelumAdaMahasiswa()
                      else if (mhs == null)
                        _buildBelumDipilih()
                      else ...[
                        IpkSummaryCard(mahasiswa: mhs),
                        const SizedBox(height: 24),
                        Column(
                          key: _formAnchor,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle('2 · Input Mata Kuliah & Nilai'),
                            const SizedBox(height: 12),
                            NilaiFormCard(
                              key: ValueKey('${mhs.id}-${nilaiEdit?.id ?? 'baru'}'),
                              mahasiswa: mhs,
                              nilaiDiedit: nilaiEdit,
                              onSelesaiEdit: () =>
                                  setState(() => _nilaiEditId = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SectionTitle('3 · Daftar Nilai (${mhs.jumlahMataKuliah})'),
                        const SizedBox(height: 12),
                        if (mhs.nilai.isEmpty)
                          _buildBelumAdaNilai()
                        else
                          ...mhs.nilai.map(
                            (n) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: NilaiTile(
                                nilai: n,
                                highlighted: n.id == _nilaiEditId,
                                onTap: () => _mulaiEdit(n),
                                onDelete: () => _hapusNilai(mhs, n),
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildSelector(MahasiswaModel? mhs, int jumlahMahasiswa) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: AppTheme.primaryDeepPurple.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: jumlahMahasiswa == 0 ? null : _pilihMahasiswa,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    AppTheme.primaryDeepPurple.withValues(alpha: 0.1),
                child: mhs == null
                    ? const Icon(Icons.person_search_rounded,
                        color: AppTheme.primaryDeepPurple)
                    : Text(
                        mhs.inisial,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDeepPurple,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mhs?.nama ?? 'Belum ada mahasiswa dipilih',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: mhs == null
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mhs == null
                          ? 'Ketuk untuk memilih dari daftar'
                          : '${mhs.nim} • ${mhs.jurusan}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (jumlahMahasiswa > 0)
                Icon(
                  mhs == null
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.swap_horiz_rounded,
                  color: AppTheme.primaryDeepPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBelumAdaMahasiswa() {
    return EmptyState(
      icon: Icons.group_add_outlined,
      title: 'Belum Ada Mahasiswa',
      message: 'Tambahkan biodata mahasiswa terlebih dahulu\n'
          'sebelum menginput nilai.',
      action: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BiodataScreen()),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: const Text('Tambah Mahasiswa'),
      ),
    );
  }

  Widget _buildBelumDipilih() {
    return const EmptyState(
      icon: Icons.touch_app_outlined,
      title: 'Pilih Mahasiswa',
      message: 'Pilih mahasiswa di atas untuk melihat ringkasan IPK\n'
          'dan mulai menginput nilai mata kuliah.',
    );
  }

  Widget _buildBelumAdaNilai() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Belum ada nilai. Tambahkan mata kuliah pertama lewat form di atas.',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
