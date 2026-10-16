import 'dart:math' as math;

import '../harmonic_models.dart';

class FibonacciAnalysisService {
  const FibonacciAnalysisService({this.confluenceToleranceFraction = .0015});

  final double confluenceToleranceFraction;

  FibonacciAnalysis? analyze(
    List<SwingPoint> swings, {
    List<HarmonicPattern> patterns = const [],
  }) {
    if (swings.length < 2) return null;
    final start = swings[swings.length - 2];
    final end = swings.last;
    final range = (end.price - start.price).abs();
    if (range == 0) return null;
    const ratios = [.382, .5, .618, .786, 1.0, 1.272, 1.618];
    final rising = end.price > start.price;
    final levels = ratios
        .map((ratio) {
          final retracement = ratio <= 1;
          final price = retracement
              ? (rising ? end.price - range * ratio : end.price + range * ratio)
              : (rising
                    ? start.price + range * ratio
                    : start.price - range * ratio);
          return FibonacciLevel(
            ratio: ratio,
            price: price,
            kind: retracement
                ? FibonacciLevelKind.retracement
                : FibonacciLevelKind.extension,
          );
        })
        .toList(growable: false);
    final prices = <double>[
      ...levels.map((level) => level.price),
      ...patterns.expand((pattern) => [pattern.przLower, pattern.przUpper]),
    ]..sort();
    final zones = <FibonacciConfluenceZone>[];
    for (var index = 0; index < prices.length - 1; index++) {
      final tolerance = prices[index].abs() * confluenceToleranceFraction;
      var endIndex = index;
      while (endIndex + 1 < prices.length &&
          prices[endIndex + 1] - prices[index] <= tolerance) {
        endIndex++;
      }
      if (endIndex > index) {
        zones.add(
          FibonacciConfluenceZone(
            lower: prices[index],
            upper: prices[endIndex],
            levelCount: endIndex - index + 1,
          ),
        );
        index = endIndex;
      }
    }
    return FibonacciAnalysis(
      start: start,
      end: end,
      levels: levels,
      confluenceZones: zones,
    );
  }

  ({double lower, double upper}) prz(double projectedPrice, double legSize) {
    final padding = math.max(legSize.abs() * .02, projectedPrice.abs() * .0002);
    return (lower: projectedPrice - padding, upper: projectedPrice + padding);
  }
}
