import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../peminjaman/domain/peminjaman.dart';
import '../application/pengembalian_controller.dart';
import '../domain/pengembalian.dart';

@immutable
class PengembalianFormResult {
  const PengembalianFormResult({
    required this.idDetail,
    required this.kondisi,
    required this.tanggal,
  });

  final int idDetail;
  final KondisiBarang kondisi;
  final String tanggal;
}

/// FR-06 — form pengembalian satu item (UIUX §3.9).
///
/// Jumlah unit ditampilkan sebagai teks TETAP, bukan field. Tabel
/// `pengembalian` tidak punya kolom jumlah dan `id_detail`-nya UNIQUE (D-03),
/// jadi "2 dari 3 unit kembali" tidak punya tempat penyimpanan — field yang
/// bisa diubah hanya akan menjanjikan sesuatu yang tidak bisa dipenuhi.
///
/// Angka denda di sini PRATINJAU, dihitung dari tarif berjalan. Angka yang
/// mengikat tetap yang dihitung dan disimpan backend saat dicatat.
class PengembalianFormSheet extends ConsumerStatefulWidget {
  const PengembalianFormSheet({
    required this.item,
    required this.kodePeminjaman,
    required this.jatuhTempo,
    super.key,
  });

  final PeminjamanItem item;
  final String kodePeminjaman;
  final String jatuhTempo;

  static Future<PengembalianFormResult?> show(
    BuildContext context, {
    required PeminjamanItem item,
    required String kodePeminjaman,
    required String jatuhTempo,
  }) {
    return showModalBottomSheet<PengembalianFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => PengembalianFormSheet(
        item: item,
        kodePeminjaman: kodePeminjaman,
        jatuhTempo: jatuhTempo,
      ),
    );
  }

  @override
  ConsumerState<PengembalianFormSheet> createState() =>
      _PengembalianFormSheetState();
}

class _PengembalianFormSheetState extends ConsumerState<PengembalianFormSheet> {
  late DateTime _tanggal;
  KondisiBarang _kondisi = KondisiBarang.baik;

  @override
  void initState() {
    super.initState();
    final kini = DateTime.now();
    _tanggal = DateTime(kini.year, kini.month, kini.day);
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Selisih hari dari jatuh tempo, 0 kalau tepat waktu atau lebih awal.
  /// Rumusnya sama dengan backend (§3.7) supaya pratinjau tidak menyesatkan.
  int get _hariTelat {
    final tempo = DateTime.tryParse(widget.jatuhTempo);
    if (tempo == null) return 0;

    final selisih = _tanggal.difference(DateTime(tempo.year, tempo.month, tempo.day)).inDays;
    return selisih > 0 ? selisih : 0;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tarif = ref.watch(tarifDendaProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenMargin,
        right: AppSpacing.screenMargin,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kembalikan Barang', style: text.headlineMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text('${widget.kodePeminjaman} · jatuh tempo ${widget.jatuhTempo}',
                style: AppTypography.code(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.neutralBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.namaBarang, style: text.titleMedium),
                  Text(widget.item.kodeBarang,
                      style: AppTypography.code(color: AppColors.textMuted)),
                  const SizedBox(height: AppSpacing.xxs),
                  // Teks tetap, bukan field — lihat catatan kelas di atas.
                  Text('Dikembalikan ${widget.item.jumlahPinjam} unit sekaligus',
                      style: text.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            InkWell(
              onTap: () async {
                final dipilih = await showDatePicker(
                  context: context,
                  initialDate: _tanggal,
                  firstDate: DateTime(_tanggal.year - 1),
                  lastDate: DateTime(_tanggal.year + 1),
                );
                if (dipilih != null) setState(() => _tanggal = dipilih);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal pengembalian',
                  prefixIcon: Icon(Icons.event_available_outlined),
                ),
                child: Text(_iso(_tanggal), style: AppTypography.code()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Kondisi barang', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<KondisiBarang>(
              segments: const [
                ButtonSegment(
                  value: KondisiBarang.baik,
                  label: Text('Baik'),
                  icon: Icon(Icons.check_circle_outline),
                ),
                ButtonSegment(
                  value: KondisiBarang.rusak,
                  label: Text('Rusak'),
                  icon: Icon(Icons.report_problem_outlined),
                ),
              ],
              selected: {_kondisi},
              onSelectionChanged: (s) => setState(() => _kondisi = s.first),
            ),
            if (_kondisi == KondisiBarang.rusak) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Barang rusak tetap masuk kembali ke stok. Untuk mengeluarkannya '
                'dari inventaris, catat mutasi keluar lewat Aset Lab.',
                style: text.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            tarif.when(
              loading: () => const _DendaMemuat(),
              error: (e, _) => _DendaTidakDiketahui(pesan: '$e'),
              data: (t) => _PratinjauDenda(
                hariTelat: _hariTelat,
                tarifPerHari: t.tarifPerHari,
                terkonfigurasi: t.terkonfigurasi,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                PengembalianFormResult(
                  idDetail: widget.item.idDetail,
                  kondisi: _kondisi,
                  tanggal: _iso(_tanggal),
                ),
              ),
              child: const Text('Konfirmasi Pengembalian'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rincian denda, read-only — dihitung sistem, bukan diisi Laboran (FR-06).
class _PratinjauDenda extends StatelessWidget {
  const _PratinjauDenda({
    required this.hariTelat,
    required this.tarifPerHari,
    required this.terkonfigurasi,
  });

  final int hariTelat;
  final double tarifPerHari;
  final bool terkonfigurasi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final telat = hariTelat > 0;
    final denda = hariTelat * tarifPerHari;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: telat ? AppColors.dangerBg : AppColors.successBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: telat ? AppColors.dangerBorder : AppColors.successBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                telat ? Icons.warning_amber_outlined : Icons.verified_outlined,
                color: telat ? AppColors.dangerFg : AppColors.successFg,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  telat
                      ? 'Terlambat $hariTelat hari'
                      : 'Tepat waktu, tidak ada denda',
                  style: text.titleMedium?.copyWith(
                    color: telat ? AppColors.dangerFg : AppColors.successFg,
                  ),
                ),
              ),
            ],
          ),
          if (telat) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('$hariTelat hari × ${rupiah(tarifPerHari)} per hari',
                style: text.bodySmall),
            Text(rupiah(denda), style: text.displayLarge?.copyWith(
                  color: AppColors.dangerFg,
                  fontSize: 24,
                )),
          ],
          if (!terkonfigurasi) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tarif denda belum diatur, jadi dendanya dihitung nol. Atur dulu '
              'lewat Dashboard → Pengaturan Denda kalau lab memang mendendai '
              'keterlambatan.',
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _DendaMemuat extends StatelessWidget {
  const _DendaMemuat();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Menghitung denda...',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Tarif gagal dimuat. Pengembalian tetap boleh dilanjutkan — dendanya
/// dihitung backend, jadi kegagalan di sini hanya menghilangkan pratinjaunya.
class _DendaTidakDiketahui extends StatelessWidget {
  const _DendaTidakDiketahui({required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pendingBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.pendingBorder),
      ),
      child: Text(
        'Tarif denda tidak bisa dimuat, jadi dendanya belum bisa ditampilkan '
        'di sini. Pengembalian tetap bisa dilanjutkan — angkanya dihitung '
        'server dan muncul setelah tersimpan.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
