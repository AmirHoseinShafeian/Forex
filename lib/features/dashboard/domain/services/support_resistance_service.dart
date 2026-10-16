import 'dart:math' as math;

import '../analysis_models.dart';
import '../market_models.dart';

class SupportResistanceConfig {
  const SupportResistanceConfig({
    this.leftBars = 3,
    this.rightBars = 3,
    this.clusterToleranceFraction = .001,
    this.minimumTouches = 2,
    this.maximumZones = 8,
    this.zonePaddingFraction = .00025,
  });

  final int leftBars;
  final int rightBars;
  final double clusterToleranceFraction;
  final int minimumTouches;
  final int maximumZones;
  final double zonePaddingFraction;
}

class SupportResistanceService {
  const SupportResistanceService({
    this.config = const SupportResistanceConfig(),
  });

  final SupportResistanceConfig config;

  List<PriceZone> detect(List<Candle> input) {
    final candles = List<Candle>.of(input)
      ..sort((a, b) => a.time.compareTo(b.time));
    final candidates = <_LevelCandidate>[];

    for (var current = 0; current < candles.length; current++) {
      final candidate = current - config.rightBars;
      if (candidate < config.leftBars) continue;
      final start = candidate - config.leftBars;
      final end = candidate + config.rightBars;
      final high = candles[candidate].high;
      final low = candles[candidate].low;
      var swingHigh = true;
      var swingLow = true;
      for (var index = start; index <= end; index++) {
        if (index == candidate) continue;
        if (candles[index].high >= high) swingHigh = false;
        if (candles[index].low <= low) swingLow = false;
      }
      if (swingHigh) {
        candidates.add(
          _LevelCandidate(PriceZoneType.resistance, high, candidate),
        );
      }
      if (swingLow) {
        candidates.add(_LevelCandidate(PriceZoneType.support, low, candidate));
      }
    }

    final clusters = <_ZoneCluster>[];
    for (final candidate in candidates) {
      final tolerance = candidate.price.abs() * config.clusterToleranceFraction;
      final match = clusters.cast<_ZoneCluster?>().firstWhere(
        (zone) =>
            zone!.type == candidate.type &&
            (zone.midpoint - candidate.price).abs() <= tolerance,
        orElse: () => null,
      );
      if (match == null) {
        clusters.add(_ZoneCluster(candidate));
      } else {
        match.add(candidate);
      }
    }

    final zones =
        clusters.where((zone) => zone.touches >= config.minimumTouches).map((
          zone,
        ) {
          final padding = zone.midpoint.abs() * config.zonePaddingFraction;
          return PriceZone(
            type: zone.type,
            lower: zone.minimum - padding,
            upper: zone.maximum + padding,
            touches: zone.touches,
            lastTouchIndex: zone.lastTouchIndex,
          );
        }).toList()..sort((a, b) {
          final touches = b.touches.compareTo(a.touches);
          return touches != 0
              ? touches
              : b.lastTouchIndex.compareTo(a.lastTouchIndex);
        });
    return zones.take(config.maximumZones).toList(growable: false);
  }
}

class _LevelCandidate {
  const _LevelCandidate(this.type, this.price, this.index);
  final PriceZoneType type;
  final double price;
  final int index;
}

class _ZoneCluster {
  _ZoneCluster(_LevelCandidate candidate)
    : type = candidate.type,
      minimum = candidate.price,
      maximum = candidate.price,
      touches = 1,
      lastTouchIndex = candidate.index;

  final PriceZoneType type;
  double minimum;
  double maximum;
  int touches;
  int lastTouchIndex;

  double get midpoint => (minimum + maximum) / 2;

  void add(_LevelCandidate candidate) {
    minimum = math.min(minimum, candidate.price);
    maximum = math.max(maximum, candidate.price);
    touches++;
    lastTouchIndex = math.max(lastTouchIndex, candidate.index);
  }
}
