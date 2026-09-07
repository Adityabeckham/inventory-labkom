import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/dashboard_repository.dart';
import '../domain/ringkasan.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

/// Ringkasan Dashboard (FR-10).
///
/// Tidak di-`keepAlive`: provider Riverpod 3 auto-dispose, dan `AppShell`
/// membangun ulang isi tab tiap perpindahan. Jadi angkanya diambil ulang
/// setiap Dashboard dibuka, tanpa perlu menyuntik invalidasi ke controller
/// peminjaman, pengembalian, dan aset. Untuk pengguna yang berdiam di layar
/// ini, tarik-untuk-segarkan yang menyegarkannya.
final ringkasanDashboardProvider = FutureProvider<RingkasanDashboard>((ref) {
  return ref.watch(dashboardRepositoryProvider).ambil();
});
