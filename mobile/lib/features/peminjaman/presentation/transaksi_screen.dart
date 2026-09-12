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
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/profile_sheet.dart';
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
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
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
      floatingActionButton: (_tab == 0 && user.isLaboran)
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
                ButtonSegment(
                  value: 0,
                  label: Text('Peminjaman'),
                  icon: Icon(Icons.north_east_outlined),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Pengembalian'),
                  icon: Icon(Icons.south_west_outlined),
                ),
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
            builder: (list) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.xs,
                AppSpacing.screenMargin,
                AppSpacing.xxxl * 2,
              ),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.navyTint.withAlpha(128),
                    ),
                    columns: const [
                      DataColumn(label: Text('Kode')),
                      DataColumn(label: Text('Peminjam')),
                      DataColumn(label: Text('Identitas')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Total Unit')),
                      DataColumn(label: Text('Pinjam')),
                      DataColumn(label: Text('Kembali')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: List.generate(list.length, (i) {
                      final p = list[i];
                      void bukaDetail() =>
                          PeminjamanDetailSheet.show(context, id: p.id);

                      return DataRow(
                        cells: [
                          DataCell(
                            InkWell(
                              onTap: bukaDetail,
                              child: Text(
                                p.kode,
                                style: AppTypography.code(
                                  color: AppColors.navy,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataCell(
                            InkWell(
                              onTap: bukaDetail,
                              child: Text(
                                p.namaPeminjam,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              p.identitasPeminjam.isNotEmpty ? p.identitasPeminjam : '-',
                              style: AppTypography.code(color: AppColors.textMuted),
                            ),
                          ),
                          DataCell(
                            StatusPill(
                              label: p.status.label,
                              style: StatusStyle.of(p.status),
                            ),
                          ),
                          DataCell(
                            Text('${p.totalUnit} unit (${p.jumlahItem} jenis)'),
                          ),
                          DataCell(Text(p.tanggalPinjam)),
                          DataCell(Text(p.tanggalKembali)),
                          DataCell(
                            IconButton(
                              onPressed: bukaDetail,
                              icon: const Icon(Icons.visibility_outlined),
                              tooltip: 'Lihat Detail Peminjaman',
                              color: AppColors.navy,
                              iconSize: 20,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
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

