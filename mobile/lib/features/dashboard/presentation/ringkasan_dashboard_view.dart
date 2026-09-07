import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../auth/application/auth_controller.dart';
import '../../pengembalian/domain/pengembalian.dart' show rupiah;
import '../application/dashboard_controller.dart';
import '../domain/ringkasan.dart';

/// Angka ringkasan Dashboard (FR-10).
///
/// Dipisah dari `DashboardScreen` supaya layarnya tetap terbaca dan supaya
/// bagian ini bisa diuji sendiri.
class RingkasanDashboardView extends ConsumerWidget {
  const RingkasanDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringkasan = ref.watch(ringkasanDashboardProvider);

    return switch (ringkasan) {
      AsyncData(:final value) => _Angka(ringkasan: value),
      AsyncError(:final error) => _Gagal(pesan: '$error'),
      _ => const _Memuat(),
    };
  }
}

class _Memuat extends StatelessWidget {
  const _Memuat();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _Gagal extends ConsumerWidget {
  const _Gagal({required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off_outlined, color: AppColors.dangerFg),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Ringkasan gagal dimuat',
                    style: text.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(pesan, style: text.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => ref.invalidate(ringkasanDashboardProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Angka extends ConsumerWidget {
  const _Angka({required this.ringkasan});

  final RingkasanDashboard ringkasan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final r = ringkasan;

    return Column(
      children: [
        _KartuAngka(
          ikon: Icons.inventory_2_outlined,
          judul: 'Total Barang',
          angka: '${r.totalUnit} unit',
          keterangan:
              '${r.jenisBarang} jenis barang, '
              '${r.unitTersedia} unit ada di rak'
              '${r.jenisHabis > 0 ? ' · ${r.jenisHabis} jenis stoknya habis' : ''}',
          // Hanya Laboran punya tab Aset Lab (Tabel 3.1 Use Case), jadi
          // tautannya cuma dipasang untuk dia — bukan sekadar disembunyikan,
          // tapi memang tidak ada tujuan yang boleh dibuka.
          tujuan: user.isLaboran ? '/aset' : null,
        ),
        const SizedBox(height: AppSpacing.cardGap),
        _KartuAngka(
          ikon: Icons.outbox_outlined,
          judul: 'Sedang Dipinjam',
          angka: '${r.unitDipinjam} unit',
          keterangan: r.transaksiDipinjam == 0
              ? 'Tidak ada peminjaman berjalan'
              : 'Tersebar di ${r.transaksiDipinjam} transaksi yang sudah '
                    'disetujui',
          tujuan: user.isLaboran ? '/transaksi' : null,
        ),
        const SizedBox(height: AppSpacing.cardGap),
        _KartuAngka(
          ikon: Icons.pending_actions_outlined,
          judul: 'Perlu Verifikasi',
          angka: '${r.menungguVerifikasi} pengajuan',
          // Menyebut unitnya penting: unit ini SUDAH keluar dari stok sejak
          // diajukan (§3.5.1), jadi "Total Barang − ada di rak" akan lebih
          // besar dari "Sedang Dipinjam" selama masih ada pengajuan.
          keterangan: r.menungguVerifikasi == 0
              ? 'Tidak ada pengajuan yang menggantung'
              : 'Menahan ${r.unitDiajukan} unit dari stok sampai diputuskan',
          tujuan: user.isKepalaProgram ? '/verifikasi' : null,
        ),
        if (r.terlambat > 0) ...[
          const SizedBox(height: AppSpacing.cardGap),
          _KartuAngka(
            ikon: Icons.warning_amber_outlined,
            judul: 'Terlambat',
            angka: '${r.terlambat} transaksi',
            keterangan: 'Sudah lewat tanggal kembali dan belum lengkap',
            warna: AppColors.dangerFg,
            tujuan: user.isLaboran ? '/transaksi' : null,
          ),
        ],
        const SizedBox(height: AppSpacing.cardGap),
        _KartuAngka(
          ikon: Icons.payments_outlined,
          judul: 'Denda Tercatat',
          angka: rupiah(r.totalDenda),
          keterangan: 'Total seluruh denda yang pernah dicatat',
        ),
      ],
    );
  }
}

class _KartuAngka extends StatelessWidget {
  const _KartuAngka({
    required this.ikon,
    required this.judul,
    required this.angka,
    required this.keterangan,
    this.warna = AppColors.navy,
    this.tujuan,
  });

  final IconData ikon;
  final String judul;
  final String angka;
  final String keterangan;
  final Color warna;

  /// Route yang dibuka saat kartu disentuh. Null berarti kartunya sekadar
  /// menampilkan angka — dipakai kalau perannya tidak punya layar tujuan.
  final String? tujuan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Tinggi kartu dibiarkan mengikuti isinya, tanpa tinggi patokan: angka
    // dan keterangannya ikut membesar saat pengguna menaikkan ukuran teks
    // sistem, dan kartu yang ikut tumbuh tidak akan meluber.
    final isi = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(ikon, color: warna),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: text.bodySmall),
                Text(angka, style: text.titleLarge?.copyWith(color: warna)),
                const SizedBox(height: AppSpacing.xxs),
                Text(keterangan, style: text.bodySmall),
              ],
            ),
          ),
          if (tujuan != null)
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );

    if (tujuan == null) return Card(child: isi);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: () => context.go(tujuan!), child: isi),
    );
  }
}
