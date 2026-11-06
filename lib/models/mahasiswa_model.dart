import '../utils/id_generator.dart';
import 'nilai_model.dart';

/// Data seorang mahasiswa beserta seluruh nilai mata kuliahnya.
///
/// Immutable. Semua angka akademik (SKS, total mutu, IPK, predikat) adalah
/// *getter turunan* dari [nilai], jadi otomatis selalu benar setiap kali
/// daftar nilai berubah — tidak ada nilai IPK yang disimpan terpisah.
class MahasiswaModel {
  MahasiswaModel({
    String? id,
    required this.nim,
    required this.nama,
    required this.jurusan,
    required this.angkatan,
    this.jenisKelamin = 'Laki-laki',
    this.email = '',
    this.telepon = '',
    this.alamat = '',
    List<NilaiModel> nilai = const [],
  })  : id = id ?? generateId(),
        nilai = List.unmodifiable(nilai);

  factory MahasiswaModel.fromJson(Map<String, dynamic> json) {
    final rawNilai = json['nilai'] as List<dynamic>? ?? const [];
    return MahasiswaModel(
      id: json['id'] as String,
      nim: json['nim'] as String,
      nama: json['nama'] as String,
      jurusan: json['jurusan'] as String,
      angkatan: (json['angkatan'] as num).toInt(),
      jenisKelamin: json['jenisKelamin'] as String? ?? 'Laki-laki',
      email: json['email'] as String? ?? '',
      telepon: json['telepon'] as String? ?? '',
      alamat: json['alamat'] as String? ?? '',
      nilai: rawNilai
          .map((e) => NilaiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String nim;
  final String nama;
  final String jurusan;
  final int angkatan;
  final String jenisKelamin;
  final String email;
  final String telepon;
  final String alamat;
  final List<NilaiModel> nilai;

  // ===========================================================================
  // Status akademik (turunan dari daftar nilai)
  // ===========================================================================

  int get jumlahMataKuliah => nilai.length;

  /// Total SKS yang sudah ditempuh.
  int get totalSks => NilaiModel.hitungSks(nilai);

  /// Total nilai mutu = Σ(bobot × SKS).
  double get totalMutu => nilai.fold(0.0, (sum, n) => sum + n.nilaiMutu);

  /// IPK (0.0 bila belum ada nilai).
  double get ipk => NilaiModel.hitungIp(nilai);

  /// Predikat berdasarkan IPK.
  String get predikat {
    if (nilai.isEmpty) return 'Belum ada nilai';
    final v = ipk;
    if (v >= 3.51) return 'Cumlaude';
    if (v >= 3.01) return 'Sangat Memuaskan';
    if (v >= 2.76) return 'Memuaskan';
    if (v >= 2.00) return 'Cukup';
    return 'Perlu Perbaikan';
  }

  /// Daftar semester yang memiliki nilai, urut naik.
  List<int> get daftarSemester =>
      (nilai.map((n) => n.semester).toSet().toList()..sort());

  /// Nilai pada satu semester.
  List<NilaiModel> nilaiSemester(int semester) =>
      nilai.where((n) => n.semester == semester).toList();

  /// Inisial (maks. 2 huruf) untuk avatar.
  String get inisial {
    final bagian = nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    if (bagian.isEmpty) return '?';
    return bagian.map((p) => p[0].toUpperCase()).join();
  }

  MahasiswaModel copyWith({
    String? nim,
    String? nama,
    String? jurusan,
    int? angkatan,
    String? jenisKelamin,
    String? email,
    String? telepon,
    String? alamat,
    List<NilaiModel>? nilai,
  }) {
    return MahasiswaModel(
      id: id,
      nim: nim ?? this.nim,
      nama: nama ?? this.nama,
      jurusan: jurusan ?? this.jurusan,
      angkatan: angkatan ?? this.angkatan,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      email: email ?? this.email,
      telepon: telepon ?? this.telepon,
      alamat: alamat ?? this.alamat,
      nilai: nilai ?? this.nilai,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nim': nim,
        'nama': nama,
        'jurusan': jurusan,
        'angkatan': angkatan,
        'jenisKelamin': jenisKelamin,
        'email': email,
        'telepon': telepon,
        'alamat': alamat,
        'nilai': nilai.map((n) => n.toJson()).toList(),
      };
}
