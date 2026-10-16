import 'dart:math' as math;

import '../harmonic_models.dart';
import '../market_models.dart';
import 'fibonacci_analysis_service.dart';

class RatioRange {
  const RatioRange(this.minimum, this.maximum);
  final double minimum;
  final double maximum;
  double get midpoint => (minimum + maximum) / 2;
}

class HarmonicPatternRule {
  const HarmonicPatternRule({
    required this.type,
    required this.abXa,
    required this.bcAb,
    required this.cdBc,
    required this.adXa,
  });

  final HarmonicPatternType type;
  final RatioRange abXa;
  final RatioRange bcAb;
  final RatioRange cdBc;
  final RatioRange adXa;
}

class HarmonicPatternConfig {
  const HarmonicPatternConfig({
    this.ratioTolerance = .04,
    this.rules = defaultRules,
  });

  final double ratioTolerance;
  final List<HarmonicPatternRule> rules;

  static const defaultRules = [
    HarmonicPatternRule(
      type: HarmonicPatternType.gartley,
      abXa: RatioRange(.618, .618),
      bcAb: RatioRange(.382, .886),
      cdBc: RatioRange(1.13, 1.618),
      adXa: RatioRange(.786, .786),
    ),
    HarmonicPatternRule(
      type: HarmonicPatternType.bat,
      abXa: RatioRange(.382, .5),
      bcAb: RatioRange(.382, .886),
      cdBc: RatioRange(1.618, 2.618),
      adXa: RatioRange(.886, .886),
    ),
    // Scott Carney's Alternate Bat uses a shallow B point and a 1.13 XA
    // completion. It is kept separate from Bat to avoid ambiguous matches.
    HarmonicPatternRule(
      type: HarmonicPatternType.alternateBat,
      abXa: RatioRange(.382, .382),
      bcAb: RatioRange(.382, .886),
      cdBc: RatioRange(2, 3.618),
      adXa: RatioRange(1.13, 1.13),
    ),
    HarmonicPatternRule(
      type: HarmonicPatternType.butterfly,
      abXa: RatioRange(.786, .786),
      bcAb: RatioRange(.382, .886),
      cdBc: RatioRange(1.618, 2.618),
      adXa: RatioRange(1.27, 1.618),
    ),
    HarmonicPatternRule(
      type: HarmonicPatternType.crab,
      abXa: RatioRange(.382, .618),
      bcAb: RatioRange(.382, .886),
      cdBc: RatioRange(2.618, 3.618),
      adXa: RatioRange(1.618, 1.618),
    ),
    HarmonicPatternRule(
      type: HarmonicPatternType.deepCrab,
      abXa: RatioRange(.886, .886),
      bcAb: RatioRange(.382, .886),
      cdBc: RatioRange(2, 3.618),
      adXa: RatioRange(1.618, 1.618),
    ),
  ];
}

class HarmonicPatternEngine {
  const HarmonicPatternEngine({
    this.config = const HarmonicPatternConfig(),
    this.fibonacci = const FibonacciAnalysisService(),
  });

  final HarmonicPatternConfig config;
  final FibonacciAnalysisService fibonacci;

  HarmonicAnalysisResult analyze(
    List<SwingPoint> swings,
    String timeframe, {
    List<Candle> candles = const [],
  }) {
    if (swings.length < 4) {
      return const HarmonicAnalysisResult(
        patterns: [],
        diagnostics: [
          HarmonicDiagnostic(
            reason: HarmonicDiagnosticReason.insufficientData,
            detail: 'At least four confirmed swings are required.',
          ),
        ],
      );
    }
    final patterns = detect(swings, timeframe, candles: candles);
    final diagnostics = <HarmonicDiagnostic>[];
    var combinationsChecked = 0;
    for (var start = 0; start + 4 < swings.length; start++) {
      final points = swings.sublist(start, start + 5);
      if (!_alternating(points)) continue;
      combinationsChecked += config.rules.length + 3;
      if (diagnostics.length < 30) {
        diagnostics.addAll(
          _ratioDiagnostics(points).take(30 - diagnostics.length),
        );
      }
    }
    for (var start = 0; start + 3 < swings.length; start++) {
      final points = swings.sublist(start, start + 4);
      if (!_alternating(points)) continue;
      combinationsChecked += 2;
      if (diagnostics.length < 30) {
        diagnostics.addAll(
          _abcdRatioDiagnostics(points).take(30 - diagnostics.length),
        );
      }
    }
    if (!_hasAlternatingSequence(swings)) {
      diagnostics.add(
        const HarmonicDiagnostic(
          reason: HarmonicDiagnosticReason.noValidSwingSequence,
          detail: 'No chronological alternating swing sequence was found.',
        ),
      );
    } else if (patterns.isEmpty) {
      diagnostics.add(
        const HarmonicDiagnostic(
          reason: HarmonicDiagnosticReason.invalidFibonacciRatios,
          detail:
              'Swing sequences exist but do not match the enabled registry.',
        ),
      );
    }
    final invalidated = patterns
        .where((item) => item.status == HarmonicPatternStatus.invalidated)
        .length;
    if (invalidated > 0) {
      diagnostics.add(
        HarmonicDiagnostic(
          reason: HarmonicDiagnosticReason.patternInvalidated,
          detail: '$invalidated detected pattern(s) crossed invalidation.',
        ),
      );
    }
    return HarmonicAnalysisResult(
      patterns: patterns,
      diagnostics: List.unmodifiable(diagnostics),
      combinationsChecked: combinationsChecked,
    );
  }

  Iterable<HarmonicDiagnostic> _ratioDiagnostics(List<SwingPoint> p) sync* {
    final xa = _distance(p[0], p[1]);
    final ab = _distance(p[1], p[2]);
    final bc = _distance(p[2], p[3]);
    final cd = _distance(p[3], p[4]);
    if (xa == 0 || ab == 0 || bc == 0) return;
    final ratios = <String, double>{
      'AB/XA': ab / xa,
      'BC/AB': bc / ab,
      'CD/BC': cd / bc,
      'AD/XA': _distance(p[1], p[4]) / xa,
    };
    for (final rule in config.rules) {
      final allowed = <String, RatioRange>{
        'AB/XA': rule.abXa,
        'BC/AB': rule.bcAb,
        'CD/BC': rule.cdBc,
        'AD/XA': rule.adXa,
      };
      final rejected = ratios.entries.where(
        (entry) => !_matches(entry.value, allowed[entry.key]!),
      );
      if (rejected.isEmpty) continue;
      yield HarmonicDiagnostic(
        reason: HarmonicDiagnosticReason.invalidFibonacciRatios,
        detail:
            '${rule.type.name} rejected at ${p.first.candleIndex}-${p.last.candleIndex}: '
            '${rejected.map((entry) {
              final range = allowed[entry.key]!;
              return '${entry.key}=${entry.value.toStringAsFixed(3)} '
                  '(allowed ${range.minimum.toStringAsFixed(3)}-'
                  '${range.maximum.toStringAsFixed(3)})';
            }).join(', ')}',
      );
    }
    final xc = _distance(p[0], p[3]);
    final ox = _distance(p[0], p[1]);
    final specialCandidates =
        <(HarmonicPatternType, Map<String, double>, Map<String, RatioRange>)>[
          if (xc > 0)
            (
              HarmonicPatternType.cypher,
              {'AB/XA': ab / xa, 'XC/XA': xc / xa, 'CD/XC': cd / xc},
              const {
                'AB/XA': RatioRange(.382, .618),
                'XC/XA': RatioRange(1.272, 1.414),
                'CD/XC': RatioRange(.786, .786),
              },
            ),
          if (ox > 0)
            (
              HarmonicPatternType.shark,
              {
                'AB/XA': bc / ab,
                'BC/AB': cd / bc,
                'OC/OX': _distance(p[0], p[4]) / ox,
              },
              const {
                'AB/XA': RatioRange(1.13, 1.618),
                'BC/AB': RatioRange(1.618, 2.24),
                'OC/OX': RatioRange(.886, 1.13),
              },
            ),
          (
            HarmonicPatternType.fiveZero,
            {
              'AB/XA': bc / ab,
              'BC/AB': cd / bc,
              'CD/BC': _distance(p[2], p[4]) / cd,
            },
            const {
              'AB/XA': RatioRange(1.13, 1.618),
              'BC/AB': RatioRange(1.618, 2.24),
              'CD/BC': RatioRange(.5, .5),
            },
          ),
        ];
    for (final candidate in specialCandidates) {
      final rejection = _ratioRejection(
        candidate.$1,
        candidate.$2,
        candidate.$3,
        p.first.candleIndex,
        p.last.candleIndex,
      );
      if (rejection != null) yield rejection;
    }
  }

  Iterable<HarmonicDiagnostic> _abcdRatioDiagnostics(List<SwingPoint> p) sync* {
    final ab = _distance(p[0], p[1]);
    final bc = _distance(p[1], p[2]);
    final cd = _distance(p[2], p[3]);
    if (ab == 0) return;
    final ratios = {'BC/AB': bc / ab, 'CD/AB': cd / ab};
    for (final candidate in const [
      (
        HarmonicPatternType.abcd,
        {'BC/AB': RatioRange(.382, .886), 'CD/AB': RatioRange(1, 1)},
      ),
      (
        HarmonicPatternType.alternateAbcd,
        {'BC/AB': RatioRange(.382, .886), 'CD/AB': RatioRange(1.272, 1.618)},
      ),
    ]) {
      final rejection = _ratioRejection(
        candidate.$1,
        ratios,
        candidate.$2,
        p.first.candleIndex,
        p.last.candleIndex,
      );
      if (rejection != null) yield rejection;
    }
  }

  HarmonicDiagnostic? _ratioRejection(
    HarmonicPatternType type,
    Map<String, double> actual,
    Map<String, RatioRange> allowed,
    int firstIndex,
    int lastIndex,
  ) {
    final rejected = actual.entries.where(
      (entry) => !_matches(entry.value, allowed[entry.key]!),
    );
    if (rejected.isEmpty) return null;
    return HarmonicDiagnostic(
      reason: HarmonicDiagnosticReason.invalidFibonacciRatios,
      detail:
          '${type.name} rejected at $firstIndex-$lastIndex: '
          '${rejected.map((entry) {
            final range = allowed[entry.key]!;
            return '${entry.key}=${entry.value.toStringAsFixed(3)} '
                '(allowed ${range.minimum.toStringAsFixed(3)}-'
                '${range.maximum.toStringAsFixed(3)})';
          }).join(', ')}',
    );
  }

  List<HarmonicPattern> detect(
    List<SwingPoint> swings,
    String timeframe, {
    List<Candle> candles = const [],
  }) {
    final found = <String, HarmonicPattern>{};
    for (var start = 0; start + 4 < swings.length; start++) {
      final points = swings.sublist(start, start + 5);
      if (!_alternating(points)) continue;
      for (final rule in config.rules) {
        final pattern = _standard(rule, points, timeframe, candles);
        if (pattern != null) found[pattern.id] = pattern;
      }
      final cypher = _cypher(points, timeframe, candles);
      if (cypher != null) found[cypher.id] = cypher;
      final shark = _shark(points, timeframe, candles);
      if (shark != null) found[shark.id] = shark;
      final fiveZero = _fiveZero(points, timeframe, candles);
      if (fiveZero != null) found[fiveZero.id] = fiveZero;
    }
    for (var start = 0; start + 3 < swings.length; start++) {
      final points = swings.sublist(start, start + 4);
      if (!_alternating(points)) continue;
      final pattern = _abcd(points, timeframe, candles);
      if (pattern != null) found[pattern.id] = pattern;
      final alternate = _alternateAbcd(points, timeframe, candles);
      if (alternate != null) found[alternate.id] = alternate;
    }
    if (swings.length >= 4) {
      final partial = swings.sublist(swings.length - 4);
      if (_alternating(partial)) {
        for (final rule in config.rules) {
          final pattern = _forming(rule, partial, timeframe);
          if (pattern != null) found[pattern.id] = pattern;
        }
      }
    }
    final result = found.values.toList()
      ..sort((a, b) => b.detectedAtUtc.compareTo(a.detectedAtUtc));
    return List.unmodifiable(result);
  }

  HarmonicPattern? _standard(
    HarmonicPatternRule rule,
    List<SwingPoint> p,
    String timeframe,
    List<Candle> candles,
  ) {
    final xa = _distance(p[0], p[1]);
    final ab = _distance(p[1], p[2]);
    final bc = _distance(p[2], p[3]);
    final cd = _distance(p[3], p[4]);
    if (xa == 0 || ab == 0 || bc == 0) return null;
    final ratios = {
      'AB/XA': ab / xa,
      'BC/AB': bc / ab,
      'CD/BC': cd / bc,
      'AD/XA': _distance(p[1], p[4]) / xa,
    };
    if (!_matches(ratios['AB/XA']!, rule.abXa) ||
        !_matches(ratios['BC/AB']!, rule.bcAb) ||
        !_matches(ratios['CD/BC']!, rule.cdBc) ||
        !_matches(ratios['AD/XA']!, rule.adXa)) {
      return null;
    }
    return _completed(
      rule.type,
      ['X', 'A', 'B', 'C', 'D'],
      p,
      ratios,
      xa,
      timeframe,
      candles,
    );
  }

  HarmonicPattern? _cypher(
    List<SwingPoint> p,
    String timeframe,
    List<Candle> candles,
  ) {
    final xa = _distance(p[0], p[1]);
    final ab = _distance(p[1], p[2]);
    final xc = _distance(p[0], p[3]);
    final cd = _distance(p[3], p[4]);
    if (xa == 0 || xc == 0) return null;
    final ratios = {'AB/XA': ab / xa, 'XC/XA': xc / xa, 'CD/XC': cd / xc};
    if (!_matches(ratios['AB/XA']!, const RatioRange(.382, .618)) ||
        !_matches(ratios['XC/XA']!, const RatioRange(1.272, 1.414)) ||
        !_matches(ratios['CD/XC']!, const RatioRange(.786, .786))) {
      return null;
    }
    return _completed(
      HarmonicPatternType.cypher,
      ['X', 'A', 'B', 'C', 'D'],
      p,
      ratios,
      xa,
      timeframe,
      candles,
    );
  }

  HarmonicPattern? _shark(
    List<SwingPoint> p,
    String timeframe,
    List<Candle> candles,
  ) {
    final ox = _distance(p[0], p[1]);
    final xa = _distance(p[1], p[2]);
    final ab = _distance(p[2], p[3]);
    final bc = _distance(p[3], p[4]);
    if (ox == 0 || xa == 0 || ab == 0) return null;
    final ratios = {
      'AB/XA': ab / xa,
      'BC/AB': bc / ab,
      'OC/OX': _distance(p[0], p[4]) / ox,
    };
    if (!_matches(ratios['AB/XA']!, const RatioRange(1.13, 1.618)) ||
        !_matches(ratios['BC/AB']!, const RatioRange(1.618, 2.24)) ||
        !_matches(ratios['OC/OX']!, const RatioRange(.886, 1.13))) {
      return null;
    }
    return _completed(
      HarmonicPatternType.shark,
      ['O', 'X', 'A', 'B', 'C'],
      p,
      ratios,
      ox,
      timeframe,
      candles,
    );
  }

  HarmonicPattern? _abcd(
    List<SwingPoint> p,
    String timeframe,
    List<Candle> candles,
  ) {
    final ab = _distance(p[0], p[1]);
    final bc = _distance(p[1], p[2]);
    final cd = _distance(p[2], p[3]);
    if (ab == 0) return null;
    final ratios = {'BC/AB': bc / ab, 'CD/AB': cd / ab};
    if (!_matches(ratios['BC/AB']!, const RatioRange(.382, .886)) ||
        !_matches(ratios['CD/AB']!, const RatioRange(1, 1))) {
      return null;
    }
    return _completed(
      HarmonicPatternType.abcd,
      ['A', 'B', 'C', 'D'],
      p,
      ratios,
      ab,
      timeframe,
      candles,
      bullishWhenFirstLow: false,
    );
  }

  HarmonicPattern? _alternateAbcd(
    List<SwingPoint> p,
    String timeframe,
    List<Candle> candles,
  ) {
    final ab = _distance(p[0], p[1]);
    final bc = _distance(p[1], p[2]);
    final cd = _distance(p[2], p[3]);
    if (ab == 0) return null;
    final ratios = {'BC/AB': bc / ab, 'CD/AB': cd / ab};
    if (!_matches(ratios['BC/AB']!, const RatioRange(.382, .886)) ||
        !_matches(ratios['CD/AB']!, const RatioRange(1.272, 1.618))) {
      return null;
    }
    return _completed(
      HarmonicPatternType.alternateAbcd,
      ['A', 'B', 'C', 'D'],
      p,
      ratios,
      ab,
      timeframe,
      candles,
      bullishWhenFirstLow: false,
    );
  }

  HarmonicPattern? _fiveZero(
    List<SwingPoint> p,
    String timeframe,
    List<Candle> candles,
  ) {
    final xa = _distance(p[1], p[2]);
    final ab = _distance(p[2], p[3]);
    final bc = _distance(p[3], p[4]);
    if (xa == 0 || ab == 0 || bc == 0) return null;
    final ratios = {
      'AB/XA': ab / xa,
      'BC/AB': bc / ab,
      'CD/BC': _distance(p[2], p[4]) / bc,
    };
    if (!_matches(ratios['AB/XA']!, const RatioRange(1.13, 1.618)) ||
        !_matches(ratios['BC/AB']!, const RatioRange(1.618, 2.24)) ||
        !_matches(ratios['CD/BC']!, const RatioRange(.5, .5))) {
      return null;
    }
    return _completed(
      HarmonicPatternType.fiveZero,
      ['0', 'X', 'A', 'B', 'C'],
      p,
      ratios,
      xa,
      timeframe,
      candles,
    );
  }

  HarmonicPattern? _forming(
    HarmonicPatternRule rule,
    List<SwingPoint> p,
    String timeframe,
  ) {
    final xa = _distance(p[0], p[1]);
    final ab = _distance(p[1], p[2]);
    final bc = _distance(p[2], p[3]);
    if (xa == 0 ||
        ab == 0 ||
        !_matches(ab / xa, rule.abXa) ||
        !_matches(bc / ab, rule.bcAb)) {
      return null;
    }
    final bullish = p.first.type == SwingType.low;
    final projected = bullish
        ? p[1].price - xa * rule.adXa.midpoint
        : p[1].price + xa * rule.adXa.midpoint;
    final prz = fibonacci.prz(projected, xa);
    final id =
        '${timeframe}_${rule.type.name}_${p.first.candleIndex}_${p.last.candleIndex}_forming';
    return HarmonicPattern(
      id: id,
      type: rule.type,
      direction: bullish ? PatternDirection.bullish : PatternDirection.bearish,
      timeframe: timeframe,
      points: Map.unmodifiable(Map.fromIterables(['X', 'A', 'B', 'C'], p)),
      ratios: {'AB/XA': ab / xa, 'BC/AB': bc / ab},
      status: HarmonicPatternStatus.forming,
      przLower: prz.lower,
      przUpper: prz.upper,
      detectedAtUtc: p.last.confirmedAtUtc,
      confirmedAtUtc: null,
      geometryScore: _geometryScore(
        {'AB/XA': ab / xa, 'BC/AB': bc / ab},
        {'AB/XA': rule.abXa, 'BC/AB': rule.bcAb},
      ),
      reasons: const ['نسبت‌های XABC معتبرند؛ نقطه D هنوز تأیید نشده است'],
    );
  }

  HarmonicPattern _completed(
    HarmonicPatternType type,
    List<String> labels,
    List<SwingPoint> p,
    Map<String, double> ratios,
    double legSize,
    String timeframe,
    List<Candle> candles, {
    bool bullishWhenFirstLow = true,
  }) {
    final bullish = bullishWhenFirstLow
        ? p.first.type == SwingType.low
        : p.first.type == SwingType.high;
    final prz = fibonacci.prz(p.last.price, legSize);
    final lastClose = candles.isEmpty ? null : candles.last.close;
    final invalidated =
        lastClose != null &&
        (bullish ? lastClose < prz.lower : lastClose > prz.upper);
    final status = invalidated
        ? HarmonicPatternStatus.invalidated
        : HarmonicPatternStatus.completed;
    final id =
        '${timeframe}_${type.name}_${p.first.candleIndex}_${p.last.candleIndex}';
    return HarmonicPattern(
      id: id,
      type: type,
      direction: bullish ? PatternDirection.bullish : PatternDirection.bearish,
      timeframe: timeframe,
      points: Map.unmodifiable(Map.fromIterables(labels, p)),
      ratios: Map.unmodifiable(ratios),
      status: status,
      przLower: prz.lower,
      przUpper: prz.upper,
      detectedAtUtc: p.last.confirmedAtUtc,
      confirmedAtUtc: p.last.confirmedAtUtc,
      geometryScore: _geometryScore(ratios, _rangesFor(type)),
      reasons: [
        'نسبت‌های فیبوناچی ${ratios.entries.map((e) => '${e.key}=${e.value.toStringAsFixed(3)}').join('، ')} معتبرند',
        if (invalidated) 'قیمت پس از تکمیل از محدوده ابطال عبور کرده است',
      ],
    );
  }

  bool _matches(double value, RatioRange range) {
    final padding = math.max(
      range.midpoint.abs() * config.ratioTolerance,
      .005,
    );
    return value >= range.minimum - padding && value <= range.maximum + padding;
  }

  bool _alternating(List<SwingPoint> points) {
    for (var index = 1; index < points.length; index++) {
      if (points[index].type == points[index - 1].type ||
          points[index].candleIndex <= points[index - 1].candleIndex) {
        return false;
      }
    }
    return true;
  }

  bool _hasAlternatingSequence(List<SwingPoint> points) {
    for (var index = 0; index + 3 < points.length; index++) {
      if (_alternating(points.sublist(index, index + 4))) return true;
    }
    return false;
  }

  Map<String, RatioRange> _rangesFor(HarmonicPatternType type) {
    for (final rule in config.rules) {
      if (rule.type == type) {
        return {
          'AB/XA': rule.abXa,
          'BC/AB': rule.bcAb,
          'CD/BC': rule.cdBc,
          'AD/XA': rule.adXa,
        };
      }
    }
    return switch (type) {
      HarmonicPatternType.cypher => const {
        'AB/XA': RatioRange(.382, .618),
        'XC/XA': RatioRange(1.272, 1.414),
        'CD/XC': RatioRange(.786, .786),
      },
      HarmonicPatternType.shark => const {
        'AB/XA': RatioRange(1.13, 1.618),
        'BC/AB': RatioRange(1.618, 2.24),
        'OC/OX': RatioRange(.886, 1.13),
      },
      HarmonicPatternType.fiveZero => const {
        'AB/XA': RatioRange(1.13, 1.618),
        'BC/AB': RatioRange(1.618, 2.24),
        'CD/BC': RatioRange(.5, .5),
      },
      HarmonicPatternType.abcd => const {
        'BC/AB': RatioRange(.382, .886),
        'CD/AB': RatioRange(1, 1),
      },
      HarmonicPatternType.alternateAbcd => const {
        'BC/AB': RatioRange(.382, .886),
        'CD/AB': RatioRange(1.272, 1.618),
      },
      _ => const {},
    };
  }

  double _geometryScore(
    Map<String, double> ratios,
    Map<String, RatioRange> ranges,
  ) {
    var total = 0.0;
    var count = 0;
    for (final entry in ratios.entries) {
      final range = ranges[entry.key];
      if (range == null) continue;
      final scale = math.max(
        range.midpoint.abs() * config.ratioTolerance,
        .005,
      );
      final error = (entry.value - range.midpoint).abs() / scale;
      total += math.max(0, 1 - math.min(1, error));
      count++;
    }
    return count == 0 ? 0 : total / count;
  }

  double _distance(SwingPoint a, SwingPoint b) => (a.price - b.price).abs();
}
