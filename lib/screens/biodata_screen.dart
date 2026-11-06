import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/katalog_mata_kuliah.dart';
import '../models/mahasiswa_model.dart';
import '../providers/akademik_provider.dart';
import '../utils/app_theme.dart';
import '../utils/ui_helpers.dart';
import '../widgets/common_widgets.dart';

/// Form biodata mahasiswa — dipakai untuk **tambah** (tanpa argumen) maupun
/// **edit** (isi [mahasiswa]). Pada mode edit, daftar nilai mahasiswa tidak
/// berubah; hanya biodata yang diperbarui.
class BiodataScreen extends StatefulWidget {
  const BiodataScreen({super.key, this.mahasiswa});

  /// Mahasiswa yang diedit. `null` berarti menambah mahasiswa baru.
  final MahasiswaModel? mahasiswa;

  @override
  State<BiodataScreen> createState() => _BiodataScreenState();
}

class _BiodataScreenState extends State<BiodataScreen> {
  static const List<String> _jenisKelaminList = ['Laki-laki', 'Perempuan'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nimCtrl;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _angkatanCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _teleponCtrl;
  late final TextEditingController _alamatCtrl;
  late final List<String> _jurusanList;

  late String _jurusan;
  late String _jenisKelamin;

  bool get _isEdit => widget.mahasiswa != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mahasiswa;
    _nimCtrl = TextEditingController(text: m?.nim ?? '');
    _namaCtrl = TextEditingController(text: m?.nama ?? '');
    _angkatanCtrl = TextEditingController(
      text: (m?.angkatan ?? DateTime.now().year).toString(),
    );
    _emailCtrl = TextEditingController(text: m?.email ?? '');
    _teleponCtrl = TextEditingController(text: m?.telepon ?? '');
    _alamatCtrl = TextEditingController(text: m?.alamat ?? '');

    // Jika jurusan tersimpan tidak ada di daftar bawaan, tetap tampilkan.
    _jurusanList = [...KatalogMataKuliah.daftarJurusan];
    final jurusanAwal = m?.jurusan;
    if (jurusanAwal != null && !_jurusanList.contains(jurusanAwal)) {
      _jurusanList.add(jurusanAwal);
    }
    _jurusan = jurusanAwal ?? _jurusanList.first;
    _jenisKelamin = m?.jenisKelamin ?? _jenisKelaminList.first;
  }

  @override
  void dispose() {
    _nimCtrl.dispose();
    _namaCtrl.dispose();
    _angkatanCtrl.dispose();
    _emailCtrl.dispose();
    _teleponCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<AkademikProvider>();
    final data = MahasiswaModel(
      id: widget.mahasiswa?.id,
      nim: _nimCtrl.text.trim(),
      nama: _namaCtrl.text.trim(),
      jurusan: _jurusan,
      angkatan: int.parse(_angkatanCtrl.text.trim()),
      jenisKelamin: _jenisKelamin,
      email: _emailCtrl.text.trim(),
      telepon: _teleponCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
    );

    final berhasil =
        _isEdit ? provider.perbaruiBiodata(data) : provider.tambahMahasiswa(data);

    if (!berhasil) {
      AppFeedback.gagal(context, 'Gagal menyimpan. NIM mungkin sudah terpakai.');
      return;
    }

    // Snackbar dipasang di ScaffoldMessenger tingkat aplikasi, jadi tetap
    // tampil di halaman sebelumnya setelah form ditutup.
    AppFeedback.sukses(
      context,
      _isEdit ? 'Biodata berhasil diperbarui' : 'Mahasiswa berhasil ditambahkan',
    );
    Navigator.of(context).pop(data.id);
  }

  @override
  Widget build(BuildContext context) {
    final int tahunSekarang = DateTime.now().year;
    final List<String> listTahun = List.generate(
      tahunSekarang - 2019 + 1,
      (index) => (2019 + index).toString(),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          GradientHeader(
            title: _isEdit ? 'Edit Biodata' : 'Tambah Mahasiswa',
            subtitle: _isEdit
                ? 'Perbarui informasi mahasiswa'
                : 'Lengkapi biodata mahasiswa baru',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Identitas Akademik'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nimCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10), // Batas maksimal 10 karakter
                      ],
                      decoration: const InputDecoration(
                        labelText: 'NIM',
                        hintText: 'Contoh: 2021000100',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) {
                        final nim = (v ?? '').trim();
                        if (nim.isEmpty) return 'NIM tidak boleh kosong';
                        if (nim.length != 10) return 'NIM harus persis 10 karakter'; // Validasi wajib 10
                        final terpakai = context
                            .read<AkademikProvider>()
                            .nimSudahTerpakai(nim, kecualiId: widget.mahasiswa?.id);
                        return terpakai ? 'NIM sudah terdaftar' : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _namaCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Hanya huruf dan spasi
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        hintText: 'Masukkan nama lengkap',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Nama tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      menuMaxHeight: 250, // Tambahkan baris ini agar dropdown memiliki scroll
                      initialValue: _jurusan,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Jurusan / Program Studi',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      borderRadius: BorderRadius.circular(14),
                      items: _jurusanList
                          .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _jurusan = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                    menuMaxHeight: 250, // Memunculkan scroll jika kepanjangan
                    value: listTahun.contains(_angkatanCtrl.text)
                        ? _angkatanCtrl.text
                        : tahunSekarang.toString(),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tahun Angkatan',
                      prefixIcon: Icon(Icons.event_note_outlined),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    items: listTahun
                        .map((tahun) => DropdownMenuItem(value: tahun, child: Text(tahun)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        _angkatanCtrl.text = v;
                      }
                    },
                  ),
                    const SizedBox(height: 22),
                    const SectionTitle('Jenis Kelamin'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: _jenisKelaminList
                            .map((j) => ButtonSegment(value: j, label: Text(j)))
                            .toList(),
                        selected: {_jenisKelamin},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) =>
                            setState(() => _jenisKelamin = s.first),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SectionTitle('Informasi Kontak'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        // Memblokir semua input huruf kapital
                        FilteringTextInputFormatter.deny(RegExp(r'[A-Z\s]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Alamat Email',
                        hintText: 'nama@gmail.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        final email = (v ?? '').trim();
                        if (email.isEmpty) return 'Email tidak boleh kosong';
                        
                        // Validasi wajib menggunakan @gmail.com
                        if (!email.endsWith('@gmail.com')) {
                          return 'Email harus menggunakan format @gmail.com';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _teleponCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Mengubah allow regex menjadi digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'No. Telepon (opsional)',
                        hintText: '0812xxxxxxxx',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) {
                        final telp = (v ?? '').trim();
                        if (telp.isEmpty) return null; 
                        if (telp.length < 8) return 'Nomor telepon terlalu pendek';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _alamatCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Domisili',
                        hintText: 'Jl. Contoh No. 1, Kota',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Alamat tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _simpan,
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: Text(
                          _isEdit ? 'Simpan Perubahan' : 'Simpan Mahasiswa',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
