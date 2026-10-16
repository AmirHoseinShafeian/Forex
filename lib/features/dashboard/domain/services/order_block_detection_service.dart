import '../market_models.dart';
import '../price_action_models.dart';

class OrderBlockConfig {
  const OrderBlockConfig({
    this.lookbackBars = 8,
    this.minimumDisplacementAtr = 1.2,
    this.duplicateDistanceAtr = .25,
    this.maximumZones = 6,
  });

  final int lookbackBars;
  final double minimumDisplacementAtr;
  final double duplicateDistanceAtr;
  final int maximumZones;
}

/// Order blocks are inferred technical-analysis zones. They do not prove the
/// presence of institutional orders.
class OrderBlockDetectionService {
  const OrderBlockDetectionService({this.config = const OrderBlockConfig()});

  final OrderBlockConfig config;

  List<OrderBlockZone> detect(
    List<Candle> candles,
    List<StructureBreak> breaks,
    List<double?> atr,
  ) {
    final zones = <OrderBlockZone>[];
    for (final marketBreak in breaks) {
      final breakIndex = marketBreak.breakCandleIndex;
      final averageRange = _atrAt(atr, breakIndex);
      if (averageRange <= 0 || breakIndex <= 0) continue;
      int? origin;
      for (
        var index = breakIndex - 1;
        index >= 0 && index >= breakIndex - config.lookbackBars;
        index--
      ) {
        final candle = candles[index];
        final opposing = marketBreak.direction == MarketDirection.bullish
            ? candle.close < candle.open
            : candle.close > candle.open;
        if (opposing) {
          origin = index;
          break;
        }
      }
      if (origin == null) continue;
      final source = candles[origin];
      final displacement =
          (candles[breakIndex].close - source.close).abs() / averageRange;
      if (displacement < config.minimumDisplacementAtr) continue;
      var status = ZoneStatus.active;
      for (var index = breakIndex + 1; index < candles.length; index++) {
        final candle = candles[index];
        if (marketBreak.direction == MarketDirection.bullish) {
          if (candle.close < source.low) {
            status = ZoneStatus.invalidated;
            break;
          }
          if (candle.low <= source.high) status = ZoneStatus.mitigated;
        } else {
          if (candle.close > source.high) {
            status = ZoneStatus.invalidated;
            break;
          }
          if (candle.high >= source.low) status = ZoneStatus.mitigated;
        }
      }
      if (status == ZoneStatus.invalidated) continue;
      final center = (source.low + source.high) / 2;
      final duplicate = zones.any(
        (zone) =>
            zone.direction == marketBreak.direction &&
            ((zone.lower + zone.upper) / 2 - center).abs() <=
                averageRange * config.duplicateDistanceAtr,
      );
      if (duplicate) continue;
      zones.add(
        OrderBlockZone(
          id: 'order-block-${marketBreak.direction.name}-$origin',
          direction: marketBreak.direction,
          lower: source.low,
          upper: source.high,
          candleIndex: origin,
          formedAtUtc: source.time.toUtc(),
          status: status,
          breakId: marketBreak.id,
        ),
      );
    }
    zones.sort((a, b) => a.candleIndex.compareTo(b.candleIndex));
    return List.unmodifiable(
      zones.length <= config.maximumZones
          ? zones
          : zones.sublist(zones.length - config.maximumZones),
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
