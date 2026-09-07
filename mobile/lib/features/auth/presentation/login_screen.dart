import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../application/auth_controller.dart';

/// FR-01 — layar Login.
///
/// Struktur mengikuti mockup asli skripsi (Gambar 3.20): header berwarna
/// dengan identitas aplikasi, form username & password, "Ingat saya",
/// "Lupa Password?", dan tombol Masuk. Warnanya mengikuti DESIGN.md.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Tutup keyboard supaya pesan error di bawah form tidak tertutup.
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(authControllerProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
    // Navigasi ditangani router lewat perubahan state — tidak ada push manual.
  }

  void _showLupaPassword() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lupa Password'),
        content: const Text(
          'Password akun hanya bisa direset oleh Laboran lewat menu '
          'Kelola User. Silakan hubungi Laboran laboratorium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            const _LoginHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Login', style: text.displayLarge),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Selamat datang. Silakan login untuk melanjutkan '
                          'mengakses aplikasi inventori.',
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        Text('Username', style: text.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            hintText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Username wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        Text('Password', style: text.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              tooltip: _obscure
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Password wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(
                                          () => _rememberMe = v ?? false),
                                    ),
                                    Flexible(
                                      child: Text('Ingat saya',
                                          style: text.bodyLarge),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _showLupaPassword,
                              child: const Text('Lupa Password?'),
                            ),
                          ],
                        ),

                        if (state.errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _ErrorBanner(message: state.errorMessage!),
                        ],

                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: state.isSubmitting ? null : _submit,
                          icon: state.isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onNavy,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            state.isSubmitting ? 'Memproses...' : 'Masuk',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2, size: 48, color: AppColors.onNavy),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'INVENTORY LABKOM',
            textAlign: TextAlign.center,
            style: text.headlineLarge?.copyWith(
              color: AppColors.onNavy,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Sistem Inventori Laboratorium Komputer\nSMK Al-Madani',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: AppColors.navyTint),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.dangerFg, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.dangerFg),
            ),
          ),
        ],
      ),
    );
  }
}
