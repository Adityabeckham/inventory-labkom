import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_style.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/form_feedback.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/peminjaman_controller.dart';
import '../domain/peminjaman.dart';

/// Rincian satu transaksi peminjaman.
///
/// Dipakai dua layar: Transaksi (Laboran, baca saja) dan Verifikasi (Kepala
/// Program, dengan tombol Setujui/Tolak). Tombolnya dikendalikan
/// [bolehVerifikasi] — penjaga sesungguhnya tetap di backend, yang menolak
/// PATCH dari level yang tidak berhak.
class PeminjamanDetailSheet extends ConsumerWidget {
  const PeminjamanDetailSheet({
    required this.id,
    this.bolehVerifikasi = false,
    super.key,
  });

  final int id;
  final bool bolehVerifikasi;

  static Future<void> show(
    BuildContext context, {
    required int id,
    bool bolehVerifikasi = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => PeminjamanDetailSheet(
        id: id,
        bolehVerifikasi: bolehVerifikasi,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(peminjamanDetailProvider(id));

    return Padding
      (
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: SizedBox(
        // Sheet tidak boleh menutupi seluruh layar; sisakan konteks di atasnya.
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: AsyncView<Peminjaman>(
          value: detail,
          onRetry: () => ref.invalidate(peminjamanDetailProvider(id)),
          builder: (p) => _Isi(peminjaman: p, bolehVerifikasi: bolehVerifikasi),
        ),
      ),
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.peminjaman, required this.bolehVerifikasi});

  final Peminjaman peminjaman;
  final bool bolehVerifikasi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final p = peminjaman;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(p.kode, style: text.headlineMedium),
            ),
            const SizedBox(width: AppSpacing.xs),
            StatusPill(label: p.status.label, style: StatusStyle.of(p.status)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        _baris(text, 'Peminjam', p.namaPeminjam,
            catatan: p.identitasPeminjam.isEmpty ? null : p.identitasPeminjam),
        _baris(text, 'Dicatat oleh', p.dicatatOleh),
        _baris(text, 'Tanggal pinjam', p.tanggalPinjam, kode: true),
        _baris(text, 'Jatuh tempo', p.tanggalKembali, kode: true),

        if (p.alasanDibatalkan != null && p.alasanDibatalkan!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.dangerBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alasan ditolak',
                    style: text.labelMedium?.copyWith(color: AppColors.dangerFg)),
                const SizedBox(height: AppSpacing.xxs),
                Text(p.alasanDibatalkan!, style: text.bodyLarge),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: Text('Barang dipinjam', style: text.titleMedium)),
            Text('${p.jumlahItem} jenis · ${p.totalUnit} unit',
                style: text.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        Expanded(
          child: ListView.separated(
            itemCount: p.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final item = p.items[i];
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.namaBarang,
                                style: text.titleMedium,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              item.merk == null || item.merk!.isEmpty
                                  ? item.kodeBarang
                                  : '${item.kodeBarang} · ${item.merk}',
                              style: AppTypography.code(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      StatusPill(
                        label: '${item.jumlahPinjam} unit',
                        style: StatusStyle.kategori,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        if (bolehVerifikasi && p.menungguVerifikasi) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _tolak(context, ref, p),
                  icon: const Icon(Icons.close),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.crimson,
                    side: const BorderSide(color: AppColors.crimson),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _setujui(context, ref, p),
                  icon: const Icon(Icons.check),
                  label: const Text('Setujui'),
                ),
              ),
            ],
          ),
        ] else if (bolehVerifikasi) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pengajuan ini sudah berstatus "${p.status.label}" dan tidak bisa '
            'diverifikasi lagi.',
            style: text.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _baris(
    TextTheme text,
    String label,
    String nilai, {
    String? catatan,
    bool kode = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: text.bodySmall),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nilai, style: kode ? AppTypography.code() : text.bodyLarge),
                if (catatan != null)
                  Text(catatan,
                      style: AppTypography.code(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setujui(BuildContext context, WidgetRef ref, Peminjaman p) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui pengajuan?'),
        content: Text(
          '${p.kode} untuk ${p.namaPeminjam} akan berstatus "Dipinjam". '
          'Stok barangnya sudah berkurang sejak pengajuan dibuat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    final berhasil = await jalankanAksi(messenger, () async {
      await ref.read(peminjamanActionsProvider).setujui(p.id);
      return '${p.kode} disetujui dan tercatat dipinjam.';
    });

    if (berhasil && navigator.canPop()) navigator.pop();
  }

  Future<void> _tolak(BuildContext context, WidgetRef ref, Peminjaman p) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final alasan = await _tanyaAlasan(context, p);
    if (alasan == null) return;

    final berhasil = await jalankanAksi(messenger, () async {
      await ref.read(peminjamanActionsProvider).tolak(p.id, alasan);
      return '${p.kode} ditolak dan stok barang dipulihkan.';
    });

    if (berhasil && navigator.canPop()) navigator.pop();
  }

  /// Alasan wajib diisi — backend menolak reject tanpa alasan, dan alasannya
  /// yang nanti dibaca Laboran untuk tahu kenapa pengajuannya dibatalkan.
  Future<String?> _tanyaAlasan(BuildContext context, Peminjaman p) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak pengajuan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stok barang pada ${p.kode} akan dipulihkan otomatis.',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: controller,
                autofocus: true,
                maxLength: 255,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alasan penolakan',
                  hintText: 'mis. Barang sedang dipakai praktik kelas XII',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Alasan wajib diisi'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(dialogContext).pop(controller.text.trim());
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}
