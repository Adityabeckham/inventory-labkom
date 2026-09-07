import 'package:flutter/foundation.dart';

/// Konfigurasi runtime aplikasi.
///
/// Alamat backend bisa ditimpa saat build tanpa mengubah kode:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
abstract final class AppConfig {
  static const _override = String.fromEnvironment('API_BASE_URL');

  /// Alamat dasar REST API.
  ///
  /// `localhost` di emulator maupun HP menunjuk ke perangkat itu sendiri,
  /// bukan ke komputer yang menjalankan backend — makanya default tiap
  /// platform berbeda. Untuk HP fisik, alamat IP komputer harus dimasukkan
  /// lewat `--dart-define`.
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://127.0.0.1:8080';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8080' // alias host dari emulator Android
        : 'http://127.0.0.1:8080';
  }

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);
}
