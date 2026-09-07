@Tags(['integration'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_labkom/core/network/api_client.dart';
import 'package:inventory_labkom/core/network/api_exception.dart';
import 'package:inventory_labkom/core/storage/token_storage.dart';
import 'package:inventory_labkom/features/auth/data/auth_repository.dart';
import 'package:inventory_labkom/features/auth/domain/app_user.dart';
import 'package:inventory_labkom/features/users/data/user_repository.dart';

/// Integration test: lapisan jaringan Flutter diuji terhadap backend SUNGGUHAN.
///
/// Ini yang membuktikan dio, header token, penguraian amplop respons, dan
/// pemetaan model benar-benar nyambung — hal yang tidak bisa dibuktikan
/// unit test dengan data palsu.
///
/// Prasyarat:
///   php -S 127.0.0.1:8080 -t backend/public &
///   database sudah di-import dengan seed
///
/// Jalankan:
///   flutter test test/api_integration_test.dart
///
/// Seluruh test dilewati otomatis kalau backend tidak terjangkau, supaya
/// `flutter test` biasa tidak gagal di mesin tanpa backend.
const baseUrl = 'http://127.0.0.1:8080';

Future<bool> backendUp() async {
  try {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
      validateStatus: (_) => true,
    ));
    final res = await dio.get('$baseUrl/api/health');
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

ApiClient buildClient(TokenStorage storage) {
  // baseUrl wajib ditegaskan: di lingkungan flutter test,
  // defaultTargetPlatform bernilai android, sehingga alamat bawaan jadi
  // 10.0.2.2 (alias emulator) yang tidak bisa dijangkau dari mesin ini.
  return ApiClient(storage, baseUrl: baseUrl);
}

void main() {
  late bool up;

  setUpAll(() async {
    up = await backendUp();
    if (!up) {
      stdout.writeln(
        '\n  Backend di $baseUrl tidak merespons — test integrasi dilewati.\n'
        '  Jalankan: php -S 127.0.0.1:8080 -t backend/public\n',
      );
    }
  });

  group('FR-01 Autentikasi lewat lapisan jaringan Flutter', () {
    test('login Laboran mengembalikan AppUser yang benar', () async {
      if (!up) return;

      final storage = InMemoryTokenStorage();
      final repo = AuthRepository(buildClient(storage), storage);

      final user = await repo.login(
        username: 'laboran',
        password: 'laboran123',
        rememberMe: true,
      );

      expect(user.username, 'laboran');
      expect(user.level, UserLevel.laboran);
      expect(user.isLaboran, isTrue);
      // "Ingat saya" dicentang → token ditulis ke penyimpanan.
      expect(await storage.read(), isNotNull);
    });

    test('tanpa "Ingat saya", token TIDAK ditulis ke penyimpanan', () async {
      if (!up) return;

      final storage = InMemoryTokenStorage();
      final repo = AuthRepository(buildClient(storage), storage);

      await repo.login(
        username: 'laboran',
        password: 'laboran123',
        rememberMe: false,
      );

      // Perangkat di lab sering dipakai bergantian — sesi boleh hidup selama
      // aplikasi terbuka, tapi tidak boleh tertinggal di penyimpanan.
      expect(await storage.read(), isNull);
    });

    test('password salah melempar ApiException 401', () async {
      if (!up) return;

      final storage = InMemoryTokenStorage();
      final repo = AuthRepository(buildClient(storage), storage);

      await expectLater(
        repo.login(
          username: 'laboran',
          password: 'jelas-salah',
          rememberMe: false,
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    });

    test('restore memulihkan sesi dari token tersimpan', () async {
      if (!up) return;

      final storage = InMemoryTokenStorage();
      final repo = AuthRepository(buildClient(storage), storage);

      await repo.login(
        username: 'kaprog',
        password: 'kaprog123',
        rememberMe: true,
      );

      // Klien baru, penyimpanan sama — meniru aplikasi dibuka ulang.
      final repoBaru = AuthRepository(buildClient(storage), storage);
      final restored = await repoBaru.restore();

      expect(restored, isNotNull);
      expect(restored!.level, UserLevel.kepalaProgram);
    });

    test('token sampah membuat restore mengembalikan null, bukan melempar',
        () async {
      if (!up) return;

      final storage = InMemoryTokenStorage();
      await storage.write('bukan.token.asli');

      final restored =
          await AuthRepository(buildClient(storage), storage).restore();

      expect(restored, isNull);
      // Token tidak sah juga dibuang, supaya tidak dicoba lagi terus-menerus.
      expect(await storage.read(), isNull);
    });
  });

  group('FR-12 Kelola User & penegakan peran', () {
    test('Laboran bisa membaca daftar akun', () async {
      if (!up) return;

      final storage = InMemoryTokenStorage();
      final client = buildClient(storage);
      await AuthRepository(client, storage).login(
        username: 'laboran',
        password: 'laboran123',
        rememberMe: true,
      );

      final users = await UserRepository(client).fetchAll();

      expect(users, isNotEmpty);
      expect(users.map((u) => u.username), contains('laboran'));
    });

    test('Kepala Program DITOLAK backend dengan 403', () async {
      if (!up) return;

      final storage = InMemoryTokenStorage();
      final client = buildClient(storage);
      await AuthRepository(client, storage).login(
        username: 'kaprog',
        password: 'kaprog123',
        rememberMe: true,
      );

      // Penjaga rute di Flutter cuma kenyamanan. Ini membuktikan backend
      // menolak walaupun lapisan UI dilewati sepenuhnya.
      await expectLater(
        UserRepository(client).fetchAll(),
        throwsA(isA<ApiException>()
            .having((e) => e.isForbidden, 'isForbidden', isTrue)),
      );
    });

    test('siklus penuh buat → ubah password → hapus', () async {
      if (!up) return;

      final storage = InMemoryTokenStorage();
      final client = buildClient(storage);
      await AuthRepository(client, storage).login(
        username: 'laboran',
        password: 'laboran123',
        rememberMe: true,
      );

      final repo = UserRepository(client);
      final username = 'uji_flutter_${DateTime.now().millisecondsSinceEpoch}';

      final dibuat = await repo.create(
        username: username,
        password: 'rahasia123',
        level: UserLevel.kepalaProgram,
        nip: '12345',
      );
      expect(dibuat.username, username);
      expect(dibuat.level, UserLevel.kepalaProgram);
      expect(dibuat.nip, '12345');

      await repo.update(dibuat.id, password: 'passwordbaru123');

      // Password benar-benar berganti di server, bukan cuma di respons.
      final storageBaru = InMemoryTokenStorage();
      final userBaru = await AuthRepository(
        buildClient(storageBaru),
        storageBaru,
      ).login(
        username: username,
        password: 'passwordbaru123',
        rememberMe: false,
      );
      expect(userBaru.username, username);

      await repo.delete(dibuat.id);

      final tersisa = await repo.fetchAll();
      expect(tersisa.map((u) => u.username), isNot(contains(username)));
    });

    test('pesan penolakan dari backend diteruskan apa adanya', () async {
      if (!up) return;

      final storage = InMemoryTokenStorage();
      final client = buildClient(storage);
      final me = await AuthRepository(client, storage).login(
        username: 'laboran',
        password: 'laboran123',
        rememberMe: true,
      );

      // Backend menolak dengan penjelasan spesifik; UI menampilkannya apa
      // adanya, jadi pesan itu tidak boleh hilang di lapisan jaringan.
      await expectLater(
        UserRepository(client).delete(me.id),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.message, 'message',
                contains('akun yang sedang dipakai login'))),
      );
    });
  });
}
