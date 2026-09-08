import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../aset/application/barang_controller.dart';
import '../../aset/domain/barang.dart';
import '../../peminjam/application/peminjam_controller.dart';
import '../../peminjam/domain/peminjam.dart';
import '../domain/peminjaman.dart';

@immutable
class PeminjamanFormResult {
  const PeminjamanFormResult({
    required this.idPeminjam,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.items,
  });

  final int idPeminjam;
  final String tanggalPinjam;
  final String tanggalKembali;
  final List<ItemKeranjang> items;
}

/// FR-05 — form Peminjaman Baru multi-item (UIUX §3.8).
///
/// Alur di dokumen berupa wizard empat langkah. Di sini disusun sebagai satu
/// form bergulir: di layar 360dp, wizard justru menyembunyikan keranjang saat
/// pengguna sedang menambah barang berikutnya, padahal isi keranjang itulah
/// yang perlu terus terlihat. Langkah-langkahnya tetap urut dari atas ke bawah.
class PeminjamanFormSheet extends ConsumerStatefulWidget {
  const PeminjamanFormSheet({super.key});

  static Future<PeminjamanFormResult?> show(BuildContext context) {
    return showModalBottomSheet<PeminjamanFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const PeminjamanFormSheet(),
    );
  }

  @override
  ConsumerState<PeminjamanFormSheet> createState() => _PeminjamanFormSheetState();
}

class _PeminjamanFormSheetState extends ConsumerState<PeminjamanFormSheet> {
  final _formKey = GlobalKey<FormState>();

  int? _idPeminjam;
  late DateTime _tanggalPinjam;
  late DateTime _tanggalKembali;
  final List<ItemKeranjang> _keranjang = [];

  /// Ditampilkan hanya setelah percobaan simpan, supaya form tidak langsung
  /// terlihat menyalahkan pengguna sebelum mereka sempat mengisi apa pun.
  bool _keranjangDisorot = false;

  @override
  void initState() {
    super.initState();
    final kini = DateTime.now();
    _tanggalPinjam = DateTime(kini.year, kini.month, kini.day);
    // Tujuh hari adalah tempo yang paling sering dipakai; tetap bisa diubah.
    _tanggalKembali = _tanggalPinjam.add(const Duration(days: 7));
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final peminjam = ref.watch(peminjamListProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screenMargin,
        right: AppSpacing.screenMargin,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Peminjaman Baru', style: text.headlineMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Pengajuan masuk ke Kepala Program untuk diverifikasi. '
                'Stok barang langsung berkurang saat diajukan.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),

              peminjam.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Gagal memuat data peminjam: $e',
                    style: text.bodyMedium?.copyWith(color: AppColors.crimson)),
                data: (list) => _pilihPeminjam(list),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _pilihTanggal(
                      label: 'Tanggal pinjam',
                      nilai: _tanggalPinjam,
                      onPilih: (d) => setState(() {
                        _tanggalPinjam = d;
                        // Jatuh tempo tidak boleh mendahului tanggal pinjam;
                        // digeser otomatis daripada menolak diam-diam.
                        if (_tanggalKembali.isBefore(d)) _tanggalKembali = d;
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _pilihTanggal(
                      label: 'Jatuh tempo',
                      nilai: _tanggalKembali,
                      pertama: _tanggalPinjam,
                      onPilih: (d) => setState(() => _tanggalKembali = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _judulKeranjang(text),
              const SizedBox(height: AppSpacing.xs),
              ..._keranjang.map(_barisKeranjang),
              if (_keranjang.isEmpty) _keranjangKosong(text),
              const SizedBox(height: AppSpacing.xs),

              OutlinedButton.icon(
                onPressed: _tambahItem,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Barang'),
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton(
                onPressed: _simpan,
                child: const Text('Ajukan Peminjaman'),
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

  Widget _pilihPeminjam(List<Peminjam> list) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: _idPeminjam,
      decoration: const InputDecoration(
        labelText: 'Peminjam',
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: [
        for (final p in list)
          DropdownMenuItem(
            value: p.id,
            child: Text(
              p.nisNip == null || p.nisNip!.isEmpty
                  ? p.nama
                  : '${p.nama} · ${p.nisNip}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) => setState(() => _idPeminjam = v),
      validator: (v) => v == null ? 'Peminjam wajib dipilih' : null,
    );
  }

  Widget _pilihTanggal({
    required String label,
    required DateTime nilai,
    required ValueChanged<DateTime> onPilih,
    DateTime? pertama,
  }) {
    return InkWell(
      onTap: () async {
        final awal = pertama ?? DateTime(nilai.year - 1);
        final dipilih = await showDatePicker(
          context: context,
          initialDate: nilai.isBefore(awal) ? awal : nilai,
          firstDate: awal,
          lastDate: DateTime(nilai.year + 2),
        );
        if (dipilih != null) onPilih(dipilih);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(_iso(nilai), style: AppTypography.code()),
      ),
    );
  }

  Widget _judulKeranjang(TextTheme text) {
    final unit = _keranjang.fold<int>(0, (a, e) => a + e.jumlah);

    return Row(
      children: [
        Expanded(child: Text('Barang dipinjam', style: text.titleMedium)),
        if (_keranjang.isNotEmpty)
          Text('${_keranjang.length} jenis · $unit unit', style: text.bodySmall),
      ],
    );
  }

  Widget _keranjangKosong(TextTheme text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _keranjangDisorot ? AppColors.dangerBg : AppColors.neutralBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _keranjangDisorot ? AppColors.dangerBorder : AppColors.neutralBg,
        ),
      ),
      child: Text(
        _keranjangDisorot
            ? 'Tambahkan minimal satu barang sebelum mengajukan.'
            : 'Belum ada barang. Tambahkan satu per satu lewat tombol di bawah.',
        style: text.bodyMedium?.copyWith(
          color: _keranjangDisorot ? AppColors.dangerFg : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _barisKeranjang(ItemKeranjang item) {
    final text = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.namaBarang,
                      style: text.titleMedium, overflow: TextOverflow.ellipsis),
                  Text(
                    '${item.kodeBarang} · ${item.jumlah} dari ${item.stokTersedia} unit',
                    style: AppTypography.code(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _ubahJumlah(item),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah jumlah',
              color: AppColors.navy,
            ),
            IconButton(
              onPressed: () => setState(
                () => _keranjang.removeWhere((e) => e.idBarang == item.idBarang),
              ),
              icon: const Icon(Icons.close),
              tooltip: 'Keluarkan dari keranjang',
              color: AppColors.crimson,
            ),
          ],
        ),
      ),
    );
  }

  // ── Aksi ───────────────────────────────────────────────────────────

  Future<void> _tambahItem() async {
    final messenger = ScaffoldMessenger.of(context);
    final semua = await ref.read(barangListProvider.future);
    if (!mounted) return;

    // Barang yang sudah masuk keranjang tidak ditawarkan lagi: backend
    // menolak id_barang kembar, dan menggabungkannya diam-diam justru
    // menyembunyikan kekeliruan pengguna.
    final terpakai = _keranjang.map((e) => e.idBarang).toSet();
    final tersedia = semua
        .where((b) => b.stok > 0 && !terpakai.contains(b.id))
        .toList(growable: false);

    if (tersedia.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            semua.any((b) => b.stok > 0)
                ? 'Semua barang yang tersedia sudah masuk keranjang.'
                : 'Tidak ada barang berstok tersedia untuk dipinjam.',
          ),
        ),
      );
      return;
    }

    final hasil = await _dialogItem(tersedia: tersedia);
    if (hasil != null) setState(() => _keranjang.add(hasil));
  }

  Future<void> _ubahJumlah(ItemKeranjang item) async {
    final hasil = await _dialogItem(existing: item);
    if (hasil == null) return;

    setState(() {
      final i = _keranjang.indexWhere((e) => e.idBarang == item.idBarang);
      if (i >= 0) _keranjang[i] = hasil;
    });
  }

  /// Dialog pilih barang + jumlah. Saat [existing] diisi, barangnya terkunci
  /// dan hanya jumlahnya yang bisa diubah.
  Future<ItemKeranjang?> _dialogItem({
    List<Barang> tersedia = const [],
    ItemKeranjang? existing,
  }) {
    return showDialog<ItemKeranjang>(
      context: context,
      builder: (dialogContext) => _ItemDialog(
        tersedia: tersedia,
        existing: existing,
      ),
    );
  }

  void _simpan() {
    final formValid = _formKey.currentState?.validate() ?? false;

    // Keranjang kosong disorot terpisah: Form tidak tahu-menahu soal daftar
    // yang bukan field, jadi tanpa ini tombolnya seolah tidak bereaksi.
    setState(() => _keranjangDisorot = _keranjang.isEmpty);
    if (!formValid || _keranjang.isEmpty) return;

    Navigator.of(context).pop(
      PeminjamanFormResult(
        idPeminjam: _idPeminjam!,
        tanggalPinjam: _iso(_tanggalPinjam),
        tanggalKembali: _iso(_tanggalKembali),
        items: List.unmodifiable(_keranjang),
      ),
    );
  }
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({
    this.tersedia = const [],
    this.existing,
  });

  final List<Barang> tersedia;
  final ItemKeranjang? existing;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _jumlahController;
  int? _idBarang;
  int _stok = 0;

  @override
  void initState() {
    super.initState();
    _idBarang = widget.existing?.idBarang;
    _stok = widget.existing?.stokTersedia ?? 0;
    _jumlahController =
        TextEditingController(text: '${widget.existing?.jumlah ?? 1}');
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Tambah Barang' : 'Ubah Jumlah'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.existing == null)
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _idBarang,
                decoration: const InputDecoration(labelText: 'Barang'),
                items: [
                  for (final b in widget.tersedia)
                    DropdownMenuItem(
                      value: b.id,
                      child: Text('${b.kode} · ${b.nama}',
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) {
                  setState(() {
                    _idBarang = v;
                    _stok = widget.tersedia.firstWhere((b) => b.id == v).stok;
                    final diisi = int.tryParse(_jumlahController.text.trim());
                    if (diisi == null || diisi > _stok) {
                      _jumlahController.text = '1';
                    }
                  });
                },
                validator: (v) => v == null ? 'Barang wajib dipilih' : null,
              )
            else
              Text(
                widget.existing!.namaBarang,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Jumlah',
                helperText: _idBarang == null
                    ? 'Pilih barang dulu untuk melihat stoknya'
                    : 'Stok tersedia $_stok unit',
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n < 1) return 'Jumlah minimal 1';
                if (_idBarang != null && n > _stok) {
                  return 'Stok tersedia hanya $_stok unit';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;

            final id = _idBarang!;
            final n = int.parse(_jumlahController.text.trim());
            final barang = widget.existing == null
                ? widget.tersedia.firstWhere((b) => b.id == id)
                : null;

            Navigator.of(context).pop(
              widget.existing?.copyWith(jumlah: n) ??
                  ItemKeranjang(
                    idBarang: id,
                    kodeBarang: barang!.kode,
                    namaBarang: barang.nama,
                    jumlah: n,
                    stokTersedia: barang.stok,
                  ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

