enum MarketDirection { bullish, bearish }

enum StructurePointType { higherHigh, higherLow, lowerHigh, lowerLow }

enum StructureBreakType { breakOfStructure, changeOfCharacter }

class StructurePoint {
  const StructurePoint({
    required this.id,
    required this.type,
    required this.candleIndex,
    required this.confirmedAtIndex,
    required this.price,
    required this.occurredAtUtc,
    required this.confirmedAtUtc,
  });

  final String id;
  final StructurePointType type;
  final int candleIndex;
  final int confirmedAtIndex;
  final double price;
  final DateTime occurredAtUtc;
  final DateTime confirmedAtUtc;
}

class StructureBreak {
  const StructureBreak({
    required this.id,
    required this.type,
    required this.direction,
    required this.level,
    required this.sourceCandleIndex,
    required this.breakCandleIndex,
    required this.occurredAtUtc,
    required this.confirmedAtUtc,
    required this.confirmedByClose,
  });

  final String id;
  final StructureBreakType type;
  final MarketDirection direction;
  final double level;
  final int sourceCandleIndex;
  final int breakCandleIndex;
  final DateTime occurredAtUtc;
  final DateTime confirmedAtUtc;
  final bool confirmedByClose;
}

enum ZoneStatus { active, mitigated, invalidated }

class OrderBlockZone {
  const OrderBlockZone({
    required this.id,
    required this.direction,
    required this.lower,
    required this.upper,
    required this.candleIndex,
    required this.formedAtUtc,
    required this.status,
    required this.breakId,
  });

  final String id;
  final MarketDirection direction;
  final double lower;
  final double upper;
  final int candleIndex;
  final DateTime formedAtUtc;
  final ZoneStatus status;
  final String breakId;
}

enum FairValueGapStatus { unfilled, partiallyFilled, filled }

class FairValueGap {
  const FairValueGap({
    required this.id,
    required this.direction,
    required this.lower,
    required this.upper,
    required this.candleIndex,
    required this.formedAtUtc,
    required this.status,
  });

  final String id;
  final MarketDirection direction;
  final double lower;
  final double upper;
  final int candleIndex;
  final DateTime formedAtUtc;
  final FairValueGapStatus status;
}

enum LiquidityType { equalHigh, equalLow }

class LiquiditySweep {
  const LiquiditySweep({
    required this.id,
    required this.type,
    required this.direction,
    required this.level,
    required this.referenceCandleIndex,
    required this.sweepCandleIndex,
    required this.occurredAtUtc,
    required this.confirmedAtUtc,
  });

  final String id;
  final LiquidityType type;
  final MarketDirection direction;
  final double level;
  final int referenceCandleIndex;
  final int sweepCandleIndex;
  final DateTime occurredAtUtc;
  final DateTime confirmedAtUtc;
}

enum PriceActionPatternType {
  bullishEngulfing,
  bearishEngulfing,
  bullishPinBar,
  bearishPinBar,
  insideBar,
  doji,
  bullishBreakout,
  bearishBreakout,
  bullishRetest,
  bearishRetest,
  supportResistanceFlip,
}

class PriceActionPattern {
  const PriceActionPattern({
    required this.id,
    required this.type,
    required this.candleIndex,
    required this.occurredAtUtc,
    required this.level,
    required this.reason,
    required this.lowConfidence,
    this.direction,
  });

  final String id;
  final PriceActionPatternType type;
  final MarketDirection? direction;
  final int candleIndex;
  final DateTime occurredAtUtc;
  final double level;
  final String reason;
  final bool lowConfidence;
}

class PriceActionSmcSnapshot {
  const PriceActionSmcSnapshot({
    required this.structurePoints,
    required this.structureBreaks,
    required this.orderBlocks,
    required this.fairValueGaps,
    required this.liquiditySweeps,
    required this.priceActionPatterns,
  });

  const PriceActionSmcSnapshot.empty()
    : structurePoints = const [],
      structureBreaks = const [],
      orderBlocks = const [],
      fairValueGaps = const [],
      liquiditySweeps = const [],
      priceActionPatterns = const [];

  final List<StructurePoint> structurePoints;
  final List<StructureBreak> structureBreaks;
  final List<OrderBlockZone> orderBlocks;
  final List<FairValueGap> fairValueGaps;
  final List<LiquiditySweep> liquiditySweeps;
  final List<PriceActionPattern> priceActionPatterns;

  bool get isEmpty =>
      structureBreaks.isEmpty &&
      orderBlocks.isEmpty &&
      fairValueGaps.isEmpty &&
      liquiditySweeps.isEmpty &&
      priceActionPatterns.isEmpty;
}
