import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

/// Format angka: bulat ditampilkan tanpa desimal (85), selain itu 1 desimal (85.5).
String formatAngka(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Notifikasi snackbar seragam di seluruh aplikasi.
class AppFeedback {
  AppFeedback._();

  static void sukses(BuildContext context, String pesan) =>
      _tampilkan(context, pesan, AppTheme.successGreen,
          Icons.check_circle_rounded);

  static void gagal(BuildContext context, String pesan) =>
      _tampilkan(context, pesan, AppTheme.errorRed, Icons.error_rounded);

  static void _tampilkan(
    BuildContext context,
    String pesan,
    Color warna,
    IconData ikon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(ikon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pesan,
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: warna,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}

/// Dialog konfirmasi. Mengembalikan `true` hanya bila pengguna menekan tombol aksi.
Future<bool> konfirmasi(
  BuildContext context, {
  required String judul,
  required String pesan,
  String labelAksi = 'Hapus',
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        judul,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: Text(
        pesan,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Batal',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorRed,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            labelAksi,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return hasil ?? false;
}
