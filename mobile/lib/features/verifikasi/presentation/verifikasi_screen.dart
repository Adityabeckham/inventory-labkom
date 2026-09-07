import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_style.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/profile_sheet.dart';
import '../../peminjaman/application/peminjaman_controller.dart';
import '../../peminjaman/domain/peminjaman.dart';
import '../../peminjaman/presentation/peminjaman_detail_sheet.dart';

/// FR-07 — layar Verifikasi milik Kepala Program (UIUX §3.10).
///
/// Hanya menampilkan pengajuan berstatus `menunggu_verifikasi`; tidak ada
/// filter status di sini karena status lain bukan urusan layar ini.
class VerifikasiScreen extends ConsumerWidget {
  const VerifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pengajuan = ref.watch(pengajuanMenungguProvider);
    final user = ref.watch(currentUserProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi'),
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
            onPressed: () => ref.invalidate(pengajuanMenungguProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
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
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(pengajuanMenungguProvider),
        child: AsyncView<List<Peminjaman>>(
          value: pengajuan,
          onRetry: () => ref.invalidate(pengajuanMenungguProvider),
          emptyMessage: 'Tidak ada pengajuan yang menunggu verifikasi.',
          builder: (list) => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            // Satu baris keterangan di atas daftar, lalu kartunya.
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Text(
                  list.length == 1
                      ? '1 pengajuan menunggu keputusan Anda.'
                      : '${list.length} pengajuan menunggu keputusan Anda.',
                  style: text.bodyMedium,
                );
              }
              return _PengajuanCard(peminjaman: list[i - 1]);
            },
          ),
        ),
      ),
    );
  }
}

class _PengajuanCard extends StatelessWidget {
  const _PengajuanCard({required this.peminjaman});

  final Peminjaman peminjaman;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = peminjaman;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => PeminjamanDetailSheet.show(
          context,
          id: p.id,
          bolehVerifikasi: true,
        ),
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
                'diajukan ${p.dicatatOleh}',
                style: text.bodySmall,
              ),
              Text('Pinjam ${p.tanggalPinjam} · tempo ${p.tanggalKembali}',
                  style: text.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => PeminjamanDetailSheet.show(
                    context,
                    id: p.id,
                    bolehVerifikasi: true,
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Periksa & putuskan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
