import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Menyimpan ke penyimpanan privat aplikasi lalu membukanya dengan aplikasi
/// bawaan perangkat.
///
/// Sengaja TIDAK menulis ke folder Download publik: di Android itu butuh
/// MediaStore dan izin tambahan, sementara laporan ini memang untuk langsung
/// dibuka atau dibagikan, bukan disimpan permanen di perangkat lab.
Future<String> simpanDanBuka(
  Uint8List bytes,
  String namaBerkas,
  String mime,
) async {
  final dir = await getApplicationDocumentsDirectory();
  final berkas = File('${dir.path}/$namaBerkas');
  await berkas.writeAsBytes(bytes, flush: true);

  final hasil = await OpenFilex.open(berkas.path, type: mime);

  return switch (hasil.type) {
    ResultType.done => '$namaBerkas dibuka.',
    ResultType.noAppToOpen =>
      '$namaBerkas tersimpan, tapi belum ada aplikasi di perangkat ini '
          'yang bisa membukanya.',
    ResultType.permissionDenied =>
      '$namaBerkas tersimpan, tapi izin membukanya ditolak.',
    _ => '$namaBerkas tersimpan di penyimpanan aplikasi.',
  };
}
