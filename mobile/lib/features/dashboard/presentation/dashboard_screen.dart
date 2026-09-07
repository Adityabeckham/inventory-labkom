import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../auth/application/auth_controller.dart';

/// Tab Dashboard — sapaan, ringkasan, dan grid akses fitur sekunder.
///
/// Angka ringkasan masih placeholder; dihubungkan ke data asli di Sprint 6
/// (Sprint_Planning_Task_Breakdown.md).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          Text('Halo ${user.level.label}', style: text.headlineMedium),
          Text('Selamat datang kembali, ${user.username}.',
              style: text.bodyMedium),
          const SizedBox(height: AppSpacing.xl),

          if (user.isLaboran) ...[
            Text('Akses cepat', style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Tinggi kartu dipatok, bukan lewat childAspectRatio. Rasio
              // menghitung tinggi dari lebar layar dan sama sekali tidak
              // tahu-menahu soal tinggi teks di dalamnya: begitu pengguna
              // menaikkan ukuran font sistem satu takik (skala 1,15) grid
              // sudah meluber. Angka tetap memberi ruang label dua baris.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.cardGap,
                crossAxisSpacing: AppSpacing.cardGap,
                mainAxisExtent: 100,
              ),
              children: [
                _GridTile(
                  icon: Icons.category_outlined,
                  label: 'Kategori',
                  onTap: () => context.go('/kategori'),
                ),
                _GridTile(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Kelola User',
                  onTap: () => context.go('/users'),
                ),
                _GridTile(
                  icon: Icons.groups_outlined,
                  label: 'Data Peminjam',
                  onTap: () => context.go('/peminjam'),
                ),
                _GridTile(
                  icon: Icons.payments_outlined,
                  label: 'Pengaturan Denda',
                  onTap: () => _belumTersedia(context, 'Pengaturan Denda', 4),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          Text('Ringkasan', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const _SummaryPlaceholder(),
        ],
      ),
    );
  }

  void _belumTersedia(BuildContext context, String fitur, int sprint) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$fitur dikerjakan pada Sprint $sprint.')),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari aplikasi?'),
        content: const Text('Anda perlu login kembali untuk mengakses data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: AppColors.navy),
              const SizedBox(height: AppSpacing.xs),
              // Flexible + ellipsis jadi jaring pengaman kalau pengguna
              // membesarkan ukuran teks sistem: labelnya terpotong, bukan
              // kartunya yang pecah.
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPlaceholder extends StatelessWidget {
  const _SummaryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.insights_outlined, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Angka ringkasan (Total Barang, Sedang Dipinjam, Perlu '
                'Verifikasi) dihubungkan ke data asli pada Sprint 6.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
