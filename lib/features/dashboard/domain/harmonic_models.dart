enum SwingType { high, low }

class SwingPoint {
  const SwingPoint({
    required this.type,
    required this.candleIndex,
    required this.price,
    required this.timeUtc,
    required this.confirmedAtUtc,
    required this.confirmedAtIndex,
  });

  final SwingType type;
  final int candleIndex;
  final double price;
  final DateTime timeUtc;
  final DateTime confirmedAtUtc;
  final int confirmedAtIndex;
}

enum HarmonicPatternType {
  gartley,
  bat,
  alternateBat,
  butterfly,
  crab,
  deepCrab,
  cypher,
  shark,
  fiveZero,
  abcd,
  alternateAbcd,
}

enum PatternDirection { bullish, bearish }

enum HarmonicPatternStatus { forming, completed, invalidated }

class HarmonicPattern {
  const HarmonicPattern({
    required this.id,
    required this.type,
    required this.direction,
    required this.timeframe,
    required this.points,
    required this.ratios,
    required this.status,
    required this.przLower,
    required this.przUpper,
    required this.detectedAtUtc,
    required this.confirmedAtUtc,
    required this.geometryScore,
    required this.reasons,
  });

  final String id;
  final HarmonicPatternType type;
  final PatternDirection direction;
  final String timeframe;
  final Map<String, SwingPoint> points;
  final Map<String, double> ratios;
  final HarmonicPatternStatus status;
  final double przLower;
  final double przUpper;
  final DateTime detectedAtUtc;
  final DateTime? confirmedAtUtc;
  final double geometryScore;
  final List<String> reasons;

  String get displayName => switch (type) {
    HarmonicPatternType.gartley => 'Gartley',
    HarmonicPatternType.bat => 'Bat',
    HarmonicPatternType.alternateBat => 'Alternate Bat',
    HarmonicPatternType.butterfly => 'Butterfly',
    HarmonicPatternType.crab => 'Crab',
    HarmonicPatternType.deepCrab => 'Deep Crab',
    HarmonicPatternType.cypher => 'Cypher',
    HarmonicPatternType.shark => 'Shark',
    HarmonicPatternType.fiveZero => '5-0',
    HarmonicPatternType.abcd => 'AB=CD',
    HarmonicPatternType.alternateAbcd => 'Alternate AB=CD',
  };

  HarmonicPattern scoped(String symbol) => HarmonicPattern(
    id: '$symbol:$id',
    type: type,
    direction: direction,
    timeframe: timeframe,
    points: points,
    ratios: ratios,
    status: status,
    przLower: przLower,
    przUpper: przUpper,
    detectedAtUtc: detectedAtUtc,
    confirmedAtUtc: confirmedAtUtc,
    geometryScore: geometryScore,
    reasons: reasons,
  );
}

enum HarmonicDiagnosticReason {
  unsupportedPattern,
  insufficientData,
  noValidSwingSequence,
  invalidFibonacciRatios,
  patternNotConfirmed,
  patternInvalidated,
  filteredBySettings,
  hiddenOverlay,
  differentSymbolOrTimeframe,
}

class HarmonicDiagnostic {
  const HarmonicDiagnostic({required this.reason, required this.detail});

  final HarmonicDiagnosticReason reason;
  final String detail;
}

class HarmonicAnalysisResult {
  const HarmonicAnalysisResult({
    required this.patterns,
    required this.diagnostics,
    this.combinationsChecked = 0,
  });

  final List<HarmonicPattern> patterns;
  final List<HarmonicDiagnostic> diagnostics;
  final int combinationsChecked;
}

class HarmonicDebugSnapshot {
  const HarmonicDebugSnapshot({
    required this.candleCount,
    required this.swingCounts,
    required this.combinationsChecked,
    required this.validPatternCount,
    required this.diagnostics,
  });

  const HarmonicDebugSnapshot.empty()
    : candleCount = 0,
      swingCounts = const {},
      combinationsChecked = 0,
      validPatternCount = 0,
      diagnostics = const [];

  final int candleCount;
  final Map<String, int> swingCounts;
  final int combinationsChecked;
  final int validPatternCount;
  final List<HarmonicDiagnostic> diagnostics;
}

enum FibonacciLevelKind { retracement, extension }

class FibonacciLevel {
  const FibonacciLevel({
    required this.ratio,
    required this.price,
    required this.kind,
  });

  final double ratio;
  final double price;
  final FibonacciLevelKind kind;
}

class FibonacciConfluenceZone {
  const FibonacciConfluenceZone({
    required this.lower,
    required this.upper,
    required this.levelCount,
  });

  final double lower;
  final double upper;
  final int levelCount;
}

class FibonacciAnalysis {
  const FibonacciAnalysis({
    required this.start,
    required this.end,
    required this.levels,
    required this.confluenceZones,
  });

  final SwingPoint start;
  final SwingPoint end;
  final List<FibonacciLevel> levels;
  final List<FibonacciConfluenceZone> confluenceZones;
}
