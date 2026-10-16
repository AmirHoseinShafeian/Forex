import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/mock_market_data.dart';
import '../../domain/analysis_models.dart';
import '../../domain/price_action_models.dart';
import 'dashboard_card.dart';

class AnalysisPanel extends StatelessWidget {
  const AnalysisPanel({
    required this.analysis,
    required this.timeframeTrends,
    required this.indicators,
    required this.marketAnalysis,
    super.key,
  });

  final TrendAnalysis? analysis;
  final Map<String, TrendAnalysis> timeframeTrends;
  final IndicatorSnapshot? indicators;
  final PriceActionSmcSnapshot marketAnalysis;

  @override
  Widget build(BuildContext context) {
    final trend = analysis ?? const TrendAnalysis.unknown();
    final color = _directionColor(trend.direction);
    return DashboardCard(
      padding: const EdgeInsets.all(11),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppColors.cyan, size: 19),
                const SizedBox(width: 7),
                Text(
                  context.l10n.text('trendAnalysis'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: color.withValues(alpha: .7)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .12),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Text(
                _directionLabel(context, trend.direction),
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _QuickStat(
                    label: context.l10n.text('trendStrength'),
                    value: _strengthLabel(context, trend.strength),
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _QuickStat(
                    label: 'ADX 14',
                    value: _value(indicators?.latestAdx),
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _QuickStat(
                    label: 'ATR 14',
                    value: _value(indicators?.latestAtr),
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.text('analysisReasons'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ...trend.reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: color, size: 6),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _localizedReason(context, reason),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.text('currentIndicators'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            _IndicatorValue('EMA 20', indicators?.latestEma20, AppColors.cyan),
            _IndicatorValue('EMA 50', indicators?.latestEma50, AppColors.amber),
            _IndicatorValue('EMA 200', indicators?.latestEma200, AppColors.red),
            _IndicatorValue('RSI 14', indicators?.latestRsi, AppColors.purple),
            _IndicatorValue('MACD', indicators?.latestMacd, AppColors.cyan),
            _IndicatorValue(
              'Avg Volume 20',
              indicators?.latestAverageVolume,
              AppColors.green,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.text('timeframeStatus'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: MockMarketData.timeframes.map((timeframe) {
                final value =
                    timeframeTrends[timeframe] ?? const TrendAnalysis.unknown();
                return _TimeframeTrend(timeframe, value.direction);
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.text('phaseSixSummary'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            _PhaseSixSummary(analysis: marketAnalysis),
          ],
        ),
      ),
    );
  }

  static String _value(double? value) => value?.toStringAsFixed(2) ?? '—';
}

class _PhaseSixSummary extends StatelessWidget {
  const _PhaseSixSummary({required this.analysis});
  final PriceActionSmcSnapshot analysis;

  @override
  Widget build(BuildContext context) {
    if (analysis.isEmpty) {
      return Text(
        context.l10n.text('noDetections'),
        style: const TextStyle(color: AppColors.muted, fontSize: 10),
      );
    }
    final latestBreak = analysis.structureBreaks.lastOrNull;
    final latestPattern = analysis.priceActionPatterns.lastOrNull;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (latestBreak != null)
          _SummaryChip(
            label: latestBreak.type == StructureBreakType.changeOfCharacter
                ? 'CHoCH'
                : 'BOS',
            color: latestBreak.direction == MarketDirection.bullish
                ? AppColors.green
                : AppColors.red,
          ),
        _SummaryChip(
          label:
              '${context.l10n.text('orderBlock')}: ${analysis.orderBlocks.length}',
          color: AppColors.purple,
        ),
        _SummaryChip(
          label:
              '${context.l10n.text('fairValueGap')}: ${analysis.fairValueGaps.length}',
          color: AppColors.cyan,
        ),
        if (latestPattern != null)
          _SummaryChip(
            label: context.l10n.text('priceAction'),
            color: latestPattern.direction == MarketDirection.bearish
                ? AppColors.red
                : AppColors.green,
          ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
    ),
  );
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

class _IndicatorValue extends StatelessWidget {
  const _IndicatorValue(this.label, this.value, this.color);
  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 5),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(Icons.circle, color: color, size: 7),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontSize: 10)),
        const Spacer(),
        Text(
          value?.toStringAsFixed(3) ?? '—',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _TimeframeTrend extends StatelessWidget {
  const _TimeframeTrend(this.timeframe, this.direction);
  final String timeframe;
  final TrendDirection direction;

  @override
  Widget build(BuildContext context) {
    final color = _directionColor(direction);
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .5)),
      ),
      child: Row(
        children: [
          Text(
            timeframe,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          ),
          const Spacer(),
          Text(
            _directionLabel(context, direction),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

Color _directionColor(TrendDirection direction) => switch (direction) {
  TrendDirection.bullish => AppColors.green,
  TrendDirection.bearish => AppColors.red,
  TrendDirection.sideways => AppColors.amber,
  TrendDirection.unknown => AppColors.muted,
};

String _directionLabel(BuildContext context, TrendDirection direction) =>
    context.l10n.text(switch (direction) {
      TrendDirection.bullish => 'bullish',
      TrendDirection.bearish => 'bearish',
      TrendDirection.sideways => 'sideways',
      TrendDirection.unknown => 'unknown',
    });

String _strengthLabel(BuildContext context, TrendStrength strength) =>
    context.l10n.text(switch (strength) {
      TrendStrength.weak => 'weak',
      TrendStrength.moderate => 'moderate',
      TrendStrength.strong => 'strong',
      TrendStrength.unknown => 'unknown',
    });

String _localizedReason(BuildContext context, String reason) {
  if (context.l10n.isPersian) return reason;
  if (reason.contains('EMA')) return 'EMA alignment confirms the trend';
  if (reason.contains('ADX')) {
    final value = RegExp(r'\d+(?:\.\d+)?').firstMatch(reason)?.group(0);
    return value == null ? 'ADX confirms trend strength' : 'ADX is $value';
  }
  return 'Price structure confirms the detected direction';
}
