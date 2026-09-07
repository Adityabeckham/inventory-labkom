import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../auth/domain/app_user.dart';
import '../domain/managed_user.dart';

/// Hasil isian form — null kalau pengguna membatalkan.
@immutable
class UserFormResult {
  const UserFormResult({
    required this.username,
    required this.password,
    required this.level,
    required this.nip,
  });

  final String username;

  /// Kosong saat mengubah akun berarti password tidak diganti.
  final String password;

  final UserLevel level;
  final String nip;
}

/// Form tambah/ubah akun. Dipakai untuk keduanya karena bedanya cuma satu:
/// saat mengubah, password boleh dikosongkan.
class UserFormSheet extends StatefulWidget {
  const UserFormSheet({this.existing, super.key});

  final ManagedUser? existing;

  bool get isEdit => existing != null;

  static Future<UserFormResult?> show(
    BuildContext context, {
    ManagedUser? existing,
  }) {
    return showModalBottomSheet<UserFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => UserFormSheet(existing: existing),
    );
  }

  @override
  State<UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _nip;
  final _password = TextEditingController();

  late UserLevel _level;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.existing?.username ?? '');
    _nip = TextEditingController(text: widget.existing?.nip ?? '');
    _level = widget.existing?.level ?? UserLevel.laboran;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _nip.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      UserFormResult(
        username: _username.text.trim(),
        password: _password.text,
        level: _level,
        nip: _nip.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      // Naikkan sheet di atas keyboard supaya field tidak tertutup.
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isEdit ? 'Ubah Akun' : 'Tambah Akun',
              style: text.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _username,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Username wajib diisi';
                if (value.length > 50) return 'Maksimal 50 karakter';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: widget.isEdit
                    ? 'Password baru (kosongkan bila tidak diubah)'
                    : 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                final value = v ?? '';
                // Saat mengubah, kosong berarti "jangan ganti password".
                if (widget.isEdit && value.isEmpty) return null;
                if (value.length < 8) return 'Password minimal 8 karakter';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<UserLevel>(
              isExpanded: true,
              initialValue: _level,
              decoration: const InputDecoration(
                labelText: 'Peran',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: [
                for (final level in UserLevel.values)
                  DropdownMenuItem(value: level, child: Text(level.label)),
              ],
              onChanged: (v) => setState(() => _level = v ?? _level),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _nip,
              decoration: const InputDecoration(
                labelText: 'NIP (opsional)',
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (v) => (v != null && v.trim().length > 30)
                  ? 'Maksimal 30 karakter'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              onPressed: _submit,
              child: Text(widget.isEdit ? 'Simpan Perubahan' : 'Tambah Akun'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
