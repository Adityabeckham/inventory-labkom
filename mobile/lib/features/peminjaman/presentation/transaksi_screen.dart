import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_style.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/form_feedback.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../pengembalian/presentation/pengembalian_view.dart';
import '../application/peminjaman_controller.dart';
import '../domain/peminjaman.dart';
import 'peminjaman_detail_sheet.dart';
import 'peminjaman_form_sheet.dart';

/// Tab Transaksi — segmented control "Peminjaman | Pengembalian".
/// FR-05 dan FR-06, sesuai UIUX_Wireframe_dan_Flow.md §3.7 dan §3.9.
class TransaksiScreen extends ConsumerStatefulWidget {
  const TransaksiScreen({super.key});

  @override
  ConsumerState<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends ConsumerState<TransaksiScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _peminjamanBaru,
              icon: const Icon(Icons.add),
              label: const Text('Peminjaman Baru'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Peminjaman')),
                ButtonSegment(value: 1, label: Text('Pengembalian')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: _tab == 0
                ? const _PeminjamanView()
                : const PengembalianView(),
          ),
        ],
      ),
    );
  }

  Future<void> _peminjamanBaru() async {
    final messenger = ScaffoldMessenger.of(context);
    final hasil = await PeminjamanFormSheet.show(context);
    if (hasil == null) return;

    await jalankanAksi(messenger, () async {
      final p = await ref.read(peminjamanActionsProvider).ajukan(
            idPeminjam: hasil.idPeminjam,
            tanggalPinjam: hasil.tanggalPinjam,
            tanggalKembali: hasil.tanggalKembali,
            items: hasil.items,
          );
      return '${p.kode} diajukan dan menunggu verifikasi Kepala Program.';
    });
  }
}

// ── Daftar peminjaman ────────────────────────────────────────────────

class _PeminjamanView extends ConsumerWidget {
  const _PeminjamanView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(peminjamanFilterProvider);
    final daftar = ref.watch(peminjamanListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
          child: SearchField(
            hintText: 'Cari kode, nama peminjam, atau NIS...',
            initialValue: filter.cari,
            onChanged: (q) =>
                ref.read(peminjamanFilterProvider.notifier).cari(q),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        SizedBox(
          height: 40,
          child: _StatusChips(
            terpilih: filter.status,
            onPilih: (s) =>
                ref.read(peminjamanFilterProvider.notifier).pilihStatus(s),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        Expanded(
          child: AsyncView<List<Peminjaman>>(
            value: daftar,
            onRetry: () => ref.invalidate(peminjamanListProvider),
            emptyMessage: filter.cari.isEmpty && filter.status == null
                ? 'Belum ada transaksi peminjaman. Buat lewat tombol di bawah.'
                : 'Tidak ada transaksi yang cocok dengan filter ini.',
            builder: (list) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.xs,
                AppSpacing.screenMargin,
                AppSpacing.xxxl * 2,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
              itemBuilder: (context, i) => _PeminjamanCard(peminjaman: list[i]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip filter status. Urutannya mengikuti UIUX §3.7: tiga status dasar dari
/// mockup asli, dengan "Menunggu Verifikasi" sebagai tab tambahan.
class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.terpilih, required this.onPilih});

  final StatusPeminjaman? terpilih;
  final ValueChanged<StatusPeminjaman?> onPilih;

  static const _urutan = [
    StatusPeminjaman.menungguVerifikasi,
    StatusPeminjaman.dipinjam,
    StatusPeminjaman.dikembalikan,
    StatusPeminjaman.dibatalkan,
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      children: [
        _chip(context, label: 'Semua', aktif: terpilih == null, onTap: () => onPilih(null)),
        for (final s in _urutan)
          _chip(
            context,
            label: s.label,
            aktif: terpilih == s,
            onTap: () => onPilih(s),
          ),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool aktif,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: aktif,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.navy,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: aktif ? AppColors.onNavy : AppColors.neutralFg,
            ),
        showCheckmark: false,
      ),
    );
  }
}

class _PeminjamanCard extends StatelessWidget {
  const _PeminjamanCard({required this.peminjaman});

  final Peminjaman peminjaman;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = peminjaman;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => PeminjamanDetailSheet.show(context, id: p.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(p.kode, style: AppTypography.code())),
                  const SizedBox(width: AppSpacing.xs),
                  StatusPill(label: p.status.label, style: StatusStyle.of(p.status)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(p.namaPeminjam,
                  style: text.titleMedium, overflow: TextOverflow.ellipsis),
              if (p.identitasPeminjam.isNotEmpty)
                Text(p.identitasPeminjam,
                    style: AppTypography.code(color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${p.jumlahItem} jenis · ${p.totalUnit} unit · '
                'pinjam ${p.tanggalPinjam} · tempo ${p.tanggalKembali}',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
