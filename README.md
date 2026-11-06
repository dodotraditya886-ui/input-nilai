# AkademikKu

Aplikasi Flutter untuk mengelola biodata mahasiswa dan nilai mata kuliah, dengan
perhitungan IPK otomatis. Proyek UTS Pemrograman Mobile.

Login demo: username `admin`, password `123`.

## Fitur

- **Data Mahasiswa** — daftar semua mahasiswa dengan status akademik (IPK, total SKS,
  total nilai mutu, predikat). Ada pencarian, pengurutan, dan tampilan kartu / tabel.
- **Tambah & Edit Biodata** — NIM (unik), nama, jurusan, angkatan, jenis kelamin,
  email, telepon, alamat. Mengedit biodata tidak menghapus nilai.
- **Dashboard Input Nilai** — pilih mahasiswa → lihat ringkasan IPK → tambah / edit /
  hapus mata kuliah (kode, nama, SKS, semester, nilai **angka** atau **huruf**).
  IPK langsung dihitung ulang.
- **Transkrip** — biodata + nilai per semester lengkap dengan IP semester. Geser untuk
  menghapus, ketuk untuk mengedit.
- Data **tersimpan permanen** di perangkat (`shared_preferences`).

## Arsitektur

```
lib/
├── main.dart                     MultiProvider + MaterialApp
├── models/
│   ├── nilai_model.dart          Nilai 1 MK + skala nilai + rumus IP (immutable)
│   └── mahasiswa_model.dart      Biodata + daftar nilai; IPK/SKS/mutu = getter turunan
├── providers/
│   ├── akademik_provider.dart    Satu-satunya sumber data mahasiswa & nilai (CRUD)
│   └── auth_provider.dart        Status login
├── services/
│   └── akademik_storage.dart     Kontrak penyimpanan + implementasi shared_preferences
├── screens/                      Splash, Login, Home, MahasiswaList, Biodata,
│                                 InputNilai (dashboard), Transkrip, Profile
├── widgets/                      Komponen reusable (kartu mahasiswa, form nilai, dll.)
└── utils/                        Tema, helper UI, generator ID
```

Prinsip utama:

- **Satu sumber kebenaran.** Semua layar membaca dari `AkademikProvider` lewat
  `Consumer` / `context.watch`; perubahan di satu halaman otomatis tampil di halaman lain.
- **IPK tidak pernah disimpan**, selalu dihitung dari daftar nilai, sehingga tidak bisa
  tidak sinkron.
- **Model immutable**; provider mengganti daftar secara utuh pada setiap perubahan.
- Aturan data (NIM unik, kode MK unik per mahasiswa) ditegakkan di provider, bukan hanya
  di form.

## Skala nilai

| Angka  | Huruf | Bobot |
|--------|-------|-------|
| ≥ 85   | A     | 4.0   |
| 75–84  | B     | 3.0   |
| 65–74  | C     | 2.0   |
| 55–64  | D     | 1.0   |
| < 55   | E     | 0.0   |

`IPK = Σ(bobot × SKS) / Σ SKS`. Untuk mengubah skala, edit `NilaiModel` — cukup satu tempat.

## Menjalankan

```bash
flutter pub get
flutter run
flutter test      # unit test model & provider
```
