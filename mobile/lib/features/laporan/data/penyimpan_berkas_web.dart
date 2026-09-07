import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Menyerahkan berkas ke browser lewat object URL dan anchor.
///
/// Web dipakai untuk verifikasi dan demo; unduhan yang dipicu skrip bisa
/// ditahan sebagian browser, dan itu di luar kendali aplikasi.
Future<String> simpanDanBuka(
  Uint8List bytes,
  String namaBerkas,
  String mime,
) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = namaBerkas
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // Dilepas setelah klik supaya memori blob tidak tertahan selama sesi.
  web.URL.revokeObjectURL(url);

  return '$namaBerkas diunduh browser.';
}
