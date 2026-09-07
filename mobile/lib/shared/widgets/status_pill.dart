import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/status_style.dart';

/// Badge status berbentuk pil — DESIGN.md §Status Badges & Chips.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.style, super.key});

  final String label;
  final StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: style.border),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: style.foreground),
      ),
    );
  }
}
