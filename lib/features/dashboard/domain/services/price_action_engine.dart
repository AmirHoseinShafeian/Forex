import 'dart:math' as math;

import '../market_models.dart';
import '../price_action_models.dart';

class PriceActionConfig {
  const PriceActionConfig({
    this.dojiMaximumBodyFraction = .1,
    this.pinBarMinimumWickToBody = 2.2,
    this.engulfingMinimumBodyAtr = .2,
    this.retestToleranceAtr = .15,
    this.retestLookaheadBars = 10,
    this.maximumPatterns = 24,
  });

  final double dojiMaximumBodyFraction;
  final double pinBarMinimumWickToBody;
  final double engulfingMinimumBodyAtr;
  final double retestToleranceAtr;
  final int retestLookaheadBars;
  final int maximumPatterns;
}

class PriceActionEngine {
  const PriceActionEngine({this.config = const PriceActionConfig()});

  final PriceActionConfig config;

  List<PriceActionPattern> detect(
    List<Candle> candles,
    List<double?> atr,
    List<StructureBreak> structureBreaks,
  ) {
    final result = <PriceActionPattern>[];
    for (var index = 1; index < candles.length; index++) {
      final previous = candles[index - 1];
      final current = candles[index];
      final range = current.high - current.low;
      if (range <= 0) continue;
      final body = (current.close - current.open).abs();
      final averageRange = _atrAt(atr, index);
      final lowConfidence = averageRange <= 0 || body < averageRange * .1;

      final bullishEngulfing =
          previous.close < previous.open &&
          current.close > current.open &&
          current.open <= previous.close &&
          current.close >= previous.open;
      final bearishEngulfing =
          previous.close > previous.open &&
          current.close < current.open &&
          current.open >= previous.close &&
          current.close <= previous.open;
      if ((bullishEngulfing || bearishEngulfing) &&
          (averageRange <= 0 ||
              body >= averageRange * config.engulfingMinimumBodyAtr)) {
        result.add(
          _pattern(
            candles,
            index,
            bullishEngulfing
                ? PriceActionPatternType.bullishEngulfing
                : PriceActionPatternType.bearishEngulfing,
            bullishEngulfing
                ? MarketDirection.bullish
                : MarketDirection.bearish,
            bullishEngulfing ? current.low : current.high,
            'Current real body engulfs the previous opposing body',
            lowConfidence,
          ),
        );
      }

      final upperWick = current.high - math.max(current.open, current.close);
      final lowerWick = math.min(current.open, current.close) - current.low;
      final safeBody = math.max(body, range * .02);
      if (lowerWick / safeBody >= config.pinBarMinimumWickToBody &&
          upperWick <= lowerWick * .5) {
        result.add(
          _pattern(
            candles,
            index,
            PriceActionPatternType.bullishPinBar,
            MarketDirection.bullish,
            current.low,
            'Long lower rejection wick',
            lowConfidence,
          ),
        );
      } else if (upperWick / safeBody >= config.pinBarMinimumWickToBody &&
          lowerWick <= upperWick * .5) {
        result.add(
          _pattern(
            candles,
            index,
            PriceActionPatternType.bearishPinBar,
            MarketDirection.bearish,
            current.high,
            'Long upper rejection wick',
            lowConfidence,
          ),
        );
      }
      if (current.high < previous.high && current.low > previous.low) {
        result.add(
          _pattern(
            candles,
            index,
            PriceActionPatternType.insideBar,
            null,
            current.close,
            'Range is contained by the previous candle',
            lowConfidence,
          ),
        );
      }
      if (body / range <= config.dojiMaximumBodyFraction) {
        result.add(
          _pattern(
            candles,
            index,
            PriceActionPatternType.doji,
            null,
            current.close,
            'Open and close are close relative to the candle range',
            lowConfidence,
          ),
        );
      }
    }

    for (final marketBreak in structureBreaks) {
      final bullish = marketBreak.direction == MarketDirection.bullish;
      result.add(
        _pattern(
          candles,
          marketBreak.breakCandleIndex,
          bullish
              ? PriceActionPatternType.bullishBreakout
              : PriceActionPatternType.bearishBreakout,
          marketBreak.direction,
          marketBreak.level,
          'Candle close confirmed a market-structure breakout',
          false,
        ),
      );
      final breakAtr = _atrAt(atr, marketBreak.breakCandleIndex);
      final end = math.min(
        candles.length,
        marketBreak.breakCandleIndex + config.retestLookaheadBars + 1,
      );
      for (var index = marketBreak.breakCandleIndex + 1; index < end; index++) {
        final candle = candles[index];
        final tolerance = breakAtr * config.retestToleranceAtr;
        final touched =
            candle.low <= marketBreak.level + tolerance &&
            candle.high >= marketBreak.level - tolerance;
        final held = bullish
            ? candle.close >= marketBreak.level
            : candle.close <= marketBreak.level;
        if (!touched || !held) continue;
        result.add(
          _pattern(
            candles,
            index,
            bullish
                ? PriceActionPatternType.bullishRetest
                : PriceActionPatternType.bearishRetest,
            marketBreak.direction,
            marketBreak.level,
            'Broken structure level was retested and held',
            false,
          ),
        );
        result.add(
          _pattern(
            candles,
            index,
            PriceActionPatternType.supportResistanceFlip,
            marketBreak.direction,
            marketBreak.level,
            'The broken level changed support/resistance role',
            false,
          ),
        );
        break;
      }
    }
    result.sort((a, b) => a.candleIndex.compareTo(b.candleIndex));
    return List.unmodifiable(
      result.length <= config.maximumPatterns
          ? result
          : result.sublist(result.length - config.maximumPatterns),
    );
  }

  PriceActionPattern _pattern(
    List<Candle> candles,
    int index,
    PriceActionPatternType type,
    MarketDirection? direction,
    double level,
    String reason,
    bool lowConfidence,
  ) => PriceActionPattern(
    id: 'price-action-${type.name}-$index',
    type: type,
    direction: direction,
    candleIndex: index,
    occurredAtUtc: candles[index].time.toUtc(),
    level: level,
    reason: reason,
    lowConfidence: lowConfidence,
  );

  double _atrAt(List<double?> atr, int index) {
    if (atr.isEmpty) return 0;
    for (var cursor = index.clamp(0, atr.length - 1); cursor >= 0; cursor--) {
      final value = atr[cursor];
      if (value != null && value > 0) return value;
    }
    return 0;
  }
}
