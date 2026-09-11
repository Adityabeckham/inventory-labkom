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
import '../../kategori/application/kategori_controller.dart';
import '../../kategori/data/kategori.dart';
import '../application/barang_controller.dart';
import '../domain/barang.dart';
import '../domain/stok_mutasi.dart';
import 'barang_detail_sheet.dart';
import 'barang_form_sheet.dart';
import 'mutasi_form_sheet.dart';

/// Tab Aset Lab — segmented control "Daftar Barang | Mutasi Stok".
/// FR-02 dan FR-13, sesuai UIUX_Wireframe_dan_Flow.md §3.3 dan §3.3b.
class AsetScreen extends ConsumerStatefulWidget {
  const AsetScreen({super.key});

  @override
  ConsumerState<AsetScreen> createState() => _AsetScreenState();
}

class _AsetScreenState extends ConsumerState<AsetScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aset Lab'),
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
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _tambahBarang,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Barang'),
            )
          : FloatingActionButton.extended(
              onPressed: _catatMutasi,
              icon: const Icon(Icons.swap_vert),
              label: const Text('Catat Mutasi'),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Daftar Barang'),
                  icon: Icon(Icons.inventory_2_outlined),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Mutasi Stok'),
                  icon: Icon(Icons.swap_vert_outlined),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: _tab == 0 ? const _DaftarBarangView() : const _MutasiView(),
          ),
        ],
      ),
    );
  }

  Future<void> _tambahBarang() async {
    final kategori = await ref.read(kategoriListProvider.future);
    if (!mounted) return;

    if (kategori.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buat minimal satu kategori dulu lewat Dashboard → Kategori.'),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final body = await BarangFormSheet.show(context, kategori: kategori);
    if (body == null) return;

    await jalankanAksi(messenger, () async {
      await ref.read(asetActionsProvider).simpanBarang(body);
      return 'Barang ${body['nama_barang']} ditambahkan.';
    });
  }

  Future<void> _catatMutasi() async {
    final barang = await ref.read(barangListProvider.future);
    if (!mounted) return;

    if (barang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada barang yang bisa dimutasi.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final hasil = await MutasiFormSheet.show(context, barang: barang);
    if (hasil == null) return;

    await jalankanAksi(messenger, () async {
      await ref.read(asetActionsProvider).catatMutasi(
            idBarang: hasil.idBarang,
            jenis: hasil.jenis,
            jumlah: hasil.jumlah,
            keterangan: hasil.keterangan,
          );
      return 'Mutasi ${hasil.jenis.label.toLowerCase()} ${hasil.jumlah} unit dicatat.';
    });
  }
}

// ── Daftar Barang ────────────────────────────────────────────────────

class _DaftarBarangView extends ConsumerWidget {
  const _DaftarBarangView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(barangFilterProvider);
    final kategori = ref.watch(kategoriListProvider);
    final barang = ref.watch(barangListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
          child: SearchField(
            hintText: 'Cari nama, kode, merk, atau SN...',
            initialValue: filter.cari,
            onChanged: (q) => ref.read(barangFilterProvider.notifier).cari(q),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        SizedBox(
          height: 40,
          child: kategori.maybeWhen(
            data: (list) => _KategoriChips(
              kategori: list,
              terpilih: filter.idKategori,
              onPilih: (id) =>
                  ref.read(barangFilterProvider.notifier).pilihKategori(id),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        Expanded(
          child: AsyncView<List<Barang>>(
            value: barang,
            onRetry: () => ref.invalidate(barangListProvider),
            emptyMessage: filter.cari.isEmpty && filter.idKategori == null
                ? 'Belum ada barang. Tambahkan lewat tombol di bawah.'
                : 'Tidak ada barang yang cocok dengan pencarian.',
            builder: (list) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    // Header Tabel Data Barang
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 65,
                            child: Text(
                              'KODE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Expanded(
                            child: Text(
                              'NAMA BARANG & SPESIFIKASI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const SizedBox(
                            width: 60,
                            child: Text(
                              'STOK',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                        ],
                      ),
                    ),

                    // Body List Tabel Data Barang
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        itemBuilder: (context, i) => _BarangTableRow(barang: list[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _KategoriChips extends StatelessWidget {
  const _KategoriChips({
    required this.kategori,
    required this.terpilih,
    required this.onPilih,
  });

  final List<Kategori> kategori;
  final int? terpilih;
  final ValueChanged<int?> onPilih;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      children: [
        _chip(context, label: 'Semua', aktif: terpilih == null, onTap: () => onPilih(null)),
        for (final k in kategori)
          _chip(
            context,
            label: '${k.nama} (${k.jumlahBarang})',
            aktif: terpilih == k.id,
            onTap: () => onPilih(k.id),
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
              fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
            ),
        showCheckmark: false,
      ),
    );
  }
}

class _BarangTableRow extends ConsumerWidget {
  const _BarangTableRow({required this.barang});

  final Barang barang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => BarangDetailSheet.show(context, barang),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Kode Barang Column
            SizedBox(
              width: 65,
              child: Text(
                barang.kode,
                style: AppTypography.code(color: AppColors.primary).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Nama & Spesifikasi Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    barang.nama,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    barang.spesifikasi ?? '${barang.namaKategori} · Merk ${barang.merk ?? '-'}',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Stok Column
            SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${barang.stok}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: barang.tersedia ? AppColors.navy : AppColors.crimson,
                    ),
                  ),
                  Text(
                    '/ ${barang.jumlah}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // Detail Arrow Icon
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mutasi Stok ──────────────────────────────────────────────────────

class _MutasiView extends ConsumerWidget {
  const _MutasiView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutasi = ref.watch(mutasiListProvider);

    return AsyncView<List<StokMutasi>>(
      value: mutasi,
      onRetry: () => ref.invalidate(mutasiListProvider),
      emptyMessage: 'Belum ada mutasi stok yang tercatat.',
      builder: (list) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.xs,
          AppSpacing.screenMargin,
          AppSpacing.xxxl * 2,
        ),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
        itemBuilder: (context, i) => _MutasiCard(mutasi: list[i]),
      ),
    );
  }
}

class _MutasiCard extends StatelessWidget {
  const _MutasiCard({required this.mutasi});

  final StokMutasi mutasi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final masuk = mutasi.jenis == JenisMutasi.masuk;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: masuk ? AppColors.successBg : AppColors.dangerBg,
              foregroundColor: masuk ? AppColors.successFg : AppColors.dangerFg,
              child: Icon(masuk ? Icons.arrow_downward : Icons.arrow_upward),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mutasi.namaBarang, style: text.titleMedium),
                  Text(mutasi.kodeBarang,
                      style: AppTypography.code(color: AppColors.textMuted)),
                  if (mutasi.keterangan != null && mutasi.keterangan!.isNotEmpty)
                    Text(mutasi.keterangan!, style: text.bodySmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('${mutasi.tanggal} · dicatat ${mutasi.dicatatOleh}',
                      style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            StatusPill(
              label: '${masuk ? '+' : '−'}${mutasi.jumlah}',
              style: masuk ? StatusStyle.tersedia : StatusStyle.kritis,
            ),
          ],
        ),
      ),
    );
  }
}
