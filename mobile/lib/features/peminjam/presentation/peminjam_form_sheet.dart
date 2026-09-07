import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../domain/peminjam.dart';

@immutable
class PeminjamFormResult {
  const PeminjamFormResult({
    required this.nama,
    required this.nisNip,
    required this.kelasJabatan,
    required this.noHp,
  });

  final String nama;
  final String nisNip;
  final String kelasJabatan;
  final String noHp;
}

/// FR-04 — form tambah/ubah peminjam.
class PeminjamFormSheet extends StatefulWidget {
  const PeminjamFormSheet({this.existing, super.key});

  final Peminjam? existing;

  bool get isEdit => existing != null;

  static Future<PeminjamFormResult?> show(BuildContext context, {Peminjam? existing}) {
    return showModalBottomSheet<PeminjamFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => PeminjamFormSheet(existing: existing),
    );
  }

  @override
  State<PeminjamFormSheet> createState() => _PeminjamFormSheetState();
}

class _PeminjamFormSheetState extends State<PeminjamFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _nisNip;
  late final TextEditingController _kelas;
  late final TextEditingController _noHp;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nama = TextEditingController(text: p?.nama ?? '');
    _nisNip = TextEditingController(text: p?.nisNip ?? '');
    _kelas = TextEditingController(text: p?.kelasJabatan ?? '');
    _noHp = TextEditingController(text: p?.noHp ?? '');
  }

  @override
  void dispose() {
    for (final c in [_nama, _nisNip, _kelas, _noHp]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(PeminjamFormResult(
      nama: _nama.text.trim(),
      nisNip: _nisNip.text.trim(),
      kelasJabatan: _kelas.text.trim(),
      noHp: _noHp.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.isEdit ? 'Ubah Peminjam' : 'Tambah Peminjam',
                  style: text.headlineMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Peminjam adalah siswa, guru, atau staf yang meminjam barang — '
                'bukan akun untuk masuk ke aplikasi.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Peminjam',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _nisNip,
                decoration: const InputDecoration(
                  labelText: 'NIS / NIP',
                  hintText: 'NIS untuk siswa, NIP untuk guru/staf',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => (v != null && v.trim().length > 30)
                    ? 'Maksimal 30 karakter'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _kelas,
                decoration: const InputDecoration(
                  labelText: 'Kelas / Jabatan',
                  hintText: 'mis. XII TKJ 1',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _noHp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No. HP',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton(
                onPressed: _submit,
                child: Text(widget.isEdit ? 'Simpan Perubahan' : 'Tambah Peminjam'),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
