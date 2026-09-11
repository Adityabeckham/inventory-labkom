import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/application/auth_controller.dart';
import '../../pengembalian/domain/pengembalian.dart' show rupiah;
import '../application/dashboard_controller.dart';
import '../domain/ringkasan.dart';

/// Angka ringkasan Dashboard berbasis Bento Grid & Stacked Card Deck (Design System §5).
class RingkasanDashboardView extends ConsumerWidget {
  const RingkasanDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringkasan = ref.watch(ringkasanDashboardProvider);

    return switch (ringkasan) {
      AsyncData(:final value) => _AngkaBento(ringkasan: value),
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
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
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
                  child: Text('Ringkasan gagal dimuat', style: text.titleMedium),
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

class _AngkaBento extends ConsumerWidget {
  const _AngkaBento({required this.ringkasan});

  final RingkasanDashboard ringkasan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final r = ringkasan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 5.3 Stacked Card Deck — Layer 1 Hero Focus Card (Electric Blue #1622E5, Radius 32px)
        Container(
          decoration: BoxDecoration(
            gradient: AppGradients.electricBlue,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            boxShadow: AppShadows.electricGlow,
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: InkWell(
            onTap: () => context.go('/aset'),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'TOTAL BARANG',
                            style: AppTypography.captionLabel(color: Colors.white).copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.north_east, size: 18, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${r.totalUnit}',
                  style: AppTypography.displayNumber(color: Colors.white),
                ),
                Text(
                  'Unit Terinventaris',
                  style: AppTypography.captionLabel(color: Colors.white70).copyWith(fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${r.jenisBarang} Jenis Barang · ${r.unitTersedia} Tersedia di Rak',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (r.jenisHabis > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.crimson,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '${r.jenisHabis} Habis',
                            style: AppTypography.captionLabel(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 5.2 Bento Grid 2x2 Metrics Cards
        Row(
          children: [
            Expanded(
              child: _BentoMetricCard(
                ikon: Icons.outbox_outlined,
                judul: 'Sedang Dipinjam',
                nilai: '${r.unitDipinjam}',
                satuan: 'Unit',
                keterangan: '${r.transaksiDipinjam} Transaksi',
                iconBg: AppColors.brandSurfaceTint,
                iconColor: AppColors.primary,
                onTap: user.isLaboran ? () => context.go('/transaksi') : null,
              ),
            ),
            const SizedBox(width: AppSpacing.cardGap),
            Expanded(
              child: _BentoMetricCard(
                ikon: Icons.pending_actions_outlined,
                judul: 'Perlu Verifikasi',
                nilai: '${r.menungguVerifikasi}',
                satuan: 'Pengajuan',
                keterangan: '${r.unitDiajukan} Unit diajukan',
                iconBg: AppColors.pendingBg,
                iconColor: AppColors.warning,
                onTap: user.isKepalaProgram ? () => context.go('/verifikasi') : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.cardGap),

        Row(
          children: [
            Expanded(
              child: _BentoMetricCard(
                ikon: r.terlambat > 0 ? Icons.warning_amber : Icons.history,
                judul: 'Terlambat',
                nilai: '${r.terlambat}',
                satuan: 'Transaksi',
                keterangan: r.terlambat > 0 ? 'Lewat Jatuh Tempo' : 'Stok Aman',
                iconBg: r.terlambat > 0 ? AppColors.dangerBg : AppColors.pillInactive,
                iconColor: r.terlambat > 0 ? AppColors.danger : AppColors.textMuted,
                onTap: user.isLaboran ? () => context.go('/transaksi') : null,
              ),
            ),
            const SizedBox(width: AppSpacing.cardGap),
            Expanded(
              child: _BentoMetricCard(
                ikon: Icons.payments_outlined,
                judul: 'Denda Tercatat',
                nilai: rupiah(r.totalDenda),
                satuan: '',
                keterangan: 'Total Rekap Denda',
                iconBg: AppColors.brandSurfaceTint,
                iconColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoMetricCard extends StatelessWidget {
  const _BentoMetricCard({
    required this.ikon,
    required this.judul,
    required this.nilai,
    required this.satuan,
    required this.keterangan,
    required this.iconBg,
    required this.iconColor,
    this.onTap,
  });

  final IconData ikon;
  final String judul;
  final String nilai;
  final String satuan;
  final String keterangan;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBase,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.subtleAmbient,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(ikon, size: 20, color: iconColor),
                  ),
                  if (onTap != null)
                    const Icon(Icons.north_east, size: 16, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                judul,
                style: AppTypography.captionLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      nilai,
                      style: AppTypography.metricCardVal(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (satuan.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(satuan, style: AppTypography.captionLabel()),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                keterangan,
                style: AppTypography.captionLabel().copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
