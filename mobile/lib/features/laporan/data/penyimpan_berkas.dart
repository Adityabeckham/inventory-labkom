import 'dart:typed_data';

// Web jadi bawaan; `dart.library.io` benar di Android, iOS, desktop, dan juga
// di `flutter test` yang berjalan di VM. Karena itu penyimpannya disuntikkan
// lewat provider, supaya pengujian tidak menyentuh plugin sungguhan.
export 'penyimpan_berkas_web.dart'
    if (dart.library.io) 'penyimpan_berkas_io.dart';

/// Menyimpan berkas hasil unduhan lalu menyerahkannya ke pengguna.
///
/// Mengembalikan kalimat siap tampil tentang apa yang terjadi — di HP
/// berkasnya dibuka aplikasi lain, di web browser yang mengunduhnya, dan
/// keduanya perlu dijelaskan berbeda.
typedef PenyimpanBerkas = Future<String> Function(
  Uint8List bytes,
  String namaBerkas,
  String mime,
);
