import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';

/// Satu tujuan di Bottom Navigation Bar.
@immutable
class ShellTab {
  const ShellTab({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Struktur navigasi per peran — UIUX_Wireframe_dan_Flow.md §1.
///
/// Kepala Program tidak punya tab Aset Lab maupun Transaksi karena scope-nya
/// memang hanya Verifikasi dan Lihat Laporan (Tabel 3.1 Use Case).
abstract final class ShellTabs {
  static const laboran = <ShellTab>[
    ShellTab(
      path: '/dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    ShellTab(
      path: '/aset',
      label: 'Aset Lab',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    ShellTab(
      path: '/transaksi',
      label: 'Transaksi',
      icon: Icons.swap_horiz_outlined,
      selectedIcon: Icons.swap_horiz,
    ),
    ShellTab(
      path: '/laporan',
      label: 'Laporan',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
    ),
  ];

  static const kepalaProgram = <ShellTab>[
    ShellTab(
      path: '/dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    ShellTab(
      path: '/verifikasi',
      label: 'Verifikasi',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
    ShellTab(
      path: '/laporan',
      label: 'Laporan',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
    ),
  ];

  static List<ShellTab> forLevel(UserLevel level) => switch (level) {
        UserLevel.laboran => laboran,
        UserLevel.kepalaProgram => kepalaProgram,
      };

  /// Semua path yang boleh diakses level tertentu — dipakai router sebagai
  /// lapisan penjaga kedua di sisi klien. Penjaga utama tetap di backend.
  static Set<String> pathsFor(UserLevel level) =>
      forLevel(level).map((t) => t.path).toSet();
}

/// Kerangka aplikasi setelah login: Bottom Nav + isi tab yang sedang aktif.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tabs = ShellTabs.forLevel(user.level);
    final location = GoRouterState.of(context).uri.path;

    // Layar yang dibuka dari grid Dashboard (mis. /users) tidak punya tab
    // sendiri — indeksnya jatuh ke Dashboard supaya Bottom Nav tetap masuk akal.
    final index = tabs.indexWhere((t) => location.startsWith(t.path));
    final selectedIndex = index < 0 ? 0 : index;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(tabs[i].path),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
