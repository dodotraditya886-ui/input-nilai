import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../data/katalog_mata_kuliah.dart';
import '../models/mahasiswa_model.dart';
import '../models/nilai_model.dart';
import '../providers/akademik_provider.dart';
import '../utils/app_theme.dart';
import '../utils/ui_helpers.dart';
import 'common_widgets.dart';
import 'katalog_picker_sheet.dart';

enum ModeInputNilai { angka, huruf }

/// Form tambah / edit satu mata kuliah untuk [mahasiswa].
///
/// Saat disimpan, form langsung memanggil [AkademikProvider] sehingga IPK,
/// total SKS, dan seluruh halaman lain ter-update seketika.
///
/// Catatan: induk sebaiknya memberi `key` yang berubah ketika mahasiswa atau
/// [nilaiDiedit] berganti, agar state form di-reset.
class NilaiFormCard extends StatefulWidget {
  const NilaiFormCard({
    super.key,
    required this.mahasiswa,
    this.nilaiDiedit,
    this.onSelesaiEdit,
  });

  final MahasiswaModel mahasiswa;

  /// Bila tidak null, form berada pada mode edit untuk nilai ini.
  final NilaiModel? nilaiDiedit;

  /// Dipanggil setelah edit disimpan atau dibatalkan.
  final VoidCallback? onSelesaiEdit;

  @override
  State<NilaiFormCard> createState() => _NilaiFormCardState();
}

class _NilaiFormCardState extends State<NilaiFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _kodeCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _angkaCtrl = TextEditingController();

  int _sks = 3;
  int _semester = 1;
  ModeInputNilai _mode = ModeInputNilai.angka;
  String? _huruf;
  bool _hurufError = false;

  bool get _isEdit => widget.nilaiDiedit != null;

  @override
  void initState() {
    super.initState();
    final n = widget.nilaiDiedit;
    if (n != null) {
      _kodeCtrl.text = n.kodeMk;
      _namaCtrl.text = n.namaMataKuliah;
      _sks = n.jumlahSks;
      _semester = n.semester;
      if (n.nilaiAngka != null) {
        _mode = ModeInputNilai.angka;
        _angkaCtrl.text = formatAngka(n.nilaiAngka!);
      } else {
        _mode = ModeInputNilai.huruf;
        _huruf = n.nilaiHuruf;
      }
    } else {
      // Mulai dari semester setelah semester terakhir yang sudah punya nilai.
      final semesters = widget.mahasiswa.daftarSemester;
      if (semesters.isNotEmpty) _semester = semesters.last;
    }
  }

  @override
  void dispose() {
    _kodeCtrl.dispose();
    _namaCtrl.dispose();
    _angkaCtrl.dispose();
    super.dispose();
  }

  /// Menerima koma maupun titik sebagai pemisah desimal ("85,5" / "85.5").
  static double? _parseAngka(String teks) =>
      double.tryParse(teks.trim().replaceAll(',', '.'));

  /// Huruf yang akan dihasilkan oleh input saat ini (null bila belum valid).
  String? get _hurufPreview {
    if (_mode == ModeInputNilai.huruf) return _huruf;
    final angka = _parseAngka(_angkaCtrl.text);
    if (angka == null || angka < 0 || angka > 100) return null;
    return NilaiModel.hitungNilaiHuruf(angka);
  }

  /// Isi kode, nama, SKS, dan semester dari katalog jurusan mahasiswa.
  Future<void> _pilihDariKatalog() async {
    final mk = await showModalBottomSheet<MataKuliahKatalog>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => KatalogPickerSheet(
        jurusan: widget.mahasiswa.jurusan,
        sudahDiinput: widget.mahasiswa.nilai
            .where((n) => n.id != widget.nilaiDiedit?.id)
            .map((n) => n.kodeMk.toUpperCase())
            .toSet(),
      ),
    );
    if (mk == null || !mounted) return;
    setState(() {
      _kodeCtrl.text = mk.kode;
      _namaCtrl.text = mk.nama;
      _sks = mk.sks.clamp(1, 6);
      _semester = mk.semester;
    });
  }

  void _simpan() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final hurufValid = _mode == ModeInputNilai.angka || _huruf != null;
    if (!hurufValid) setState(() => _hurufError = true);
    if (!formValid || !hurufValid) return;

    final kode = _kodeCtrl.text.trim().toUpperCase();
    final nama = _namaCtrl.text.trim();
    final id = widget.nilaiDiedit?.id;

    final nilai = _mode == ModeInputNilai.angka
        ? NilaiModel.dariAngka(
            id: id,
            kodeMk: kode,
            namaMataKuliah: nama,
            jumlahSks: _sks,
            nilaiAngka: _parseAngka(_angkaCtrl.text)!,
            semester: _semester,
          )
        : NilaiModel.dariHuruf(
            id: id,
            kodeMk: kode,
            namaMataKuliah: nama,
            jumlahSks: _sks,
            nilaiHuruf: _huruf!,
            semester: _semester,
          );

    final provider = context.read<AkademikProvider>();
    final berhasil = _isEdit
        ? provider.perbaruiNilai(widget.mahasiswa.id, nilai)
        : provider.tambahNilai(widget.mahasiswa.id, nilai);

    if (!berhasil) {
      AppFeedback.gagal(context, 'Nilai gagal disimpan. Periksa kode MK.');
      return;
    }

    FocusScope.of(context).unfocus();
    AppFeedback.sukses(
      context,
      _isEdit
          ? '${nilai.namaMataKuliah} diperbarui'
          : '${nilai.namaMataKuliah} ditambahkan • IPK dihitung ulang',
    );

    if (_isEdit) {
      widget.onSelesaiEdit?.call();
    } else {
      // Kosongkan field spesifik MK; SKS & semester dipertahankan agar input
      // beberapa MK berurutan di semester yang sama lebih cepat.
      _kodeCtrl.clear();
      _namaCtrl.clear();
      _angkaCtrl.clear();
      setState(() {
        _huruf = null;
        _hurufError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _hurufPreview;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: _isEdit
            ? Border.all(color: AppTheme.primaryDeepPurple, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeepPurple.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (_isEdit)
                  TextButton(
                    onPressed: widget.onSelesaiEdit,
                    child: const Text('Batal'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pilihDariKatalog,
                icon: const Icon(Icons.library_books_outlined, size: 18),
                label: Text('Pilih dari katalog ${widget.mahasiswa.jurusan}',
                    overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _kodeCtrl,
              readOnly: true,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Kode Mata Kuliah',
                hintText: 'Contoh: IF101',
                prefixIcon: Icon(Icons.qr_code_rounded),
              ),
              validator: (v) {
                final kode = (v ?? '').trim();
                if (kode.isEmpty) return 'Kode MK wajib diisi';
                final ganda = context.read<AkademikProvider>().kodeMkSudahAda(
                      widget.mahasiswa.id,
                      kode,
                      kecualiNilaiId: widget.nilaiDiedit?.id,
                    );
                return ganda ? 'Kode MK sudah ada untuk mahasiswa ini' : null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _namaCtrl,
              readOnly: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama Mata Kuliah',
                hintText: 'Contoh: Algoritma dan Pemrograman',
                prefixIcon: Icon(Icons.menu_book_rounded),
              ),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Nama mata kuliah wajib diisi'
                  : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('sks-$_sks'),
                    initialValue: _sks,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'SKS',
                      prefixIcon: Icon(Icons.layers_outlined),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    items: [for (var s = 1; s <= 6; s++) s]
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text('$s SKS')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _sks = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('semester-$_semester'),
                    initialValue: _semester,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Semester',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    items: [for (var s = 1; s <= 14; s++) s]
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text('Sem $s')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _semester = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionTitle('Nilai'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ModeInputNilai>(
                segments: const [
                  ButtonSegment(
                    value: ModeInputNilai.angka,
                    label: Text('Nilai Angka'),
                  ),
                  ButtonSegment(
                    value: ModeInputNilai.huruf,
                    label: Text('Nilai Huruf'),
                  ),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() {
                  _mode = s.first;
                  _hurufError = false;
                }),
              ),
            ),
            const SizedBox(height: 14),
            if (_mode == ModeInputNilai.angka)
              TextFormField(
                controller: _angkaCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  // Hanya mengizinkan angka, koma, dan titik
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Nilai Angka (0–100)',
                  hintText: 'Contoh: 87.5',
                  prefixIcon: Icon(Icons.grade_outlined),
                ),
                validator: (v) {
                  final teks = (v ?? '').trim();
                  if (teks.isEmpty) return 'Nilai angka wajib diisi';
                  
                  final n = _parseAngka(teks);
                  if (n == null) return 'Masukkan angka yang valid (contoh: 85.5)';
                  
                  // Validasi batas angka 0 sampai 100
                  if (n < 0 || n > 100) return 'Nilai maksimal 100 dan minimal 0';
                  
                  return null;
                },
              )
            else
              _buildPilihanHuruf(),
            const SizedBox(height: 14),
            _buildPreview(preview),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _simpan,
                icon: Icon(
                  _isEdit
                      ? Icons.save_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 20,
                ),
                label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Nilai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPilihanHuruf() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NilaiModel.daftarHuruf.map((h) {
            final warna = Color(NilaiModel.colorFromHuruf(h));
            return ChoiceChip(
              label: Text(
                '$h  (${NilaiModel.hurufKeBobot(h).toStringAsFixed(1)})',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: _huruf == h ? warna : AppTheme.textSecondary,
                ),
              ),
              selected: _huruf == h,
              selectedColor: warna.withValues(alpha: 0.15),
              showCheckmark: false,
              onSelected: (_) => setState(() {
                _huruf = h;
                _hurufError = false;
              }),
            );
          }).toList(),
        ),
        if (_hurufError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Pilih salah satu nilai huruf',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.errorRed,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreview(String? huruf) {
    final h = huruf; // variabel lokal agar tipe bisa dipromosikan ke non-null
    final ada = h != null;
    final warna = h != null ? Color(NilaiModel.colorFromHuruf(h)) : Colors.grey;
    final bobot = h != null ? NilaiModel.hurufKeBobot(h) : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ada ? warna.withValues(alpha: 0.07) : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ada ? warna.withValues(alpha: 0.25) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          NilaiBadge(huruf: h ?? '—'),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ada
                  ? 'Huruf $h • bobot ${bobot.toStringAsFixed(1)} × $_sks SKS '
                      '= ${formatAngka(bobot * _sks)} mutu'
                  : 'Isi nilai untuk melihat konversi huruf & bobot',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
