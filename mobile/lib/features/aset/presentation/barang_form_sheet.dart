import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../kategori/data/kategori.dart';
import '../domain/barang.dart';

/// Form tambah/ubah barang (FR-02).
class BarangFormSheet extends StatefulWidget {
  const BarangFormSheet({required this.kategori, this.existing, super.key});

  final List<Kategori> kategori;
  final Barang? existing;

  bool get isEdit => existing != null;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required List<Kategori> kategori,
    Barang? existing,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => BarangFormSheet(kategori: kategori, existing: existing),
    );
  }

  @override
  State<BarangFormSheet> createState() => _BarangFormSheetState();
}

class _BarangFormSheetState extends State<BarangFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kode;
  late final TextEditingController _nama;
  late final TextEditingController _merk;
  late final TextEditingController _jumlah;
  late final TextEditingController _stok;
  late final TextEditingController _kondisi;
  late final TextEditingController _serial;

  int? _idKategori;
  late DateTime _tanggal;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _kode = TextEditingController(text: b?.kode ?? '');
    _nama = TextEditingController(text: b?.nama ?? '');
    _merk = TextEditingController(text: b?.merk ?? '');
    _jumlah = TextEditingController(text: b?.jumlah.toString() ?? '');
    _stok = TextEditingController(text: b?.stok.toString() ?? '');
    _kondisi = TextEditingController(text: b?.kondisi ?? 'Baik');
    _serial = TextEditingController(text: b?.serialNumber ?? '');
    _idKategori = b?.idKategori ?? widget.kategori.firstOrNull?.id;
    _tanggal = DateTime.tryParse(b?.tanggalInput ?? '') ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final c in [_kode, _nama, _merk, _jumlah, _stok, _kondisi, _serial]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickTanggal() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dipilih != null) setState(() => _tanggal = dipilih);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(<String, dynamic>{
      'id_kategori': _idKategori,
      'kode_barang': _kode.text.trim(),
      'nama_barang': _nama.text.trim(),
      'merk': _merk.text.trim(),
      'jumlah': int.parse(_jumlah.text.trim()),
      'kondisi': _kondisi.text.trim(),
      'stok': int.parse(_stok.text.trim()),
      'tanggal_input': _fmt(_tanggal),
      'serial_number': _serial.text.trim(),
    });
  }

  String? _validAngka(String? v, String label) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return '$label wajib diisi';
    final n = int.tryParse(value);
    if (n == null) return '$label harus angka bulat';
    if (n < 0) return '$label tidak boleh negatif';
    return null;
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
              Text(widget.isEdit ? 'Ubah Barang' : 'Tambah Barang',
                  style: text.headlineMedium),
              const SizedBox(height: AppSpacing.lg),

              DropdownButtonFormField<int>(
                initialValue: _idKategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final k in widget.kategori)
                    DropdownMenuItem(value: k.id, child: Text(k.nama)),
                ],
                onChanged: (v) => setState(() => _idKategori = v),
                validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _kode,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Kode Barang',
                  hintText: 'mis. A01',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Kode barang wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _nama,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Nama barang wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _merk,
                decoration: const InputDecoration(
                  labelText: 'Merk (opsional)',
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _jumlah,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Jumlah total'),
                      validator: (v) => _validAngka(v, 'Jumlah'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _stok,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Stok tersedia'),
                      validator: (v) {
                        final dasar = _validAngka(v, 'Stok');
                        if (dasar != null) return dasar;
                        // Cek di sini juga, bukan cuma di backend — pengguna
                        // tidak perlu menunggu round-trip untuk tahu.
                        final stok = int.parse(v!.trim());
                        final jumlah = int.tryParse(_jumlah.text.trim());
                        if (jumlah != null && stok > jumlah) {
                          return 'Tidak boleh melebihi jumlah total';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _kondisi,
                decoration: const InputDecoration(
                  labelText: 'Kondisi',
                  prefixIcon: Icon(Icons.health_and_safety_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _serial,
                decoration: const InputDecoration(
                  labelText: 'Serial Number (opsional)',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              InkWell(
                onTap: _pickTanggal,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Input',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(_fmt(_tanggal)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton(
                onPressed: _submit,
                child: Text(widget.isEdit ? 'Simpan Perubahan' : 'Tambah Barang'),
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
