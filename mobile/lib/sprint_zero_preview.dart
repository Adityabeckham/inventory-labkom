import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_dimens.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/status_style.dart';

/// Layar sementara Sprint 0 — memperlihatkan tema `DESIGN.md` sudah terpasang.
///
/// Akan diganti layar Login begitu Sprint 1 sisi frontend dikerjakan.
class SprintZeroPreview extends StatelessWidget {
  const SprintZeroPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Labkom')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Peminjaman Baru'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          Text('Sprint 0 — fondasi', style: text.headlineMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Tema, tipografi, dan token status dari DESIGN.md sudah terpasang.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),

          _Section('Badge status transaksi'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final status in StatusPeminjaman.values)
                _Badge(label: status.label, style: StatusStyle.of(status)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          _Section('Kartu barang'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Laptop Lenovo ThinkPad', style: text.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text('A01 · SN LNV-TP-0001', style: AppTypography.code(
                          color: AppColors.textMuted,
                        )),
                        Text('Stok 40', style: text.bodySmall),
                      ],
                    ),
                  ),
                  const _Badge(label: 'Tersedia', style: StatusStyle.tersedia),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _Section('Kontrol'),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Cari nama barang....',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: const [
              Chip(label: Text('Semua')),
              Chip(label: Text('Komputer')),
              Chip(label: Text('Jaringan')),
              Chip(label: Text('Elektronik')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: () {}, child: const Text('Masuk')),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton(onPressed: () {}, child: const Text('Batal')),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Aset Lab'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Transaksi'),
          NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Laporan'),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.style});

  final String label;
  final StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: style.border),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: style.foreground,
            ),
      ),
    );
  }
}
