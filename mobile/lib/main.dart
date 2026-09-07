import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'sprint_zero_preview.dart';

void main() {
  runApp(const ProviderScope(child: InventoryLabkomApp()));
}

class InventoryLabkomApp extends StatelessWidget {
  const InventoryLabkomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Labkom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SprintZeroPreview(),
    );
  }
}
