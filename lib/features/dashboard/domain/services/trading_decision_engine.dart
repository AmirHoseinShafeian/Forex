import 'dart:math' as math;

import '../analysis_models.dart';
import '../dashboard_state.dart';
import '../harmonic_models.dart';
import '../market_models.dart';
import '../price_action_models.dart';
import '../trading_decision_models.dart';
import '../economic_news_models.dart';

class TradingDecisionConfig {
  const TradingDecisionConfig({
    this.riskPercent = .5,
    this.minimumRiskReward = 2,
    this.decisionThreshold = 55,
    this.waitThreshold = 30,
    this.weights = const {
      DecisionGroup.trendStructure: .30,
      DecisionGroup.momentum: .15,
      DecisionGroup.harmonicFibonacci: .15,
      DecisionGroup.priceActionSmc: .25,
      DecisionGroup.supportResistance: .15,
    },
  });

  final double riskPercent;
  final double minimumRiskReward;
  final int decisionThreshold;
  final int waitThreshold;
  final Map<DecisionGroup, double> weights;
}

class TradingDecisionInput {
  const TradingDecisionInput({
    required this.symbol,
    required this.timeframe,
    required this.status,
    required this.candles,
    required this.tick,
    required this.indicators,
    required this.trend,
    required this.timeframeTrends,
    required this.zones,
    required this.patterns,
    required this.fibonacci,
    required this.marketAnalysis,
    required this.timestampUtc,
    required this.newsRisk,
  });

  final String symbol;
  final String timeframe;
  final MarketStatus status;
  final List<Candle> candles;
  final MarketTick? tick;
  final IndicatorSnapshot? indicators;
  final TrendAnalysis trend;
  final Map<String, TrendAnalysis> timeframeTrends;
  final List<PriceZone> zones;
  final List<HarmonicPattern> patterns;
  final FibonacciAnalysis? fibonacci;
  final PriceActionSmcSnapshot marketAnalysis;
  final DateTime timestampUtc;
  final NewsRiskSnapshot newsRisk;
}

class TradingDecisionEngine {
  const TradingDecisionEngine({this.config = const TradingDecisionConfig()});

  final TradingDecisionConfig config;

  TradingDecision evaluate(TradingDecisionInput input) {
    final indicators = input.indicators;
    final tick = input.tick;
    if (indicators == null || tick == null || input.candles.length < 200) {
      return _blocked(
        input,
        DecisionDataQuality.unavailable,
        'Insufficient candles, indicators, or live tick data',
      );
    }
    if (input.status == MarketStatus.disconnected ||
        input.status == MarketStatus.cached) {
      return _blocked(
        input,
        input.status == MarketStatus.cached
            ? DecisionDataQuality.stale
            : DecisionDataQuality.unavailable,
        input.status == MarketStatus.cached
            ? 'Cached data cannot produce a new executable setup'
            : 'Market connection is unavailable',
      );
    }

    final age = input.timestampUtc.difference(tick.timeUtc).abs();
    if (age > _timeframeDuration(input.timeframe) * 2) {
      return _blocked(input, DecisionDataQuality.stale, 'Market tick is stale');
    }

    final groups = <DecisionGroupResult>[
      _trendGroup(input),
      _momentumGroup(input),
      _harmonicGroup(input),
      _priceActionGroup(input),
      _supportResistanceGroup(input),
      _riskGroup(input),
    ];
    final directionalGroups = groups
        .where((group) => config.weights.containsKey(group.group))
        .toList();
    final weightTotal = directionalGroups.fold<double>(
      0,
      (sum, group) => sum + config.weights[group.group]!,
    );
    final signedScore =
        directionalGroups.fold<double>(0, (sum, group) {
          final quality = group.reliability / 100;
          return sum +
              group.signedStrength * config.weights[group.group]! * quality;
        }) /
        math.max(.001, weightTotal);

    final risk = groups.last;
    final contradictions = directionalGroups
        .where((group) => group.direction != TrendDirection.unknown)
        .map((group) => group.direction)
        .toSet();
    final hasConflict =
        contradictions.contains(TrendDirection.bullish) &&
        contradictions.contains(TrendDirection.bearish);
    final aligned = _higherTimeframeAligned(input, signedScore.sign);
    final lowerConfirmation = _lowerTimeframeConfirmation(
      input,
      signedScore.sign,
    );
    final reasonsFor = <String>[];
    final reasonsAgainst = <String>[];
    final missing = <String>[];
    for (final group in groups) {
      if (group.direction == TrendDirection.unknown) {
        missing.addAll(group.invalidations);
      } else if (group.signedStrength.sign == signedScore.sign) {
        reasonsFor.addAll(group.reasons);
      } else if (group.signedStrength != 0) {
        reasonsAgainst.addAll(group.reasons);
      }
    }
    if (!aligned) reasonsAgainst.add('Higher timeframe direction conflicts');
    if (lowerConfirmation == false) {
      reasonsAgainst.add('Lower timeframe confirmation conflicts');
    } else if (lowerConfirmation == null) {
      missing.add('Lower timeframe confirmation is unavailable');
    }
    if (hasConflict) {
      reasonsAgainst.add('Analysis groups are materially divided');
    }

    var action = TradingDecisionAction.wait;
    final absoluteScore = signedScore.abs().round().clamp(0, 100);
    if (risk.invalidations.isNotEmpty) {
      action = TradingDecisionAction.noTrade;
      reasonsAgainst.addAll(risk.invalidations);
    } else if (absoluteScore >= config.decisionThreshold &&
        aligned &&
        !hasConflict &&
        lowerConfirmation != false) {
      action = signedScore > 0
          ? TradingDecisionAction.buy
          : TradingDecisionAction.sell;
    } else if (absoluteScore < config.waitThreshold) {
      missing.add('Directional agreement is below the decision threshold');
    }

    TradeSetupLevels? levels;
    if (input.newsRisk.blocksNewEntries) {
      action = TradingDecisionAction.noTrade;
      reasonsAgainst.addAll(input.newsRisk.reasons);
      missing.add('Wait until the configured news risk window has ended');
    }
    if (action == TradingDecisionAction.buy ||
        action == TradingDecisionAction.sell) {
      levels = _buildLevels(input, action);
      if (levels == null || levels.riskReward < config.minimumRiskReward) {
        action = levels == null
            ? TradingDecisionAction.wait
            : TradingDecisionAction.noTrade;
        reasonsAgainst.add(
          levels == null
              ? 'No defensible invalidation level is available'
              : 'Risk/reward is below ${config.minimumRiskReward.toStringAsFixed(1)}',
        );
        levels = null;
      }
    }

    final warnings = <String>[
      if (input.status == MarketStatus.demo) 'DEMO data: analysis only',
      if (tick.spreadPrice > (indicators.latestAtr ?? double.infinity) * .05)
        'Spread is elevated relative to ATR',
      'Suggested setup only; no order is sent to MT5',
    ];
    return TradingDecision(
      symbol: input.symbol,
      timeframe: input.timeframe,
      action: action,
      setupQualityScore: absoluteScore,
      trendAlignment: aligned,
      groups: List.unmodifiable(groups),
      reasonsFor: List.unmodifiable(reasonsFor.take(5)),
      reasonsAgainst: List.unmodifiable(reasonsAgainst.take(5)),
      missingConfirmations: List.unmodifiable(missing.toSet().take(5)),
      warnings: List.unmodifiable(warnings),
      dataQuality: DecisionDataQuality.valid,
      sourceStatus: input.status,
      updatedAtUtc: input.timestampUtc,
      riskPercent: config.riskPercent,
      levels: levels,
      suggestedVolume: null,
    );
  }

  TradingDecision _blocked(
    TradingDecisionInput input,
    DecisionDataQuality quality,
    String reason,
  ) => TradingDecision(
    symbol: input.symbol,
    timeframe: input.timeframe,
    action: TradingDecisionAction.noTrade,
    setupQualityScore: 0,
    trendAlignment: false,
    groups: const [],
    reasonsFor: const [],
    reasonsAgainst: [reason],
    missingConfirmations: const [],
    warnings: const ['No new trade setup is issued'],
    dataQuality: quality,
    sourceStatus: input.status,
    updatedAtUtc: input.timestampUtc,
    riskPercent: config.riskPercent,
  );

  DecisionGroupResult _trendGroup(TradingDecisionInput input) {
    final trend = input.trend;
    final strength = switch (trend.strength) {
      TrendStrength.strong => 90,
      TrendStrength.moderate => 70,
      TrendStrength.weak => 40,
      TrendStrength.unknown => 0,
    };
    return _group(
      DecisionGroup.trendStructure,
      trend.direction,
      strength,
      trend.direction == TrendDirection.unknown ? 0 : 85,
      input,
      trend.reasons,
      trend.direction == TrendDirection.unknown
          ? const ['Trend and structure need more data']
          : const [],
    );
  }

  DecisionGroupResult _momentumGroup(TradingDecisionInput input) {
    final value = input.indicators!;
    final rsi = value.latestRsi;
    final histogram = value.latestMacdHistogram;
    if (rsi == null || histogram == null) {
      return _group(
        DecisionGroup.momentum,
        TrendDirection.unknown,
        0,
        0,
        input,
        const [],
        const ['RSI or MACD is unavailable'],
      );
    }
    final bullish = histogram > 0 && rsi >= 50 && rsi < 72;
    final bearish = histogram < 0 && rsi <= 50 && rsi > 28;
    final direction = bullish
        ? TrendDirection.bullish
        : bearish
        ? TrendDirection.bearish
        : TrendDirection.sideways;
    final strength = (50 + (rsi - 50).abs()).round().clamp(35, 85);
    return _group(DecisionGroup.momentum, direction, strength, 75, input, [
      'RSI ${rsi.toStringAsFixed(1)} and MACD momentum are evaluated together',
    ], const []);
  }

  DecisionGroupResult _harmonicGroup(TradingDecisionInput input) {
    final pattern = input.patterns
        .where((item) => item.status != HarmonicPatternStatus.invalidated)
        .firstOrNull;
    if (pattern == null) {
      return _group(
        DecisionGroup.harmonicFibonacci,
        TrendDirection.unknown,
        0,
        0,
        input,
        const [],
        const ['No valid harmonic setup'],
      );
    }
    final direction = pattern.direction == PatternDirection.bullish
        ? TrendDirection.bullish
        : TrendDirection.bearish;
    final confirmed = pattern.status == HarmonicPatternStatus.completed;
    return _group(
      DecisionGroup.harmonicFibonacci,
      direction,
      (pattern.geometryScore * 100).round().clamp(0, 100),
      confirmed ? 80 : 55,
      input,
      ['${pattern.displayName} ${pattern.status.name} near its PRZ'],
      confirmed ? const [] : const ['Harmonic pattern is not completed'],
    );
  }

  DecisionGroupResult _priceActionGroup(TradingDecisionInput input) {
    final values = <MarketDirection>[];
    final reasons = <String>[];
    final analysis = input.marketAnalysis;
    if (analysis.structureBreaks.isNotEmpty) {
      values.add(analysis.structureBreaks.last.direction);
      reasons.add(analysis.structureBreaks.last.type.name);
    }
    if (analysis.liquiditySweeps.isNotEmpty) {
      values.add(analysis.liquiditySweeps.last.direction);
      reasons.add('Confirmed liquidity sweep');
    }
    final pattern = analysis.priceActionPatterns.lastOrNull;
    if (pattern?.direction != null && !pattern!.lowConfidence) {
      values.add(pattern.direction!);
      reasons.add(pattern.reason);
    }
    if (values.isEmpty) {
      return _group(
        DecisionGroup.priceActionSmc,
        TrendDirection.unknown,
        0,
        0,
        input,
        const [],
        const ['No confirmed Price Action/SMC trigger'],
      );
    }
    final bullish = values
        .where((item) => item == MarketDirection.bullish)
        .length;
    final bearish = values.length - bullish;
    final direction = bullish == bearish
        ? TrendDirection.sideways
        : bullish > bearish
        ? TrendDirection.bullish
        : TrendDirection.bearish;
    return _group(
      DecisionGroup.priceActionSmc,
      direction,
      (55 + 12 * values.length).clamp(0, 92),
      80,
      input,
      reasons,
      const [],
    );
  }

  DecisionGroupResult _supportResistanceGroup(TradingDecisionInput input) {
    final price = input.tick!.last;
    final atr = input.indicators!.latestAtr;
    if (input.zones.isEmpty || atr == null || atr <= 0) {
      return _group(
        DecisionGroup.supportResistance,
        TrendDirection.unknown,
        0,
        0,
        input,
        const [],
        const ['No reliable support/resistance distance'],
      );
    }
    final support =
        input.zones
            .where(
              (zone) =>
                  zone.type == PriceZoneType.support && zone.midpoint < price,
            )
            .toList()
          ..sort((a, b) => b.midpoint.compareTo(a.midpoint));
    final resistance =
        input.zones
            .where(
              (zone) =>
                  zone.type == PriceZoneType.resistance &&
                  zone.midpoint > price,
            )
            .toList()
          ..sort((a, b) => a.midpoint.compareTo(b.midpoint));
    final supportDistance = support.isEmpty
        ? double.infinity
        : price - support.first.upper;
    final resistanceDistance = resistance.isEmpty
        ? double.infinity
        : resistance.first.lower - price;
    final direction = supportDistance < atr
        ? TrendDirection.bullish
        : resistanceDistance < atr
        ? TrendDirection.bearish
        : TrendDirection.sideways;
    return _group(
      DecisionGroup.supportResistance,
      direction,
      direction == TrendDirection.sideways ? 30 : 65,
      70,
      input,
      [
        direction == TrendDirection.bullish
            ? 'Price is near confirmed support'
            : direction == TrendDirection.bearish
            ? 'Price is near confirmed resistance'
            : 'Price is between major support and resistance',
      ],
      const [],
    );
  }

  DecisionGroupResult _riskGroup(TradingDecisionInput input) {
    final atr = input.indicators!.latestAtr;
    final price = input.tick!.last;
    final invalidations = <String>[];
    final reasons = <String>[];
    if (atr == null || atr <= 0) invalidations.add('ATR is unavailable');
    if (atr != null && atr > price * .03) {
      invalidations.add('Volatility is extreme');
    }
    if (atr != null && atr < price * .0002) {
      invalidations.add('Volatility is too low');
    }
    if (atr != null && input.tick!.spreadPrice > atr * .08) {
      invalidations.add('Spread is abnormal relative to volatility');
    }
    if (invalidations.isEmpty) {
      reasons.add('Spread and volatility are acceptable');
    }
    return _group(
      DecisionGroup.riskMarket,
      TrendDirection.sideways,
      invalidations.isEmpty ? 100 : 0,
      90,
      input,
      reasons,
      invalidations,
    );
  }

  DecisionGroupResult _group(
    DecisionGroup group,
    TrendDirection direction,
    int strength,
    int reliability,
    TradingDecisionInput input,
    List<String> reasons,
    List<String> invalidations,
  ) => DecisionGroupResult(
    group: group,
    direction: direction,
    strength: strength,
    reliability: reliability,
    weight: config.weights[group] ?? 0,
    timeframe: input.timeframe,
    timestampUtc: input.timestampUtc,
    reasons: List.unmodifiable(reasons),
    invalidations: List.unmodifiable(invalidations),
  );

  bool _higherTimeframeAligned(TradingDecisionInput input, num sign) {
    final required = _higherTimeframes[input.timeframe] ?? const <String>[];
    if (required.isEmpty) return true;
    final known = required
        .map((item) => input.timeframeTrends[item]?.direction)
        .whereType<TrendDirection>()
        .where((item) => item != TrendDirection.unknown)
        .toList();
    if (known.isEmpty) return false;
    final desired = sign >= 0 ? TrendDirection.bullish : TrendDirection.bearish;
    return known.every(
      (item) => item == desired || item == TrendDirection.sideways,
    );
  }

  bool? _lowerTimeframeConfirmation(TradingDecisionInput input, num sign) {
    final timeframe = _lowerTimeframes[input.timeframe];
    if (timeframe == null) return null;
    final direction = input.timeframeTrends[timeframe]?.direction;
    if (direction == null || direction == TrendDirection.unknown) return null;
    final desired = sign >= 0 ? TrendDirection.bullish : TrendDirection.bearish;
    return direction == desired || direction == TrendDirection.sideways;
  }

  TradeSetupLevels? _buildLevels(
    TradingDecisionInput input,
    TradingDecisionAction action,
  ) {
    final atr = input.indicators!.latestAtr;
    if (atr == null || atr <= 0) return null;
    final bullish = action == TradingDecisionAction.buy;
    final entry = bullish ? input.tick!.ask : input.tick!.bid;
    final candidates = <double>[];
    for (final zone in input.zones) {
      if (bullish && zone.type == PriceZoneType.support && zone.lower < entry) {
        candidates.add(zone.lower);
      } else if (!bullish &&
          zone.type == PriceZoneType.resistance &&
          zone.upper > entry) {
        candidates.add(zone.upper);
      }
    }
    for (final point in input.marketAnalysis.structurePoints) {
      if (bullish && point.price < entry || !bullish && point.price > entry) {
        candidates.add(point.price);
      }
    }
    final fallback = bullish ? entry - atr * 1.5 : entry + atr * 1.5;
    final stop = candidates.isEmpty
        ? fallback
        : candidates.reduce(bullish ? math.max : math.min);
    final risk = (entry - stop).abs();
    if (risk <= input.tick!.point * 2) return null;
    final minimumTarget = bullish
        ? entry + risk * config.minimumRiskReward
        : entry - risk * config.minimumRiskReward;
    final targetCandidates =
        input.zones
            .where(
              (zone) => bullish
                  ? zone.type == PriceZoneType.resistance && zone.lower > entry
                  : zone.type == PriceZoneType.support && zone.upper < entry,
            )
            .map((zone) => bullish ? zone.lower : zone.upper)
            .toList()
          ..sort(bullish ? (a, b) => a.compareTo(b) : (a, b) => b.compareTo(a));
    final nearestObstacle = targetCandidates.firstOrNull;
    final tp1 = nearestObstacle ?? minimumTarget;
    final reward = (tp1 - entry).abs();
    final riskReward = reward / risk;
    final fartherTargets = targetCandidates
        .where((target) => bullish ? target > tp1 : target < tp1)
        .toList();
    final tp2 =
        fartherTargets.firstOrNull ??
        (bullish ? entry + risk * 3 : entry - risk * 3);
    return TradeSetupLevels(
      entryType: SuggestedEntryType.market,
      entry: entry,
      stopLoss: stop,
      takeProfit1: tp1,
      takeProfit2: tp2,
      riskReward: riskReward,
      invalidationReason: bullish
          ? 'Close below the selected support/structure level'
          : 'Close above the selected resistance/structure level',
    );
  }

  Duration _timeframeDuration(String timeframe) => switch (timeframe) {
    'M1' => const Duration(minutes: 1),
    'M5' => const Duration(minutes: 5),
    'M15' => const Duration(minutes: 15),
    'M30' => const Duration(minutes: 30),
    'H1' => const Duration(hours: 1),
    'H4' => const Duration(hours: 4),
    'D1' => const Duration(days: 1),
    _ => const Duration(minutes: 15),
  };
}

const _higherTimeframes = <String, List<String>>{
  'M1': ['M5', 'M15'],
  'M5': ['M15', 'H1'],
  'M15': ['H1', 'H4'],
  'M30': ['H1', 'H4'],
  'H1': ['H4', 'D1'],
  'H4': ['D1'],
  'D1': [],
};

const _lowerTimeframes = <String, String>{
  'M5': 'M1',
  'M15': 'M5',
  'M30': 'M15',
  'H1': 'M15',
  'H4': 'H1',
  'D1': 'H4',
};
