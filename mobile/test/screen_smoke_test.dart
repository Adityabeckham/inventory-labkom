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
import 'package:inventory_labkom/features/peminjam/presentation/peminjam_screen.dart';
import 'package:inventory_labkom/features/peminjaman/presentation/transaksi_screen.dart';
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
    await (FontLoader(AppTypography.family)
          ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf')))
        .load();
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
    '/api/peminjaman/1/verifikasi':
        peminjamanJson(status: 'dipinjam', withItems: true),
    '/api/barang': barangJson,
    '/api/kategori': kategoriJson,
    '/api/peminjam': peminjamJson,
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

    testWidgets('di layar 640dp tautan bawah masih terjangkau lewat scroll',
        (tester) async {
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
    testWidgets('Laboran melihat sapaan dan empat pintasan', (tester) async {
      await pasang(tester, const DashboardScreen());

      expect(tester.takeException(), isNull);
      expect(find.text('Halo Laboran'), findsOne);
      expect(find.text('Selamat datang kembali, laboran.'), findsOne);
      for (final label in ['Kategori', 'Kelola User', 'Data Peminjam', 'Pengaturan Denda']) {
        expect(find.text(label), findsOne, reason: 'pintasan $label hilang');
      }
    });

    testWidgets('Kepala Program tidak melihat grid akses cepat', (tester) async {
      await pasang(tester, const DashboardScreen(), user: kaprog);

      expect(tester.takeException(), isNull);
      expect(find.text('Halo Kepala Program'), findsOne);
      // Grid ini pintu ke fitur milik Laboran — Tabel 3.1 tidak memberi
      // Kepala Program hak mengelola data.
      expect(find.text('Akses cepat'), findsNothing);
      expect(find.text('Kelola User'), findsNothing);
      expect(find.text('Ringkasan'), findsOne);
    });

    testWidgets('tombol logout membuka dialog konfirmasi', (tester) async {
      await pasang(tester, const DashboardScreen());

      await tester.tap(find.byTooltip('Logout'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Keluar dari aplikasi?'), findsOne);
    });
  });

  // ── Kelola User ────────────────────────────────────────────────────

  group('Kelola User', () {
    testWidgets('menampilkan kartu akun dan menandai akun sendiri', (tester) async {
      await pasang(tester, const UsersScreen(), respons: {'/api/users': usersJson});

      expect(tester.takeException(), isNull);
      expect(find.text('laboran'), findsOne);
      expect(find.text('Laboran · NIP 198203122008011004'), findsOne);
      // StatusPill menaikkan label jadi huruf kapital.
      expect(find.text('ANDA'), findsOne);
      expect(find.text('Tambah User'), findsOne);
    });

    testWidgets('tombol hapus akun sendiri dimatikan', (tester) async {
      await pasang(tester, const UsersScreen(), respons: {'/api/users': usersJson});

      // byTooltip menunjuk widget Tooltip-nya; tombolnya ada di atasnya.
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

    testWidgets('keadaan gagal menampilkan pesan backend apa adanya', (tester) async {
      await pasang(tester, const UsersScreen(), mode: _ModeApi.gagal);

      expect(tester.takeException(), isNull);
      expect(find.text(_ApiPalsu.pesanGagal), findsOne);
      expect(find.text('Coba lagi'), findsOne);
    });

    testWidgets('keadaan kosong memakai pesan sendiri', (tester) async {
      await pasang(tester, const UsersScreen(), respons: {'/api/users': const []});

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
      // jumlah 20, stok 18 → dua unit sedang di tangan peminjam.
      expect(find.text('Stok 18 dari 20 · 2 dipinjam'), findsOne);
      expect(find.text('Semua'), findsOne);
      expect(find.text('Komputer (12)'), findsOne);
      // stok 0 pada barang kedua.
      expect(find.text('HABIS'), findsOne);
      expect(find.text('TERSEDIA'), findsOne);
    });

    testWidgets('memilih chip kategori memuat ulang daftar', (tester) async {
      await pasang(tester, const AsetScreen(), respons: asetRespons);

      // Tiga chip pertama muat di lebar 360dp; yang keempat berlabel panjang
      // ada di luar viewport dan dijangkau dengan menggulir baris chip.
      expect(_di(tester, 'Jaringan (3)').dx, lessThan(360));

      await tester.tap(find.text('Jaringan (3)'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Filter dikirim ke server; API palsu menyaring seperti backend.
      expect(find.text('PC Rakitan Core i5'), findsNothing);
      expect(find.text('Tidak ada barang yang cocok dengan pencarian.'), findsOne);
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

      await tester.tap(find.byTooltip('Hapus barang').first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Hapus barang?'), findsOne);
    });

    testWidgets('gagal memuat barang tetap menampilkan segmented control',
        (tester) async {
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

    testWidgets('peminjam tanpa NIS dan kelas tidak menabrak layout',
        (tester) async {
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
    testWidgets('daftar peminjaman dengan kode, badge status, dan identitas',
        (tester) async {
      await pasang(tester, const TransaksiScreen(), respons: transaksiRespons);

      expect(tester.takeException(), isNull);
      expect(find.text('PMJ-2026-001'), findsOne);
      expect(find.text('MENUNGGU VERIFIKASI'), findsOne);
      expect(find.text('DIPINJAM'), findsOne);
      expect(find.text('DIBATALKAN'), findsOne);
      expect(find.text('0051234567 · XI Rekayasa Perangkat Lunak 2'),
          findsExactly(3));
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

    testWidgets('tab Pengembalian menjelaskan dikerjakan Sprint 4',
        (tester) async {
      await pasang(tester, const TransaksiScreen(), respons: transaksiRespons);

      await tester.tap(find.text('Pengembalian'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Sprint 4'), findsOne);
      // FAB peminjaman tidak boleh ikut muncul di tab ini.
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

    testWidgets('rincian transaksi yang ditolak menampilkan alasannya',
        (tester) async {
      await pasang(tester, const TransaksiScreen(), respons: transaksiRespons);

      await tester.tap(find.text('PMJ-2026-003'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alasan ditolak'), findsOne);
      expect(find.text('Barang sedang dipakai praktik kelas XII sore ini.'),
          findsOne);
    });

    testWidgets('keadaan kosong dan gagal terender', (tester) async {
      await pasang(tester, const TransaksiScreen(),
          respons: {'/api/peminjaman': const []});
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Belum ada transaksi peminjaman'), findsOne);

      await pasang(tester, const TransaksiScreen(), mode: _ModeApi.gagal);
      expect(tester.takeException(), isNull);
      expect(find.text(_ApiPalsu.pesanGagal), findsOne);
    });
  });

  // ── Form Peminjaman Baru multi-item ────────────────────────────────

  group('Peminjaman Baru', () {
    testWidgets('form terbuka di layar pendek dengan keranjang kosong',
        (tester) async {
      await pasang(tester, const TransaksiScreen(),
          ukuran: _layarPendek, respons: transaksiRespons);

      await tester.tap(find.text('Peminjaman Baru'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Peminjam'), findsWidgets);
      expect(find.text('Tanggal pinjam'), findsOne);
      expect(find.text('Jatuh tempo'), findsOne);
      expect(find.textContaining('Belum ada barang'), findsOne);
      expect(find.text('Tambah Barang'), findsOne);
    });

    testWidgets('mengajukan tanpa barang menyorot keranjang, bukan diam',
        (tester) async {
      await pasang(tester, const TransaksiScreen(), respons: transaksiRespons);

      await tester.tap(find.text('Peminjaman Baru'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan Peminjaman'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tambahkan minimal satu barang sebelum mengajukan.'),
          findsOne);
      // Peminjam belum dipilih, jadi validator Form juga bicara.
      expect(find.text('Peminjam wajib dipilih'), findsOne);
      // Sheet tetap terbuka — tidak boleh tertutup diam-diam.
      expect(find.text('Ajukan Peminjaman'), findsOne);
    });

    testWidgets('menambah barang ke keranjang menampilkan jumlah dan stok',
        (tester) async {
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

    testWidgets('menampilkan pengajuan yang menunggu keputusan',
        (tester) async {
      await pasang(tester, const VerifikasiScreen(),
          user: kaprog, respons: verifikasiRespons);

      expect(tester.takeException(), isNull);
      expect(find.text('1 pengajuan menunggu keputusan Anda.'), findsOne);
      expect(find.text('PMJ-2026-001'), findsOne);
      expect(find.text('Periksa & putuskan'), findsOne);
    });

    testWidgets('rincian pengajuan memunculkan tombol Setujui dan Tolak',
        (tester) async {
      await pasang(tester, const VerifikasiScreen(),
          user: kaprog, respons: verifikasiRespons);

      await tester.tap(find.text('Periksa & putuskan'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Setujui'), findsOne);
      expect(find.text('Tolak'), findsOne);
      expect(find.text('2 UNIT'), findsOne);
    });

    testWidgets('Setujui meminta konfirmasi lebih dulu', (tester) async {
      await pasang(tester, const VerifikasiScreen(),
          user: kaprog, respons: verifikasiRespons);

      await tester.tap(find.text('Periksa & putuskan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setujui'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Setujui pengajuan?'), findsOne);
    });

    testWidgets('Tolak mewajibkan alasan diisi', (tester) async {
      await pasang(tester, const VerifikasiScreen(),
          user: kaprog, respons: verifikasiRespons);

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

    testWidgets('tidak ada pengajuan menampilkan keadaan kosong',
        (tester) async {
      await pasang(tester, const VerifikasiScreen(),
          user: kaprog, respons: {'/api/peminjaman': const []});

      expect(tester.takeException(), isNull);
      expect(find.text('Tidak ada pengajuan yang menunggu verifikasi.'),
          findsOne);
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

  // ── Skala teks sistem ──────────────────────────────────────────────
  //
  // Pengaturan "Ukuran font" Android naik satu takik ke 1,15 dan bisa sampai
  // 1,5 atau lebih. Inilah yang dulu memecahkan grid Dashboard — bukan lebar
  // layar — dan jadi alasan tinggi kartunya dipatok, bukan ikut rasio.

  group('Skala teks 1,3', () {
    testWidgets('Dashboard', (tester) async {
      await pasang(tester, const DashboardScreen(), skalaTeks: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kelola User', (tester) async {
      await pasang(tester, const UsersScreen(),
          respons: {'/api/users': usersJson}, skalaTeks: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Aset Lab', (tester) async {
      await pasang(tester, const AsetScreen(), skalaTeks: 1.3, respons: {
        '/api/barang': barangJson,
        '/api/kategori': kategoriJson,
        '/api/stok-mutasi': mutasiJson,
      });
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kategori', (tester) async {
      await pasang(tester, const KategoriScreen(),
          respons: {'/api/kategori': kategoriJson}, skalaTeks: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Data Peminjam', (tester) async {
      await pasang(tester, const PeminjamScreen(),
          respons: {'/api/peminjam': peminjamJson}, skalaTeks: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Login', (tester) async {
      await pasang(tester, const LoginScreen(), skalaTeks: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Transaksi', (tester) async {
      await pasang(tester, const TransaksiScreen(),
          respons: transaksiRespons, skalaTeks: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Verifikasi', (tester) async {
      await pasang(tester, const VerifikasiScreen(),
          user: kaprog, respons: transaksiRespons, skalaTeks: 1.3);
      expect(tester.takeException(), isNull);
    });
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

    return data.where((baris) => _cocok(baris as Map<String, Object?>, query)).toList();
  }

  bool _cocok(Map<String, Object?> baris, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return true;

    // Setiap parameter selain `cari` diperlakukan sebagai kecocokan persis
    // pada field bernama sama — meniru id_kategori, id_barang, dan status
    // di backend tanpa perlu cabang khusus per endpoint.
    for (final entry in query.entries) {
      if (entry.key == 'cari') continue;
      if (baris.containsKey(entry.key) && baris[entry.key] != entry.value) {
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

  // Layar hanya membaca dalam pengujian ini; tulis dipastikan lewat
  // api_integration_test.dart yang memukul backend sungguhan.
  @override
  Future<dynamic> post(String path, {Object? body}) async =>
      throw UnimplementedError('post $path tidak dipakai pengujian render.');

  @override
  Future<dynamic> put(String path, {Object? body}) async =>
      throw UnimplementedError('put $path tidak dipakai pengujian render.');

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
