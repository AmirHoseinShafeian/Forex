import 'package:flutter_test/flutter_test.dart';
import 'package:forex/features/dashboard/domain/analysis_models.dart';
import 'package:forex/features/dashboard/domain/market_models.dart';
import 'package:forex/features/dashboard/domain/services/indicator_engine.dart';
import 'package:forex/features/dashboard/domain/services/support_resistance_service.dart';
import 'package:forex/features/dashboard/domain/services/trend_analysis_service.dart';

void main() {
  group('TrendAnalysisService', () {
    final engine = IndicatorEngine();
    const service = TrendAnalysisService();

    test('detects bullish and bearish trends', () {
      final rising = _linearCandles(260);
      final falling = _linearCandles(260, descending: true);

      expect(
        service.analyze(rising, engine.calculate('up', rising)).direction,
        TrendDirection.bullish,
      );
      expect(
        service.analyze(falling, engine.calculate('down', falling)).direction,
        TrendDirection.bearish,
      );
    });

    test('detects sideways data and reports short data as unknown', () {
      final flat = _flatCandles(260);
      final short = _linearCandles(30);

      expect(
        service.analyze(flat, engine.calculate('flat', flat)).direction,
        TrendDirection.sideways,
      );
      expect(
        service.analyze(short, engine.calculate('short', short)).direction,
        TrendDirection.unknown,
      );
    });
  });

  group('SupportResistanceService', () {
    test('clusters repeated levels instead of returning duplicates', () {
      const service = SupportResistanceService(
        config: SupportResistanceConfig(
          leftBars: 1,
          rightBars: 1,
          minimumTouches: 2,
          clusterToleranceFraction: .01,
        ),
      );
      final candles = _candlesFromHighs([1, 3, 1, 3.01, 1, 2.99, 1]);

      final resistance = service
          .detect(candles)
          .where((zone) => zone.type == PriceZoneType.resistance)
          .toList();

      expect(resistance, hasLength(1));
      expect(resistance.single.touches, 3);
    });

    test('does not expose a swing before its right-side confirmation', () {
      const service = SupportResistanceService(
        config: SupportResistanceConfig(
          leftBars: 1,
          rightBars: 2,
          minimumTouches: 1,
        ),
      );
      final candles = _candlesFromHighs([1, 2, 5, 3, 2]);

      final early = service.detect(candles.take(4).toList());
      final confirmed = service.detect(candles);

      expect(
        early.where((zone) => zone.type == PriceZoneType.resistance),
        isEmpty,
      );
      expect(
        confirmed.where((zone) => zone.type == PriceZoneType.resistance),
        hasLength(1),
      );
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
        volume: 100,
      );
    });

List<Candle> _flatCandles(int count) => List.generate(count, (index) {
  const close = 100.0;
  return Candle(
    time: DateTime.utc(2025, 1, 1).add(Duration(minutes: index)),
    open: close,
    high: close + 1,
    low: close - 1,
    close: close,
    volume: 100,
  );
});

List<Candle> _candlesFromHighs(List<double> highs) =>
    List.generate(highs.length, (index) {
      final high = highs[index];
      return Candle(
        time: DateTime.utc(2025, 1, 1).add(Duration(minutes: index)),
        open: high - .5,
        high: high,
        low: 0,
        close: high - .25,
        volume: 100,
      );
    });
