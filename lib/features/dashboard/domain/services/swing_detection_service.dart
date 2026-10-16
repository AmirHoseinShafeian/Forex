import 'dart:math' as math;

import '../harmonic_models.dart';
import '../market_models.dart';

class SwingDetectionConfig {
  const SwingDetectionConfig({
    this.leftBars = 3,
    this.rightBars = 3,
    this.minimumMoveFraction = .0005,
    this.minimumAtrMultiple = .2,
    this.atrPeriod = 14,
  });

  final int leftBars;
  final int rightBars;
  final double minimumMoveFraction;
  final double minimumAtrMultiple;
  final int atrPeriod;
}

class SwingDetectionService {
  const SwingDetectionService({this.config = const SwingDetectionConfig()});

  final SwingDetectionConfig config;

  List<List<SwingPoint>> detectMultiScale(
    List<Candle> input,
    String timeframe,
  ) {
    final center = switch (timeframe) {
      'M1' => 2,
      'M5' => 3,
      'M15' => 4,
      'M30' => 5,
      'H1' => 6,
      'H4' => 8,
      'D1' => 10,
      _ => config.leftBars,
    };
    final minimumMoveFraction = switch (timeframe) {
      'M1' => .00010,
      'M5' => .00020,
      'M15' => .00030,
      'M30' => .00040,
      'H1' => .00050,
      'H4' => .00070,
      'D1' => .00100,
      _ => config.minimumMoveFraction,
    };
    final atrMultiple = switch (timeframe) {
      'M1' => .12,
      'M5' => .16,
      'M15' => .20,
      'M30' => .22,
      'H1' => .25,
      'H4' => .30,
      'D1' => .35,
      _ => config.minimumAtrMultiple,
    };
    final windows = <int>{math.max(2, center - 2), center, center + 2};
    return List.unmodifiable(
      windows
          .map(
            (window) => SwingDetectionService(
              config: SwingDetectionConfig(
                leftBars: window,
                rightBars: window,
                minimumMoveFraction: minimumMoveFraction,
                minimumAtrMultiple: atrMultiple,
                atrPeriod: config.atrPeriod,
              ),
            ).detect(input),
          )
          .where((points) => points.isNotEmpty),
    );
  }

  List<SwingPoint> detect(List<Candle> input) {
    final candles = List<Candle>.of(input)
      ..sort((a, b) => a.time.compareTo(b.time));
    final result = <SwingPoint>[];
    for (
      var candidate = config.leftBars;
      candidate + config.rightBars < candles.length;
      candidate++
    ) {
      final candle = candles[candidate];
      var isHigh = true;
      var isLow = true;
      for (
        var index = candidate - config.leftBars;
        index <= candidate + config.rightBars;
        index++
      ) {
        if (index == candidate) continue;
        if (candles[index].high >= candle.high) isHigh = false;
        if (candles[index].low <= candle.low) isLow = false;
      }
      if (isHigh) _add(result, candles, candidate, SwingType.high, candle.high);
      if (isLow) _add(result, candles, candidate, SwingType.low, candle.low);
    }
    return List.unmodifiable(result);
  }

  void _add(
    List<SwingPoint> points,
    List<Candle> candles,
    int index,
    SwingType type,
    double price,
  ) {
    final point = SwingPoint(
      type: type,
      candleIndex: index,
      price: price,
      timeUtc: candles[index].time.toUtc(),
      confirmedAtUtc: candles[index + config.rightBars].time.toUtc(),
      confirmedAtIndex: index + config.rightBars,
    );
    if (points.isNotEmpty && points.last.type == type) {
      final previous = points.last;
      final isMoreExtreme = type == SwingType.high
          ? price > previous.price
          : price < previous.price;
      if (isMoreExtreme) points[points.length - 1] = point;
      return;
    }
    if (points.isNotEmpty) {
      final move = (price - points.last.price).abs();
      final fractionThreshold =
          points.last.price.abs() * config.minimumMoveFraction;
      final atrThreshold = _atrAt(candles, index) * config.minimumAtrMultiple;
      final threshold = math.max(fractionThreshold, atrThreshold);
      if (move < threshold) return;
    }
    points.add(point);
  }

  double _atrAt(List<Candle> candles, int endIndex) {
    if (endIndex <= 0) return 0;
    final start = math.max(1, endIndex - config.atrPeriod + 1);
    var total = 0.0;
    var count = 0;
    for (var index = start; index <= endIndex; index++) {
      final candle = candles[index];
      final previousClose = candles[index - 1].close;
      total += math.max(
        candle.high - candle.low,
        math.max(
          (candle.high - previousClose).abs(),
          (candle.low - previousClose).abs(),
        ),
      );
      count++;
    }
    return count == 0 ? 0 : total / count;
  }
}
