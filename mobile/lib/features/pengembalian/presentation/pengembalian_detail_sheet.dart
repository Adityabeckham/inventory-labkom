import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_style.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/form_feedback.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../peminjaman/application/peminjaman_controller.dart';
import '../../peminjaman/domain/peminjaman.dart';
import '../application/pengembalian_controller.dart';
import '../domain/pengembalian.dart';
import 'pengembalian_form_sheet.dart';

/// FR-06 — Detail Pengembalian: status per item, lalu form per item
/// (UIUX §3.9). Berbeda dari sheet rincian peminjaman yang hanya membaca.
class PengembalianDetailSheet extends ConsumerWidget {
  const PengembalianDetailSheet({required this.idPeminjaman, super.key});

  final int idPeminjaman;

  static Future<void> show(BuildContext context, {required int idPeminjaman}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => PengembalianDetailSheet(idPeminjaman: idPeminjaman),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(peminjamanDetailProvider(idPeminjaman));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: ConstrainedBox(
        // Batas atas, bukan tinggi tetap — alasan sama dengan sheet rincian
        // peminjaman: tinggi yang diturunkan dari layar tidak tahu-menahu
        // soal tinggi teks di dalamnya saat skala font dinaikkan.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: AsyncView<Peminjaman>(
          value: detail,
          onRetry: () => ref.invalidate(peminjamanDetailProvider(idPeminjaman)),
          builder: (p) => _Isi(peminjaman: p),
        ),
      ),
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.peminjaman});

  final Peminjaman peminjaman;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final p = peminjaman;
    final sisa = p.belumKembali.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(p.kode, style: text.headlineMedium)),
            const SizedBox(width: AppSpacing.xs),
            StatusPill(label: p.status.label, style: StatusStyle.of(p.status)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text('${p.namaPeminjam} · jatuh tempo ${p.tanggalKembali}',
            style: text.bodyMedium),
        const SizedBox(height: AppSpacing.md),

        if (p.totalDenda > 0)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.dangerBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: AppColors.dangerFg),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text('Total denda transaksi ini',
                      style: text.bodyMedium?.copyWith(color: AppColors.dangerFg)),
                ),
                Text(rupiah(p.totalDenda),
                    style: text.titleMedium?.copyWith(color: AppColors.dangerFg)),
              ],
            ),
          ),

        Row(
          children: [
            Expanded(child: Text('Barang', style: text.titleMedium)),
            Text(
              sisa == 0
                  ? 'Semua sudah kembali'
                  : '$sisa dari ${p.items.length} belum kembali',
              style: text.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in p.items)
                  _ItemCard(
                    item: item,
                    peminjaman: p,
                    onKembalikan: () => _kembalikan(context, ref, item),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _kembalikan(
    BuildContext context,
    WidgetRef ref,
    PeminjamanItem item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final hasil = await PengembalianFormSheet.show(
      context,
      item: item,
      kodePeminjaman: peminjaman.kode,
      jatuhTempo: peminjaman.tanggalKembali,
    );
    if (hasil == null) return;

    // Item terakhir: setelah ini transaksinya selesai, jadi sheet ditutup
    // supaya pengguna kembali ke daftar yang sudah berubah.
    final terakhir = peminjaman.belumKembali.length == 1;

    final berhasil = await jalankanAksi(messenger, () async {
      final pg = await ref.read(pengembalianActionsProvider).catat(
            idDetail: hasil.idDetail,
            kondisi: hasil.kondisi,
            tanggal: hasil.tanggal,
          );

      return pg.telat
          ? '${item.namaBarang} dikembalikan, telat ${pg.hariTelat} hari — '
              'denda ${rupiah(pg.denda)}.'
          : '${item.namaBarang} dikembalikan tepat waktu, tanpa denda.';
    });

    if (berhasil && terakhir && navigator.canPop()) navigator.pop();
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.peminjaman,
    required this.onKembalikan,
  });

  final PeminjamanItem item;
  final Peminjaman peminjaman;
  final VoidCallback onKembalikan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pg = item.pengembalian;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pg == null ? Icons.pending_outlined : Icons.check_circle_outline,
                  color: pg == null ? AppColors.pendingFg : AppColors.successFg,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.namaBarang,
                          style: text.titleMedium,
                          overflow: TextOverflow.ellipsis),
                      Text('${item.kodeBarang} · ${item.jumlahPinjam} unit',
                          style: AppTypography.code(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),

            if (pg == null) ...[
              const SizedBox(height: AppSpacing.xs),
              // Tombol hanya muncul kalau transaksinya memang boleh menerima
              // pengembalian; backend menolak sisanya dengan 409.
              if (peminjaman.bisaDikembalikan)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: onKembalikan,
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('Kembalikan'),
                  ),
                )
              else
                Text('Masih dipinjam.', style: text.bodySmall),
            ] else ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  StatusPill(
                    label: 'Kembali ${pg.tanggal}',
                    style: StatusStyle.tersedia,
                  ),
                  StatusPill(
                    label: pg.kondisi.label,
                    style: pg.kondisi == KondisiBarang.baik
                        ? StatusStyle.tersedia
                        : StatusStyle.kritis,
                  ),
                  if (pg.telat)
                    StatusPill(
                      label: 'Telat ${pg.hariTelat} hari · ${rupiah(pg.denda)}',
                      style: StatusStyle.kritis,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
