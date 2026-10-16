import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/analysis_models.dart';
import '../../domain/harmonic_models.dart';
import '../../domain/price_action_models.dart';
import '../dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_card.dart';
import 'economic_calendar_panel.dart';

class BottomPanels extends StatelessWidget {
  const BottomPanels({
    super.key,
    required this.indicators,
    required this.patterns,
    required this.selectedPatternId,
    required this.hiddenPatternIds,
    required this.harmonicDiagnostics,
    required this.harmonicDebug,
    required this.marketAnalysis,
    required this.selectedMarketDetectionId,
  });

  final IndicatorSnapshot? indicators;
  final List<HarmonicPattern> patterns;
  final String? selectedPatternId;
  final Set<String> hiddenPatternIds;
  final List<HarmonicDiagnostic> harmonicDiagnostics;
  final HarmonicDebugSnapshot harmonicDebug;
  final PriceActionSmcSnapshot marketAnalysis;
  final String? selectedMarketDetectionId;

  @override
  Widget build(BuildContext context) {
    final panels = <Widget>[
      const EconomicCalendarPanel(compact: true),
      _PatternsPanel(
        patterns: patterns,
        selectedPatternId: selectedPatternId,
        hiddenPatternIds: hiddenPatternIds,
        diagnostics: harmonicDiagnostics,
        debug: harmonicDebug,
      ),
      _SmartMoneyPanel(
        analysis: marketAnalysis,
        selectedId: selectedMarketDetectionId,
      ),
      _PriceActionPanel(
        patterns: marketAnalysis.priceActionPatterns,
        selectedId: selectedMarketDetectionId,
      ),
      _IndicatorsPanel(indicators),
    ];
    return SizedBox(
      height: 210,
      child: DefaultTabController(
        length: panels.length,
        child: Column(
          children: [
            TabBar(
              dividerColor: AppColors.border,
              indicatorColor: AppColors.cyan,
              labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                Tab(text: context.l10n.text('news')),
                Tab(text: context.l10n.text('detectedPatterns')),
                Tab(text: context.l10n.text('smartMoney')),
                Tab(text: context.l10n.text('priceAction')),
                Tab(text: context.l10n.text('indicatorsStatus')),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(child: TabBarView(children: panels)),
          ],
        ),
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.icon,
    required this.title,
    required this.child,
    required this.color,
    this.showDemo = true,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final Color color;
  final bool showDemo;

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
            if (showDemo) const DemoBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    ),
  );
}

class _PatternsPanel extends StatefulWidget {
  const _PatternsPanel({
    required this.patterns,
    required this.selectedPatternId,
    required this.hiddenPatternIds,
    required this.diagnostics,
    required this.debug,
  });

  final List<HarmonicPattern> patterns;
  final String? selectedPatternId;
  final Set<String> hiddenPatternIds;
  final List<HarmonicDiagnostic> diagnostics;
  final HarmonicDebugSnapshot debug;

  @override
  State<_PatternsPanel> createState() => _PatternsPanelState();
}

class _PatternsPanelState extends State<_PatternsPanel> {
  String _query = '';
  PatternDirection? _direction;
  HarmonicPatternStatus? _status;

  @override
  Widget build(BuildContext context) {
    final patterns = widget.patterns.where((pattern) {
      final queryMatches =
          _query.isEmpty ||
          pattern.displayName.toLowerCase().contains(_query.toLowerCase()) ||
          pattern.timeframe.toLowerCase().contains(_query.toLowerCase());
      return queryMatches &&
          (_direction == null || pattern.direction == _direction) &&
          (_status == null || pattern.status == _status);
    }).toList();
    return _PanelShell(
      icon: Icons.polyline,
      title: context.l10n.text('detectedPatterns'),
      color: AppColors.purple,
      showDemo: false,
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value.trim()),
                    style: const TextStyle(fontSize: 9),
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search, size: 14),
                      hintText: 'Pattern / timeframe',
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                _compactFilter<PatternDirection>(
                  _direction,
                  PatternDirection.values,
                  (value) => setState(() => _direction = value),
                ),
                _compactFilter<HarmonicPatternStatus>(
                  _status,
                  HarmonicPatternStatus.values,
                  (value) => setState(() => _status = value),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showDebugPanel(context),
            child: Row(
              children: [
                const Icon(
                  Icons.bug_report_outlined,
                  size: 12,
                  color: AppColors.amber,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.patterns.isEmpty
                        ? 'Pattern Not Detected'
                        : widget.patterns.every(
                            (item) => widget.hiddenPatternIds.contains(item.id),
                          )
                        ? 'Pattern Detected But Hidden'
                        : 'Pattern Detected',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.amber, fontSize: 8),
                  ),
                ),
                const Icon(Icons.open_in_new, size: 11, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: patterns.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.text('insufficientData'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: patterns.length,
                    itemBuilder: (context, index) {
                      final pattern = patterns[index];
                      final hidden = widget.hiddenPatternIds.contains(
                        pattern.id,
                      );
                      final selected = widget.selectedPatternId == pattern.id;
                      final color =
                          pattern.direction == PatternDirection.bullish
                          ? AppColors.green
                          : AppColors.red;
                      return InkWell(
                        onTap: () => context
                            .read<DashboardCubit>()
                            .selectPattern(pattern.id),
                        child: Container(
                          color: selected
                              ? AppColors.purple.withValues(alpha: .12)
                              : null,
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.circle, color: color, size: 7),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${pattern.direction.name} ${pattern.displayName} · ${pattern.timeframe}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                  ),
                                  Text(
                                    '${pattern.status.name}  ${(pattern.geometryScore * 100).round()}%',
                                    style: TextStyle(color: color, fontSize: 8),
                                  ),
                                  SizedBox(
                                    width: 28,
                                    height: 24,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      iconSize: 14,
                                      icon: Icon(
                                        hidden
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppColors.muted,
                                      ),
                                      onPressed: () {
                                        context
                                            .read<DashboardCubit>()
                                            .togglePatternVisibility(
                                              pattern.id,
                                            );
                                        final hidden = Set<String>.of(
                                          widget.hiddenPatternIds,
                                        );
                                        hidden.contains(pattern.id)
                                            ? hidden.remove(pattern.id)
                                            : hidden.add(pattern.id);
                                        AppSettingsScope.of(
                                          context,
                                        ).setHarmonicDisplay(
                                          hiddenPatternIds: hidden,
                                          showAll: context
                                              .read<DashboardCubit>()
                                              .state
                                              .showAllPatterns,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (selected)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    13,
                                    0,
                                    6,
                                    4,
                                  ),
                                  child: Text(
                                    'PRZ ${pattern.przLower.toStringAsFixed(3)}–${pattern.przUpper.toStringAsFixed(3)} · '
                                    '${pattern.detectedAtUtc.toLocal()}\n'
                                    '${pattern.ratios.entries.map((item) => '${item.key}=${item.value.toStringAsFixed(3)}').join(' · ')}',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _compactFilter<T>(
    T? value,
    List<T> values,
    ValueChanged<T?> onChanged,
  ) => SizedBox(
    width: 74,
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T?>(
        value: value,
        isExpanded: true,
        style: const TextStyle(fontSize: 8, color: AppColors.muted),
        items: [
          DropdownMenuItem<T?>(
            value: null,
            child: Text(context.l10n.text('all')),
          ),
          ...values.map(
            (item) => DropdownMenuItem<T?>(
              value: item,
              child: Text((item as Enum).name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    ),
  );

  Future<void> _showDebugPanel(BuildContext context) {
    final hiddenCount = widget.patterns
        .where((item) => widget.hiddenPatternIds.contains(item.id))
        .length;
    final forming = widget.patterns
        .where((item) => item.status == HarmonicPatternStatus.forming)
        .length;
    final completed = widget.patterns
        .where((item) => item.status == HarmonicPatternStatus.completed)
        .length;
    final invalidated = widget.patterns
        .where((item) => item.status == HarmonicPatternStatus.invalidated)
        .length;
    final status = widget.patterns.isEmpty
        ? 'Pattern Not Detected'
        : hiddenCount == widget.patterns.length
        ? 'Pattern Detected But Hidden'
        : 'Pattern Detected';
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Harmonic Debug'),
        content: SizedBox(
          width: 620,
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(
                  color: widget.patterns.isEmpty
                      ? AppColors.red
                      : hiddenCount == widget.patterns.length
                      ? AppColors.amber
                      : AppColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text('Candles: ${widget.debug.candleCount}'),
              Text(
                'Swings: ${widget.debug.swingCounts.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
              ),
              Text('Combinations checked: ${widget.debug.combinationsChecked}'),
              Text('Valid patterns: ${widget.debug.validPatternCount}'),
              Text('Hidden patterns: $hiddenCount'),
              Text(
                'Forming: $forming · Completed: $completed · Invalidated: $invalidated',
              ),
              const Divider(),
              const Text(
                'Rejected candidates',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: widget.debug.diagnostics.isEmpty
                    ? const Center(child: Text('No rejection details'))
                    : ListView.separated(
                        itemCount: widget.debug.diagnostics.length,
                        separatorBuilder: (_, _) => const Divider(height: 8),
                        itemBuilder: (context, index) {
                          final item = widget.debug.diagnostics[index];
                          return Text(
                            '${item.reason.name}: ${item.detail}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.text('close')),
          ),
        ],
      ),
    );
  }
}

class _SmartMoneyPanel extends StatelessWidget {
  const _SmartMoneyPanel({required this.analysis, required this.selectedId});

  final PriceActionSmcSnapshot analysis;
  final String? selectedId;

  @override
  Widget build(BuildContext context) => _PanelShell(
    icon: Icons.account_balance,
    title: context.l10n.text('smartMoney'),
    color: AppColors.cyan,
    showDemo: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.text('probableZoneNotice'),
          style: const TextStyle(color: AppColors.muted, fontSize: 8),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _smcItems(context).isEmpty
              ? Center(child: Text(context.l10n.text('insufficientData')))
              : ListView(
                  children: _smcItems(context)
                      .map(
                        (item) => _DetectionRow(
                          id: item.$1,
                          label: item.$2,
                          value: item.$3,
                          color: item.$4,
                          selected: item.$1 == selectedId,
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    ),
  );

  List<(String, String, String, Color)> _smcItems(BuildContext context) => [
    ...analysis.structureBreaks.reversed
        .take(4)
        .map(
          (item) => (
            item.id,
            item.type == StructureBreakType.changeOfCharacter ? 'CHoCH' : 'BOS',
            '${item.direction.name}  ${item.level.toStringAsFixed(2)}',
            item.direction == MarketDirection.bullish
                ? AppColors.green
                : AppColors.red,
          ),
        ),
    ...analysis.orderBlocks.reversed
        .take(3)
        .map(
          (item) => (
            item.id,
            context.l10n.text('orderBlock'),
            '${item.lower.toStringAsFixed(2)} – ${item.upper.toStringAsFixed(2)}',
            item.direction == MarketDirection.bullish
                ? AppColors.green
                : AppColors.red,
          ),
        ),
    ...analysis.fairValueGaps.reversed
        .take(3)
        .map(
          (item) => (
            item.id,
            '${context.l10n.text('fairValueGap')} · ${_gapStatus(context, item.status)}',
            '${item.lower.toStringAsFixed(2)} – ${item.upper.toStringAsFixed(2)}',
            item.direction == MarketDirection.bullish
                ? AppColors.green
                : AppColors.red,
          ),
        ),
    ...analysis.liquiditySweeps.reversed
        .take(3)
        .map(
          (item) => (
            item.id,
            context.l10n.text('liquiditySweep'),
            item.level.toStringAsFixed(2),
            item.direction == MarketDirection.bullish
                ? AppColors.green
                : AppColors.red,
          ),
        ),
  ];

  String _gapStatus(BuildContext context, FairValueGapStatus status) =>
      context.l10n.text(switch (status) {
        FairValueGapStatus.unfilled => 'unfilled',
        FairValueGapStatus.partiallyFilled => 'partiallyFilled',
        FairValueGapStatus.filled => 'filled',
      });
}

class _PriceActionPanel extends StatelessWidget {
  const _PriceActionPanel({required this.patterns, required this.selectedId});
  final List<PriceActionPattern> patterns;
  final String? selectedId;

  @override
  Widget build(BuildContext context) => _PanelShell(
    icon: Icons.show_chart,
    title: context.l10n.text('priceAction'),
    color: AppColors.green,
    showDemo: false,
    child: patterns.isEmpty
        ? Center(child: Text(context.l10n.text('insufficientData')))
        : ListView(
            children: patterns.reversed
                .take(12)
                .map(
                  (item) => _DetectionRow(
                    id: item.id,
                    label: _patternLabel(context, item.type),
                    value: item.lowConfidence
                        ? context.l10n.text('lowConfidence')
                        : item.level.toStringAsFixed(2),
                    color: item.direction == MarketDirection.bearish
                        ? AppColors.red
                        : item.direction == MarketDirection.bullish
                        ? AppColors.green
                        : AppColors.amber,
                    selected: item.id == selectedId,
                  ),
                )
                .toList(),
          ),
  );

  String _patternLabel(BuildContext context, PriceActionPatternType type) =>
      context.l10n.text(switch (type) {
        PriceActionPatternType.bullishEngulfing => 'bullishEngulfing',
        PriceActionPatternType.bearishEngulfing => 'bearishEngulfing',
        PriceActionPatternType.bullishPinBar => 'bullishPinBar',
        PriceActionPatternType.bearishPinBar => 'bearishPinBar',
        PriceActionPatternType.insideBar => 'insideBar',
        PriceActionPatternType.doji => 'doji',
        PriceActionPatternType.bullishBreakout => 'bullishBreakout',
        PriceActionPatternType.bearishBreakout => 'bearishBreakout',
        PriceActionPatternType.bullishRetest => 'bullishRetest',
        PriceActionPatternType.bearishRetest => 'bearishRetest',
        PriceActionPatternType.supportResistanceFlip => 'supportResistanceFlip',
      });
}

class _DetectionRow extends StatelessWidget {
  const _DetectionRow({
    required this.id,
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
  });
  final String id;
  final String label;
  final String value;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.read<DashboardCubit>().selectMarketDetection(id),
    child: Container(
      color: selected ? color.withValues(alpha: .1) : null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
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
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _IndicatorsPanel extends StatelessWidget {
  const _IndicatorsPanel(this.indicators);

  final IndicatorSnapshot? indicators;

  @override
  Widget build(BuildContext context) {
    final snapshot = indicators;
    final ema20 = snapshot?.latestEma20;
    final ema50 = snapshot?.latestEma50;
    final ema200 = snapshot?.latestEma200;
    final emaBullish =
        ema20 != null &&
        ema50 != null &&
        ema200 != null &&
        ema20 > ema50 &&
        ema50 > ema200;
    final emaBearish =
        ema20 != null &&
        ema50 != null &&
        ema200 != null &&
        ema20 < ema50 &&
        ema50 < ema200;
    final histogram = snapshot?.latestMacdHistogram;
    final adx = snapshot?.latestAdx;

    return _PanelShell(
      icon: Icons.tune,
      title: context.l10n.text('indicatorsStatus'),
      color: AppColors.green,
      showDemo: false,
      child: Column(
        children: [
          _StatusRow(
            'EMA 20/50/200',
            emaBullish
                ? 'Bullish'
                : emaBearish
                ? 'Bearish'
                : _value(ema20),
            emaBullish
                ? AppColors.green
                : emaBearish
                ? AppColors.red
                : AppColors.muted,
          ),
          _StatusRow('RSI (14)', _value(snapshot?.latestRsi), AppColors.amber),
          _StatusRow(
            'MACD Histogram',
            _value(histogram),
            histogram == null
                ? AppColors.muted
                : histogram >= 0
                ? AppColors.green
                : AppColors.red,
          ),
          _StatusRow(
            'ADX / ATR',
            '${_value(adx)} / ${_value(snapshot?.latestAtr)}',
            AppColors.cyan,
          ),
          _StatusRow(
            'Volume / Avg 20',
            '${snapshot?.tickVolume ?? '--'} / ${_value(snapshot?.latestAverageVolume, digits: 0)}',
            AppColors.purple,
          ),
        ],
      ),
    );
  }

  static String _value(double? value, {int digits = 2}) =>
      value == null ? '--' : value.toStringAsFixed(digits);
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
