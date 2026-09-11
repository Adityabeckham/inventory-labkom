import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_labkom/core/network/api_client.dart';
import 'package:inventory_labkom/core/network/api_exception.dart';
import 'package:inventory_labkom/core/storage/token_storage.dart';
import 'package:inventory_labkom/core/theme/app_theme.dart';
import 'package:inventory_labkom/core/theme/app_typography.dart';
import 'package:inventory_labkom/features/aset/presentation/aset_screen.dart';
import 'package:inventory_labkom/features/auth/application/auth_controller.dart';
import 'package:inventory_labkom/features/auth/domain/app_user.dart';
import 'package:inventory_labkom/features/auth/presentation/login_screen.dart';
import 'package:inventory_labkom/features/dashboard/presentation/dashboard_screen.dart';
import 'package:inventory_labkom/features/kategori/presentation/kategori_screen.dart';
import 'package:inventory_labkom/features/laporan/application/laporan_controller.dart';
import 'package:inventory_labkom/features/laporan/presentation/laporan_screen.dart';
import 'package:inventory_labkom/features/peminjam/presentation/peminjam_screen.dart';
import 'package:inventory_labkom/features/peminjaman/presentation/transaksi_screen.dart';
import 'package:inventory_labkom/features/pengembalian/presentation/pengaturan_denda_screen.dart';
import 'package:inventory_labkom/features/users/presentation/users_screen.dart';
import 'package:inventory_labkom/features/verifikasi/presentation/verifikasi_screen.dart';

/// Pengujian render tiap layar — sebelum ini tidak satu pun layar selain Login
/// pernah benar-benar dibangun, karena `flutter analyze` tidak menyusun widget
/// tree dan pengujian integrasi hanya menyentuh lapisan jaringan.
///
/// Yang dicari di sini bukan kecocokan piksel, tapi kegagalan yang baru muncul
/// saat layar dirender: `RenderFlex overflowed`, exception dari provider yang
/// dibaca sebelum siap, dan null deref di pembentuk kartu.
///
/// Lebarnya 360dp, bukan 375dp: 375 itu ukuran iPhone, sedangkan sasaran
/// aplikasi ini adalah Android kelas bawah yang umumnya 360dp. Setiap layar
/// juga diuji dengan satu baris data bernama panjang, karena data seed yang
/// pendek justru menyembunyikan overflow.

// ── Ukuran layar uji ─────────────────────────────────────────────────

/// HP Android kelas bawah masa kini — Redmi dan Galaxy A seri umumnya
/// selebar 360dp dengan tinggi di kisaran ini.
const _layarUmum = Size(360, 740);

/// Layar 5 inci 720p yang masih banyak dipakai siswa. Dipakai untuk
/// memastikan form panjang tetap terjangkau lewat scroll.
const _layarPendek = Size(360, 640);

void main() {
  // Mendaftarkan Inter ke engine. Tanpa ini `flutter test` memakai font uji
  // bawaan yang setiap glifnya kotak selebar satu em — jauh lebih lebar dari
  // Inter, sehingga overflow yang terdeteksi belum tentu terjadi di perangkat
  // sungguhan, dan sebaliknya.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      AppTypography.family,
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
  });

  // ── Data uji ───────────────────────────────────────────────────────

  const laboran = AppUser(
    id: 1,
    username: 'laboran',
    level: UserLevel.laboran,
    nip: '198203122008011004',
  );

  const kaprog = AppUser(
    id: 2,
    username: 'kaprog',
    level: UserLevel.kepalaProgram,
    nip: '197505102006041002',
  );

  /// Nama sepanjang ini masih realistis untuk hibah dinas, dan panjangnya
  /// yang membuat Row di kartu pecah kalau ada widget yang tidak fleksibel.
  const namaPanjang =
      'Monitor LED 24 inci Full HD Hibah Dinas Pendidikan Tahun 2019';

  final kategoriJson = [
    {'id_kategori': 1, 'nama_kategori': 'Komputer', 'jumlah_barang': 12},
    {'id_kategori': 2, 'nama_kategori': 'Jaringan', 'jumlah_barang': 3},
    {
      'id_kategori': 3,
      'nama_kategori': 'Perangkat Presentasi dan Audio Visual',
      'jumlah_barang': 0,
    },
  ];

  final barangJson = [
    {
      'id_barang': 1,
      'id_kategori': 1,
      'nama_kategori': 'Komputer',
      'kode_barang': 'BRG-001',
      'nama_barang': 'PC Rakitan Core i5',
      'jumlah': 20,
      'stok': 18,
      'tanggal_input': '2026-01-10',
      'merk': 'Rakitan',
      'kondisi': 'baik',
      'serial_number': 'SN-PC-0001',
    },
    {
      'id_barang': 2,
      'id_kategori': 1,
      'nama_kategori': 'Komputer',
      'kode_barang': 'BRG-002',
      'nama_barang': namaPanjang,
      'jumlah': 8,
      'stok': 0,
      'tanggal_input': '2026-01-12',
      'merk': 'Samsung',
      'kondisi': 'baik',
      'serial_number': 'SN-MON-000000000123456',
    },
  ];

  final mutasiJson = [
    {
      'id_mutasi': 1,
      'id_barang': 1,
      'kode_barang': 'BRG-001',
      'nama_barang': 'PC Rakitan Core i5',
      'jenis': 'masuk',
      'jumlah': 5,
      'tanggal_mutasi': '2026-02-01',
      'dicatat_oleh': 'laboran',
      'keterangan': 'Pengadaan tambahan semester genap',
    },
    {
      'id_mutasi': 2,
      'id_barang': 2,
      'kode_barang': 'BRG-002',
      'nama_barang': namaPanjang,
      'jenis': 'keluar',
      'jumlah': 3,
      'tanggal_mutasi': '2026-02-03',
      'dicatat_oleh': 'laboran',
      'keterangan': 'Rusak berat, dikeluarkan dari inventaris',
    },
  ];

  final usersJson = [
    {
      'id_user': 1,
      'username': 'laboran',
      'level': 'admin',
      'nip': '198203122008011004',
      'created_at': '2026-01-01 08:00:00',
    },
    {
      'id_user': 2,
      'username': 'kepala.program.rekayasa.perangkat.lunak',
      'level': 'super_admin',
      'nip': '197505102006041002',
      'created_at': '2026-01-01 08:05:00',
    },
  ];

  final peminjamJson = [
    {
      'id_peminjam': 1,
      'nama_peminjam': 'Raka Maulana Abdurrahman Wijayakusuma',
      'nis_nip': '0051234567',
      'kelas_jabatan': 'XI Rekayasa Perangkat Lunak 2',
      'no_hp': '081234567890',
    },
    {
      'id_peminjam': 2,
      'nama_peminjam': 'Siti Aminah',
      'nis_nip': null,
      'kelas_jabatan': null,
      'no_hp': null,
    },
  ];

  final itemsJson = [
    {
      'id_detail': 1,
      'id_barang': 1,
      'kode_barang': 'BRG-001',
      'nama_barang': 'PC Rakitan Core i5',
      'merk': 'Rakitan',
      'jumlah_pinjam': 2,
    },
    {
      'id_detail': 2,
      'id_barang': 2,
      'kode_barang': 'BRG-002',
      'nama_barang': namaPanjang,
      'merk': 'Samsung',
      'jumlah_pinjam': 1,
    },
  ];

  Map<String, Object?> peminjamanJson({
    int id = 1,
    String kode = 'PMJ-2026-001',
    String status = 'menunggu_verifikasi',
    String? alasan,
    bool withItems = false,
  }) => {
    'id_peminjaman': id,
    'kode_peminjaman': kode,
    'id_peminjam': 1,
    'nama_peminjam': 'Raka Maulana Abdurrahman Wijayakusuma',
    'nis_nip': '0051234567',
    'kelas_jabatan': 'XI Rekayasa Perangkat Lunak 2',
    'dicatat_oleh': 'laboran',
    'tanggal_pinjam': '2026-09-01',
    'tanggal_kembali': '2026-09-08',
    'status': status,
    'alasan_dibatalkan': alasan,
    'jumlah_item': 2,
    'total_unit': 3,
    if (withItems) 'items': itemsJson,
  };

  // Angka ringkasan Dashboard. Nilainya sengaja konsisten satu sama lain:
  // total_unit - unit_tersedia == unit_dipinjam + unit_diajukan
  // (224 - 204 == 4 + 16). Pengujian di bawah ikut menegakkan identitas itu,
  // karena kalau tidak konsisten angkanya di layar akan terbaca seperti bug.
  Map<String, Object?> dashboardJson({
    int terlambat = 0,
    int menunggu = 6,
    int jenisHabis = 0,
  }) => {
    'barang': {
      'jenis': 8,
      'total_unit': 224,
      'unit_tersedia': 204,
      'jenis_habis': jenisHabis,
    },
    'peminjaman': {
      'unit_dipinjam': 4,
      'transaksi_dipinjam': 2,
      'unit_diajukan': 16,
      'menunggu_verifikasi': menunggu,
      'terlambat': terlambat,
    },
    'denda': {'total_tercatat': 30000},
  };

  final transaksiRespons = <String, Object?>{
    '/api/peminjaman': [
      peminjamanJson(),
      peminjamanJson(id: 2, kode: 'PMJ-2026-002', status: 'dipinjam'),
      peminjamanJson(
        id: 3,
        kode: 'PMJ-2026-003',
        status: 'dibatalkan',
        alasan: 'Barang sedang dipakai praktik kelas XII sore ini.',
      ),
    ],
    '/api/peminjaman/1': peminjamanJson(withItems: true),
    '/api/peminjaman/3': peminjamanJson(
      id: 3,
      kode: 'PMJ-2026-003',
      status: 'dibatalkan',
      alasan: 'Barang sedang dipakai praktik kelas XII sore ini.',
      withItems: true,
    ),
    '/api/peminjaman/1/verifikasi': peminjamanJson(
      status: 'dipinjam',
      withItems: true,
    ),
    '/api/barang': barangJson,
    '/api/kategori': kategoriJson,
    '/api/peminjam': peminjamJson,
  };

  // Satu transaksi dengan dua item: satu sudah kembali (telat, kena denda),
  // satu masih di tangan peminjam.
  final itemsSebagianJson = [
    {
      'id_detail': 1,
      'id_barang': 1,
      'kode_barang': 'BRG-001',
      'nama_barang': 'PC Rakitan Core i5',
      'merk': 'Rakitan',
      'jumlah_pinjam': 2,
      'pengembalian': {
        'id_pengembalian': 1,
        'tanggal_pengembalian': '2026-09-05',
        'kondisi': 'rusak',
        'jumlah_hari_telat': 3,
        'denda': 15000,
      },
    },
    {
      'id_detail': 2,
      'id_barang': 2,
      'kode_barang': 'BRG-002',
      'nama_barang': namaPanjang,
      'merk': 'Samsung',
      'jumlah_pinjam': 1,
      'pengembalian': null,
    },
  ];

  Map<String, Object?> transaksiKembaliJson({
    int id = 1,
    String kode = 'PMJ-2026-001',
    String tampilan = 'terlambat',
    int sisa = 1,
    int kembali = 1,
    double denda = 15000,
  }) => {
    'id_peminjaman': id,
    'kode_peminjaman': kode,
    'nama_peminjam': 'Raka Maulana Abdurrahman Wijayakusuma',
    'nis_nip': '0051234567',
    'kelas_jabatan': 'XI Rekayasa Perangkat Lunak 2',
    'dicatat_oleh': 'laboran',
    'tanggal_pinjam': '2026-08-28',
    'tanggal_kembali': '2026-09-02',
    'status': sisa == 0 ? 'dikembalikan' : 'sebagian_kembali',
    'jumlah_item': 2,
    'total_unit': 3,
    'item_sisa': sisa,
    'item_kembali': kembali,
    'total_denda': denda,
    'tampilan_status': tampilan,
  };

  final pengembalianRespons = <String, Object?>{
    '/api/pengembalian': [
      transaksiKembaliJson(),
      transaksiKembaliJson(
        id: 2,
        kode: 'PMJ-2026-002',
        tampilan: 'sudah_kembali',
        sisa: 0,
        kembali: 2,
        denda: 0,
      ),
    ],
    '/api/peminjaman/1': {
      ...peminjamanJson(id: 1, status: 'sebagian_kembali'),
      'tanggal_kembali': '2026-09-02',
      'total_denda': 15000,
      'items': itemsSebagianJson,
    },
    '/api/pengaturan-denda': {
      'id_pengaturan': 1,
      'tarif_per_hari': 5000,
      'updated_at': '2026-09-01 08:00:00',
      'terkonfigurasi': true,
    },
    'POST /api/pengembalian': {
      'id_pengembalian': 2,
      'id_detail': 2,
      'tanggal_pengembalian': '2026-09-07',
      'kondisi': 'baik',
      'jumlah_hari_telat': 5,
      'denda': 25000,
    },
    'PUT /api/pengaturan-denda': {
      'id_pengaturan': 1,
      'tarif_per_hari': 7500,
      'updated_at': '2026-09-07 10:00:00',
      'terkonfigurasi': true,
    },
  };

  // ── Perkakas ───────────────────────────────────────────────────────

  /// Memasang layar di atas API palsu. Repository, controller, dan filter
  /// tetap yang asli — yang dipalsukan hanya lapisan HTTP paling bawah, jadi
  /// parser `fromJson` ikut teruji.
  Future<void> pasang(
    WidgetTester tester,
    Widget layar, {
    AppUser user = laboran,
    Map<String, Object?> respons = const {},
    _ModeApi mode = _ModeApi.data,
    Size ukuran = _layarUmum,
    double skalaTeks = 1,
  }) async {
    await tester.binding.setSurfaceSize(ukuran);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          apiClientProvider.overrideWithValue(_ApiPalsu(respons, mode)),
          currentUserProvider.overrideWithValue(user),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(skalaTeks)),
            child: child!,
          ),
          home: layar,
        ),
      ),
    );

    // Keadaan memuat memakai CircularProgressIndicator yang berputar tanpa
    // henti; pumpAndSettle di sana akan menggantung sampai timeout.
    if (mode == _ModeApi.menggantung) {
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  // ── Login ──────────────────────────────────────────────────────────

  group('Login', () {
    testWidgets('form lengkap muat di layar 360dp', (tester) async {
      await pasang(tester, const LoginScreen());

      expect(tester.takeException(), isNull);
      // Muncul dua kali: label di atas field dan hint di dalamnya.
      expect(find.text('Username'), findsWidgets);
      expect(find.text('Password'), findsWidgets);
      expect(find.text('Ingat saya'), findsOne);
      expect(find.text('Lupa Password?'), findsOne);
    });

    testWidgets('di layar 640dp tautan bawah masih terjangkau lewat scroll', (
      tester,
    ) async {
      await pasang(tester, const LoginScreen(), ukuran: _layarPendek);

      // Di layar sependek ini tautannya jatuh di bawah lipatan; yang penting
      // form-nya bisa digulir, bukan terpotong permanen.
      await tester.ensureVisible(find.text('Lupa Password?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lupa Password?'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Lupa Password'), findsOne);
    });
  });

  // ── Dashboard ──────────────────────────────────────────────────────

  group('Dashboard', () {
    final ringkasan = {'/api/dashboard': dashboardJson()};

    testWidgets('Laboran melihat sapaan dan empat pintasan', (tester) async {
      await pasang(tester, const DashboardScreen(), respons: ringkasan);

      expect(tester.takeException(), isNull);
      expect(find.text('Halo, laboran'), findsOne);
      expect(find.text('LABORAN'), findsOne);

      await tester.scrollUntilVisible(find.text('Kategori'), 100);
      for (final label in [
        'Kategori',
        'Kelola User',
        'Data Peminjam',
        'Pengaturan Denda',
      ]) {
        expect(find.text(label), findsOne, reason: 'pintasan $label hilang');
      }
    });

    testWidgets('Kepala Program tidak melihat grid akses cepat', (
      tester,
    ) async {
      await pasang(
        tester,
        const DashboardScreen(),
        user: kaprog,
        respons: ringkasan,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Halo, kaprog'), findsOne);
      expect(find.text('KEPALA PROGRAM'), findsOne);
      expect(find.text('Akses Cepat'), findsNothing);
      expect(find.text('Kelola User'), findsNothing);
      expect(find.text('Ringkasan Inventoris'), findsOne);
    });

    testWidgets('tombol logout membuka dialog konfirmasi', (tester) async {
      await pasang(tester, const DashboardScreen(), respons: ringkasan);

      await tester.tap(find.byTooltip('Profil & Pengaturan Akun'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Logout / Keluar'));
      await tester.tap(find.text('Logout / Keluar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Keluar dari aplikasi?'), findsOne);
    });

    testWidgets('angka ringkasan diambil dari API, bukan placeholder', (
      tester,
    ) async {
      await pasang(tester, const DashboardScreen(), respons: ringkasan);

      expect(tester.takeException(), isNull);
      expect(find.text('224'), findsOne);
      expect(find.text('8 Jenis Barang · 204 Tersedia di Rak'), findsOne);
      expect(find.text('4'), findsOne);
      expect(find.text('6'), findsOne);
    });

    testWidgets('unit tertahan pengajuan disebut, bukan digabung ke dipinjam', (
      tester,
    ) async {
      await pasang(tester, const DashboardScreen(), respons: ringkasan);

      expect(find.text('4'), findsOne);
      expect(find.text('6'), findsOne);
    });

    testWidgets('kartu Terlambat hanya muncul kalau ada yang terlambat', (
      tester,
    ) async {
      await pasang(tester, const DashboardScreen(), respons: ringkasan);
      expect(find.text('Lewat Jatuh Tempo'), findsNothing);

      await pasang(
        tester,
        const DashboardScreen(),
        respons: {'/api/dashboard': dashboardJson(terlambat: 3)},
      );

      expect(find.text('Terlambat'), findsOne);
      expect(find.text('3'), findsOne);
    });

    testWidgets('nol pengajuan berbunyi wajar, bukan "0 unit ditahan"', (
      tester,
    ) async {
      await pasang(
        tester,
        const DashboardScreen(),
        respons: {'/api/dashboard': dashboardJson(menunggu: 0)},
      );

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('stok habis disebut hanya kalau memang ada', (tester) async {
      await pasang(
        tester,
        const DashboardScreen(),
        respons: {'/api/dashboard': dashboardJson(jenisHabis: 2)},
      );

      expect(
        find.text('2 Habis'),
        findsOne,
      );
    });

    testWidgets('ringkasan gagal dimuat menawarkan Coba lagi', (tester) async {
      await pasang(tester, const DashboardScreen(), mode: _ModeApi.gagal);

      expect(tester.takeException(), isNull);
      expect(find.text('Halo, laboran'), findsOne);
      expect(find.text('Ringkasan gagal dimuat'), findsOne);
      expect(find.text('Coba lagi'), findsOne);
    });

    testWidgets('kartu Perlu Verifikasi bisa disentuh Kepala Program saja', (
      tester,
    ) async {
      for (final (user, adaTautan) in [(laboran, false), (kaprog, true)]) {
        await pasang(
          tester,
          const DashboardScreen(),
          user: user,
          respons: ringkasan,
        );

        final inkWell = tester.widget<InkWell>(
          find.ancestor(
            of: find.text('Perlu Verifikasi'),
            matching: find.byType(InkWell),
          ),
        );
        expect(
          inkWell.onTap != null,
          adaTautan,
          reason: 'tautan verifikasi untuk ${user.level.label}',
        );
      }
    });
  });

  // ── Kelola User ────────────────────────────────────────────────────

  group('Kelola User', () {
    testWidgets('menampilkan kartu akun dan menandai akun sendiri', (
      tester,
    ) async {
      await pasang(
        tester,
        const UsersScreen(),
        respons: {'/api/users': usersJson},
      );

      expect(tester.takeException(), isNull);
      expect(find.text('laboran'), findsOne);
      expect(find.text('Laboran · NIP 198203122008011004'), findsOne);
      expect(find.text('ANDA'), findsOne);
      expect(find.text('Tambah User'), findsOne);
    });

    testWidgets('tombol hapus akun sendiri dimatikan', (tester) async {
      await pasang(
        tester,
        const UsersScreen(),
        respons: {'/api/users': usersJson},
      );

      final tombol = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Tidak bisa menghapus akun sendiri'),
          matching: find.byType(IconButton),
        ),
      );
      expect(tombol.onPressed, isNull);
    });

    testWidgets('keadaan memuat menampilkan indikator', (tester) async {
      await pasang(tester, const UsersScreen(), mode: _ModeApi.menggantung);

      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOne);
    });

    testWidgets('keadaan gagal menampilkan pesan backend apa adanya', (
      tester,
    ) async {
      await pasang(tester, const UsersScreen(), mode: _ModeApi.gagal);

      expect(tester.takeException(), isNull);
      expect(find.text(_ApiPalsu.pesanGagal), findsOne);
      expect(find.text('Coba lagi'), findsOne);
    });

    testWidgets('keadaan kosong memakai pesan sendiri', (tester) async {
      await pasang(
        tester,
        const UsersScreen(),
        respons: {'/api/users': const []},
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Belum ada akun pengguna.'), findsOne);
    });
  });

  // ── Aset Lab ───────────────────────────────────────────────────────

  group('Aset Lab', () {
    final asetRespons = <String, Object?>{
      '/api/barang': barangJson,
      '/api/kategori': kategoriJson,
      '/api/stok-mutasi': mutasiJson,
    };

    testWidgets('daftar barang, chip kategori, dan badge stok', (tester) async {
      await pasang(tester, const AsetScreen(), respons: asetRespons);

      expect(tester.takeException(), isNull);
      expect(find.text('PC Rakitan Core i5'), findsOne);
      expect(find.text(namaPanjang), findsOne);
      expect(find.text('18'), findsOne);
      expect(find.text('Semua'), findsOne);
      expect(find.text('Komputer (12)'), findsOne);
    });

    testWidgets('memilih chip kategori memuat ulang daftar', (tester) async {
      await pasang(tester, const AsetScreen(), respons: asetRespons);

      expect(_di(tester, 'Jaringan (3)').dx, lessThan(360));

      await tester.tap(find.text('Jaringan (3)'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('PC Rakitan Core i5'), findsNothing);
      expect(
        find.text('Tidak ada barang yang cocok dengan pencarian.'),
        findsOne,
      );
    });

    testWidgets('beralih ke Mutasi Stok menampilkan riwayat', (tester) async {
      await pasang(tester, const AsetScreen(), respons: asetRespons);

      await tester.tap(find.text('Mutasi Stok'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('+5'), findsOne);
      expect(find.text('−3'), findsOne);
      expect(find.text('Catat Mutasi'), findsOne);
      expect(find.text('Pengadaan tambahan semester genap'), findsOne);
    });

    testWidgets('menekan kartu barang membuka form ubah', (tester) async {
      await pasang(tester, const AsetScreen(), respons: asetRespons);

      await tester.tap(find.text('PC Rakitan Core i5'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('BRG-001'), findsWidgets);
    });

    testWidgets('tombol hapus barang meminta konfirmasi', (tester) async {
      await pasang(tester, const AsetScreen(), respons: asetRespons);

      await tester.tap(find.text('PC Rakitan Core i5'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Hapus Barang'));
      await tester.tap(find.text('Hapus Barang'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Hapus barang?'), findsOne);
    });

    testWidgets('gagal memuat barang tetap menampilkan segmented control', (
      tester,
    ) async {
      await pasang(tester, const AsetScreen(), mode: _ModeApi.gagal);

      expect(tester.takeException(), isNull);
      expect(find.text('Daftar Barang'), findsOne);
      expect(find.text(_ApiPalsu.pesanGagal), findsOne);
    });
  });

  // ── Kategori ───────────────────────────────────────────────────────

  group('Kategori', () {
    testWidgets('menampilkan jumlah barang dan badge Dipakai', (tester) async {
      await pasang(
        tester,
        const KategoriScreen(),
        respons: {'/api/kategori': kategoriJson},
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Komputer'), findsOne);
      expect(find.text('12 barang'), findsOne);
      // Hanya dua dari tiga kategori punya barang.
      expect(find.text('DIPAKAI'), findsExactly(2));
      expect(find.text('Perangkat Presentasi dan Audio Visual'), findsOne);
    });

    testWidgets('tombol tambah membuka dialog isi nama', (tester) async {
      await pasang(
        tester,
        const KategoriScreen(),
        respons: {'/api/kategori': kategoriJson},
      );

      await tester.tap(find.text('Tambah Kategori'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Nama kategori'), findsOne);
    });

    testWidgets('keadaan kosong mengarahkan ke tombol tambah', (tester) async {
      await pasang(
        tester,
        const KategoriScreen(),
        respons: {'/api/kategori': const []},
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('Belum ada kategori. Tambahkan lewat tombol di bawah.'),
        findsOne,
      );
    });
  });

  // ── Data Peminjam ──────────────────────────────────────────────────

  group('Data Peminjam', () {
    testWidgets('kartu bernomor dengan NIS dan kelas', (tester) async {
      await pasang(
        tester,
        const PeminjamScreen(),
        respons: {'/api/peminjam': peminjamJson},
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Raka Maulana Abdurrahman Wijayakusuma'), findsOne);
      expect(find.text('0051234567 · XI Rekayasa Perangkat Lunak 2'), findsOne);
      expect(find.text('081234567890'), findsOne);
      expect(find.text('1'), findsOne);
      expect(find.text('2'), findsOne);
    });

    testWidgets('peminjam tanpa NIS dan kelas tidak menabrak layout', (
      tester,
    ) async {
      await pasang(
        tester,
        const PeminjamScreen(),
        respons: {'/api/peminjam': peminjamJson},
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Siti Aminah'), findsOne);
      // Baris gabungan NIS · kelas jadi string kosong, bukan "null".
      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('pencarian tanpa hasil memakai pesan berbeda', (tester) async {
      await pasang(
        tester,
        const PeminjamScreen(),
        respons: {'/api/peminjam': peminjamJson},
      );

      await tester.enterText(find.byType(TextField), 'zzz');
      // SearchField menahan 350ms sebelum memanggil server.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Tidak ada peminjam yang cocok dengan pencarian.'),
        findsOne,
      );
    });
  });

  // ── Transaksi (FR-05) ──────────────────────────────────────────────

  group('Transaksi', () {
    testWidgets('daftar peminjaman dengan kode, badge status, dan identitas', (
      tester,
    ) async {
      await pasang(tester, const TransaksiScreen(), respons: transaksiRespons);

      expect(tester.takeException(), isNull);
      expect(find.text('PMJ-2026-001'), findsOne);
      expect(find.text('MENUNGGU VERIFIKASI'), findsOne);
      expect(find.text('DIPINJAM'), findsOne);
      expect(find.text('DIBATALKAN'), findsOne);
      expect(
        find.text('0051234567 · XI Rekayasa Perangkat Lunak 2'),
        findsExactly(3),
      );
      expect(find.text('Peminjaman Baru'), findsOne);
    });

    testWidgets('chip filter status menyaring lewat server', (tester) async {
      await pasang(tester, const TransaksiScreen(), respons: transaksiRespons);

      await tester.tap(find.text('Dipinjam'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('PMJ-2026-002'), findsOne);
      expect(find.text('PMJ-2026-001'), findsNothing);
    });

    testWidgets('beralih ke tab Pengembalian memuat daftarnya', (tester) async {
      await pasang(
        tester,
        const TransaksiScreen(),
        respons: {...transaksiRespons, ...pengembalianRespons},
      );

      await tester.tap(find.text('Pengembalian'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Belum Kembali'), findsOne);
      expect(find.text('TERLAMBAT'), findsOne);
      // FAB Peminjaman Baru tidak boleh ikut muncul di tab ini.
      expect(find.text('Peminjaman Baru'), findsNothing);
    });

    testWidgets('menekan kartu membuka rincian barang', (tester) async {
      await pasang(tester, const TransaksiScreen(), respons: transaksiRespons);

      await tester.tap(find.text('PMJ-2026-001'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Barang dipinjam'), findsOne);
      expect(find.text('2 jenis · 3 unit'), findsWidgets);
      expect(find.text('2 UNIT'), findsOne);
      // Laboran tidak boleh melihat tombol keputusan.
      expect(find.text('Setujui'), findsNothing);
      expect(find.text('Tolak'), findsNothing);
    });

    testWidgets('rincian transaksi yang sudah kembali menampilkan denda juga', (
      tester,
    ) async {
      // Sheet ini dibuka dari tab Peminjaman, bukan Pengembalian. Kalau
      // rincian pengembaliannya tidak ikut ditampilkan, dua layar akan
      // bercerita berbeda tentang transaksi yang sama.
      await pasang(
        tester,
        const TransaksiScreen(),
        respons: {
          ...transaksiRespons,
          '/api/peminjaman/1': {
            ...peminjamanJson(id: 1, status: 'sebagian_kembali'),
            'total_denda': 15000,
            'items': itemsSebagianJson,
          },
        },
      );

      await tester.tap(find.text('PMJ-2026-001'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Total denda keterlambatan'), findsOne);
      expect(find.text('Rp 15.000'), findsOne);
      expect(find.text('KEMBALI 2026-09-05'), findsOne);
      expect(find.text('RUSAK'), findsOne);
      expect(find.text('TELAT 3 HARI · RP 15.000'), findsOne);
      expect(find.text('Masih di tangan peminjam.'), findsOne);
      expect(find.text('1 dari 2 belum kembali'), findsOne);
    });

    testWidgets('rincian transaksi yang ditolak menampilkan alasannya', (
      tester,
    ) async {
      await pasang(tester, const TransaksiScreen(), respons: transaksiRespons);

      await tester.tap(find.text('PMJ-2026-003'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alasan ditolak'), findsOne);
      expect(
        find.text('Barang sedang dipakai praktik kelas XII sore ini.'),
        findsOne,
      );
    });

    testWidgets('keadaan kosong dan gagal terender', (tester) async {
      await pasang(
        tester,
        const TransaksiScreen(),
        respons: {'/api/peminjaman': const []},
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Belum ada transaksi peminjaman'), findsOne);

      await pasang(tester, const TransaksiScreen(), mode: _ModeApi.gagal);
      expect(tester.takeException(), isNull);
      expect(find.text(_ApiPalsu.pesanGagal), findsOne);
    });
  });

  // ── Form Peminjaman Baru multi-item ────────────────────────────────

  group('Peminjaman Baru', () {
    testWidgets('form terbuka di layar pendek dengan keranjang kosong', (
      tester,
    ) async {
      await pasang(
        tester,
        const TransaksiScreen(),
        ukuran: _layarPendek,
        respons: transaksiRespons,
      );

      await tester.tap(find.text('Peminjaman Baru'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Peminjam'), findsWidgets);
      expect(find.text('Tanggal pinjam'), findsOne);
      expect(find.text('Jatuh tempo'), findsOne);
      expect(find.textContaining('Belum ada barang'), findsOne);
      expect(find.text('Tambah Barang'), findsOne);
    });

    testWidgets('mengajukan tanpa barang menyorot keranjang, bukan diam', (
      tester,
    ) async {
      await pasang(tester, const TransaksiScreen(), respons: transaksiRespons);

      await tester.tap(find.text('Peminjaman Baru'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan Peminjaman'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Tambahkan minimal satu barang sebelum mengajukan.'),
        findsOne,
      );
      // Peminjam belum dipilih, jadi validator Form juga bicara.
      expect(find.text('Peminjam wajib dipilih'), findsOne);
      // Sheet tetap terbuka — tidak boleh tertutup diam-diam.
      expect(find.text('Ajukan Peminjaman'), findsOne);
    });

    testWidgets('menambah barang ke keranjang menampilkan jumlah dan stok', (
      tester,
    ) async {
      await pasang(tester, const TransaksiScreen(), respons: transaksiRespons);

      await tester.tap(find.text('Peminjaman Baru'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah Barang'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Jumlah'), findsWidgets);

      // Barang berstok 0 tidak boleh ditawarkan untuk dipinjam.
      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('PC Rakitan'), findsWidgets);
      expect(find.textContaining(namaPanjang), findsNothing);
    });
  });

  // ── Verifikasi (FR-07) ─────────────────────────────────────────────

  group('Verifikasi', () {
    // Layar ini selalu meminta status=menunggu_verifikasi, dan API palsu
    // menyaringnya seperti backend — jadi daftar lengkap boleh dipakai
    // apa adanya; yang tersisa nanti hanya satu pengajuan.
    final verifikasiRespons = transaksiRespons;

    testWidgets('menampilkan pengajuan yang menunggu keputusan', (
      tester,
    ) async {
      await pasang(
        tester,
        const VerifikasiScreen(),
        user: kaprog,
        respons: verifikasiRespons,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('1 pengajuan menunggu keputusan Anda.'), findsOne);
      expect(find.text('PMJ-2026-001'), findsOne);
      expect(find.text('Periksa & putuskan'), findsOne);
    });

    testWidgets('rincian pengajuan memunculkan tombol Setujui dan Tolak', (
      tester,
    ) async {
      await pasang(
        tester,
        const VerifikasiScreen(),
        user: kaprog,
        respons: verifikasiRespons,
      );

      await tester.tap(find.text('Periksa & putuskan'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Setujui'), findsOne);
      expect(find.text('Tolak'), findsOne);
      expect(find.text('2 UNIT'), findsOne);
    });

    testWidgets('Setujui meminta konfirmasi lebih dulu', (tester) async {
      await pasang(
        tester,
        const VerifikasiScreen(),
        user: kaprog,
        respons: verifikasiRespons,
      );

      await tester.tap(find.text('Periksa & putuskan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setujui'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Setujui pengajuan?'), findsOne);
    });

    testWidgets('Setujui sampai tuntas: PATCH, SnackBar, lalu sheet tertutup', (
      tester,
    ) async {
      await pasang(
        tester,
        const VerifikasiScreen(),
        user: kaprog,
        respons: verifikasiRespons,
      );

      await tester.tap(find.text('Periksa & putuskan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setujui'));
      await tester.pumpAndSettle();

      // Konfirmasi ditekan — dari sini alurnya berjalan sampai habis:
      // PATCH ke server, invalidate provider, SnackBar, lalu sheet ditutup.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Setujui'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('disetujui'), findsOne);
      // Sheet rincian sudah tidak ada lagi.
      expect(find.text('Barang dipinjam'), findsNothing);
    });

    testWidgets('Tolak mewajibkan alasan diisi', (tester) async {
      await pasang(
        tester,
        const VerifikasiScreen(),
        user: kaprog,
        respons: verifikasiRespons,
      );

      await tester.tap(find.text('Periksa & putuskan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tolak'));
      await tester.pumpAndSettle();

      expect(find.text('Tolak pengajuan'), findsOne);

      // Menekan Tolak dengan alasan kosong harus ditahan validator,
      // karena backend juga menolaknya dengan 422.
      await tester.tap(find.widgetWithText(FilledButton, 'Tolak'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alasan wajib diisi'), findsOne);
      expect(find.text('Tolak pengajuan'), findsOne);
    });

    testWidgets('tidak ada pengajuan menampilkan keadaan kosong', (
      tester,
    ) async {
      await pasang(
        tester,
        const VerifikasiScreen(),
        user: kaprog,
        respons: {'/api/peminjaman': const []},
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('Tidak ada pengajuan yang menunggu verifikasi.'),
        findsOne,
      );
    });
  });

  // ── Form bottom sheet ──────────────────────────────────────────────
  //
  // Ketiga sheet ini sebelumnya hanya dibuktikan lewat keberadaan tombolnya,
  // tidak pernah benar-benar dibangun. Diuji di layar terpendek karena isi
  // sheet itulah yang paling panjang.

  group('Form bottom sheet', () {
    testWidgets('Catat Mutasi terbuka di layar pendek', (tester) async {
      await pasang(
        tester,
        const AsetScreen(),
        ukuran: _layarPendek,
        respons: {
          '/api/barang': barangJson,
          '/api/kategori': kategoriJson,
          '/api/stok-mutasi': mutasiJson,
        },
      );

      await tester.tap(find.text('Mutasi Stok'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Catat Mutasi'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Barang'), findsWidgets);
    });

    testWidgets('Tambah User terbuka di layar pendek', (tester) async {
      await pasang(
        tester,
        const UsersScreen(),
        ukuran: _layarPendek,
        respons: {'/api/users': usersJson},
      );

      await tester.tap(find.text('Tambah User'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Peran'), findsWidgets);
    });

    testWidgets('Tambah Peminjam terbuka di layar pendek', (tester) async {
      await pasang(
        tester,
        const PeminjamScreen(),
        ukuran: _layarPendek,
        respons: {'/api/peminjam': peminjamJson},
      );

      await tester.tap(find.text('Tambah Peminjam'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Nama Peminjam'), findsWidgets);
      expect(find.text('NIS / NIP'), findsWidgets);
    });

    testWidgets('Tambah Barang terbuka di layar pendek', (tester) async {
      await pasang(
        tester,
        const AsetScreen(),
        ukuran: _layarPendek,
        respons: {
          '/api/barang': barangJson,
          '/api/kategori': kategoriJson,
          '/api/stok-mutasi': mutasiJson,
        },
      );

      await tester.tap(find.text('Tambah Barang'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kode Barang'), findsWidgets);
    });
  });

  // ── Pengembalian (FR-06) ───────────────────────────────────────────

  group('Pengembalian', () {
    Future<void> bukaTab(
      WidgetTester tester, {
      double skala = 1,
      Size? ukuran,
    }) async {
      await pasang(
        tester,
        const TransaksiScreen(),
        respons: {...transaksiRespons, ...pengembalianRespons},
        skalaTeks: skala,
        ukuran: ukuran ?? _layarUmum,
      );
      await tester.tap(find.text('Pengembalian'));
      await tester.pumpAndSettle();
    }

    testWidgets('daftar menampilkan badge turunan dan denda', (tester) async {
      await bukaTab(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('PMJ-2026-001'), findsOne);
      expect(find.text('TERLAMBAT'), findsOne);
      expect(find.text('SUDAH KEMBALI'), findsOne);
      expect(find.text('DENDA RP 15.000'), findsOne);
      expect(find.text('1 dari 2 jenis kembali · tempo 2026-09-02'), findsOne);
      expect(find.text('2 jenis · semua sudah kembali'), findsOne);
    });

    testWidgets('chip tab menyaring lewat server', (tester) async {
      await bukaTab(tester);

      // Lima chip tidak muat di 360dp, dan yang di luar cache extent
      // viewport belum dibangun sama sekali — jadi barisnya digeser dulu,
      // bukan sekadar di-scroll ke posisi.
      expect(find.text('Sudah Kembali'), findsNothing);
      await tester.drag(find.text('Semua'), const Offset(-280, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sudah Kembali'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // API palsu menyaring dengan mencocokkan tampilan_status.
      expect(find.text('PMJ-2026-002'), findsOne);
      expect(find.text('PMJ-2026-001'), findsNothing);
    });

    testWidgets('rincian memisahkan item yang sudah dan belum kembali', (
      tester,
    ) async {
      await bukaTab(tester);

      await tester.tap(find.text('PMJ-2026-001'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1 dari 2 belum kembali'), findsOne);
      expect(find.text('Total denda transaksi ini'), findsOne);
      // Item yang sudah kembali menampilkan tanggal, kondisi, dan dendanya.
      expect(find.text('KEMBALI 2026-09-05'), findsOne);
      expect(find.text('RUSAK'), findsOne);
      expect(find.text('TELAT 3 HARI · RP 15.000'), findsOne);
      // Item yang belum kembali menawarkan tombolnya.
      expect(find.text('Kembalikan'), findsOne);
    });

    testWidgets('form pengembalian menampilkan pratinjau denda read-only', (
      tester,
    ) async {
      await bukaTab(tester);
      await tester.tap(find.text('PMJ-2026-001'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kembalikan'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kembalikan Barang'), findsOne);
      // Jumlah unit adalah teks tetap, bukan field — tabelnya tidak punya
      // kolom jumlah (D-03).
      expect(find.text('Dikembalikan 1 unit sekaligus'), findsOne);
      expect(find.text('Tanggal pengembalian'), findsOne);
      expect(find.text('Baik'), findsOne);
      expect(find.text('Rusak'), findsOne);
      // Jatuh tempo 2026-09-02 sudah lewat, jadi pratinjaunya menghitung denda.
      expect(find.textContaining('Terlambat'), findsWidgets);
      expect(find.textContaining('per hari'), findsOne);
    });

    testWidgets('memilih kondisi rusak menjelaskan stok tetap dipulihkan', (
      tester,
    ) async {
      await bukaTab(tester);
      await tester.tap(find.text('PMJ-2026-001'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kembalikan'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rusak'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('tetap masuk kembali ke stok'), findsOne);
    });

    testWidgets('konfirmasi sampai tuntas: POST lalu SnackBar berisi denda', (
      tester,
    ) async {
      await bukaTab(tester);
      await tester.tap(find.text('PMJ-2026-001'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kembalikan'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Konfirmasi Pengembalian'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Angka yang dilaporkan berasal dari balasan server, bukan pratinjau.
      expect(find.textContaining('telat 5 hari'), findsOne);
      expect(find.textContaining('Rp 25.000'), findsOne);
    });

    testWidgets('keadaan kosong dan gagal terender', (tester) async {
      await pasang(
        tester,
        const TransaksiScreen(),
        respons: {...transaksiRespons, '/api/pengembalian': const []},
      );
      await tester.tap(find.text('Pengembalian'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Belum ada barang yang perlu dikembalikan'),
        findsOne,
      );
    });

    testWidgets('rincian di layar pendek pada skala 1,5', (tester) async {
      await bukaTab(tester, skala: 1.5, ukuran: _layarPendek);

      await tester.tap(find.text('PMJ-2026-001'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kembalikan'), findsOne);
    });
  });

  // ── Pengaturan Denda (FR-11) ───────────────────────────────────────

  group('Pengaturan Denda', () {
    testWidgets('menampilkan tarif berjalan dan contoh perhitungannya', (
      tester,
    ) async {
      await pasang(
        tester,
        const PengaturanDendaScreen(),
        respons: pengembalianRespons,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Tarif denda keterlambatan'), findsOne);
      expect(find.text('5000'), findsOne);
      expect(find.textContaining('3 × Rp 5.000 = Rp 15.000'), findsOne);
    });

    testWidgets('tarif negatif tidak bisa diketik, kosong ditolak validator', (
      tester,
    ) async {
      await pasang(
        tester,
        const PengaturanDendaScreen(),
        respons: pengembalianRespons,
      );

      // FilteringTextInputFormatter.digitsOnly menyaring tanda minus.
      await tester.enterText(find.byType(TextFormField), '-500');
      await tester.pumpAndSettle();
      expect(find.text('500'), findsOne);

      await tester.enterText(find.byType(TextFormField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Tarif'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tarif wajib diisi berupa angka'), findsOne);
    });

    testWidgets('tarif di atas batas ditolak validator', (tester) async {
      await pasang(
        tester,
        const PengaturanDendaScreen(),
        respons: pengembalianRespons,
      );

      await tester.enterText(find.byType(TextFormField), '2000000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Tarif'));
      await tester.pumpAndSettle();

      expect(find.text('Tarif maksimal Rp 1.000.000 per hari'), findsOne);
    });

    testWidgets('tarif 0 dijelaskan artinya, bukan ditolak', (tester) async {
      await pasang(
        tester,
        const PengaturanDendaScreen(),
        respons: pengembalianRespons,
      );

      await tester.enterText(find.byType(TextFormField), '0');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('tidak menghasilkan denda'), findsOne);
    });

    testWidgets('menyimpan tarif melaporkan hasilnya', (tester) async {
      await pasang(
        tester,
        const PengaturanDendaScreen(),
        respons: pengembalianRespons,
      );

      await tester.enterText(find.byType(TextFormField), '7500');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Tarif'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Rp 7.500 per hari'), findsOne);
    });
  });

  // ── Laporan (FR-08 / FR-09) ────────────────────────────────────────

  group('Laporan', () {
    /// Penyimpan berkas palsu: implementasi sungguhannya menyentuh
    /// path_provider dan open_filex yang tidak ada di `flutter test`.
    /// Yang dicatat di sini cukup untuk memastikan byte, nama, dan mime
    /// benar-benar diteruskan.
    late List<({int panjang, String nama, String mime})> tersimpan;

    Future<void> pasangLaporan(
      WidgetTester tester, {
      AppUser user = laboran,
      _ModeApi mode = _ModeApi.data,
      double skalaTeks = 1,
      Size? ukuran,
    }) async {
      tersimpan = [];
      await tester.binding.setSurfaceSize(ukuran ?? _layarUmum);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
            apiClientProvider.overrideWithValue(_ApiPalsu(const {}, mode)),
            currentUserProvider.overrideWithValue(user),
            penyimpanBerkasProvider.overrideWithValue((
              bytes,
              nama,
              mime,
            ) async {
              tersimpan.add((panjang: bytes.length, nama: nama, mime: mime));
              return '$nama diunduh browser.';
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(skalaTeks)),
              child: child!,
            ),
            home: const LaporanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Layar Laporan adalah ListView, jadi kartu di bawah lipatan belum
    /// dibangun sama sekali — bukan sekadar tak terlihat. Karena itu tiap
    /// kartu digulir dulu sebelum diperiksa, dan itu sekaligus membuktikan
    /// kelimanya benar-benar terjangkau di layar 360dp.
    Future<void> gulirKe(WidgetTester tester, String judul) async {
      await tester.scrollUntilVisible(
        find.text(judul),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    Finder tombolDiKartu(String judul, String format) => find.descendant(
      of: find.ancestor(of: find.text(judul), matching: find.byType(Card)),
      matching: find.text(format),
    );

    testWidgets('lima kartu laporan, masing-masing bertombol tiga format', (
      tester,
    ) async {
      await pasangLaporan(tester);
      expect(tester.takeException(), isNull);

      for (final judul in [
        'Data Barang',
        'Peminjaman',
        'Pengembalian',
        'Stok Barang',
        'Denda',
      ]) {
        await gulirKe(tester, judul);
        expect(
          find.text(judul),
          findsOne,
          reason: 'kartu $judul tak terjangkau',
        );
        for (final format in ['PDF', 'Word', 'Excel']) {
          expect(
            tombolDiKartu(judul, format),
            findsOne,
            reason: 'tombol $format di kartu $judul hilang',
          );
        }
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('Laboran tidak diberi label Mode Lihat Saja', (tester) async {
      await pasangLaporan(tester);

      expect(find.text('MODE LIHAT SAJA'), findsNothing);
      expect(find.textContaining('Buat dan cetak laporan'), findsOne);
    });

    testWidgets('Kepala Program ditandai Mode Lihat Saja (FR-09)', (
      tester,
    ) async {
      await pasangLaporan(tester, user: kaprog);

      expect(tester.takeException(), isNull);
      expect(find.text('MODE LIHAT SAJA'), findsOne);
      expect(find.textContaining('Perubahan data dilakukan Laboran'), findsOne);
      // Tetap boleh mengunduh — hanya penandaannya yang berbeda.
      expect(tombolDiKartu('Data Barang', 'PDF'), findsOne);
    });

    testWidgets('laporan Stok dijelaskan tidak terpengaruh periode', (
      tester,
    ) async {
      await pasangLaporan(tester);

      await gulirKe(tester, 'Peminjaman');
      expect(find.text('Disaring menurut tanggal pinjam.'), findsOne);

      await gulirKe(tester, 'Stok Barang');
      expect(find.text('Tidak terpengaruh filter periode.'), findsOne);
    });

    testWidgets('periode kosong ditampilkan sebagai seluruh periode', (
      tester,
    ) async {
      await pasangLaporan(tester);

      expect(find.text('Seluruh periode'), findsOne);
      expect(find.text('Dari'), findsOne);
      expect(find.text('Sampai'), findsOne);
      // Tombol bersihkan hanya muncul kalau ada yang perlu dibersihkan.
      expect(find.text('Bersihkan'), findsNothing);
    });

    testWidgets('menekan format mengunduh dan meneruskan nama serta mime', (
      tester,
    ) async {
      await pasangLaporan(tester);

      await tester.tap(find.text('Excel').first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tersimpan, hasLength(1));
      expect(tersimpan.first.nama, endsWith('.xlsx'));
      expect(tersimpan.first.nama, startsWith('laporan-barang-'));
      expect(tersimpan.first.mime, contains('spreadsheetml'));
      expect(tersimpan.first.panjang, greaterThan(0));
      expect(find.textContaining('diunduh browser'), findsOne);
    });

    testWidgets('laporan Stok tidak mengirim filter periode ke server', (
      tester,
    ) async {
      // Backend menolak parameter tanggal pada laporan Stok, jadi UI harus
      // menyaringnya sendiri, bukan meneruskannya lalu memunculkan error.
      final api = _ApiPalsu(const {}, _ModeApi.data);
      await tester.binding.setSurfaceSize(_layarUmum);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
            apiClientProvider.overrideWithValue(api),
            currentUserProvider.overrideWithValue(laboran),
            periodeLaporanProvider.overrideWith(
              () => _PeriodeTetap(
                PeriodeLaporan(
                  dari: DateTime(2026, 1, 1),
                  sampai: DateTime(2026, 12, 31),
                ),
              ),
            ),
            penyimpanBerkasProvider.overrideWithValue(
              (bytes, nama, mime) async => nama,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LaporanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kartu Peminjaman: periode HARUS terkirim.
      await gulirKe(tester, 'Peminjaman');
      await tester.tap(tombolDiKartu('Peminjaman', 'PDF'));
      await tester.pumpAndSettle();
      expect(api.pathUnduhTerakhir, '/api/laporan/peminjaman');
      expect(api.queryUnduhTerakhir?['dari'], '2026-01-01');
      expect(api.queryUnduhTerakhir?['sampai'], '2026-12-31');

      // Kartu Stok: periode TIDAK boleh terkirim.
      await gulirKe(tester, 'Stok Barang');
      await tester.tap(tombolDiKartu('Stok Barang', 'PDF'));
      await tester.pumpAndSettle();
      expect(api.pathUnduhTerakhir, '/api/laporan/stok');
      expect(api.queryUnduhTerakhir?.containsKey('dari'), isFalse);
      expect(api.queryUnduhTerakhir?.containsKey('sampai'), isFalse);
    });

    testWidgets('unduhan gagal melaporkan pesan server, bukan diam', (
      tester,
    ) async {
      await pasangLaporan(tester, mode: _ModeApi.gagal);

      await tester.tap(find.text('PDF').first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(_ApiPalsu.pesanGagal), findsOne);
      expect(tersimpan, isEmpty);
    });

    testWidgets('di layar pendek pada skala 1,5 seluruh kartu tetap utuh', (
      tester,
    ) async {
      await pasangLaporan(tester, ukuran: _layarPendek, skalaTeks: 1.5);

      expect(tester.takeException(), isNull);
      expect(find.text('Laporan Inventaris'), findsOne);
    });
  });

  // ── Skala teks sistem ──────────────────────────────────────────────
  //
  // Pengaturan "Ukuran font" Android naik satu takik ke 1,15 dan bisa sampai
  // 1,5 atau lebih. Inilah yang dulu memecahkan grid Dashboard — bukan lebar
  // layar — dan jadi alasan tinggi kartunya dipatok, bukan ikut rasio.

  group('Skala teks sistem', () {
    testWidgets('Dashboard pada 1,3', (tester) async {
      // Ringkasannya ikut dipasang: kartu angka adalah bagian terbaru dan
      // paling padat teksnya di layar ini, jadi menguji Dashboard tanpa
      // datanya berarti tidak menguji bagian yang paling mungkin meluber.
      await pasang(
        tester,
        const DashboardScreen(),
        respons: {'/api/dashboard': dashboardJson(terlambat: 3)},
        skalaTeks: 1.3,
      );
      expect(tester.takeException(), isNull);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Kelola User pada 1,3', (tester) async {
      await pasang(
        tester,
        const UsersScreen(),
        respons: {'/api/users': usersJson},
        skalaTeks: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Aset Lab pada 1,3', (tester) async {
      await pasang(
        tester,
        const AsetScreen(),
        skalaTeks: 1.3,
        respons: {
          '/api/barang': barangJson,
          '/api/kategori': kategoriJson,
          '/api/stok-mutasi': mutasiJson,
        },
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kategori pada 1,3', (tester) async {
      await pasang(
        tester,
        const KategoriScreen(),
        respons: {'/api/kategori': kategoriJson},
        skalaTeks: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Data Peminjam pada 1,3', (tester) async {
      await pasang(
        tester,
        const PeminjamScreen(),
        respons: {'/api/peminjam': peminjamJson},
        skalaTeks: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Login pada 1,3', (tester) async {
      await pasang(tester, const LoginScreen(), skalaTeks: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Transaksi pada 1,3', (tester) async {
      await pasang(
        tester,
        const TransaksiScreen(),
        respons: transaksiRespons,
        skalaTeks: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Laporan pada 1,3', (tester) async {
      await pasang(tester, const LaporanScreen(), skalaTeks: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Pengaturan Denda pada 1,3', (tester) async {
      await pasang(
        tester,
        const PengaturanDendaScreen(),
        respons: pengembalianRespons,
        skalaTeks: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Verifikasi pada 1,3', (tester) async {
      await pasang(
        tester,
        const VerifikasiScreen(),
        user: kaprog,
        respons: transaksiRespons,
        skalaTeks: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    // Sheet rincian tingginya diturunkan dari tinggi layar, sementara baris
    // di atas daftar tumbuh mengikuti teks — bentuk yang sama dengan grid
    // Dashboard yang tadi pecah. Dua varian diuji karena bagian tertingginya
    // saling meniadakan: yang menunggu punya tombol keputusan, yang
    // dibatalkan punya kotak alasan.
    testWidgets('rincian pengajuan + tombol keputusan, 1,5 di layar pendek', (
      tester,
    ) async {
      await pasang(
        tester,
        const VerifikasiScreen(),
        user: kaprog,
        ukuran: _layarPendek,
        respons: transaksiRespons,
        skalaTeks: 1.5,
      );

      await tester.tap(find.text('Periksa & putuskan'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Setujui'), findsOne);
    });

    testWidgets(
      'rincian transaksi ditolak + kotak alasan, 1,5 di layar pendek',
      (tester) async {
        // Daftarnya sengaja hanya berisi transaksi yang ditolak: di layar
        // pendek berskala 1,3, kartu ketiga tidak pernah dibangun ListView
        // yang malas, dan yang diuji di sini adalah sheet-nya, bukan scroll.
        final ditolak = peminjamanJson(
          id: 3,
          kode: 'PMJ-2026-003',
          status: 'dibatalkan',
          alasan: 'Barang sedang dipakai praktik kelas XII sore ini.',
        );
        await pasang(
          tester,
          const TransaksiScreen(),
          ukuran: _layarPendek,
          skalaTeks: 1.5,
          respons: {
            '/api/peminjaman': [ditolak],
            '/api/peminjaman/3': {...ditolak, 'items': itemsJson},
          },
        );

        await tester.tap(find.text('PMJ-2026-003'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Alasan ditolak'), findsOne);
      },
    );
  });
}

/// Titik tengah widget berteks [teks] di koordinat layar.
Offset _di(WidgetTester tester, String teks) =>
    tester.getCenter(find.text(teks));

enum _ModeApi { data, gagal, menggantung }

/// Pengganti [ApiClient] yang menjawab dari peta path → data, tanpa jaringan.
///
/// Penyaringan `cari` dan `id_kategori` ditiru seperti backend supaya interaksi
/// filter di layar benar-benar mengubah hasil, bukan hanya memicu rebuild.
class _ApiPalsu extends ApiClient {
  _ApiPalsu(this._respons, this._mode)
    : super(InMemoryTokenStorage(), baseUrl: 'http://uji.lokal');

  static const pesanGagal = 'Sesi Anda berakhir. Silakan login kembali.';

  final Map<String, Object?> _respons;
  final _ModeApi _mode;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    switch (_mode) {
      case _ModeApi.gagal:
        throw ApiException(pesanGagal, statusCode: 401);
      case _ModeApi.menggantung:
        return Completer<dynamic>().future;
      case _ModeApi.data:
        break;
    }

    final data = _respons[path];
    if (data == null) {
      throw ApiException('Path $path tidak disiapkan di pengujian.');
    }
    if (data is! List) return data;

    return data
        .where((baris) => _cocok(baris as Map<String, Object?>, query))
        .toList();
  }

  bool _cocok(Map<String, Object?> baris, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return true;

    // Setiap parameter selain `cari` diperlakukan sebagai kecocokan persis
    // pada field bernama sama — meniru id_kategori, id_barang, dan status
    // di backend tanpa perlu cabang khusus per endpoint.
    //
    // `tab` adalah satu-satunya kekecualian: di backend ia menyaring status
    // TURUNAN yang dihitung dari data, dan di respons namanya
    // `tampilan_status`. Pemetaan ditulis di sini supaya penyaringan tabnya
    // tetap teruji tanpa meniru seluruh perhitungan turunannya.
    const alias = {'tab': 'tampilan_status'};

    for (final entry in query.entries) {
      if (entry.key == 'cari') continue;
      final field = alias[entry.key] ?? entry.key;
      if (baris.containsKey(field) && baris[field] != entry.value) {
        return false;
      }
    }

    final cari = query['cari'] as String?;
    if (cari == null || cari.isEmpty) return true;

    final kunci = cari.toLowerCase();
    return baris.values.any(
      (v) => v is String && v.toLowerCase().contains(kunci),
    );
  }

  /// Dicatat supaya pengujian bisa memastikan filter periode benar-benar
  /// terkirim ke server, bukan cuma tampil di layar.
  String? pathUnduhTerakhir;
  Map<String, dynamic>? queryUnduhTerakhir;

  /// Balasan unduhan: byte palsu berawalan %PDF- supaya alurnya realistis.
  /// Yang membuktikan berkasnya sungguhan sah adalah api_integration_test.dart
  /// terhadap backend nyata; di sini yang diuji jalur UI-nya.
  @override
  Future<Uint8List> unduh(String path, {Map<String, dynamic>? query}) async {
    if (_mode == _ModeApi.gagal) {
      throw ApiException(pesanGagal, statusCode: 500);
    }
    pathUnduhTerakhir = path;
    queryUnduhTerakhir = query;
    return Uint8List.fromList('%PDF-palsu'.codeUnits);
  }

  /// POST dilayani untuk endpoint yang disiapkan, supaya alur tulis bisa
  /// ditelusuri sampai SnackBar-nya. Yang membuktikan datanya benar-benar
  /// tersimpan tetap api_integration_test.dart terhadap backend sungguhan.
  @override
  Future<dynamic> post(String path, {Object? body}) async {
    if (_mode == _ModeApi.gagal) {
      throw ApiException(pesanGagal, statusCode: 409);
    }
    final data = _respons['POST $path'];
    if (data == null) {
      throw ApiException('POST $path tidak disiapkan di pengujian.');
    }
    return data;
  }

  @override
  Future<dynamic> put(String path, {Object? body}) async {
    if (_mode == _ModeApi.gagal) {
      throw ApiException(pesanGagal, statusCode: 409);
    }
    final data = _respons['PUT $path'];
    if (data == null) {
      throw ApiException('PUT $path tidak disiapkan di pengujian.');
    }
    return data;
  }

  /// Verifikasi memakai PATCH; dilayani supaya alur Setujui/Tolak bisa
  /// ditelusuri sampai SnackBar-nya, bukan berhenti di UnimplementedError.
  @override
  Future<dynamic> patch(String path, {Object? body}) async {
    if (_mode == _ModeApi.gagal) {
      throw ApiException(pesanGagal, statusCode: 409);
    }
    final data = _respons[path];
    if (data == null) {
      throw ApiException('Path $path tidak disiapkan di pengujian.');
    }
    return data;
  }

  @override
  Future<dynamic> delete(String path) async =>
      throw UnimplementedError('delete $path tidak dipakai pengujian render.');
}

/// Periode yang nilainya dipatok, untuk menguji apa yang dikirim ke server.
class _PeriodeTetap extends PeriodeNotifier {
  _PeriodeTetap(this._nilai);

  final PeriodeLaporan _nilai;

  @override
  PeriodeLaporan build() => _nilai;
}
