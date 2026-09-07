import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/status_style.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../application/users_controller.dart';
import '../domain/managed_user.dart';
import 'user_form_sheet.dart';

/// FR-12 — Kelola User.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersControllerProvider);
    final currentUserId = ref.watch(currentUserProvider).id;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola User')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Tambah User'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(usersControllerProvider.notifier).refresh(),
        child: AsyncView<List<ManagedUser>>(
          value: users,
          onRetry: () => ref.read(usersControllerProvider.notifier).refresh(),
          emptyMessage: 'Belum ada akun pengguna.',
          builder: (list) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.screenMargin,
              AppSpacing.screenMargin,
              // Ruang ekstra supaya kartu terakhir tidak tertutup FAB.
              AppSpacing.xxxl * 2,
            ),
            itemCount: list.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.cardGap),
            itemBuilder: (context, i) => _UserCard(
              user: list[i],
              isCurrentUser: list[i].id == currentUserId,
              onEdit: () => _openForm(context, ref, existing: list[i]),
              onDelete: () => _confirmDelete(context, ref, list[i]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    ManagedUser? existing,
  }) async {
    // Diambil sebelum await — setelahnya context bisa saja sudah tidak valid.
    final messenger = ScaffoldMessenger.of(context);
    final result = await UserFormSheet.show(context, existing: existing);
    if (result == null) return;

    final controller = ref.read(usersControllerProvider.notifier);

    await _run(messenger, () async {
      if (existing == null) {
        await controller.create(
          username: result.username,
          password: result.password,
          level: result.level,
          nip: result.nip,
        );
        return 'Akun ${result.username} berhasil dibuat.';
      }

      await controller.updateUser(
        existing.id,
        username: result.username,
        password: result.password.isEmpty ? null : result.password,
        level: result.level,
        nip: result.nip,
      );
      return 'Akun ${result.username} berhasil diperbarui.';
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ManagedUser user,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: Text(
          'Akun "${user.username}" akan dihapus permanen. '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _run(messenger, () async {
      await ref.read(usersControllerProvider.notifier).delete(user.id);
      return 'Akun ${user.username} dihapus.';
    });
  }

  /// Menjalankan aksi lalu melaporkan hasilnya lewat SnackBar.
  ///
  /// Pesan penolakan dari backend ditampilkan apa adanya — backend sudah
  /// menjelaskan sebabnya dengan baik ("Ini satu-satunya akun Laboran yang
  /// tersisa...", "Akun ini tercatat pada 3 transaksi..."), dan itu jauh lebih
  /// berguna daripada "Gagal menghapus".
  Future<void> _run(
    ScaffoldMessengerState messenger,
    Future<String> Function() action,
  ) async {
    try {
      final message = await action();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.crimsonDark,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isCurrentUser,
    required this.onEdit,
    required this.onDelete,
  });

  final ManagedUser user;
  final bool isCurrentUser;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: user.level == UserLevel.laboran
                  ? AppColors.navyTint
                  : AppColors.pendingBg,
              foregroundColor: user.level == UserLevel.laboran
                  ? AppColors.navy
                  : AppColors.pendingFg,
              child: Icon(
                user.level == UserLevel.laboran
                    ? Icons.engineering_outlined
                    : Icons.supervisor_account_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.username,
                          style: text.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const StatusPill(
                          label: 'Anda',
                          style: StatusStyle.kategori,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    user.nip == null || user.nip!.isEmpty
                        ? user.level.label
                        : '${user.level.label} · NIP ${user.nip}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah akun',
              color: AppColors.navy,
            ),
            IconButton(
              // Backend juga menolak ini, tapi mematikan tombolnya lebih jujur
              // daripada membiarkan pengguna menekan lalu ditolak.
              onPressed: isCurrentUser ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: isCurrentUser
                  ? 'Tidak bisa menghapus akun sendiri'
                  : 'Hapus akun',
              color: AppColors.crimson,
            ),
          ],
        ),
      ),
    );
  }
}
