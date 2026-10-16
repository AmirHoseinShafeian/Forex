import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/dashboard_state.dart';
import '../dashboard_cubit.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, this.compact = false});

  final bool compact;

  static const groups = <_MenuGroup>[
    _MenuGroup('overview', [
      _MenuItem('Dashboard', 'dashboard', Icons.dashboard_outlined),
      _MenuItem('Chart', 'chart', Icons.candlestick_chart_outlined),
    ]),
    _MenuGroup('analysis', [
      _MenuItem('AI Analysis', 'analysisOverview', Icons.auto_awesome_outlined),
      _MenuItem('Indicators', 'trendIndicators', Icons.tune),
      _MenuItem('Patterns', 'harmonicFibonacci', Icons.polyline_outlined),
      _MenuItem('Smart Money', 'smartMoney', Icons.account_balance_outlined),
      _MenuItem('Price Action', 'priceAction', Icons.show_chart),
      _MenuItem('Multi-Timeframe', 'multiTimeframe', Icons.filter_alt_outlined),
    ]),
    _MenuGroup('tools', [
      _MenuItem('News', 'news', Icons.newspaper_outlined),
      _MenuItem('Alerts', 'alerts', Icons.notifications_none),
      _MenuItem('Backtest', 'historyBacktest', Icons.history),
      _MenuItem('Trade Journal', 'tradeJournal', Icons.menu_book_outlined),
    ]),
    _MenuGroup('system', [
      _MenuItem('Settings', 'settings', Icons.settings_outlined),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: compact ? 72 : 220,
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
                const Icon(Icons.hexagon, color: AppColors.amber, size: 29),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'XAUUSD',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          context.l10n.text('appName'),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  tooltip: compact ? 'Expand' : 'Collapse',
                  onPressed: settings.toggleSidebar,
                  icon: Icon(
                    compact ? Icons.chevron_right : Icons.chevron_left,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) => ListView(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                children: [
                  for (final group in groups) ...[
                    if (!compact)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          10,
                          10,
                          8,
                          5,
                        ),
                        child: Text(
                          context.l10n.text(group.labelKey),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Divider(height: 1),
                      ),
                    for (final item in group.items)
                      _SidebarItem(
                        item: item,
                        compact: compact,
                        selected: item.id == state.selectedMenu,
                      ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: BlocBuilder<DashboardCubit, DashboardState>(
              buildWhen: (previous, current) =>
                  previous.marketStatus != current.marketStatus,
              builder: (context, state) =>
                  StatusBadge(status: state.marketStatus),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.compact,
    required this.selected,
  });

  final _MenuItem item;
  final bool compact;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Tooltip(
      message: compact ? context.l10n.text(item.labelKey) : '',
      child: Material(
        color: selected ? const Color(0xFF073E72) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: ValueKey('menu-${item.id}'),
          onTap: () => context.read<DashboardCubit>().selectMenu(item.id),
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 39,
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (!compact) const SizedBox(width: 10),
                Icon(
                  item.icon,
                  size: 19,
                  color: selected ? Colors.white : AppColors.muted,
                ),
                if (!compact) ...[
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      context.l10n.text(item.labelKey),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.text,
                        fontSize: 11,
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
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});
  final MarketStatus status;

  @override
  Widget build(BuildContext context) {
    final label = status == MarketStatus.demo ? 'MOCK MODE' : status.dataLabel;
    final color = switch (status) {
      MarketStatus.live => AppColors.green,
      MarketStatus.demo => AppColors.purple,
      MarketStatus.cached || MarketStatus.loading => AppColors.amber,
      MarketStatus.disconnected => AppColors.red,
    };
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '●  $label',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MenuGroup {
  const _MenuGroup(this.labelKey, this.items);
  final String labelKey;
  final List<_MenuItem> items;
}

class _MenuItem {
  const _MenuItem(this.id, this.labelKey, this.icon);
  final String id;
  final String labelKey;
  final IconData icon;
}
