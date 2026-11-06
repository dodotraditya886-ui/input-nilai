import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/mahasiswa_model.dart';
import '../models/nilai_model.dart';
import '../services/akademik_storage.dart';

/// Sumber kebenaran tunggal untuk seluruh data mahasiswa & nilai.
///
/// Semua layar membaca dari sini (via `Consumer` / `context.watch`) dan
/// mengubah data hanya lewat method di bawah. Setiap perubahan:
///   1. mengganti daftar secara immutable,
///   2. memanggil `notifyListeners()` → semua halaman (daftar, transkrip,
///      dashboard nilai, beranda) langsung ter-refresh, dan IPK dihitung ulang,
///   3. menyimpan ke storage secara berurutan di latar belakang.
///
/// Method yang bisa gagal karena aturan data (NIM/kode MK ganda, ID tidak
/// ditemukan) mengembalikan `bool` — `true` bila berhasil.
class AkademikProvider extends ChangeNotifier {
  AkademikProvider({AkademikStorage? storage})
      : _storage = storage ?? SharedPrefsAkademikStorage();

  final AkademikStorage _storage;

  List<MahasiswaModel> _daftar = const [];
  bool _isLoaded = false;
  bool _disposed = false;
  Future<void> _antrianSimpan = Future<void>.value();

  // ===========================================================================
  // Baca data
  // ===========================================================================

  /// `true` setelah data dari storage selesai dimuat.
  bool get isLoaded => _isLoaded;

  List<MahasiswaModel> get daftarMahasiswa => UnmodifiableListView(_daftar);

  int get jumlahMahasiswa => _daftar.length;

  /// Total seluruh entri mata kuliah di semua mahasiswa.
  int get totalMataKuliah =>
      _daftar.fold(0, (sum, m) => sum + m.jumlahMataKuliah);

  /// Rata-rata IPK mahasiswa yang sudah punya nilai (0.0 bila belum ada).
  double get rataRataIpk {
    final punyaNilai = _daftar.where((m) => m.nilai.isNotEmpty).toList();
    if (punyaNilai.isEmpty) return 0.0;
    final total = punyaNilai.fold(0.0, (sum, m) => sum + m.ipk);
    return double.parse((total / punyaNilai.length).toStringAsFixed(2));
  }

  MahasiswaModel? cariById(String? id) {
    if (id == null) return null;
    for (final m in _daftar) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Apakah [nim] sudah dipakai mahasiswa lain? [kecualiId] dipakai saat edit
  /// agar mahasiswa itu sendiri tidak dianggap duplikat.
  bool nimSudahTerpakai(String nim, {String? kecualiId}) {
    final target = nim.trim();
    return _daftar.any((m) => m.nim == target && m.id != kecualiId);
  }

  /// Apakah [kodeMk] sudah ada pada nilai milik mahasiswa [mahasiswaId]?
  bool kodeMkSudahAda(
    String mahasiswaId,
    String kodeMk, {
    String? kecualiNilaiId,
  }) {
    final mhs = cariById(mahasiswaId);
    if (mhs == null) return false;
    final target = kodeMk.trim().toUpperCase();
    return mhs.nilai.any(
      (n) => n.kodeMk.toUpperCase() == target && n.id != kecualiNilaiId,
    );
  }

  // ===========================================================================
  // Muat data awal
  // ===========================================================================

  Future<void> muat() async {
    final data = await _storage.muat();
    if (_disposed) return;
    _daftar = List.unmodifiable(data);
    _isLoaded = true;
    notifyListeners();
  }

  // ===========================================================================
  // Mahasiswa: tambah / edit biodata / hapus
  // ===========================================================================

  bool tambahMahasiswa(MahasiswaModel mahasiswa) {
    if (nimSudahTerpakai(mahasiswa.nim)) return false;
    _terapkan([..._daftar, mahasiswa]);
    return true;
  }

  /// Memperbarui biodata. Daftar nilai milik mahasiswa **dipertahankan**
  /// (diambil dari data tersimpan, bukan dari [dataBaru]).
  bool perbaruiBiodata(MahasiswaModel dataBaru) {
    if (nimSudahTerpakai(dataBaru.nim, kecualiId: dataBaru.id)) return false;
    return _ubahMahasiswa(
      dataBaru.id,
      (lama) => dataBaru.copyWith(nilai: lama.nilai),
    );
  }

  bool hapusMahasiswa(String id) {
    if (cariById(id) == null) return false;
    _terapkan(_daftar.where((m) => m.id != id).toList());
    return true;
  }

  // ===========================================================================
  // Nilai mata kuliah (selalu terikat ke satu mahasiswa)
  // ===========================================================================

  bool tambahNilai(String mahasiswaId, NilaiModel nilai) {
    if (kodeMkSudahAda(mahasiswaId, nilai.kodeMk)) return false;
    return _ubahMahasiswa(
      mahasiswaId,
      (m) => m.copyWith(nilai: [...m.nilai, nilai]),
    );
  }

  bool perbaruiNilai(String mahasiswaId, NilaiModel nilai) {
    if (kodeMkSudahAda(mahasiswaId, nilai.kodeMk, kecualiNilaiId: nilai.id)) {
      return false;
    }
    final mhs = cariById(mahasiswaId);
    if (mhs == null || !mhs.nilai.any((n) => n.id == nilai.id)) return false;
    return _ubahMahasiswa(
      mahasiswaId,
      (m) => m.copyWith(
        nilai: m.nilai.map((n) => n.id == nilai.id ? nilai : n).toList(),
      ),
    );
  }

  bool hapusNilai(String mahasiswaId, String nilaiId) {
    final mhs = cariById(mahasiswaId);
    if (mhs == null || !mhs.nilai.any((n) => n.id == nilaiId)) return false;
    return _ubahMahasiswa(
      mahasiswaId,
      (m) => m.copyWith(
        nilai: m.nilai.where((n) => n.id != nilaiId).toList(),
      ),
    );
  }

  // ===========================================================================
  // Internal
  // ===========================================================================

  bool _ubahMahasiswa(
    String id,
    MahasiswaModel Function(MahasiswaModel lama) ubah,
  ) {
    final index = _daftar.indexWhere((m) => m.id == id);
    if (index < 0) return false;
    final baru = List<MahasiswaModel>.of(_daftar);
    baru[index] = ubah(baru[index]);
    _terapkan(baru);
    return true;
  }

  void _terapkan(List<MahasiswaModel> baru) {
    _daftar = List.unmodifiable(baru);
    notifyListeners();
    _jadwalkanSimpan();
  }

  /// Simpan berurutan: setiap penyimpanan menunggu yang sebelumnya selesai,
  /// sehingga data lama tidak pernah menimpa data yang lebih baru.
  void _jadwalkanSimpan() {
    final snapshot = _daftar;
    _antrianSimpan = _antrianSimpan
        .then((_) => _storage.simpan(snapshot))
        .catchError((Object e) {
      debugPrint('Penyimpanan gagal: $e');
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
