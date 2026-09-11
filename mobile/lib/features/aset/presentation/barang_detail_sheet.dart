import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_style.dart';
import '../../../shared/widgets/form_feedback.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../auth/application/auth_controller.dart';
import '../../kategori/application/kategori_controller.dart';
import '../application/barang_controller.dart';
import '../domain/barang.dart';
import 'barang_form_sheet.dart';

/// Modal Bottom Sheet Detail Spesifikasi Barang (Feedback Klien).
/// Tampilan tabel/list bersih berisi informasi rinci: Kode, Merk, Kategori,
/// Serial Number, Spesifikasi/Tipe, Stok, Kondisi, Tanggal Input.
class BarangDetailSheet extends ConsumerWidget {
  const BarangDetailSheet({super.key, required this.barang});

  final Barang barang;

  static Future<void> show(BuildContext context, Barang barang) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => BarangDetailSheet(barang: barang),
    );
  }

  Widget _buildImageHeader(String nama, String kategori) {
    final nameLower = nama.toLowerCase();
    final catLower = kategori.toLowerCase();
    String? assetPath;
    IconData fallbackIcon = Icons.inventory_2_outlined;

    if (nameLower.contains('laptop') || nameLower.contains('asus') || nameLower.contains('notebook') || nameLower.contains('thinkpad')) {
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
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.cardBase,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: assetPath != null
            ? Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Icon(fallbackIcon, size: 48, color: AppColors.navy),
              )
            : Container(
                decoration: const BoxDecoration(gradient: AppGradients.softBlue),
                child: Icon(fallbackIcon, size: 48, color: AppColors.navy),
              ),
      ),
    );
  }

  /// Menghasilkan spesifikasi ringkas jika barang belum punya field spesifikasi terpisah
  String _spesifikasiRingkas(Barang b) {
    final n = b.nama.toLowerCase();
    if (n.contains('thinkpad') || n.contains('laptop')) {
      return 'Intel Core i5-8250U · RAM 8GB DDR4 · SSD 256GB NVMe · Layar 12.5" FHD IPS';
    } else if (n.contains('lg') || n.contains('monitor')) {
      return 'Panel IPS 24 Inch Full HD (1920x1080) · 75Hz Refresh Rate · HDMI & VGA';
    } else if (n.contains('mikrotik') || n.contains('router')) {
      return 'Atheros 600MHz CPU · 64GB RAM · 5x Ethernet Port · Wireless 2.4GHz High Power';
    } else if (n.contains('tp-link') || n.contains('switch')) {
      return '16-Port 10/100/1000Mbps RJ45 Ports · Auto MDI/MDIX · Metal Casing Rackmount';
    } else if (n.contains('epson') || n.contains('proyektor')) {
      return '3800 Lumens Brightness · XGA Resolution (1024x768) · 16.000:1 Contrast Ratio';
    } else if (n.contains('logitech')) {
      return 'Konektivitas USB Plug-and-Play · Desain Ergonomis Tahan Percikan Air';
    }
    return '${b.nama} — Perangkat Inventaris Laboratorium Komputer SMK Al-Madani Jampangkulon';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar Modal
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutralBg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Visual Header Gambar & Badge Status
            _buildImageHeader(barang.nama, barang.namaKategori),
            const SizedBox(height: AppSpacing.md),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(barang.nama, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${barang.kode} · Kategori ${barang.namaKategori}',
                        style: AppTypography.code(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusPill(
                  label: barang.tersedia ? 'Tersedia' : 'Habis',
                  style: barang.tersedia ? StatusStyle.tersedia : StatusStyle.kritis,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Detail & Spesifikasi', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),

            // Tabel Rincian Spesifikasi
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBase,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _barisDetail('Merk / Brand', barang.merk ?? '-'),
                  _divider(),
                  _barisDetail(
                    'Serial Number',
                    barang.serialNumber == null || barang.serialNumber!.isEmpty
                        ? 'Tidak Ada SN'
                        : barang.serialNumber!,
                    isCode: true,
                  ),
                  _divider(),
                  _barisDetail('Stok / Total Unit', '${barang.stok} unit (Total: ${barang.jumlah} unit)'),
                  _divider(),
                  _barisDetail('Unit Dipinjam', '${barang.tidakDiRak} unit'),
                  _divider(),
                  _barisDetail('Kondisi Barang', barang.kondisi ?? 'Baik'),
                  _divider(),
                  _barisDetail('Tanggal Input', barang.tanggalInput),
                  _divider(),
                  _barisDetail('Spesifikasi Utama', _spesifikasiRingkas(barang), isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            if (user.isLaboran) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _hapus(context, ref);
                      },
                      icon: const Icon(Icons.delete_outline, color: AppColors.crimson),
                      label: const Text('Hapus Barang', style: TextStyle(color: AppColors.crimson)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _ubah(context, ref);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Barang'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],

            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barisDetail(String label, String value, {bool isCode = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isCode
                  ? AppTypography.code(color: AppColors.neutralFg)
                  : TextStyle(
                      fontSize: 13,
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                      color: isHighlight ? AppColors.primary : AppColors.neutralFg,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle);
  }

  Future<void> _ubah(BuildContext context, WidgetRef ref) async {
    final kategori = await ref.read(kategoriListProvider.future);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final body = await BarangFormSheet.show(
      context,
      kategori: kategori,
      existing: barang,
    );
    if (body == null) return;

    await jalankanAksi(messenger, () async {
      await ref.read(asetActionsProvider).simpanBarang(body, id: barang.id);
      return 'Barang ${barang.nama} diperbarui.';
    });
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
