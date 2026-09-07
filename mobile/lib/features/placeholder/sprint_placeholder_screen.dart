import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Layar untuk tab yang sudah ada di struktur navigasi tapi fiturnya belum
/// dikerjakan. Menyebut sprint-nya secara eksplisit supaya jelas ini rencana
/// yang tertunda, bukan bagian yang terlewat.
class SprintPlaceholderScreen extends StatelessWidget {
  const SprintPlaceholderScreen({
    required this.title,
    required this.sprint,
    required this.description,
    super.key,
  });

  final String title;
  final int sprint;
  final String description;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_outlined,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text('Dikerjakan pada Sprint $sprint',
                  style: text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(description,
                  style: text.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
