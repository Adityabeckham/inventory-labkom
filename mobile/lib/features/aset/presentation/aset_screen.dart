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
            builder: (list) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.xs,
                AppSpacing.screenMargin,
                AppSpacing.xxxl * 2,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
              itemBuilder: (context, i) => _BarangCard(barang: list[i]),
            ),
          ),
        ),
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

class _BarangCard extends ConsumerWidget {
  const _BarangCard({required this.barang});

  final Barang barang;

  Widget _buildCategoryThumbnail(String namaItem, String namaKategori) {
    final nameLower = namaItem.toLowerCase();
    final catLower = namaKategori.toLowerCase();
    String? assetPath;
    IconData fallbackIcon = Icons.inventory_2_outlined;

    if (nameLower.contains('laptop') || nameLower.contains('asus') || nameLower.contains('notebook')) {
      assetPath = 'assets/images/item_laptop_asus.png';
      fallbackIcon = Icons.laptop;
    } else if (nameLower.contains('router') || nameLower.contains('mikrotik') || nameLower.contains('switch')) {
      assetPath = 'assets/images/item_mikrotik_router.png';
      fallbackIcon = Icons.router;
    } else if (catLower.contains('komputer') || catLower.contains('pc')) {
      assetPath = 'assets/images/cat_komputer.png';
      fallbackIcon = Icons.computer;
    } else if (catLower.contains('jaringan')) {
      assetPath = 'assets/images/cat_jaringan.png';
      fallbackIcon = Icons.hub;
    } else if (catLower.contains('proyektor') || catLower.contains('display')) {
      fallbackIcon = Icons.videocam_outlined;
    } else if (catLower.contains('elektronik') || catLower.contains('kabel')) {
      fallbackIcon = Icons.cable_outlined;
    }

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: assetPath != null
            ? Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Icon(fallbackIcon, color: AppColors.navy),
              )
            : Container(
                decoration: const BoxDecoration(gradient: AppGradients.softBlue),
                child: Icon(fallbackIcon, color: AppColors.navy, size: 26),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () => BarangDetailSheet.show(context, barang),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _buildCategoryThumbnail(barang.nama, barang.namaKategori),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(barang.nama, style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      barang.serialNumber == null || barang.serialNumber!.isEmpty
                          ? barang.kode
                          : '${barang.kode} · SN ${barang.serialNumber}',
                      style: AppTypography.code(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      barang.tidakDiRak > 0
                          ? 'Stok ${barang.stok} dari ${barang.jumlah} · '
                              '${barang.tidakDiRak} dipinjam/diajukan'
                          : 'Stok ${barang.stok} · ${barang.namaKategori}',
                      style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(
                    label: barang.tersedia ? 'Tersedia' : 'Habis',
                    style: barang.tersedia ? StatusStyle.tersedia : StatusStyle.kritis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _hapus(context, ref),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.crimson,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _hapus(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final yakin = await konfirmasiHapus(
      context,
      judul: 'Hapus barang?',
      pesan: '"${barang.nama}" (${barang.kode}) akan dihapus permanen.',
    );
    if (!yakin) return;

    await jalankanAksi(messenger, () async {
      await ref.read(asetActionsProvider).hapusBarang(barang.id);
      return 'Barang ${barang.nama} dihapus.';
    });
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
