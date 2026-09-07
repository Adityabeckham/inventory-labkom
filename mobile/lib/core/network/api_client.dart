import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Pembungkus Dio untuk REST API Inventory Labkom.
///
/// Menempelkan token ke setiap request dan menerjemahkan amplop respons
/// backend (`{status, message, data}`) jadi data mentah atau [ApiException].
class ApiClient {
  /// [baseUrl] menimpa alamat bawaan — dipakai pengujian dan skenario
  /// deployment yang alamatnya ditentukan saat runtime.
  ApiClient(this._tokenStorage, {Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl {
    _dio.options
      ..baseUrl = _baseUrl
      ..connectTimeout = AppConfig.connectTimeout
      ..receiveTimeout = AppConfig.receiveTimeout
      ..headers['Accept'] = 'application/json'
      // Terima status apa pun; penerjemahan error dilakukan di _unwrap
      // supaya pesan dari backend tidak hilang tertelan DioException.
      ..validateStatus = (_) => true;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = sessionToken ?? await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final String _baseUrl;
  final TokenStorage _tokenStorage;

  /// Token yang hanya hidup selama aplikasi berjalan.
  ///
  /// Dipakai saat "Ingat saya" TIDAK dicentang: pengguna tetap bisa memakai
  /// aplikasi sampai menutupnya, tapi tidak ada apa pun yang tertinggal di
  /// perangkat — penting karena HP di lab sering dipakai bergantian.
  String? sessionToken;

  /// Dipanggil saat backend membalas 401 — memberi kesempatan lapisan auth
  /// membersihkan sesi dan melempar pengguna kembali ke layar Login.
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post(path, data: body));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  /// Mengunduh berkas biner — laporan PDF, Word, atau Excel (FR-08).
  ///
  /// Sengaja TIDAK lewat [_send]: [_unwrap] menolak apa pun yang bukan
  /// amplop JSON, sedangkan balasan laporan berupa byte berkas. Yang tetap
  /// berlaku adalah interceptor token, jadi endpoint berlisensi tetap bisa
  /// dijangkau — itu juga alasan berkasnya tidak boleh dibuka lewat browser
  /// luar, yang tidak akan mengirim header Authorization.
  ///
  /// Kegagalan dikenali dari status HTTP, bukan dari bentuk isinya: server
  /// tetap membalas JSON saat error, dan pesannya diteruskan apa adanya.
  Future<Uint8List> unduh(String path, {Map<String, dynamic>? query}) async {
    final Response<List<int>> response;

    try {
      response = await _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (e) {
      throw ApiException(_networkMessage(e));
    }

    final status = response.statusCode ?? 0;
    final bytes = response.data ?? const <int>[];

    if (status >= 200 && status < 300) {
      if (bytes.isEmpty) {
        throw ApiException('Server mengirim berkas kosong.', statusCode: status);
      }
      return Uint8List.fromList(bytes);
    }

    if (status == 401) {
      onUnauthorized?.call();
    }

    throw ApiException(_pesanGagalUnduh(bytes, status), statusCode: status);
  }

  /// Menggali pesan error dari badan respons yang terlanjur dibaca sebagai
  /// byte. Kalau bukan JSON — misalnya halaman error HTML dari web server —
  /// pesannya diganti yang generik daripada menampilkan potongan HTML.
  String _pesanGagalUnduh(List<int> bytes, int status) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } on FormatException {
      // Bukan JSON — jatuh ke pesan generik di bawah.
    }

    return 'Gagal mengunduh laporan (HTTP $status).';
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    final Response<dynamic> response;

    try {
      response = await call();
    } on DioException catch (e) {
      throw ApiException(_networkMessage(e));
    }

    return _unwrap(response);
  }

  dynamic _unwrap(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final body = response.data;

    if (body is! Map<String, dynamic>) {
      // Bukan JSON — biasanya HTML error page karena URL backend salah.
      throw ApiException(
        'Balasan server tidak dikenali (HTTP $status). '
        'Periksa alamat backend di pengaturan aplikasi.',
        statusCode: status,
      );
    }

    if (status >= 200 && status < 300 && body['status'] == 'success') {
      return body['data'];
    }

    if (status == 401) {
      onUnauthorized?.call();
    }

    throw ApiException(
      body['message'] as String? ?? 'Terjadi kesalahan (HTTP $status).',
      statusCode: status,
    );
  }

  String _networkMessage(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'Server tidak merespons. Periksa koneksi jaringan Anda.',
        DioExceptionType.connectionError =>
          'Tidak bisa terhubung ke server di $_baseUrl. '
              'Pastikan backend berjalan dan perangkat berada di jaringan yang sama.',
        _ => 'Gagal menghubungi server: ${e.message ?? 'penyebab tidak diketahui'}',
      };
}
