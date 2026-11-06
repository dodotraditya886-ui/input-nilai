import '../utils/id_generator.dart';

/// Nilai satu mata kuliah milik seorang mahasiswa.
///
/// Immutable. Bobot (4.0–0.0) dan nilai mutu (bobot × SKS) selalu diturunkan
/// dari [nilaiHuruf], sehingga tidak mungkin ada data yang tidak konsisten.
/// [nilaiAngka] bersifat opsional: null berarti nilai diinput langsung
/// dalam bentuk huruf.
class NilaiModel {
  const NilaiModel({
    required this.id,
    required this.kodeMk,
    required this.namaMataKuliah,
    required this.jumlahSks,
    required this.nilaiHuruf,
    required this.semester,
    this.nilaiAngka,
  });

  /// Buat nilai dari input angka (0–100); huruf dihitung otomatis.
  factory NilaiModel.dariAngka({
    String? id,
    required String kodeMk,
    required String namaMataKuliah,
    required int jumlahSks,
    required double nilaiAngka,
    required int semester,
  }) {
    return NilaiModel(
      id: id ?? generateId(),
      kodeMk: kodeMk,
      namaMataKuliah: namaMataKuliah,
      jumlahSks: jumlahSks,
      nilaiHuruf: hitungNilaiHuruf(nilaiAngka),
      nilaiAngka: nilaiAngka,
      semester: semester,
    );
  }

  /// Buat nilai dari input huruf langsung (A–E).
  factory NilaiModel.dariHuruf({
    String? id,
    required String kodeMk,
    required String namaMataKuliah,
    required int jumlahSks,
    required String nilaiHuruf,
    required int semester,
  }) {
    return NilaiModel(
      id: id ?? generateId(),
      kodeMk: kodeMk,
      namaMataKuliah: namaMataKuliah,
      jumlahSks: jumlahSks,
      nilaiHuruf: nilaiHuruf.toUpperCase(),
      semester: semester,
    );
  }

  factory NilaiModel.fromJson(Map<String, dynamic> json) {
    return NilaiModel(
      id: json['id'] as String,
      kodeMk: json['kodeMk'] as String,
      namaMataKuliah: json['namaMataKuliah'] as String,
      jumlahSks: (json['jumlahSks'] as num).toInt(),
      nilaiHuruf: (json['nilaiHuruf'] as String).toUpperCase(),
      nilaiAngka: (json['nilaiAngka'] as num?)?.toDouble(),
      semester: (json['semester'] as num).toInt(),
    );
  }

  final String id;
  final String kodeMk;
  final String namaMataKuliah;
  final int jumlahSks;
  final String nilaiHuruf;
  final double? nilaiAngka;
  final int semester;

  /// Bobot mutu dari huruf (A=4 … E=0).
  double get bobotNilai => hurufKeBobot(nilaiHuruf);

  /// Nilai mutu = bobot × SKS (komponen pembilang rumus IPK).
  double get nilaiMutu => bobotNilai * jumlahSks;

  NilaiModel copyWith({
    String? kodeMk,
    String? namaMataKuliah,
    int? jumlahSks,
    String? nilaiHuruf,
    double? nilaiAngka,
    int? semester,
  }) {
    return NilaiModel(
      id: id,
      kodeMk: kodeMk ?? this.kodeMk,
      namaMataKuliah: namaMataKuliah ?? this.namaMataKuliah,
      jumlahSks: jumlahSks ?? this.jumlahSks,
      nilaiHuruf: nilaiHuruf ?? this.nilaiHuruf,
      nilaiAngka: nilaiAngka ?? this.nilaiAngka,
      semester: semester ?? this.semester,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kodeMk': kodeMk,
        'namaMataKuliah': namaMataKuliah,
        'jumlahSks': jumlahSks,
        'nilaiHuruf': nilaiHuruf,
        'nilaiAngka': nilaiAngka,
        'semester': semester,
      };

  // ===========================================================================
  // Helper statis (skala nilai & rumus IP) — satu-satunya sumber kebenaran
  // ===========================================================================

  /// Pilihan huruf yang tersedia pada form.
  static const List<String> daftarHuruf = ['A', 'B', 'C', 'D', 'E'];

  /// Konversi nilai angka (0–100) ke huruf.
  static String hitungNilaiHuruf(double nilaiAngka) {
    if (nilaiAngka >= 85) return 'A';
    if (nilaiAngka >= 75) return 'B';
    if (nilaiAngka >= 65) return 'C';
    if (nilaiAngka >= 55) return 'D';
    return 'E';
  }

  /// Konversi huruf ke bobot mutu.
  static double hurufKeBobot(String huruf) {
    switch (huruf.toUpperCase()) {
      case 'A':
        return 4.0;
      case 'B':
        return 3.0;
      case 'C':
        return 2.0;
      case 'D':
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Warna badge (ARGB) berdasarkan huruf.
  static int colorFromHuruf(String huruf) {
    switch (huruf.toUpperCase()) {
      case 'A':
        return 0xFF2E7D32; // hijau tua
      case 'B':
        return 0xFF1565C0; // biru tua
      case 'C':
        return 0xFFF57C00; // oranye
      case 'D':
        return 0xFFB71C1C; // merah tua
      default:
        return 0xFF757575; // abu-abu
    }
  }

  /// Total SKS dari sekumpulan nilai.
  static int hitungSks(Iterable<NilaiModel> daftar) =>
      daftar.fold(0, (sum, n) => sum + n.jumlahSks);

  /// Indeks prestasi = Σ(bobot × SKS) / Σ SKS, dibulatkan 2 desimal.
  /// Mengembalikan 0.0 bila belum ada nilai.
  static double hitungIp(Iterable<NilaiModel> daftar) {
    var sks = 0;
    var mutu = 0.0;
    for (final n in daftar) {
      sks += n.jumlahSks;
      mutu += n.nilaiMutu;
    }
    if (sks == 0) return 0.0;
    return double.parse((mutu / sks).toStringAsFixed(2));
  }
}
