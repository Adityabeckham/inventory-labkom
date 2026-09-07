import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_style.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/pengembalian_controller.dart';
import '../domain/pengembalian.dart';
import 'pengembalian_detail_sheet.dart';

/// FR-06 — isi tab "Pengembalian" pada layar Transaksi (UIUX §3.9).
class PengembalianView extends ConsumerWidget {
  const PengembalianView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(pengembalianFilterProvider);
    final daftar = ref.watch(pengembalianListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
          child: SearchField(
            hintText: 'Cari kode, nama peminjam, atau NIS...',
            initialValue: filter.cari,
            onChanged: (q) =>
                ref.read(pengembalianFilterProvider.notifier).cari(q),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        SizedBox(
          height: 40,
          child: _TabChips(
            terpilih: filter.tab,
            onPilih: (t) =>
                ref.read(pengembalianFilterProvider.notifier).pilihTab(t),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        Expanded(
          child: AsyncView<List<TransaksiPengembalian>>(
            value: daftar,
            onRetry: () => ref.invalidate(pengembalianListProvider),
            emptyMessage: filter.cari.isEmpty && filter.tab == null
                ? 'Belum ada barang yang perlu dikembalikan. Peminjaman yang '
                    'sudah disetujui akan muncul di sini.'
                : 'Tidak ada transaksi yang cocok dengan filter ini.',
            builder: (list) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.xs,
                AppSpacing.screenMargin,
                AppSpacing.xxxl,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
              itemBuilder: (context, i) => _TransaksiCard(transaksi: list[i]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip tab. Ini SARINGAN yang bisa beririsan, bukan pembagian yang saling
/// lepas — satu transaksi bisa muncul di "Sebagian Kembali" sekaligus
/// "Terlambat" (§3.7.1). Badge di kartunya memilih satu, dengan Terlambat
/// menang; keputusan itu dibuat backend supaya tidak pernah berbeda.
class _TabChips extends StatelessWidget {
  const _TabChips({required this.terpilih, required this.onPilih});

  final StatusPengembalian? terpilih;
  final ValueChanged<StatusPengembalian?> onPilih;

  static const _urutan = [
    StatusPengembalian.belumKembali,
    StatusPengembalian.sebagianKembali,
    StatusPengembalian.sudahKembali,
    StatusPengembalian.terlambat,
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      children: [
        _chip(context, label: 'Semua', aktif: terpilih == null, onTap: () => onPilih(null)),
        for (final t in _urutan)
          _chip(
            context,
            label: t.label,
            aktif: terpilih == t,
            onTap: () => onPilih(t),
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

class _TransaksiCard extends StatelessWidget {
  const _TransaksiCard({required this.transaksi});

  final TransaksiPengembalian transaksi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = transaksi;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => PengembalianDetailSheet.show(
          context,
          idPeminjaman: t.idPeminjaman,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(t.kode, style: AppTypography.code())),
                  const SizedBox(width: AppSpacing.xs),
                  StatusPill(
                    label: t.tampilanStatus.label,
                    style: StatusStyle.ofPengembalian(t.tampilanStatus),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(t.namaPeminjam,
                  style: text.titleMedium, overflow: TextOverflow.ellipsis),
              if (t.identitasPeminjam.isNotEmpty)
                Text(t.identitasPeminjam,
                    style: AppTypography.code(color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                t.selesai
                    ? '${t.jumlahItem} jenis · semua sudah kembali'
                    : '${t.itemKembali} dari ${t.jumlahItem} jenis kembali · '
                        'tempo ${t.tanggalKembali}',
                style: text.bodySmall,
              ),
              if (t.totalDenda > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                StatusPill(
                  label: 'Denda ${rupiah(t.totalDenda)}',
                  style: StatusStyle.kritis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
