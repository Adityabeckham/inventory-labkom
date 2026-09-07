import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/placeholder/sprint_placeholder_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/users/presentation/users_screen.dart';

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
          GoRoute(
            path: '/aset',
            builder: (_, _) => const SprintPlaceholderScreen(
              title: 'Aset Lab',
              sprint: 2,
              description:
                  'Daftar Barang, filter kategori, dan Mutasi Stok (FR-02, FR-03, FR-13).',
            ),
          ),
          GoRoute(
            path: '/transaksi',
            builder: (_, _) => const SprintPlaceholderScreen(
              title: 'Transaksi',
              sprint: 3,
              description:
                  'Peminjaman multi-item dan Pengembalian per-item (FR-05, FR-06).',
            ),
          ),
          GoRoute(
            path: '/verifikasi',
            builder: (_, _) => const SprintPlaceholderScreen(
              title: 'Verifikasi',
              sprint: 3,
              description:
                  'Menyetujui atau membatalkan pengajuan peminjaman (FR-07).',
            ),
          ),
          GoRoute(
            path: '/laporan',
            builder: (_, _) => const SprintPlaceholderScreen(
              title: 'Laporan',
              sprint: 5,
              description:
                  'Lima jenis laporan dalam format PDF, Word, dan Excel (FR-08, FR-09).',
            ),
          ),
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

  final khususLaboran = {'/users', '/aset', '/transaksi'};
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
