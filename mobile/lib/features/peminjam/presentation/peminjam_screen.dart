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
      appBar: AppBar(title: const Text('Data Peminjam')),
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
              builder: (list) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  0,
                  AppSpacing.screenMargin,
                  AppSpacing.xxxl * 2,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
                itemBuilder: (context, i) => _PeminjamCard(
                  peminjam: list[i],
                  nomor: i + 1,
                  onEdit: () => _form(context, ref, existing: list[i]),
                  onHapus: () => _hapus(context, ref, list[i]),
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

class _PeminjamCard extends StatelessWidget {
  const _PeminjamCard({
    required this.peminjam,
    required this.nomor,
    required this.onEdit,
    required this.onHapus,
  });

  final Peminjam peminjam;
  final int nomor;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.navyTint,
              foregroundColor: AppColors.navy,
              child: Text('$nomor', style: text.labelLarge?.copyWith(
                color: AppColors.navy,
              )),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(peminjam.nama, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    [
                      if (peminjam.nisNip?.isNotEmpty ?? false) peminjam.nisNip!,
                      if (peminjam.kelasJabatan?.isNotEmpty ?? false)
                        peminjam.kelasJabatan!,
                    ].join(' · '),
                    style: AppTypography.code(color: AppColors.textMuted),
                  ),
                  if (peminjam.noHp?.isNotEmpty ?? false)
                    Text(peminjam.noHp!, style: text.bodySmall),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah data',
              color: AppColors.navy,
            ),
            IconButton(
              onPressed: onHapus,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus peminjam',
              color: AppColors.crimson,
            ),
          ],
        ),
      ),
    );
  }
}
