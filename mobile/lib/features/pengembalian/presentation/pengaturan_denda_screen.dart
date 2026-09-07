import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/form_feedback.dart';
import '../application/pengembalian_controller.dart';
import '../domain/pengembalian.dart';

/// FR-11 — Pengaturan Denda, dibuka dari grid Dashboard.
class PengaturanDendaScreen extends ConsumerWidget {
  const PengaturanDendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarif = ref.watch(tarifDendaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Denda'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryNavy,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.xl),
            ),
          ),
        ),
      ),
      body: AsyncView<TarifDenda>(
        value: tarif,
        onRetry: () => ref.invalidate(tarifDendaProvider),
        builder: (t) => _Form(tarif: t),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.tarif});

  final TarifDenda tarif;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tarif;

  @override
  void initState() {
    super.initState();
    // Ditampilkan sebagai bilangan bulat; denda rupiah di sekolah tidak
    // pernah pakai sen, dan ".0" di field hanya bikin ragu.
    _tarif = TextEditingController(
      text: widget.tarif.tarifPerHari.truncate().toString(),
    );
  }

  @override
  void dispose() {
    _tarif.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final nilai = int.tryParse(_tarif.text.trim()) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        Text('Tarif denda keterlambatan', style: text.titleLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Denda dihitung otomatis saat barang dikembalikan: jumlah hari '
          'terlambat dikalikan tarif ini, per baris barang.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),

        Form(
          key: _formKey,
          child: TextFormField(
            controller: _tarif,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Tarif per hari',
              prefixText: 'Rp ',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null) return 'Tarif wajib diisi berupa angka';
              if (n < 0) return 'Tarif tidak boleh negatif';
              if (n > 1000000) return 'Tarif maksimal Rp 1.000.000 per hari';
              return null;
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _Contoh(tarif: nilai.toDouble()),
        const SizedBox(height: AppSpacing.xl),

        FilledButton(
          onPressed: _simpan,
          child: const Text('Simpan Tarif'),
        ),

        const SizedBox(height: AppSpacing.lg),
        Text(
          'Mengubah tarif tidak mengubah denda yang sudah tercatat. Setiap '
          'pengembalian menyimpan angkanya sendiri saat dicatat, supaya '
          'laporan lama tetap sesuai keadaan waktu itu.',
          style: text.bodySmall,
        ),
      ],
    );
  }

  Future<void> _simpan() async {
    if (_formKey.currentState?.validate() != true) return;

    final messenger = ScaffoldMessenger.of(context);
    final nilai = double.parse(_tarif.text.trim());

    await jalankanAksi(messenger, () async {
      await ref.read(pengembalianActionsProvider).simpanTarif(nilai);
      return nilai == 0
          ? 'Denda dimatikan — keterlambatan tidak lagi dikenai biaya.'
          : 'Tarif denda disimpan: ${rupiah(nilai)} per hari.';
    });
  }
}

/// Contoh perhitungan, supaya angka tarif tidak terasa abstrak.
class _Contoh extends StatelessWidget {
  const _Contoh({required this.tarif});

  final double tarif;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contoh', style: text.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            tarif == 0
                ? 'Dengan tarif Rp 0, keterlambatan berapa hari pun tidak '
                    'menghasilkan denda.'
                : 'Satu barang telat 3 hari dikenai 3 × ${rupiah(tarif)} = '
                    '${rupiah(tarif * 3)}.',
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}
