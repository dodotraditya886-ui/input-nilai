import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mahasiswa_model.dart';

/// Kontrak penyimpanan data akademik.
///
/// Dipisahkan dari provider agar mudah diganti (mis. SQLite / API) dan agar
/// provider bisa diuji dengan storage palsu.
abstract class AkademikStorage {
  Future<List<MahasiswaModel>> muat();
  Future<void> simpan(List<MahasiswaModel> data);
}

/// Implementasi default: menyimpan seluruh data sebagai JSON di
/// `shared_preferences`, sehingga data tetap ada setelah aplikasi ditutup.
class SharedPrefsAkademikStorage implements AkademikStorage {
  static const String _key = 'akademik.mahasiswa.v1';

  @override
  Future<List<MahasiswaModel>> muat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => MahasiswaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Data rusak / format lama: mulai dari kosong daripada crash.
      debugPrint('Gagal memuat data akademik: $e');
      return [];
    }
  }

  @override
  Future<void> simpan(List<MahasiswaModel> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(data.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Gagal menyimpan data akademik: $e');
    }
  }
}
