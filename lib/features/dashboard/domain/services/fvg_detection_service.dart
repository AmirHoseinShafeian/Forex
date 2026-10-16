import '../market_models.dart';
import '../price_action_models.dart';

class FvgDetectionConfig {
  const FvgDetectionConfig({
    this.minimumSizeAtr = .15,
    this.maximumZones = 8,
    this.keepFilledZones = true,
  });

  final double minimumSizeAtr;
  final int maximumZones;
  final bool keepFilledZones;
}

class FvgDetectionService {
  const FvgDetectionService({this.config = const FvgDetectionConfig()});

  final FvgDetectionConfig config;

  List<FairValueGap> detect(List<Candle> candles, List<double?> atr) {
    final gaps = <FairValueGap>[];
    for (var index = 2; index < candles.length; index++) {
      final first = candles[index - 2];
      final third = candles[index];
      final averageRange = _atrAt(atr, index);
      if (averageRange <= 0) continue;
      MarketDirection? direction;
      late double lower;
      late double upper;
      if (third.low > first.high) {
        direction = MarketDirection.bullish;
        lower = first.high;
        upper = third.low;
      } else if (third.high < first.low) {
        direction = MarketDirection.bearish;
        lower = third.high;
        upper = first.low;
      }
      if (direction == null ||
          upper - lower < averageRange * config.minimumSizeAtr) {
        continue;
      }
      var status = FairValueGapStatus.unfilled;
      for (var cursor = index + 1; cursor < candles.length; cursor++) {
        final candle = candles[cursor];
        if (direction == MarketDirection.bullish) {
          if (candle.low <= lower) {
            status = FairValueGapStatus.filled;
            break;
          }
          if (candle.low < upper) status = FairValueGapStatus.partiallyFilled;
        } else {
          if (candle.high >= upper) {
            status = FairValueGapStatus.filled;
            break;
          }
          if (candle.high > lower) status = FairValueGapStatus.partiallyFilled;
        }
      }
      if (!config.keepFilledZones && status == FairValueGapStatus.filled) {
        continue;
      }
      gaps.add(
        FairValueGap(
          id: 'fvg-${direction.name}-$index',
          direction: direction,
          lower: lower,
          upper: upper,
          candleIndex: index,
          formedAtUtc: third.time.toUtc(),
          status: status,
        ),
      );
    }
    return List.unmodifiable(
      gaps.length <= config.maximumZones
          ? gaps
          : gaps.sublist(gaps.length - config.maximumZones),
    );
  }

  double _atrAt(List<double?> atr, int index) {
    if (atr.isEmpty) return 0;
    for (var cursor = index.clamp(0, atr.length - 1); cursor >= 0; cursor--) {
      final value = atr[cursor];
      if (value != null && value > 0) return value;
    }
    return 0;
  }
}
