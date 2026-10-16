import 'package:flutter_test/flutter_test.dart';
import 'package:forex/features/dashboard/domain/market_models.dart';
import 'package:forex/features/dashboard/domain/services/indicator_engine.dart';

void main() {
  group('IndicatorEngine', () {
    test('matches reference values for a steadily rising series', () {
      final candles = _linearCandles(260);
      final result = IndicatorEngine().calculate('M15', candles);

      expect(result.latestEma20, closeTo(250.5, 1e-9));
      expect(result.latestEma50, closeTo(235.5, 1e-9));
      expect(result.latestEma200, closeTo(160.5, 1e-9));
      expect(result.latestRsi, closeTo(100, 1e-9));
      expect(result.latestMacd, closeTo(7, 1e-9));
      expect(result.latestMacdSignal, closeTo(7, 1e-9));
      expect(result.latestMacdHistogram, closeTo(0, 1e-9));
      expect(result.latestAtr, closeTo(2, 1e-9));
      expect(result.latestAdx, closeTo(100, 1e-9));
      expect(result.latestAverageVolume, closeTo(250.5, 1e-9));
    });

    test('returns null for periods without enough data', () {
      final result = IndicatorEngine().calculate('M1', _linearCandles(10));

      expect(result.latestEma20, isNull);
      expect(result.latestEma50, isNull);
      expect(result.latestEma200, isNull);
      expect(result.latestRsi, isNull);
      expect(result.latestMacd, isNull);
      expect(result.latestAdx, isNull);
      expect(result.latestAtr, isNull);
      expect(result.latestAverageVolume, isNull);
    });

    test('keeps every indicator aligned to candle time', () {
      final result = IndicatorEngine().calculate('H1', _linearCandles(260));
      final lengths = [
        result.ema20.length,
        result.ema50.length,
        result.ema200.length,
        result.rsi14.length,
        result.macd.length,
        result.macdSignal.length,
        result.macdHistogram.length,
        result.adx14.length,
        result.atr14.length,
        result.averageVolume20.length,
      ];

      expect(lengths, everyElement(result.candles.length));
    });

    test('recalculates only the last point when current candle changes', () {
      final engine = IndicatorEngine();
      final candles = _linearCandles(260);
      engine.calculate('M5', candles);
      final last = candles.last;
      final updated = [
        ...candles.take(candles.length - 1),
        Candle(
          time: last.time,
          open: last.open,
          high: last.high + 1,
          low: last.low,
          close: last.close + .5,
          volume: last.volume + 1,
        ),
      ];

      engine.calculate('M5', updated);

      expect(engine.fullRecalculationCount, 1);
      expect(engine.incrementalUpdateCount, 1);
    });
  });
}

List<Candle> _linearCandles(int count, {bool descending = false}) =>
    List.generate(count, (index) {
      final close = descending ? (count - index).toDouble() : index + 1.0;
      return Candle(
        time: DateTime.utc(2025, 1, 1).add(Duration(minutes: index)),
        open: close - .5,
        high: close + 1,
        low: close - 1,
        close: close,
        volume: index + 1,
      );
    });
