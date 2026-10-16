import 'analysis_models.dart';
import 'dashboard_state.dart';

enum TradingDecisionAction { buy, sell, wait, noTrade }

enum DecisionDataQuality { valid, limited, stale, unavailable }

enum DecisionGroup {
  trendStructure,
  momentum,
  harmonicFibonacci,
  priceActionSmc,
  supportResistance,
  riskMarket,
}

enum SuggestedEntryType { market, limit, stop }

class DecisionGroupResult {
  const DecisionGroupResult({
    required this.group,
    required this.direction,
    required this.strength,
    required this.reliability,
    required this.weight,
    required this.timeframe,
    required this.timestampUtc,
    required this.reasons,
    required this.invalidations,
  });

  final DecisionGroup group;
  final TrendDirection direction;
  final int strength;
  final int reliability;
  final double weight;
  final String timeframe;
  final DateTime timestampUtc;
  final List<String> reasons;
  final List<String> invalidations;

  int get signedStrength => switch (direction) {
    TrendDirection.bullish => strength,
    TrendDirection.bearish => -strength,
    TrendDirection.sideways || TrendDirection.unknown => 0,
  };
}

class TradeSetupLevels {
  const TradeSetupLevels({
    required this.entryType,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.riskReward,
    required this.invalidationReason,
  });

  final SuggestedEntryType entryType;
  final double entry;
  final double stopLoss;
  final double takeProfit1;
  final double takeProfit2;
  final double riskReward;
  final String invalidationReason;
}

class TradingDecision {
  const TradingDecision({
    required this.symbol,
    required this.timeframe,
    required this.action,
    required this.setupQualityScore,
    required this.trendAlignment,
    required this.groups,
    required this.reasonsFor,
    required this.reasonsAgainst,
    required this.missingConfirmations,
    required this.warnings,
    required this.dataQuality,
    required this.sourceStatus,
    required this.updatedAtUtc,
    required this.riskPercent,
    this.levels,
    this.suggestedVolume,
  });

  const TradingDecision.unavailable({
    this.symbol = '',
    this.timeframe = '',
    this.sourceStatus = MarketStatus.loading,
  }) : action = TradingDecisionAction.noTrade,
       setupQualityScore = 0,
       trendAlignment = false,
       groups = const [],
       reasonsFor = const [],
       reasonsAgainst = const ['Market data is unavailable'],
       missingConfirmations = const ['Waiting for a complete market snapshot'],
       warnings = const [],
       dataQuality = DecisionDataQuality.unavailable,
       updatedAtUtc = null,
       riskPercent = .5,
       levels = null,
       suggestedVolume = null;

  final String symbol;
  final String timeframe;
  final TradingDecisionAction action;
  final int setupQualityScore;
  final bool trendAlignment;
  final List<DecisionGroupResult> groups;
  final List<String> reasonsFor;
  final List<String> reasonsAgainst;
  final List<String> missingConfirmations;
  final List<String> warnings;
  final DecisionDataQuality dataQuality;
  final MarketStatus sourceStatus;
  final DateTime? updatedAtUtc;
  final double riskPercent;
  final TradeSetupLevels? levels;
  final double? suggestedVolume;

  bool get hasExecutableSetup =>
      (action == TradingDecisionAction.buy ||
          action == TradingDecisionAction.sell) &&
      levels != null &&
      dataQuality == DecisionDataQuality.valid &&
      sourceStatus == MarketStatus.live;
}
