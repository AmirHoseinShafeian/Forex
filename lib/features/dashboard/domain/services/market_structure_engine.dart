import '../harmonic_models.dart';
import '../market_models.dart';
import '../price_action_models.dart';

/// A break is confirmed when price exceeds the latest confirmed swing by the
/// ATR buffer. In close-confirmation mode only the candle close can break it.
/// A break against the established HH/HL or LH/LL trend is CHoCH; a break in
/// the same direction (or before a trend exists) is BOS.
class MarketStructureConfig {
  const MarketStructureConfig({
    this.confirmByClose = true,
    this.minimumBreakAtr = .1,
    this.maximumBreaks = 16,
  });

  final bool confirmByClose;
  final double minimumBreakAtr;
  final int maximumBreaks;
}

class MarketStructureEngine {
  const MarketStructureEngine({this.config = const MarketStructureConfig()});

  final MarketStructureConfig config;

  ({List<StructurePoint> points, List<StructureBreak> breaks}) analyze(
    List<Candle> candles,
    List<SwingPoint> swings,
    List<double?> atr,
  ) {
    if (candles.isEmpty || swings.isEmpty) {
      return (points: const [], breaks: const []);
    }
    final points = _classify(swings);
    final breaks = <StructureBreak>[];
    final brokenSwings = <String>{};
    StructurePoint? latestHigh;
    StructurePoint? latestLow;
    MarketDirection? trend;
    var pointCursor = 0;

    for (var index = 0; index < candles.length; index++) {
      while (pointCursor < points.length &&
          points[pointCursor].confirmedAtIndex <= index) {
        final point = points[pointCursor++];
        if (point.type == StructurePointType.higherHigh ||
            point.type == StructurePointType.lowerHigh) {
          latestHigh = point;
        } else {
          latestLow = point;
        }
        if (point.type == StructurePointType.higherHigh &&
            latestLow?.type == StructurePointType.higherLow) {
          trend = MarketDirection.bullish;
        } else if (point.type == StructurePointType.lowerLow &&
            latestHigh?.type == StructurePointType.lowerHigh) {
          trend = MarketDirection.bearish;
        }
      }

      final candle = candles[index];
      final buffer = (index < atr.length ? atr[index] : null) ?? 0;
      if (latestHigh != null &&
          index > latestHigh.confirmedAtIndex &&
          !brokenSwings.contains(latestHigh.id)) {
        final value = config.confirmByClose ? candle.close : candle.high;
        if (value > latestHigh.price + buffer * config.minimumBreakAtr) {
          breaks.add(
            _break(
              candles,
              index,
              latestHigh,
              MarketDirection.bullish,
              trend == MarketDirection.bearish,
            ),
          );
          brokenSwings.add(latestHigh.id);
          trend = MarketDirection.bullish;
        }
      }
      if (latestLow != null &&
          index > latestLow.confirmedAtIndex &&
          !brokenSwings.contains(latestLow.id)) {
        final value = config.confirmByClose ? candle.close : candle.low;
        if (value < latestLow.price - buffer * config.minimumBreakAtr) {
          breaks.add(
            _break(
              candles,
              index,
              latestLow,
              MarketDirection.bearish,
              trend == MarketDirection.bullish,
            ),
          );
          brokenSwings.add(latestLow.id);
          trend = MarketDirection.bearish;
        }
      }
    }
    final limited = breaks.length <= config.maximumBreaks
        ? breaks
        : breaks.sublist(breaks.length - config.maximumBreaks);
    return (
      points: List.unmodifiable(points),
      breaks: List.unmodifiable(limited),
    );
  }

  List<StructurePoint> _classify(List<SwingPoint> swings) {
    final result = <StructurePoint>[];
    SwingPoint? previousHigh;
    SwingPoint? previousLow;
    for (final swing in swings) {
      final previous = swing.type == SwingType.high
          ? previousHigh
          : previousLow;
      if (previous != null) {
        final type = swing.type == SwingType.high
            ? swing.price > previous.price
                  ? StructurePointType.higherHigh
                  : StructurePointType.lowerHigh
            : swing.price > previous.price
            ? StructurePointType.higherLow
            : StructurePointType.lowerLow;
        result.add(
          StructurePoint(
            id: 'structure-point-${swing.type.name}-${swing.candleIndex}',
            type: type,
            candleIndex: swing.candleIndex,
            confirmedAtIndex: swing.confirmedAtIndex,
            price: swing.price,
            occurredAtUtc: swing.timeUtc,
            confirmedAtUtc: swing.confirmedAtUtc,
          ),
        );
      }
      if (swing.type == SwingType.high) {
        previousHigh = swing;
      } else {
        previousLow = swing;
      }
    }
    return result;
  }

  StructureBreak _break(
    List<Candle> candles,
    int index,
    StructurePoint source,
    MarketDirection direction,
    bool isChangeOfCharacter,
  ) => StructureBreak(
    id: 'structure-break-${direction.name}-$index',
    type: isChangeOfCharacter
        ? StructureBreakType.changeOfCharacter
        : StructureBreakType.breakOfStructure,
    direction: direction,
    level: source.price,
    sourceCandleIndex: source.candleIndex,
    breakCandleIndex: index,
    occurredAtUtc: candles[index].time.toUtc(),
    confirmedAtUtc: candles[index].time.toUtc(),
    confirmedByClose: config.confirmByClose,
  );
}
