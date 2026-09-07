import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_style.dart';
import '../../../shared/widgets/form_feedback.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/profile_sheet.dart';
import '../application/laporan_controller.dart';
import '../domain/laporan.dart';

/// FR-08 Cetak Laporan dan FR-09 Lihat Laporan (UIUX §3.11).
///
/// Satu layar untuk kedua peran. Endpoint dan datanya sama — Kepala Program
/// memang berhak membaca seluruh laporan; yang berbeda hanya penandaan
/// "Mode Lihat Saja" supaya jelas bahwa dari sini tidak ada yang bisa diubah.
class LaporanScreen extends ConsumerWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryNavy,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.xl),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ProfileSheet.show(context),
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  user.isLaboran
                      ? 'assets/images/avatar_laboran.png'
                      : 'assets/images/avatar_kepala_program.png',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(
                    Icons.person,
                    size: 18,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
            tooltip: 'Profil & Pengaturan Akun',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppGradients.primaryNavy,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x221E3484),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Laporan Inventaris',
                        style: text.titleLarge?.copyWith(
                          color: AppColors.onNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (user.isKepalaProgram)
                      const StatusPill(
                        label: 'Mode Lihat Saja',
                        style: StatusStyle.kategori,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  user.isKepalaProgram
                      ? 'Anda bisa membuka dan mengunduh seluruh laporan. '
                          'Perubahan data dilakukan Laboran.'
                      : 'Buat dan cetak laporan sesuai kebutuhan, dalam format '
                          'PDF, Word, atau Excel.',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.navyTint.withAlpha(242),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const _FilterPeriode(),
          const SizedBox(height: AppSpacing.lg),

          Text('Jenis laporan', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final jenis in JenisLaporan.values) ...[
            _KartuLaporan(jenis: jenis),
            const SizedBox(height: AppSpacing.cardGap),
          ],
        ],
      ),
    );
  }
}

/// Periode berlaku untuk seluruh laporan berperiode sekaligus — satu tempat,
/// bukan diulang di tiap kartu.
class _FilterPeriode extends ConsumerWidget {
  const _FilterPeriode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periode = ref.watch(periodeLaporanProvider);
    final notifier = ref.read(periodeLaporanProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Periode (opsional)', style: text.titleMedium)),
              if (!periode.kosong)
                TextButton(
                  onPressed: notifier.bersihkan,
                  child: const Text('Bersihkan'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Dibiarkan kosong berarti seluruh periode. Laporan Stok tidak '
            'terpengaruh karena isinya keadaan saat ini.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TombolTanggal(
                  label: 'Dari',
                  nilai: periode.dari,
                  onPilih: notifier.aturDari,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TombolTanggal(
                  label: 'Sampai',
                  nilai: periode.sampai,
                  pertama: periode.dari,
                  onPilih: notifier.aturSampai,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(periode.label, style: AppTypography.code(color: AppColors.navy)),
        ],
      ),
    );
  }
}

class _TombolTanggal extends StatelessWidget {
  const _TombolTanggal({
    required this.label,
    required this.nilai,
    required this.onPilih,
    this.pertama,
  });

  final String label;
  final DateTime? nilai;
  final ValueChanged<DateTime?> onPilih;
  final DateTime? pertama;

  @override
  Widget build(BuildContext context) {
    final kini = DateTime.now();

    return OutlinedButton.icon(
      onPressed: () async {
        final awal = pertama ?? DateTime(kini.year - 3);
        final dipilih = await showDatePicker(
          context: context,
          initialDate: nilai != null && !nilai!.isBefore(awal) ? nilai! : awal,
          firstDate: awal,
          lastDate: DateTime(kini.year + 1),
        );
        if (dipilih != null) onPilih(dipilih);
      },
      icon: const Icon(Icons.event_outlined, size: 18),
      label: Text(
        nilai == null ? label : PeriodeLaporan.iso(nilai)!,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _KartuLaporan extends ConsumerWidget {
  const _KartuLaporan({required this.jenis});

  final JenisLaporan jenis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final sedang = ref.watch(laporanSedangDiunduhProvider);
    final sibuk = sedang != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(jenis.ikon, color: AppColors.navy),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(jenis.judul, style: text.titleMedium)),
                if (sedang == jenis)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(jenis.keterangan, style: text.bodySmall),
            if (jenis.berperiode)
              Text('Disaring menurut ${jenis.dasarPeriode}.',
                  style: text.bodySmall)
            else
              Text('Tidak terpengaruh filter periode.', style: text.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final format in FormatLaporan.values)
                  OutlinedButton.icon(
                    // Dimatikan selama ada unduhan lain berjalan: dua
                    // permintaan sekaligus akan saling menimpa SnackBar-nya
                    // dan pengguna tidak tahu berkas mana yang jadi.
                    onPressed: sibuk ? null : () => _unduh(context, ref, format),
                    icon: Icon(format.ikon, size: 18),
                    label: Text(format.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unduh(
    BuildContext context,
    WidgetRef ref,
    FormatLaporan format,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    await jalankanAksi(messenger, () async {
      return ref.read(laporanActionsProvider).unduh(jenis, format);
    });
  }
}
