import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/aset/presentation/aset_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/kategori/presentation/kategori_screen.dart';
import '../../features/laporan/presentation/laporan_screen.dart';
import '../../features/peminjam/presentation/peminjam_screen.dart';
import '../../features/peminjaman/presentation/transaksi_screen.dart';
import '../../features/pengembalian/presentation/pengaturan_denda_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../features/verifikasi/presentation/verifikasi_screen.dart';

/// Layar tunggu selama token tersimpan diperiksa.
///
/// Tanpa ini, pengguna yang sesinya masih sah akan melihat layar Login
/// berkedip sepersekian detik sebelum dilempar ke Dashboard.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Menjembatani perubahan state Riverpod ke `refreshListenable` go_router.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final _authRefreshProvider = Provider<_AuthRefresh>((ref) => _AuthRefresh(ref));

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: ref.watch(_authRefreshProvider),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.uri.path;

      // Tahan navigasi sampai pemulihan sesi selesai.
      if (auth.isRestoring) return path == '/splash' ? null : '/splash';

      if (!auth.isLoggedIn) {
        return path == '/login' ? null : '/login';
      }

      // Sudah login tapi masih di layar login/splash → masuk ke dalam.
      if (path == '/login' || path == '/splash') return '/dashboard';

      // Penjaga peran sisi klien. Ini lapisan KENYAMANAN, bukan keamanan —
      // penjaga sesungguhnya ada di backend (Auth::role), yang tetap menolak
      // walau seseorang memanggil endpointnya langsung.
      final level = auth.user!.level;
      if (!_isAllowed(path, level)) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
          GoRoute(path: '/aset', builder: (_, _) => const AsetScreen()),
          GoRoute(path: '/kategori', builder: (_, _) => const KategoriScreen()),
          GoRoute(path: '/peminjam', builder: (_, _) => const PeminjamScreen()),
          GoRoute(
            path: '/pengaturan-denda',
            builder: (_, _) => const PengaturanDendaScreen(),
          ),
          GoRoute(path: '/transaksi', builder: (_, _) => const TransaksiScreen()),
          GoRoute(path: '/verifikasi', builder: (_, _) => const VerifikasiScreen()),
          GoRoute(path: '/laporan', builder: (_, _) => const LaporanScreen()),
        ],
      ),
    ],
  );
});

/// Path yang boleh diakses tiap peran.
///
/// Kepala Program hanya Verifikasi dan Laporan, sesuai Tabel 3.1 Use Case —
/// jadi rute kelola apa pun ditolak walau URL-nya diketik langsung.
bool _isAllowed(String path, UserLevel level) {
  const umum = {'/dashboard'};
  if (umum.contains(path)) return true;

  final khususLaboran = {
    '/users',
    '/aset',
    '/kategori',
    '/peminjam',
    '/transaksi',
    '/pengaturan-denda',
  };
  final khususKepalaProgram = {'/verifikasi'};

  return switch (level) {
    UserLevel.laboran =>
      khususLaboran.contains(path) || path == '/laporan',
    UserLevel.kepalaProgram =>
      khususKepalaProgram.contains(path) || path == '/laporan',
  };
}

/// Diekspos untuk pengujian — memastikan matriks hak akses tidak diam-diam
/// berubah saat rute baru ditambahkan di sprint berikutnya.
@visibleForTesting
bool isPathAllowedForLevel(String path, UserLevel level) =>
    _isAllowed(path, level);
