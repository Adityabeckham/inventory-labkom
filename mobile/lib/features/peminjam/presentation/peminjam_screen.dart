import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/form_feedback.dart';
import '../../../shared/widgets/search_field.dart';
import '../application/peminjam_controller.dart';
import '../domain/peminjam.dart';
import 'peminjam_form_sheet.dart';

/// FR-04 — Data Peminjam.
///
/// Mockup asli (Gambar 3.25) menampilkannya sebagai tabel. Di layar selebar
/// 375dp, tabel enam kolom memaksa scroll horizontal dan teksnya jadi terlalu
/// kecil, jadi datanya disusun sebagai kartu — informasinya persis sama.
class PeminjamScreen extends ConsumerWidget {
  const PeminjamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peminjam = ref.watch(peminjamListProvider);
    final cari = ref.watch(peminjamCariProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Peminjam'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryNavy,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.xl),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Tambah Peminjam'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: SearchField(
              hintText: 'Cari nama, NIS/NIP, atau kelas...',
              initialValue: cari,
              onChanged: (q) => ref.read(peminjamCariProvider.notifier).ubah(q),
            ),
          ),
          Expanded(
            child: AsyncView<List<Peminjam>>(
              value: peminjam,
              onRetry: () => ref.invalidate(peminjamListProvider),
              emptyMessage: cari.isEmpty
                  ? 'Belum ada data peminjam.'
                  : 'Tidak ada peminjam yang cocok dengan pencarian.',
              builder: (list) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  0,
                  AppSpacing.screenMargin,
                  AppSpacing.xxxl * 2,
                ),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.navyTint.withAlpha(128),
                      ),
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('Nama Peminjam')),
                        DataColumn(label: Text('Identitas & Kelas')),
                        DataColumn(label: Text('No HP')),
                        DataColumn(label: Text('Aksi')),
                      ],
                      rows: List.generate(list.length, (i) {
                        final p = list[i];
                        final identitas = [
                          if (p.nisNip?.isNotEmpty ?? false) p.nisNip!,
                          if (p.kelasJabatan?.isNotEmpty ?? false) p.kelasJabatan!,
                        ].join(' · ');

                        return DataRow(
                          cells: [
                            DataCell(Text('${i + 1}')),
                            DataCell(
                              Text(p.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataCell(
                              Text(
                                identitas.isNotEmpty ? identitas : '-',
                                style: AppTypography.code(color: AppColors.textMuted),
                              ),
                            ),
                            DataCell(
                              Text(
                                (p.noHp?.isNotEmpty ?? false) ? p.noHp! : '-',
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _form(context, ref, existing: p),
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Ubah data',
                                    color: AppColors.navy,
                                    iconSize: 20,
                                  ),
                                  IconButton(
                                    onPressed: () => _hapus(context, ref, p),
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Hapus peminjam',
                                    color: AppColors.crimson,
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _form(BuildContext context, WidgetRef ref, {Peminjam? existing}) async {
    final messenger = ScaffoldMessenger.of(context);
    final hasil = await PeminjamFormSheet.show(context, existing: existing);
    if (hasil == null) return;

    await jalankanAksi(messenger, () async {
      await ref.read(peminjamActionsProvider).simpan(
            id: existing?.id,
            nama: hasil.nama,
            nisNip: hasil.nisNip,
            kelasJabatan: hasil.kelasJabatan,
            noHp: hasil.noHp,
          );
      return existing == null
          ? 'Peminjam ${hasil.nama} ditambahkan.'
          : 'Data ${hasil.nama} diperbarui.';
    });
  }

  Future<void> _hapus(BuildContext context, WidgetRef ref, Peminjam p) async {
    final messenger = ScaffoldMessenger.of(context);
    final yakin = await konfirmasiHapus(
      context,
      judul: 'Hapus peminjam?',
      pesan: '"${p.nama}" akan dihapus permanen. Kalau sudah punya riwayat '
          'peminjaman, penghapusan akan ditolak.',
    );
    if (!yakin) return;

    await jalankanAksi(messenger, () async {
      await ref.read(peminjamActionsProvider).hapus(p.id);
      return 'Peminjam ${p.nama} dihapus.';
    });
  }
}

