import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_uts/data/katalog_mata_kuliah.dart';
import 'package:project_uts/models/mahasiswa_model.dart';
import 'package:project_uts/models/nilai_model.dart';
import 'package:project_uts/providers/akademik_provider.dart';
import 'package:project_uts/services/akademik_storage.dart';

/// Storage palsu di memori; menyimpan sebagai JSON agar serialisasi ikut teruji.
class FakeStorage implements AkademikStorage {
  String? raw;

  @override
  Future<List<MahasiswaModel>> muat() async {
    final data = raw;
    if (data == null) return [];
    return (jsonDecode(data) as List<dynamic>)
        .map((e) => MahasiswaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> simpan(List<MahasiswaModel> data) async {
    raw = jsonEncode(data.map((m) => m.toJson()).toList());
  }
}

MahasiswaModel buatMahasiswa({String nim = '20210001', String nama = 'Budi Santoso'}) {
  return MahasiswaModel(
    nim: nim,
    nama: nama,
    jurusan: 'Teknik Informatika',
    angkatan: 2021,
    email: 'budi@mail.com',
    alamat: 'Jl. Merdeka 1',
  );
}

NilaiModel buatNilai(String kode, int sks, String huruf, {int semester = 1}) {
  return NilaiModel.dariHuruf(
    kodeMk: kode,
    namaMataKuliah: 'MK $kode',
    jumlahSks: sks,
    nilaiHuruf: huruf,
    semester: semester,
  );
}

void main() {
  katalogTests();

  group('NilaiModel', () {
    test('konversi angka ke huruf mengikuti batas nilai', () {
      expect(NilaiModel.hitungNilaiHuruf(100), 'A');
      expect(NilaiModel.hitungNilaiHuruf(85), 'A');
      expect(NilaiModel.hitungNilaiHuruf(84.9), 'B');
      expect(NilaiModel.hitungNilaiHuruf(75), 'B');
      expect(NilaiModel.hitungNilaiHuruf(65), 'C');
      expect(NilaiModel.hitungNilaiHuruf(55), 'D');
      expect(NilaiModel.hitungNilaiHuruf(54.9), 'E');
      expect(NilaiModel.hitungNilaiHuruf(0), 'E');
    });

    test('bobot & nilai mutu diturunkan dari huruf dan SKS', () {
      final n = buatNilai('IF101', 3, 'B');
      expect(n.bobotNilai, 3.0);
      expect(n.nilaiMutu, 9.0);
    });

    test('dariAngka menyimpan angka dan menghitung huruf', () {
      final n = NilaiModel.dariAngka(
        kodeMk: 'IF102',
        namaMataKuliah: 'Basis Data',
        jumlahSks: 4,
        nilaiAngka: 88.5,
        semester: 2,
      );
      expect(n.nilaiHuruf, 'A');
      expect(n.nilaiAngka, 88.5);
      expect(n.nilaiMutu, 16.0);
    });

    test('ID yang dibuat berurutan tidak pernah bentrok', () {
      final ids = List.generate(500, (_) => buatNilai('X', 1, 'A').id).toSet();
      expect(ids.length, 500);
    });

    test('toJson / fromJson round-trip', () {
      final n = NilaiModel.dariAngka(
        kodeMk: 'IF1',
        namaMataKuliah: 'Algoritma',
        jumlahSks: 3,
        nilaiAngka: 77,
        semester: 1,
      );
      final salinan = NilaiModel.fromJson(n.toJson());
      expect(salinan.id, n.id);
      expect(salinan.nilaiHuruf, 'B');
      expect(salinan.nilaiAngka, 77);
    });
  });

  group('MahasiswaModel', () {
    test('IPK 0 dan predikat netral bila belum ada nilai', () {
      final m = buatMahasiswa();
      expect(m.ipk, 0.0);
      expect(m.totalSks, 0);
      expect(m.totalMutu, 0.0);
      expect(m.predikat, 'Belum ada nilai');
    });

    test('IPK = Σ(bobot×SKS) / ΣSKS', () {
      // A (3 SKS) = 12, B (2 SKS) = 6 → 18 / 5 = 3.6
      final m = buatMahasiswa().copyWith(nilai: [
        buatNilai('A1', 3, 'A'),
        buatNilai('B1', 2, 'B'),
      ]);
      expect(m.totalSks, 5);
      expect(m.totalMutu, 18.0);
      expect(m.ipk, 3.6);
      expect(m.predikat, 'Cumlaude');
    });

    test('IPK dibulatkan 2 desimal', () {
      // A (1) = 4, B (2) = 6, C (4) = 8 → 18/7 = 2.5714…
      final m = buatMahasiswa().copyWith(nilai: [
        buatNilai('A1', 1, 'A'),
        buatNilai('B1', 2, 'B'),
        buatNilai('C1', 4, 'C'),
      ]);
      expect(m.ipk, 2.57);
    });

    test('inisial mengambil maksimal dua kata', () {
      expect(buatMahasiswa(nama: 'siti nur haliza').inisial, 'SN');
      expect(buatMahasiswa(nama: '  ').inisial, '?');
    });

    test('daftar semester terurut & nilai per semester', () {
      final m = buatMahasiswa().copyWith(nilai: [
        buatNilai('A', 3, 'A', semester: 3),
        buatNilai('B', 3, 'B', semester: 1),
        buatNilai('C', 2, 'C', semester: 3),
      ]);
      expect(m.daftarSemester, [1, 3]);
      expect(m.nilaiSemester(3).length, 2);
    });
  });

  group('AkademikProvider', () {
    late FakeStorage storage;
    late AkademikProvider provider;

    setUp(() {
      storage = FakeStorage();
      provider = AkademikProvider(storage: storage);
    });

    tearDown(() => provider.dispose());

    test('menambah mahasiswa dan menolak NIM ganda', () {
      expect(provider.tambahMahasiswa(buatMahasiswa()), isTrue);
      expect(provider.tambahMahasiswa(buatMahasiswa(nama: 'Lain')), isFalse);
      expect(provider.jumlahMahasiswa, 1);
    });

    test('edit biodata mempertahankan nilai & mengizinkan NIM sendiri', () {
      final m = buatMahasiswa();
      provider.tambahMahasiswa(m);
      provider.tambahNilai(m.id, buatNilai('A1', 3, 'A'));

      final diedit = m.copyWith(nama: 'Budi S.', jurusan: 'Sistem Informasi');
      expect(provider.perbaruiBiodata(diedit), isTrue);

      final hasil = provider.cariById(m.id)!;
      expect(hasil.nama, 'Budi S.');
      expect(hasil.jurusan, 'Sistem Informasi');
      expect(hasil.nilai.length, 1);
    });

    test('edit biodata ditolak bila NIM dipakai mahasiswa lain', () {
      final a = buatMahasiswa(nim: '11111');
      final b = buatMahasiswa(nim: '22222', nama: 'Dewi');
      provider.tambahMahasiswa(a);
      provider.tambahMahasiswa(b);
      expect(provider.perbaruiBiodata(b.copyWith(nim: '11111')), isFalse);
      expect(provider.cariById(b.id)!.nim, '22222');
    });

    test('nilai terikat ke mahasiswa yang dipilih & IPK dihitung ulang', () {
      final a = buatMahasiswa(nim: '11111');
      final b = buatMahasiswa(nim: '22222', nama: 'Dewi');
      provider.tambahMahasiswa(a);
      provider.tambahMahasiswa(b);

      provider.tambahNilai(a.id, buatNilai('M1', 3, 'A'));
      expect(provider.cariById(a.id)!.ipk, 4.0);
      expect(provider.cariById(b.id)!.nilai, isEmpty);

      provider.tambahNilai(a.id, buatNilai('M2', 3, 'C'));
      expect(provider.cariById(a.id)!.ipk, 3.0); // (12 + 6) / 6
    });

    test('kode MK ganda pada mahasiswa yang sama ditolak (case-insensitive)', () {
      final m = buatMahasiswa();
      provider.tambahMahasiswa(m);
      expect(provider.tambahNilai(m.id, buatNilai('IF101', 3, 'A')), isTrue);
      expect(provider.tambahNilai(m.id, buatNilai('if101', 3, 'B')), isFalse);
      expect(provider.cariById(m.id)!.nilai.length, 1);
    });

    test('kode MK yang sama boleh dipakai mahasiswa lain', () {
      final a = buatMahasiswa(nim: '11111');
      final b = buatMahasiswa(nim: '22222', nama: 'Dewi');
      provider.tambahMahasiswa(a);
      provider.tambahMahasiswa(b);
      expect(provider.tambahNilai(a.id, buatNilai('IF101', 3, 'A')), isTrue);
      expect(provider.tambahNilai(b.id, buatNilai('IF101', 3, 'B')), isTrue);
    });

    test('edit nilai memperbarui IPK; hapus nilai menghitung ulang', () {
      final m = buatMahasiswa();
      provider.tambahMahasiswa(m);
      final n1 = buatNilai('M1', 3, 'A');
      final n2 = buatNilai('M2', 3, 'E');
      provider.tambahNilai(m.id, n1);
      provider.tambahNilai(m.id, n2);
      expect(provider.cariById(m.id)!.ipk, 2.0); // 12 / 6

      final n2Baru = n2.copyWith(nilaiHuruf: 'B');
      expect(provider.perbaruiNilai(m.id, n2Baru), isTrue);
      expect(provider.cariById(m.id)!.ipk, 3.5); // 21 / 6

      expect(provider.hapusNilai(m.id, n2.id), isTrue);
      expect(provider.cariById(m.id)!.ipk, 4.0);
      expect(provider.hapusNilai(m.id, 'tidak-ada'), isFalse);
    });

    test('hapus mahasiswa menghapus nilainya & statistik global ikut turun', () {
      final a = buatMahasiswa(nim: '11111');
      final b = buatMahasiswa(nim: '22222', nama: 'Dewi');
      provider.tambahMahasiswa(a);
      provider.tambahMahasiswa(b);
      provider.tambahNilai(a.id, buatNilai('M1', 3, 'A')); // IPK 4.0
      provider.tambahNilai(b.id, buatNilai('M1', 3, 'C')); // IPK 2.0
      expect(provider.rataRataIpk, 3.0);
      expect(provider.totalMataKuliah, 2);

      expect(provider.hapusMahasiswa(a.id), isTrue);
      expect(provider.jumlahMahasiswa, 1);
      expect(provider.rataRataIpk, 2.0);
      expect(provider.totalMataKuliah, 1);
    });

    test('rata-rata IPK mengabaikan mahasiswa tanpa nilai', () {
      final a = buatMahasiswa(nim: '11111');
      final b = buatMahasiswa(nim: '22222', nama: 'Dewi');
      provider.tambahMahasiswa(a);
      provider.tambahMahasiswa(b);
      provider.tambahNilai(a.id, buatNilai('M1', 3, 'B'));
      expect(provider.rataRataIpk, 3.0);
    });

    test('setiap perubahan memanggil notifyListeners', () {
      var dipanggil = 0;
      provider.addListener(() => dipanggil++);
      final m = buatMahasiswa();
      provider.tambahMahasiswa(m);
      provider.tambahNilai(m.id, buatNilai('M1', 3, 'A'));
      provider.hapusMahasiswa(m.id);
      expect(dipanggil, 3);
    });

    test('data tersimpan lalu dimuat kembali oleh provider baru', () async {
      final m = buatMahasiswa();
      provider.tambahMahasiswa(m);
      provider.tambahNilai(m.id, buatNilai('M1', 3, 'A'));
      provider.tambahNilai(m.id, buatNilai('M2', 2, 'B', semester: 2));

      // beri waktu antrean penyimpanan selesai
      await Future<void>.delayed(Duration.zero);

      final baru = AkademikProvider(storage: storage);
      addTearDown(baru.dispose);
      expect(baru.isLoaded, isFalse);
      await baru.muat();

      expect(baru.isLoaded, isTrue);
      expect(baru.jumlahMahasiswa, 1);
      final hasil = baru.cariById(m.id)!;
      expect(hasil.nama, 'Budi Santoso');
      expect(hasil.nilai.length, 2);
      expect(hasil.ipk, 3.6);
    });
  });
}

void katalogTests() {
  group('KatalogMataKuliah', () {
    test('setiap jurusan punya mata kuliah 8 semester dengan SKS valid', () {
      expect(KatalogMataKuliah.daftarJurusan.length, 8);
      for (final j in KatalogMataKuliah.daftarJurusan) {
        final daftar = KatalogMataKuliah.untuk(j);
        expect(daftar, isNotEmpty, reason: j);
        expect(daftar.map((m) => m.semester).toSet(),
            {1, 2, 3, 4, 5, 6, 7, 8}, reason: j);
        expect(daftar.every((m) => m.sks >= 1 && m.sks <= 6), isTrue, reason: j);
        // kode unik dalam satu jurusan (syarat input nilai)
        expect(daftar.map((m) => m.kode).toSet().length, daftar.length,
            reason: j);
        expect(KatalogMataKuliah.totalSks(j),
            daftar.fold(0, (s, m) => s + m.sks));
      }
    });

    test('jurusan tidak dikenal menghasilkan daftar kosong', () {
      expect(KatalogMataKuliah.untuk('Jurusan Fiktif'), isEmpty);
    });
  });
}
