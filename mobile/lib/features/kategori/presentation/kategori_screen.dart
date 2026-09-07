import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/status_style.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/form_feedback.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/kategori_controller.dart';
import '../data/kategori.dart';

/// FR-03 — Kelola Kategori.
class KategoriScreen extends ConsumerWidget {
  const KategoriScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kategori = ref.watch(kategoriListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
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
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori'),
      ),
      body: AsyncView<List<Kategori>>(
        value: kategori,
        onRetry: () => ref.invalidate(kategoriListProvider),
        emptyMessage: 'Belum ada kategori. Tambahkan lewat tombol di bawah.',
        builder: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.screenMargin,
            AppSpacing.screenMargin,
            AppSpacing.xxxl * 2,
          ),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
          itemBuilder: (context, i) {
            final k = list[i];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xxs,
                ),
                leading: const Icon(Icons.category_outlined, color: AppColors.navy),
                title: Text(k.nama, style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text('${k.jumlahBarang} barang'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (k.jumlahBarang > 0)
                      const StatusPill(label: 'Dipakai', style: StatusStyle.kategori),
                    IconButton(
                      onPressed: () => _form(context, ref, existing: k),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Ubah nama',
                      color: AppColors.navy,
                    ),
                    IconButton(
                      onPressed: () => _hapus(context, ref, k),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Hapus kategori',
                      color: AppColors.crimson,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _form(BuildContext context, WidgetRef ref, {Kategori? existing}) async {
    final controller = TextEditingController(text: existing?.nama ?? '');
    final messenger = ScaffoldMessenger.of(context);

    final nama = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Tambah Kategori' : 'Ubah Kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama kategori',
            hintText: 'mis. Komputer',
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (nama == null || nama.isEmpty) return;

    await jalankanAksi(messenger, () async {
      final actions = ref.read(kategoriActionsProvider);
      if (existing == null) {
        await actions.tambah(nama);
        return 'Kategori $nama ditambahkan.';
      }
      await actions.ubah(existing.id, nama);
      return 'Kategori diubah jadi $nama.';
    });
  }

  Future<void> _hapus(BuildContext context, WidgetRef ref, Kategori k) async {
    final messenger = ScaffoldMessenger.of(context);
    final yakin = await konfirmasiHapus(
      context,
      judul: 'Hapus kategori?',
      pesan: k.jumlahBarang > 0
          ? '"${k.nama}" masih dipakai ${k.jumlahBarang} barang. '
              'Penghapusan akan ditolak selama barangnya belum dipindah.'
          : '"${k.nama}" akan dihapus permanen.',
    );
    if (!yakin) return;

    await jalankanAksi(messenger, () async {
      await ref.read(kategoriActionsProvider).hapus(k.id);
      return 'Kategori ${k.nama} dihapus.';
    });
  }
}
