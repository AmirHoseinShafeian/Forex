import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'dashboard_card.dart';

class BottomPanels extends StatelessWidget {
  const BottomPanels({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panels = const [
          _NewsPanel(),
          _PatternsPanel(),
          _SmartMoneyPanel(),
          _IndicatorsPanel(),
        ];
        if (constraints.maxWidth < 900) {
          return SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: panels.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) =>
                  SizedBox(width: 300, child: panels[index]),
            ),
          );
        }
        return SizedBox(
          height: 190,
          child: Row(
            children: panels.indexed.map((entry) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: entry.$1 == panels.length - 1 ? 0 : 8,
                  ),
                  child: entry.$2,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.icon,
    required this.title,
    required this.child,
    required this.color,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => DashboardCard(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const DemoBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    ),
  );
}

class _NewsPanel extends StatelessWidget {
  const _NewsPanel();
  @override
  Widget build(BuildContext context) => _PanelShell(
    icon: Icons.newspaper,
    title: 'Economic News',
    color: AppColors.red,
    child: Column(
      children: const [
        _NewsRow('16:00', 'USD', 'US CPI', 'HIGH'),
        _NewsRow('17:30', 'USD', 'FOMC Statement', 'HIGH'),
        _NewsRow('19:00', 'USD', 'Initial Jobless Claims', 'MEDIUM'),
        _NewsRow('21:00', 'USD', 'Fed Powell Speech', 'MEDIUM'),
      ],
    ),
  );
}

class _NewsRow extends StatelessWidget {
  const _NewsRow(this.time, this.currency, this.event, this.impact);
  final String time;
  final String currency;
  final String event;
  final String impact;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            time,
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(currency, style: const TextStyle(fontSize: 9)),
        ),
        Expanded(
          child: Text(
            event,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: (impact == 'HIGH' ? AppColors.red : AppColors.amber)
                .withValues(alpha: .15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            impact,
            style: TextStyle(
              color: impact == 'HIGH' ? AppColors.red : AppColors.amber,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PatternsPanel extends StatelessWidget {
  const _PatternsPanel();
  @override
  Widget build(BuildContext context) => const _PanelShell(
    icon: Icons.polyline,
    title: 'Detected Patterns',
    color: AppColors.purple,
    child: Column(
      children: [
        _StatusRow('Bullish Gartley', 'Completing', AppColors.amber),
        _StatusRow('Descending Channel', 'Active', AppColors.green),
        _StatusRow('Support Zone', 'Active', AppColors.green),
        _StatusRow('Resistance Zone', 'Active', AppColors.green),
      ],
    ),
  );
}

class _SmartMoneyPanel extends StatelessWidget {
  const _SmartMoneyPanel();
  @override
  Widget build(BuildContext context) => const _PanelShell(
    icon: Icons.account_balance,
    title: 'Smart Money Concepts',
    color: AppColors.cyan,
    child: Column(
      children: [
        _StatusRow('BOS / CHoCH', 'Bullish BOS', AppColors.green),
        _StatusRow('Order Block', '4,130 - 4,135', AppColors.muted),
        _StatusRow('FVG', '4,118 - 4,120', AppColors.muted),
        _StatusRow('Liquidity', '4,145 - 4,150', AppColors.muted),
      ],
    ),
  );
}

class _IndicatorsPanel extends StatelessWidget {
  const _IndicatorsPanel();
  @override
  Widget build(BuildContext context) => const _PanelShell(
    icon: Icons.tune,
    title: 'Indicators Status',
    color: AppColors.green,
    child: Column(
      children: [
        _StatusRow('EMA 20/50/200', 'Bullish', AppColors.green),
        _StatusRow('RSI (14)', 'Neutral', AppColors.amber),
        _StatusRow('MACD', 'Bullish', AppColors.green),
        _StatusRow('ADX (14)', 'Weak', AppColors.amber),
      ],
    ),
  );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: [
        Icon(Icons.circle, color: color, size: 7),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
