import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/mock_market_data.dart';
import '../../domain/analysis_models.dart';
import '../../domain/dashboard_state.dart';
import '../../domain/market_models.dart';
import '../dashboard_cubit.dart';
import 'dashboard_card.dart';

class MarketHeader extends StatelessWidget {
  const MarketHeader({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<DashboardCubit, DashboardState>(
    builder: (context, state) {
      final settings = AppSettingsScope.of(context);
      final tick = state.tick;
      final latestCandle = state.candles.lastOrNull;
      final modeLabel = state.marketStatus.dataLabel;
      final modeColor = _statusColor(state.marketStatus);
      final price = tick?.last ?? latestCandle?.close;
      final digits = tick?.digits ?? 3;

      return DashboardCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                _SymbolPicker(state: state),
                const SizedBox(width: 8),
                Text(
                  modeLabel,
                  style: TextStyle(
                    color: modeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (state.lastUpdatedUtc != null) ...[
                  Text(
                    'UTC ${_time(state.lastUpdatedUtc!)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _ConnectionBadge(state: state),
                const SizedBox(width: 8),
                _HeaderControls(settings: settings),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MockMarketData.timeframes
                          .map(
                            (timeframe) => _TimeframeButton(
                              timeframe: timeframe,
                              selected: timeframe == state.timeframe,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.text('lastPrice'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(width: 8),
                Text(
                  price == null ? '—' : price.toStringAsFixed(digits),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: modeColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: _metrics(context, tick, latestCandle, modeLabel)
                  .map(
                    (metric) => Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        margin: const EdgeInsetsDirectional.only(end: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metric.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              metric.value,
                              textDirection: TextDirection.ltr,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: toneColor(metric.tone),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (state.errorMessage.isNotEmpty) ...[
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  state.errorMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.red, fontSize: 9),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  List<MarketMetric> _metrics(
    BuildContext context,
    MarketTick? tick,
    Candle? candle,
    String mode,
  ) {
    final suffix = ' $mode';
    return [
      MarketMetric(
        context.l10n.text('bid'),
        tick == null ? '—$suffix' : '${tick.format(tick.bid)}$suffix',
        tone: 'sell',
      ),
      MarketMetric(
        context.l10n.text('ask'),
        tick == null ? '—$suffix' : '${tick.format(tick.ask)}$suffix',
        tone: 'buy',
      ),
      MarketMetric(
        context.l10n.text('spreadPoints'),
        tick == null
            ? '—$suffix'
            : '${tick.spreadPoints.toStringAsFixed(1)}$suffix',
        tone: 'warning',
      ),
      MarketMetric(
        context.l10n.text('tickVolume'),
        candle == null ? '—$suffix' : '${candle.volume}$suffix',
      ),
      MarketMetric(
        context.l10n.text('tickTime'),
        tick == null ? '—$suffix' : '${_time(tick.timeUtc)}$suffix',
      ),
      MarketMetric(
        context.l10n.text('timeframe'),
        '${candle == null ? '—' : 'OHLC'}$suffix',
      ),
    ];
  }

  static String _time(DateTime value) {
    final utc = value.toUtc();
    return '${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}:${utc.second.toString().padLeft(2, '0')}';
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.state});
  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(state.marketStatus);
    final label = context.l10n.text(switch (state.marketStatus) {
      MarketStatus.loading => 'connecting',
      MarketStatus.live || MarketStatus.demo => 'connected',
      MarketStatus.cached || MarketStatus.disconnected => 'disconnected',
    });
    return InkWell(
      onTap: state.marketStatus.canReconnect
          ? context.read<DashboardCubit>().reconnect
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .4)),
        ),
        child: Text('●  $label', style: TextStyle(color: color, fontSize: 10)),
      ),
    );
  }
}

class _TimeframeButton extends StatelessWidget {
  const _TimeframeButton({required this.timeframe, required this.selected});
  final String timeframe;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 5),
    child: InkWell(
      key: ValueKey('timeframe-$timeframe'),
      onTap: () => context.read<DashboardCubit>().selectTimeframe(timeframe),
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0A477C) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? AppColors.cyan : AppColors.border,
          ),
        ),
        child: Text(
          timeframe,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 11,
            color: selected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    ),
  );
}

class _SymbolPicker extends StatelessWidget {
  const _SymbolPicker({required this.state});
  final DashboardState state;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('symbol-search'),
    onTap: () => _showSearch(context),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state.selectedSymbol,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.search, color: AppColors.cyan, size: 17),
        ],
      ),
    ),
  );

  Future<void> _showSearch(BuildContext context) async {
    final cubit = context.read<DashboardCubit>();
    var query = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final needle = query.trim().toLowerCase();
          final matches = state.symbols.where((symbol) {
            return needle.isEmpty ||
                symbol.name.toLowerCase().contains(needle) ||
                symbol.description.toLowerCase().contains(needle);
          }).toList();
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(context.l10n.text('searchSymbol')),
            content: SizedBox(
              width: 480,
              height: 430,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    textDirection: TextDirection.ltr,
                    onChanged: (value) => setState(() => query = value),
                    decoration: InputDecoration(
                      hintText: context.l10n.text('searchByName'),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.background,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: state.symbols.isEmpty
                        ? Center(
                            child: Text(
                              state.marketStatus == MarketStatus.loading
                                  ? context.l10n.text('loading')
                                  : context.l10n.text('symbolsUnavailable'),
                            ),
                          )
                        : matches.isEmpty
                        ? Center(child: Text(context.l10n.text('noSymbols')))
                        : ListView.builder(
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final symbol = matches[index];
                              return ListTile(
                                dense: true,
                                selected: symbol.name == state.selectedSymbol,
                                title: Text(
                                  symbol.name,
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  symbol.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: symbol.name == state.selectedSymbol
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.green,
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.of(dialogContext).pop();
                                  cubit.selectSymbol(symbol.name);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderControls extends StatelessWidget {
  const _HeaderControls({required this.settings});
  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      PopupMenuButton<DashboardDisplayMode>(
        tooltip: context.l10n.text('displayMode'),
        initialValue: settings.displayMode,
        onSelected: (mode) {
          settings.setDisplayMode(mode);
          final savedIndicators = IndicatorLayer.values
              .where(
                (layer) =>
                    settings.visibleIndicatorNames.contains(layer.name),
              )
              .toSet();
          context.read<DashboardCubit>().setAdvancedMode(
            mode == DashboardDisplayMode.advanced,
            advancedIndicators: savedIndicators,
          );
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: DashboardDisplayMode.simple,
            child: Text(context.l10n.text('simple')),
          ),
          PopupMenuItem(
            value: DashboardDisplayMode.advanced,
            child: Text(context.l10n.text('advanced')),
          ),
        ],
        child: _ControlChip(
          icon: Icons.tune,
          label: context.l10n.text(settings.isAdvanced ? 'advanced' : 'simple'),
        ),
      ),
      const SizedBox(width: 6),
      PopupMenuButton<Locale>(
        tooltip: 'FA / EN',
        initialValue: settings.locale,
        onSelected: settings.setLocale,
        itemBuilder: (_) => const [
          PopupMenuItem(value: Locale('en'), child: Text('English')),
          PopupMenuItem(value: Locale('fa'), child: Text('فارسی')),
        ],
        child: _ControlChip(
          icon: Icons.language,
          label: settings.locale.languageCode.toUpperCase(),
        ),
      ),
    ],
  );
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.cyan),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    ),
  );
}

Color _statusColor(MarketStatus status) => switch (status) {
  MarketStatus.live => AppColors.green,
  MarketStatus.demo => AppColors.purple,
  MarketStatus.cached || MarketStatus.loading => AppColors.amber,
  MarketStatus.disconnected => AppColors.red,
};
