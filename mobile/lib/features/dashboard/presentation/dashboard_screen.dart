import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/profile_sheet.dart';
import '../application/dashboard_controller.dart';
import 'ringkasan_dashboard_view.dart';

/// Tab Dashboard — sapaan, ringkasan, dan grid akses fitur sekunder (FR-10).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
              width: 34,
              height: 34,
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
                    size: 20,
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
        onRefresh: () => ref.refresh(ringkasanDashboardProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          children: [
            // Welcome Header Card with Blue Gradient
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
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        user.isLaboran
                            ? 'assets/images/avatar_laboran.png'
                            : 'assets/images/avatar_kepala_program.png',
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Icon(
                          Icons.person,
                          color: AppColors.navy,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user.username}',
                          style: text.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: user.isLaboran
                                ? AppColors.crimson
                                : AppColors.gold,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            user.level.label.toUpperCase(),
                            style: text.labelMedium?.copyWith(
                              color: user.isLaboran
                                  ? Colors.white
                                  : AppColors.onGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Ringkasan Inventoris',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            const RingkasanDashboardView(),
            const SizedBox(height: AppSpacing.xl),

            if (user.isLaboran) ...[
              Text(
                'Akses Cepat',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.cardGap,
                  crossAxisSpacing: AppSpacing.cardGap,
                  mainAxisExtent: 110,
                ),
                children: [
                  _GridTile(
                    icon: Icons.category_outlined,
                    label: 'Kategori',
                    iconBg: const Color(0xFFEEF2FF),
                    iconColor: AppColors.navy,
                    onTap: () => context.go('/kategori'),
                  ),
                  _GridTile(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Kelola User',
                    iconBg: const Color(0xFFF0FDF4),
                    iconColor: const Color(0xFF166534),
                    onTap: () => context.go('/users'),
                  ),
                  _GridTile(
                    icon: Icons.groups_outlined,
                    label: 'Data Peminjam',
                    iconBg: const Color(0xFFFFF7ED),
                    iconColor: const Color(0xFFC2410C),
                    onTap: () => context.go('/peminjam'),
                  ),
                  _GridTile(
                    icon: Icons.payments_outlined,
                    label: 'Pengaturan Denda',
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: AppColors.crimson,
                    onTap: () => context.go('/pengaturan-denda'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(height: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
