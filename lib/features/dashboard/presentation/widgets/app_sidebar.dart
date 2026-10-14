import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../dashboard_cubit.dart';
import '../../domain/dashboard_state.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, this.compact = false});

  final bool compact;

  static const items = <(String, IconData)>[
    ('Dashboard', Icons.dashboard_outlined),
    ('Chart', Icons.candlestick_chart_outlined),
    ('Multi-Timeframe', Icons.filter_alt_outlined),
    ('AI Analysis', Icons.auto_awesome_outlined),
    ('Patterns', Icons.polyline_outlined),
    ('Smart Money', Icons.account_balance_outlined),
    ('Price Action', Icons.show_chart),
    ('Indicators', Icons.tune),
    ('News', Icons.newspaper_outlined),
    ('Alerts', Icons.notifications_none),
    ('Backtest', Icons.history),
    ('Trade Journal', Icons.menu_book_outlined),
    ('Settings', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 74 : 180,
      decoration: const BoxDecoration(
        color: Color(0xFF06131F),
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hexagon, color: AppColors.amber, size: 30),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'XAUUSD',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Gold Analytics',
                        style: TextStyle(color: AppColors.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) => ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 3),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = item.$1 == state.selectedMenu;
                  return Tooltip(
                    message: compact ? item.$1 : '',
                    child: Material(
                      color: selected
                          ? const Color(0xFF073E72)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        key: ValueKey('menu-${item.$1}'),
                        onTap: () =>
                            context.read<DashboardCubit>().selectMenu(item.$1),
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 42,
                          child: Row(
                            mainAxisAlignment: compact
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              if (!compact) const SizedBox(width: 10),
                              Icon(
                                item.$2,
                                size: 20,
                                color: selected
                                    ? Colors.white
                                    : AppColors.muted,
                              ),
                              if (!compact) ...[
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    item.$1,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.text,
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.all(12), child: DemoBadge()),
        ],
      ),
    );
  }
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) => const Text(
    '●  MOCK MODE',
    style: TextStyle(
      color: AppColors.amber,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    ),
  );
}
