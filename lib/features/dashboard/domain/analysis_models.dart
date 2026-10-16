import 'market_models.dart';

enum IndicatorLayer {
  ema20,
  ema50,
  ema200,
  rsi,
  macd,
  adx,
  volume,
  supportResistance,
  harmonicPatterns,
  fibonacci,
  marketStructure,
  orderBlocks,
  fairValueGaps,
  liquiditySweeps,
  priceAction,
  tradingSetup,
}

class IndicatorSnapshot {
  const IndicatorSnapshot({
    required this.candles,
    required this.ema20,
    required this.ema50,
    required this.ema200,
    required this.rsi14,
    required this.macd,
    required this.macdSignal,
    required this.macdHistogram,
    required this.adx14,
    required this.atr14,
    required this.averageVolume20,
  });

  final List<Candle> candles;
  final List<double?> ema20;
  final List<double?> ema50;
  final List<double?> ema200;
  final List<double?> rsi14;
  final List<double?> macd;
  final List<double?> macdSignal;
  final List<double?> macdHistogram;
  final List<double?> adx14;
  final List<double?> atr14;
  final List<double?> averageVolume20;

  int? get tickVolume => candles.isEmpty ? null : candles.last.volume;
  double? get latestEma20 => _latest(ema20);
  double? get latestEma50 => _latest(ema50);
  double? get latestEma200 => _latest(ema200);
  double? get latestRsi => _latest(rsi14);
  double? get latestMacd => _latest(macd);
  double? get latestMacdSignal => _latest(macdSignal);
  double? get latestMacdHistogram => _latest(macdHistogram);
  double? get latestAdx => _latest(adx14);
  double? get latestAtr => _latest(atr14);
  double? get latestAverageVolume => _latest(averageVolume20);

  static double? _latest(List<double?> values) {
    for (var index = values.length - 1; index >= 0; index--) {
      if (values[index] != null) return values[index];
    }
    return null;
  }
}

enum TrendDirection { bullish, bearish, sideways, unknown }

enum TrendStrength { weak, moderate, strong, unknown }

class TrendAnalysis {
  const TrendAnalysis({
    required this.direction,
    required this.strength,
    required this.reasons,
  });

  const TrendAnalysis.unknown()
    : direction = TrendDirection.unknown,
      strength = TrendStrength.unknown,
      reasons = const ['داده کافی نیست'];

  final TrendDirection direction;
  final TrendStrength strength;
  final List<String> reasons;
}

enum PriceZoneType { support, resistance }

class PriceZone {
  const PriceZone({
    required this.type,
    required this.lower,
    required this.upper,
    required this.touches,
    required this.lastTouchIndex,
  });

  final PriceZoneType type;
  final double lower;
  final double upper;
  final int touches;
  final int lastTouchIndex;

  double get midpoint => (lower + upper) / 2;
}
