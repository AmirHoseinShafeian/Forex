import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(12),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

Color toneColor(String tone) => switch (tone) {
  'buy' => AppColors.green,
  'sell' => AppColors.red,
  'warning' => AppColors.amber,
  _ => AppColors.text,
};

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.amber.withValues(alpha: .55)),
      ),
      child: Text(
        context.l10n.text('demoData'),
        style: const TextStyle(
          color: AppColors.amber,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
