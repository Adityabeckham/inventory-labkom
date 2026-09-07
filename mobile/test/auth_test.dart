import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_labkom/core/router/app_router.dart';
import 'package:inventory_labkom/features/auth/domain/app_user.dart';
import 'package:inventory_labkom/features/shell/presentation/app_shell.dart';

void main() {
  group('UserLevel', () {
    test('nilai cocok dengan ENUM users.level di database', () {
      expect(
        UserLevel.values.map((l) => l.value).toSet(),
        {'admin', 'super_admin'},
      );
    });

    test('admin dipetakan ke Laboran, super_admin ke Kepala Program', () {
      // Penamaan yang mudah menipu: super_admin TERDENGAR lebih tinggi,
      // tapi hak aksesnya justru lebih terbatas.
      expect(UserLevel.tryParse('admin'), UserLevel.laboran);
      expect(UserLevel.tryParse('super_admin'), UserLevel.kepalaProgram);
      expect(UserLevel.laboran.label, 'Laboran');
      expect(UserLevel.kepalaProgram.label, 'Kepala Program');
    });

    test('level asing dan null ditolak', () {
      expect(UserLevel.tryParse('root'), isNull);
      expect(UserLevel.tryParse(null), isNull);
    });
  });

  group('AppUser', () {
    test('dibaca dari JSON backend', () {
      final user = AppUser.fromJson(const {
        'id_user': 1,
        'username': 'laboran',
        'level': 'admin',
        'peran': 'Laboran',
        'nip': '198504122010011002',
      });

      expect(user.id, 1);
      expect(user.isLaboran, isTrue);
      expect(user.isKepalaProgram, isFalse);
    });

    test('nip boleh kosong', () {
      final user = AppUser.fromJson(const {
        'id_user': 2,
        'username': 'kaprog',
        'level': 'super_admin',
        'nip': null,
      });

      expect(user.nip, isNull);
      expect(user.isKepalaProgram, isTrue);
    });

    test('level tidak dikenal melempar, bukan diam-diam jadi default', () {
      expect(
        () => AppUser.fromJson(const {
          'id_user': 3,
          'username': 'x',
          'level': 'root',
        }),
        throwsFormatException,
      );
    });
  });

  group('Struktur navigasi per peran', () {
    test('Laboran punya 4 tab, Kepala Program 3 tab', () {
      expect(ShellTabs.forLevel(UserLevel.laboran).length, 4);
      expect(ShellTabs.forLevel(UserLevel.kepalaProgram).length, 3);
    });

    test('Verifikasi hanya muncul untuk Kepala Program', () {
      // Laboran mengakses status pengajuan lewat grid Dashboard, bukan tab —
      // UIUX_Wireframe_dan_Flow.md §1.
      expect(ShellTabs.pathsFor(UserLevel.laboran), isNot(contains('/verifikasi')));
      expect(ShellTabs.pathsFor(UserLevel.kepalaProgram), contains('/verifikasi'));
    });

    test('Kepala Program tidak punya tab Aset Lab maupun Transaksi', () {
      final paths = ShellTabs.pathsFor(UserLevel.kepalaProgram);
      expect(paths, isNot(contains('/aset')));
      expect(paths, isNot(contains('/transaksi')));
    });

    test('setiap tab menunjuk path unik', () {
      for (final level in UserLevel.values) {
        final paths = ShellTabs.forLevel(level).map((t) => t.path).toList();
        expect(paths.toSet().length, paths.length, reason: 'duplikat pada $level');
      }
    });
  });

  group('Penjaga rute berbasis peran', () {
    // Ini lapisan kenyamanan; penjaga sesungguhnya ada di backend.
    // Tesnya tetap penting supaya matriks tidak diam-diam berubah saat rute
    // baru ditambahkan di sprint berikutnya.

    test('Laboran boleh mengakses seluruh rute kelola', () {
      for (final path in ['/dashboard', '/users', '/aset', '/transaksi', '/laporan']) {
        expect(isPathAllowedForLevel(path, UserLevel.laboran), isTrue,
            reason: 'Laboran seharusnya boleh $path');
      }
    });

    test('Kepala Program DITOLAK dari seluruh rute kelola', () {
      for (final path in ['/users', '/aset', '/transaksi']) {
        expect(isPathAllowedForLevel(path, UserLevel.kepalaProgram), isFalse,
            reason: 'Kepala Program seharusnya ditolak dari $path');
      }
    });

    test('Kepala Program boleh Dashboard, Verifikasi, dan Laporan', () {
      // Persis scope di Tabel 3.1 Use Case.
      for (final path in ['/dashboard', '/verifikasi', '/laporan']) {
        expect(isPathAllowedForLevel(path, UserLevel.kepalaProgram), isTrue,
            reason: 'Kepala Program seharusnya boleh $path');
      }
    });

    test('Laboran tidak diarahkan ke layar Verifikasi', () {
      expect(isPathAllowedForLevel('/verifikasi', UserLevel.laboran), isFalse);
    });

    test('rute tak dikenal ditolak untuk kedua peran', () {
      for (final level in UserLevel.values) {
        expect(isPathAllowedForLevel('/rute-hantu', level), isFalse);
      }
    });
  });
}
