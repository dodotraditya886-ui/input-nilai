import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mahasiswa_model.dart';
import '../utils/app_theme.dart';
import '../utils/ui_helpers.dart';

/// Kartu satu mahasiswa pada daftar: identitas + status akademik (IPK, SKS,
/// total nilai mutu, jumlah MK) + menu aksi (edit, input nilai, hapus).
class MahasiswaCard extends StatelessWidget {
  const MahasiswaCard({
    super.key,
    required this.mahasiswa,
    required this.onTap,
    this.onEdit,
    this.onInputNilai,
    this.onDelete,
  });

  final MahasiswaModel mahasiswa;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onInputNilai;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final m = mahasiswa;
    final adaNilai = m.nilai.isNotEmpty;
    final warna = adaNilai ? AppTheme.warnaIpk(m.ipk) : AppTheme.textSecondary;

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: AppTheme.primaryDeepPurple.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        m.inisial,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${m.nim} • ${m.jurusan}',
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
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        adaNilai ? m.ipk.toStringAsFixed(2) : '–',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: warna,
                        ),
                      ),
                      Text(
                        'IPK',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        color: AppTheme.textSecondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          onEdit?.call();
                        case 'nilai':
                          onInputNilai?.call();
                        case 'hapus':
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (_) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit biodata')),
                      if (onInputNilai != null)
                        const PopupMenuItem(
                            value: 'nilai', child: Text('Input nilai')),
                      if (onDelete != null)
                        const PopupMenuItem(
                            value: 'hapus', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    _mini('SKS', m.totalSks.toString()),
                    _mini('Total Mutu', formatAngka(m.totalMutu)),
                    _mini('MK', m.jumlahMataKuliah.toString()),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: warna.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m.predikat,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: warna,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
