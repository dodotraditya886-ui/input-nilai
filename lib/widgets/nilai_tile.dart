import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/nilai_model.dart';
import '../utils/app_theme.dart';
import '../utils/ui_helpers.dart';
import 'common_widgets.dart';

/// Baris satu mata kuliah beserta nilainya.
/// [onTap] biasanya dipakai untuk mengedit; [onDelete] menampilkan tombol hapus.
class NilaiTile extends StatelessWidget {
  const NilaiTile({
    super.key,
    required this.nilai,
    this.onTap,
    this.onDelete,
    this.highlighted = false,
  });

  final NilaiModel nilai;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  /// Tandai tile yang sedang diedit.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final angka = nilai.nilaiAngka;
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted
                  ? AppTheme.primaryDeepPurple
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              NilaiBadge(huruf: nilai.nilaiHuruf),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nilai.namaMataKuliah,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        _info(nilai.kodeMk, Icons.qr_code_2_rounded),
                        _info('${nilai.jumlahSks} SKS', Icons.layers_outlined),
                        _info('Sem ${nilai.semester}',
                            Icons.calendar_month_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    angka != null ? formatAngka(angka) : nilai.nilaiHuruf,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDeepPurple,
                    ),
                  ),
                  Text(
                    '${formatAngka(nilai.nilaiMutu)} mutu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Hapus',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.errorRed, size: 22),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppTheme.textSecondary),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
