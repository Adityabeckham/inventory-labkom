import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../application/auth_controller.dart';
import '../domain/app_user.dart';

/// Modal Profil / Pengaturan Akun (Edit Profile, Ubah Password, Logout).
/// Di-trigger dari Top App Bar atau tombol avatar user (UIUX §1).
class ProfileSheet extends ConsumerStatefulWidget {
  const ProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileSheet(),
    );
  }

  @override
  ConsumerState<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<ProfileSheet> {
  Future<void> _showEditProfileDialog(AppUser user) async {
    final usernameCtrl = TextEditingController(text: user.username);
    final nipCtrl = TextEditingController(text: user.nip ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Username tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: nipCtrl,
                decoration: const InputDecoration(
                  labelText: 'NIP / Identitas (opsional)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final success = await ref.read(authControllerProvider.notifier).updateProfile(
            username: usernameCtrl.text.trim(),
            nip: nipCtrl.text.trim().isEmpty ? null : nipCtrl.text.trim(),
          );
      if (mounted) {
        final msg = success
            ? 'Profil berhasil diperbarui.'
            : (ref.read(authControllerProvider).errorMessage ?? 'Gagal memperbarui profil.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Saat Ini',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Password saat ini wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Password baru minimal 6 karakter'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                validator: (v) => (v != newPasswordCtrl.text)
                    ? 'Konfirmasi password tidak cocok'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final success = await ref.read(authControllerProvider.notifier).changePassword(
            oldPassword: oldPasswordCtrl.text,
            newPassword: newPasswordCtrl.text,
          );
      if (mounted) {
        final msg = success
            ? 'Password berhasil diperbarui.'
            : (ref.read(authControllerProvider).errorMessage ?? 'Gagal mengubah password.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari aplikasi?'),
        content: const Text('Anda perlu login kembali untuk mengakses data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.of(context).pop();
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final text = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Profile Card Header
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.navy, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
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
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.person,
                          size: 36,
                          color: AppColors.navy,
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
                          user.username,
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.xs,
                          children: [
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
                            if (user.nip != null && user.nip!.isNotEmpty)
                              Text(
                                'NIP: ${user.nip}',
                                style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Image.asset(
                  'assets/images/smk_almadani_jampangkulon.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // Action List
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.navy),
              title: const Text('Edit Profil'),
              subtitle: const Text('Ubah username dan NIP / identitas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showEditProfileDialog(user),
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined, color: AppColors.navy),
              title: const Text('Ubah Password'),
              subtitle: const Text('Perbarui password kata sandi akun Anda'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showChangePasswordDialog,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // Logout Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.crimson),
                foregroundColor: AppColors.crimson,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.crimson),
              label: const Text('Logout / Keluar'),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
