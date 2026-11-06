import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/akademik_provider.dart';
import '../utils/app_theme.dart';
import 'common_widgets.dart';

/// Bottom sheet untuk memilih mahasiswa (dengan pencarian nama / NIM / jurusan).
/// Menutup dirinya dengan mengembalikan ID mahasiswa yang dipilih.
class MahasiswaPickerSheet extends StatefulWidget {
  const MahasiswaPickerSheet({super.key, this.selectedId});

  final String? selectedId;

  @override
  State<MahasiswaPickerSheet> createState() => _MahasiswaPickerSheetState();
}

class _MahasiswaPickerSheetState extends State<MahasiswaPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final semua = context.watch<AkademikProvider>().daftarMahasiswa;
    final q = _query.trim().toLowerCase();
    final hasil = q.isEmpty
        ? semua.toList()
        : semua
            .where((m) =>
                m.nama.toLowerCase().contains(q) ||
                m.nim.toLowerCase().contains(q) ||
                m.jurusan.toLowerCase().contains(q))
            .toList();
    hasil.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih Mahasiswa',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Cari nama, NIM, atau jurusan',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: hasil.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Tidak ditemukan',
                      message: 'Tidak ada mahasiswa yang cocok dengan pencarian.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: hasil.length,
                      separatorBuilder: (_, __) => const Divider(indent: 68),
                      itemBuilder: (context, i) {
                        final m = hasil[i];
                        final dipilih = m.id == widget.selectedId;
                        return ListTile(
                          onTap: () => Navigator.pop(context, m.id),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryDeepPurple.withValues(alpha: 0.1),
                            child: Text(
                              m.inisial,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryDeepPurple,
                              ),
                            ),
                          ),
                          title: Text(
                            m.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${m.nim} • ${m.jurusan}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: dipilih
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppTheme.primaryDeepPurple)
                              : Text(
                                  m.nilai.isEmpty
                                      ? '–'
                                      : m.ipk.toStringAsFixed(2),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
