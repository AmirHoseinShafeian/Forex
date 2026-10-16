import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/analysis_models.dart';
import '../../domain/dashboard_state.dart';
import '../../domain/trading_decision_models.dart';
import 'dashboard_card.dart';

class TradingDecisionPanel extends StatelessWidget {
  const TradingDecisionPanel({required this.decision, super.key});

  final TradingDecision decision;

  @override
  Widget build(BuildContext context) {
    final advanced = AppSettingsScope.of(context).isAdvanced;
    final color = _actionColor(decision.action);
    return DashboardCard(
      padding: const EdgeInsets.all(11),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_alt_outlined,
                  color: AppColors.cyan,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _t(context, 'تصمیم معاملاتی هوشمند', 'AI Trading Decision'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _Badge(decision.sourceStatus.dataLabel, AppColors.muted),
                const SizedBox(width: 4),
                _Badge(decision.dataQuality.name.toUpperCase(), AppColors.cyan),
              ],
            ),
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: .65)),
              ),
              child: Row(
                children: [
                  Text(
                    _actionLabel(decision.action),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${decision.setupQualityScore}/100',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        _t(context, 'امتیاز انطباق قواعد', 'Rule match score'),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _t(context, 'هم‌جهتی روند', 'Trend alignment'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
                const Spacer(),
                _Badge(
                  decision.trendAlignment
                      ? _t(context, 'تأیید', 'ALIGNED')
                      : _t(context, 'تأیید نشده', 'NOT ALIGNED'),
                  decision.trendAlignment ? AppColors.green : AppColors.amber,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _levels(context),
            const SizedBox(height: 8),
            _reasonSection(
              context,
              _t(context, 'دلایل موافق', 'Reasons for'),
              decision.reasonsFor.take(advanced ? 5 : 3),
              AppColors.green,
            ),
            _reasonSection(
              context,
              _t(
                context,
                'دلایل مخالف / تأییدهای ناقص',
                'Reasons against / missing confirmations',
              ),
              [
                ...decision.reasonsAgainst,
                ...decision.missingConfirmations,
              ].take(advanced ? 6 : 2),
              AppColors.amber,
            ),
            if (advanced) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: decision.groups.map((group) {
                  final groupColor = _directionColor(group.direction);
                  return _Badge(
                    '${_groupLabel(group.group)} ${group.strength}% '
                    'W${(group.weight * 100).round()} '
                    'R${group.reliability}',
                    groupColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 7),
              Text(
                '${_t(context, 'ریسک آزمایشی', 'Experimental risk')}: '
                '${decision.riskPercent.toStringAsFixed(1)}%  •  '
                '${_t(context, 'حجم', 'Volume')}: '
                '${decision.suggestedVolume?.toStringAsFixed(2) ?? _t(context, 'اطلاعات ناکافی', 'insufficient data')}',
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
              if (decision.levels != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    '${_t(context, 'ابطال ستاپ', 'Invalidation')}: '
                    '${decision.levels!.invalidationReason}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 9),
                  ),
                ),
            ],
            for (final warning in decision.warnings.take(2))
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '⚠ ${_localized(context, warning)}',
                  style: const TextStyle(color: AppColors.amber, fontSize: 9),
                ),
              ),
            if (decision.updatedAtUtc != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_t(context, 'آخرین بروزرسانی', 'Last updated')}: '
                  '${decision.updatedAtUtc!.toLocal()}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _levels(BuildContext context) {
    final levels = decision.levels;
    if (levels == null) {
      return Text(
        _t(
          context,
          'سطوح ورود فقط پس از تأیید ستاپ نمایش داده می‌شوند.',
          'Entry levels appear only after a setup is confirmed.',
        ),
        style: const TextStyle(color: AppColors.muted, fontSize: 9),
      );
    }
    String value(double number) => number.toStringAsFixed(3);
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        _Badge('Entry ${value(levels.entry)}', AppColors.cyan),
        _Badge('SL ${value(levels.stopLoss)}', AppColors.red),
        _Badge('TP1 ${value(levels.takeProfit1)}', AppColors.green),
        _Badge('TP2 ${value(levels.takeProfit2)}', AppColors.green),
        _Badge(
          'RR 1:${levels.riskReward.toStringAsFixed(1)}',
          AppColors.purple,
        ),
      ],
    );
  }

  Widget _reasonSection(
    BuildContext context,
    String title,
    Iterable<String> values,
    Color color,
  ) {
    final items = values.toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 9),
          ),
          for (final value in items)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '• ${_localized(context, value)}',
                style: TextStyle(color: color, fontSize: 9, height: 1.25),
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withValues(alpha: .4)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700),
    ),
  );
}

String _t(BuildContext context, String fa, String en) =>
    context.l10n.isPersian ? fa : en;

String _actionLabel(TradingDecisionAction action) => switch (action) {
  TradingDecisionAction.buy => 'BUY',
  TradingDecisionAction.sell => 'SELL',
  TradingDecisionAction.wait => 'WAIT',
  TradingDecisionAction.noTrade => 'NO TRADE',
};

Color _actionColor(TradingDecisionAction action) => switch (action) {
  TradingDecisionAction.buy => AppColors.green,
  TradingDecisionAction.sell => AppColors.red,
  TradingDecisionAction.wait => AppColors.amber,
  TradingDecisionAction.noTrade => AppColors.muted,
};

Color _directionColor(TrendDirection direction) => switch (direction) {
  TrendDirection.bullish => AppColors.green,
  TrendDirection.bearish => AppColors.red,
  TrendDirection.sideways => AppColors.amber,
  TrendDirection.unknown => AppColors.muted,
};

String _groupLabel(DecisionGroup group) => switch (group) {
  DecisionGroup.trendStructure => 'Trend',
  DecisionGroup.momentum => 'Momentum',
  DecisionGroup.harmonicFibonacci => 'Harmonic',
  DecisionGroup.priceActionSmc => 'PA/SMC',
  DecisionGroup.supportResistance => 'S/R',
  DecisionGroup.riskMarket => 'Risk',
};

String _localized(BuildContext context, String value) {
  if (!context.l10n.isPersian) return value;
  const values = {
    'Market data is unavailable': 'دادهٔ بازار در دسترس نیست',
    'No new trade setup is issued': 'ستاپ معاملاتی جدید صادر نمی‌شود',
    'Cached data cannot produce a new executable setup':
        'دادهٔ کش‌شده برای ستاپ جدید قابل اتکا نیست',
    'Market connection is unavailable': 'اتصال بازار در دسترس نیست',
    'Market tick is stale': 'دادهٔ قیمت قدیمی است',
    'Suggested setup only; no order is sent to MT5':
        'این فقط پیشنهاد تحلیلی است و سفارشی به MT5 ارسال نمی‌شود',
    'DEMO data: analysis only': 'دادهٔ آزمایشی؛ فقط برای تحلیل',
    'Higher timeframe direction conflicts': 'جهت تایم‌فریم بالاتر متناقض است',
    'Analysis groups are materially divided':
        'گروه‌های تحلیلی اختلاف جدی دارند',
  };
  return values[value] ?? value;
}
