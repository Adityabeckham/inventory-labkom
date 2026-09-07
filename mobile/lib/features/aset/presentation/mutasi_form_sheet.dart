import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../domain/barang.dart';
import '../domain/stok_mutasi.dart';

/// Hasil isian form mutasi.
@immutable
class MutasiFormResult {
  const MutasiFormResult({
    required this.idBarang,
    required this.jenis,
    required this.jumlah,
    required this.keterangan,
  });

  final int idBarang;
  final JenisMutasi jenis;
  final int jumlah;
  final String keterangan;
}

/// FR-13 — form catat mutasi stok masuk/keluar.
class MutasiFormSheet extends StatefulWidget {
  const MutasiFormSheet({required this.barang, super.key});

  final List<Barang> barang;

  static Future<MutasiFormResult?> show(
    BuildContext context, {
    required List<Barang> barang,
  }) {
    return showModalBottomSheet<MutasiFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => MutasiFormSheet(barang: barang),
    );
  }

  @override
  State<MutasiFormSheet> createState() => _MutasiFormSheetState();
}

class _MutasiFormSheetState extends State<MutasiFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _jumlah = TextEditingController();
  final _keterangan = TextEditingController();

  int? _idBarang;
  JenisMutasi _jenis = JenisMutasi.masuk;

  @override
  void initState() {
    super.initState();
    _idBarang = widget.barang.firstOrNull?.id;
  }

  @override
  void dispose() {
    _jumlah.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  Barang? get _terpilih {
    for (final b in widget.barang) {
      if (b.id == _idBarang) return b;
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(MutasiFormResult(
      idBarang: _idBarang!,
      jenis: _jenis,
      jumlah: int.parse(_jumlah.text.trim()),
      keterangan: _keterangan.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final barang = _terpilih;

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
              Text('Catat Mutasi Stok', style: text.headlineMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Untuk penyesuaian manual seperti pengadaan baru, barang '
                'rusak, atau hilang. Peminjaman dan pengembalian tidak dicatat '
                'di sini — stoknya berubah otomatis.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),

              DropdownButtonFormField<int>(
                initialValue: _idBarang,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Barang',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: [
                  for (final b in widget.barang)
                    DropdownMenuItem(
                      value: b.id,
                      child: Text('${b.kode} · ${b.nama}',
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _idBarang = v),
                validator: (v) => v == null ? 'Barang wajib dipilih' : null,
              ),

              if (barang != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Saat ini: stok ${barang.stok} dari total ${barang.jumlah} unit',
                  style: text.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              SegmentedButton<JenisMutasi>(
                segments: const [
                  ButtonSegment(
                    value: JenisMutasi.masuk,
                    label: Text('Masuk'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: JenisMutasi.keluar,
                    label: Text('Keluar'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_jenis},
                onSelectionChanged: (s) => setState(() => _jenis = s.first),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _jumlah,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Jumlah unit',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Jumlah wajib diisi';
                  if (n < 1) return 'Jumlah harus lebih dari 0';
                  // Backend juga menolak, tapi memberitahu sekarang lebih baik
                  // daripada setelah pengguna menekan Simpan.
                  if (_jenis == JenisMutasi.keluar &&
                      barang != null &&
                      n > barang.stok) {
                    return 'Stok tersedia cuma ${barang.stok} unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _keterangan,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  hintText: 'mis. Pengadaan APBD 2026 / Rusak — dibuang',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton(onPressed: _submit, child: const Text('Catat Mutasi')),
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
