import '../harmonic_models.dart';
import '../market_models.dart';
import '../price_action_models.dart';

class LiquidityAnalysisConfig {
  const LiquidityAnalysisConfig({
    this.equalLevelToleranceAtr = .15,
    this.minimumSweepAtr = .05,
    this.requireConfirmationCandle = true,
    this.maximumSweeps = 8,
  });

  final double equalLevelToleranceAtr;
  final double minimumSweepAtr;
  final bool requireConfirmationCandle;
  final int maximumSweeps;
}

/// Liquidity sweeps describe probable price behaviour around equal levels;
/// they are not order-book or institutional-position data.
class LiquidityAnalysisService {
  const LiquidityAnalysisService({
    this.config = const LiquidityAnalysisConfig(),
  });

  final LiquidityAnalysisConfig config;

  List<LiquiditySweep> detect(
    List<Candle> candles,
    List<SwingPoint> swings,
    List<double?> atr,
  ) {
    final result = <LiquiditySweep>[];
    SwingPoint? previousHigh;
    SwingPoint? previousLow;
    for (final swing in swings) {
      final previous = swing.type == SwingType.high
          ? previousHigh
          : previousLow;
      if (previous != null) {
        final averageRange = _atrAt(atr, swing.confirmedAtIndex);
        if (averageRange > 0 &&
            (swing.price - previous.price).abs() <=
                averageRange * config.equalLevelToleranceAtr) {
          final level = (swing.price + previous.price) / 2;
          for (
            var index = swing.confirmedAtIndex + 1;
            index < candles.length;
            index++
          ) {
            final candle = candles[index];
            final isHigh = swing.type == SwingType.high;
            final crossed = isHigh
                ? candle.high > level + averageRange * config.minimumSweepAtr
                : candle.low < level - averageRange * config.minimumSweepAtr;
            if (!crossed) continue;
            final returned = isHigh
                ? candle.close < level
                : candle.close > level;
            if (config.requireConfirmationCandle && !returned) break;
            if (!returned) break; // A close beyond the level is a breakout.
            result.add(
              LiquiditySweep(
                id: 'liquidity-${swing.type.name}-$index',
                type: isHigh ? LiquidityType.equalHigh : LiquidityType.equalLow,
                direction: isHigh
                    ? MarketDirection.bearish
                    : MarketDirection.bullish,
                level: level,
                referenceCandleIndex: swing.candleIndex,
                sweepCandleIndex: index,
                occurredAtUtc: candle.time.toUtc(),
                confirmedAtUtc: candle.time.toUtc(),
              ),
            );
            break;
          }
        }
      }
      if (swing.type == SwingType.high) {
        previousHigh = swing;
      } else {
        previousLow = swing;
      }
    }
    return List.unmodifiable(
      result.length <= config.maximumSweeps
          ? result
          : result.sublist(result.length - config.maximumSweeps),
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
