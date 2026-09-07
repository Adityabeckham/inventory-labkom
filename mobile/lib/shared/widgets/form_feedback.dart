import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';

/// Menjalankan aksi tulis lalu melaporkan hasilnya lewat SnackBar.
///
/// Pesan penolakan backend ditampilkan apa adanya. Backend sudah menjelaskan
/// sebabnya dengan spesifik ("Kategori ini masih dipakai 12 barang"), dan
/// menggantinya dengan "Gagal menyimpan" justru membuang informasi yang
/// dibutuhkan pengguna untuk memperbaiki keadaan.
Future<bool> jalankanAksi(
  ScaffoldMessengerState messenger,
  Future<String> Function() action,
) async {
  try {
    messenger.showSnackBar(SnackBar(content: Text(await action())));
    return true;
  } on ApiException catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(e.message),
        backgroundColor: AppColors.crimsonDark,
        duration: const Duration(seconds: 6),
      ),
    );
    return false;
  }
}

/// Dialog konfirmasi untuk tindakan yang tidak bisa dibatalkan.
Future<bool> konfirmasiHapus(
  BuildContext context, {
  required String judul,
  required String pesan,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(judul),
      content: Text(pesan),
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

  return hasil ?? false;
}
