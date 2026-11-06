import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/katalog_mata_kuliah.dart';
import '../utils/app_theme.dart';
import 'common_widgets.dart';

/// Bottom sheet pilihan mata kuliah dari katalog satu jurusan.
/// Mata kuliah yang sudah punya nilai ([sudahDiinput], berisi kode) ditandai
/// dan tidak bisa dipilih lagi. Mengembalikan [MataKuliahKatalog] terpilih.
class KatalogPickerSheet extends StatefulWidget {
  const KatalogPickerSheet({
    super.key,
    required this.jurusan,
    this.sudahDiinput = const {},
  });

  final String jurusan;
  final Set<String> sudahDiinput;

  @override
  State<KatalogPickerSheet> createState() => _KatalogPickerSheetState();
}

class _KatalogPickerSheetState extends State<KatalogPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final daftar = KatalogMataKuliah.untuk(widget.jurusan)
        .where((mk) =>
            q.isEmpty ||
            mk.nama.toLowerCase().contains(q) ||
            mk.kode.toLowerCase().contains(q))
        .toList();

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Katalog ${widget.jurusan}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Cari kode atau nama mata kuliah',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: daftar.isEmpty
                  ? const EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'Tidak Ada Mata Kuliah',
                      message:
                          'Katalog untuk jurusan ini kosong atau tidak cocok '
                          'dengan pencarian.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: daftar.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final mk = daftar[i];
                        final sudah = widget.sudahDiinput
                            .contains(mk.kode.toUpperCase());
                        return ListTile(
                          enabled: !sudah,
                          onTap: () => Navigator.pop(context, mk),
                          title: Text(
                            mk.nama,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                              '${mk.kode} • Semester ${mk.semester} • ${mk.sks} SKS'),
                          trailing: sudah
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppTheme.successGreen)
                              : const Icon(Icons.add_circle_outline_rounded,
                                  color: AppTheme.primaryDeepPurple),
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
