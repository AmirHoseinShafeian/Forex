import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forex/features/dashboard/domain/harmonic_models.dart';
import 'package:forex/features/dashboard/domain/market_models.dart';
import 'package:forex/features/dashboard/domain/services/fibonacci_analysis_service.dart';
import 'package:forex/features/dashboard/domain/services/harmonic_pattern_engine.dart';
import 'package:forex/features/dashboard/domain/services/swing_detection_service.dart';
import 'package:forex/features/dashboard/presentation/widgets/market_chart.dart';

void main() {
  group('HarmonicPatternEngine', () {
    const engine = HarmonicPatternEngine();

    test('detects configured standard harmonic samples', () {
      final samples = <HarmonicPatternType, List<double>>{
        HarmonicPatternType.gartley: [0, 100, 38.2, 69.1, 21.4],
        HarmonicPatternType.bat: [0, 100, 50, 75, 11.4],
        HarmonicPatternType.butterfly: [0, 100, 21.4, 60.7, -27],
        HarmonicPatternType.crab: [0, 100, 50, 94.3, -61.8],
        HarmonicPatternType.deepCrab: [0, 100, 11.4, 89.9, -61.8],
      };

      for (final sample in samples.entries) {
        final result = engine.detect(_swings(sample.value), 'M15');
        expect(
          result.any(
            (pattern) =>
                pattern.type == sample.key &&
                pattern.status == HarmonicPatternStatus.completed,
          ),
          isTrue,
          reason: sample.key.name,
        );
      }
    });

    test('detects Cypher, Shark and AB=CD with their own structures', () {
      final cypher = engine.detect(_swings([0, 100, 50, 130, 27.82]), 'M5');
      final shark = engine.detect(_swings([0, 100, 20, 140, -90]), 'H1');
      final abcd = engine.detect(
        _swings([100, 0, 61.8, -38.2], firstType: SwingType.high),
        'H4',
      );

      expect(cypher.any((p) => p.type == HarmonicPatternType.cypher), isTrue);
      expect(shark.any((p) => p.type == HarmonicPatternType.shark), isTrue);
      expect(abcd.any((p) => p.type == HarmonicPatternType.abcd), isTrue);
      expect(cypher.first.timeframe, 'M5');
    });

    test('rejects invalid ratios and removes duplicate identities', () {
      final invalid = engine.detect(_swings([0, 100, 5, 98, 4]), 'M30');
      final valid = engine.detect(_swings([0, 100, 38.2, 69.1, 21.4]), 'M30');

      expect(
        invalid.where((p) => p.status == HarmonicPatternStatus.completed),
        isEmpty,
      );
      expect(valid.map((p) => p.id).toSet().length, valid.length);
    });

    test('keeps point indices and does not mutate source candles', () {
      final candles = _pivotCandles();
      final before = List<Candle>.of(candles);
      const detector = SwingDetectionService(
        config: SwingDetectionConfig(leftBars: 1, rightBars: 1),
      );
      final swings = detector.detect(candles);

      expect(candles, orderedEquals(before));
      expect(
        swings.every(
          (point) => point.timeUtc == candles[point.candleIndex].time,
        ),
        isTrue,
      );
    });
  });

  test('swing is unavailable until right-side confirmation exists', () {
    const service = SwingDetectionService(
      config: SwingDetectionConfig(leftBars: 1, rightBars: 2),
    );
    final candles = _peakCandles([1, 2, 5, 3, 2]);

    expect(service.detect(candles.take(4).toList()), isEmpty);
    final confirmed = service.detect(candles);
    expect(confirmed.single.candleIndex, 2);
    expect(confirmed.single.confirmedAtIndex, 4);
  });

  test('calculates retracement, extension and overlay coordinates', () {
    const service = FibonacciAnalysisService();
    final swings = _swings([100, 200], firstType: SwingType.low);
    final analysis = service.analyze(swings)!;
    final level618 = analysis.levels.firstWhere((level) => level.ratio == .618);
    final extension = analysis.levels.firstWhere(
      (level) => level.ratio == 1.618,
    );

    expect(level618.price, closeTo(138.2, 1e-9));
    expect(extension.price, closeTo(261.8, 1e-9));
    final mapper = ChartOverlayMapper(
      size: const Size(158, 122),
      candleCount: 11,
      minY: 0,
      maxY: 100,
      transform: Matrix4.identity(),
    );
    expect(mapper.map(5, 50), const Offset(50, 50));
  });
}

List<SwingPoint> _swings(
  List<double> prices, {
  SwingType firstType = SwingType.low,
}) => List.generate(prices.length, (index) {
  final type = index.isEven
      ? firstType
      : firstType == SwingType.low
      ? SwingType.high
      : SwingType.low;
  final time = DateTime.utc(2025, 1, 1).add(Duration(minutes: index * 2));
  return SwingPoint(
    type: type,
    candleIndex: index * 2,
    price: prices[index],
    timeUtc: time,
    confirmedAtUtc: time.add(const Duration(minutes: 1)),
    confirmedAtIndex: index * 2 + 1,
  );
});

List<Candle> _peakCandles(List<double> highs) =>
    List.generate(highs.length, (index) {
      final high = highs[index];
      return Candle(
        time: DateTime.utc(2025, 1, 1).add(Duration(minutes: index)),
        open: high - .4,
        high: high,
        low: high - 1,
        close: high - .2,
        volume: 100,
      );
    });

List<Candle> _pivotCandles() => _peakCandles([1, 4, 2, 5, 1, 3, 2]);
