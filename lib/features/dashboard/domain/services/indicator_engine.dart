import 'dart:math' as math;

import '../analysis_models.dart';
import '../market_models.dart';

class IndicatorEngine {
  final Map<String, _IndicatorCache> _caches = {};

  int fullRecalculationCount = 0;
  int incrementalUpdateCount = 0;

  IndicatorSnapshot calculate(String key, List<Candle> input) {
    final candles = List<Candle>.of(input)
      ..sort((a, b) => a.time.compareTo(b.time));
    final cache = _caches.putIfAbsent(key, _IndicatorCache.new);

    if (_sameSeries(cache.candles, candles)) return cache.snapshot!;

    if (_isCurrentCandleUpdate(cache.candles, candles)) {
      cache.removeLast();
      cache.append(candles.last);
      incrementalUpdateCount++;
    } else if (_isSingleAppend(cache.candles, candles)) {
      cache.append(candles.last);
      incrementalUpdateCount++;
    } else {
      cache.rebuild(candles);
      fullRecalculationCount++;
    }
    return cache.buildSnapshot();
  }

  bool _sameSeries(List<Candle> left, List<Candle> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_sameCandle(left[index], right[index])) return false;
    }
    return true;
  }

  bool _isCurrentCandleUpdate(List<Candle> old, List<Candle> next) {
    if (old.isEmpty ||
        old.length != next.length ||
        old.last.time != next.last.time) {
      return false;
    }
    for (var index = 0; index < old.length - 1; index++) {
      if (!_sameCandle(old[index], next[index])) return false;
    }
    return true;
  }

  bool _isSingleAppend(List<Candle> old, List<Candle> next) {
    if (next.length != old.length + 1) return false;
    for (var index = 0; index < old.length; index++) {
      if (!_sameCandle(old[index], next[index])) return false;
    }
    return true;
  }

  bool _sameCandle(Candle a, Candle b) =>
      a.time == b.time &&
      a.open == b.open &&
      a.high == b.high &&
      a.low == b.low &&
      a.close == b.close &&
      a.volume == b.volume;
}

class _IndicatorCache {
  final candles = <Candle>[];
  final ema20 = <double?>[];
  final ema50 = <double?>[];
  final ema200 = <double?>[];
  final ema12 = <double?>[];
  final ema26 = <double?>[];
  final rsi14 = <double?>[];
  final averageGain = <double?>[];
  final averageLoss = <double?>[];
  final macd = <double?>[];
  final macdSignal = <double?>[];
  final macdHistogram = <double?>[];
  final trueRange = <double>[];
  final atr14 = <double?>[];
  final plusDm = <double>[];
  final minusDm = <double>[];
  final adxTrueRange = <double?>[];
  final smoothPlusDm = <double?>[];
  final smoothMinusDm = <double?>[];
  final dx = <double?>[];
  final adx14 = <double?>[];
  final averageVolume20 = <double?>[];

  IndicatorSnapshot? snapshot;

  void rebuild(List<Candle> values) {
    _clear();
    for (final candle in values) {
      append(candle);
    }
  }

  void append(Candle candle) {
    candles.add(candle);
    final index = candles.length - 1;
    final close = candle.close;

    ema12.add(_nextEma(index, 12, ema12, close));
    ema20.add(_nextEma(index, 20, ema20, close));
    ema26.add(_nextEma(index, 26, ema26, close));
    ema50.add(_nextEma(index, 50, ema50, close));
    ema200.add(_nextEma(index, 200, ema200, close));

    _appendRsi(index);
    _appendMacd(index);
    _appendAtrAndAdx(index);
    averageVolume20.add(
      index < 19
          ? null
          : candles
                    .sublist(index - 19, index + 1)
                    .fold<int>(0, (sum, item) => sum + item.volume) /
                20,
    );
    snapshot = null;
  }

  void _appendRsi(int index) {
    if (index < 14) {
      averageGain.add(null);
      averageLoss.add(null);
      rsi14.add(null);
      return;
    }
    double gain;
    double loss;
    if (index == 14) {
      gain = 0;
      loss = 0;
      for (var cursor = 1; cursor <= 14; cursor++) {
        final change = candles[cursor].close - candles[cursor - 1].close;
        gain += math.max(change, 0);
        loss += math.max(-change, 0);
      }
      gain /= 14;
      loss /= 14;
    } else {
      final change = candles[index].close - candles[index - 1].close;
      gain = (averageGain[index - 1]! * 13 + math.max(change, 0)) / 14;
      loss = (averageLoss[index - 1]! * 13 + math.max(-change, 0)) / 14;
    }
    averageGain.add(gain);
    averageLoss.add(loss);
    rsi14.add(
      loss == 0 ? (gain == 0 ? 50 : 100) : 100 - 100 / (1 + gain / loss),
    );
  }

  void _appendMacd(int index) {
    final fast = ema12[index];
    final slow = ema26[index];
    final value = fast == null || slow == null ? null : fast - slow;
    macd.add(value);

    double? signal;
    if (index == 33) {
      signal =
          macd.sublist(25, 34).whereType<double>().reduce((a, b) => a + b) / 9;
    } else if (index > 33 && value != null) {
      signal =
          macdSignal[index - 1]! + (value - macdSignal[index - 1]!) * 2 / 10;
    }
    macdSignal.add(signal);
    macdHistogram.add(value == null || signal == null ? null : value - signal);
  }

  void _appendAtrAndAdx(int index) {
    final candle = candles[index];
    final tr = index == 0
        ? candle.high - candle.low
        : math.max(
            candle.high - candle.low,
            math.max(
              (candle.high - candles[index - 1].close).abs(),
              (candle.low - candles[index - 1].close).abs(),
            ),
          );
    trueRange.add(tr);
    atr14.add(
      index < 13
          ? null
          : index == 13
          ? trueRange.take(14).reduce((a, b) => a + b) / 14
          : (atr14[index - 1]! * 13 + tr) / 14,
    );

    final upMove = index == 0 ? 0.0 : candle.high - candles[index - 1].high;
    final downMove = index == 0 ? 0.0 : candles[index - 1].low - candle.low;
    plusDm.add(upMove > downMove && upMove > 0 ? upMove : 0);
    minusDm.add(downMove > upMove && downMove > 0 ? downMove : 0);

    if (index < 14) {
      adxTrueRange.add(null);
      smoothPlusDm.add(null);
      smoothMinusDm.add(null);
      dx.add(null);
      adx14.add(null);
      return;
    }

    final smoothTr = index == 14
        ? trueRange.sublist(1, 15).reduce((a, b) => a + b) / 14
        : (adxTrueRange[index - 1]! * 13 + tr) / 14;
    final plus = index == 14
        ? plusDm.sublist(1, 15).reduce((a, b) => a + b) / 14
        : (smoothPlusDm[index - 1]! * 13 + plusDm[index]) / 14;
    final minus = index == 14
        ? minusDm.sublist(1, 15).reduce((a, b) => a + b) / 14
        : (smoothMinusDm[index - 1]! * 13 + minusDm[index]) / 14;
    adxTrueRange.add(smoothTr);
    smoothPlusDm.add(plus);
    smoothMinusDm.add(minus);

    final plusDi = smoothTr == 0 ? 0 : 100 * plus / smoothTr;
    final minusDi = smoothTr == 0 ? 0 : 100 * minus / smoothTr;
    final denominator = plusDi + minusDi;
    final dxValue = denominator == 0
        ? 0.0
        : 100 * (plusDi - minusDi).abs() / denominator;
    dx.add(dxValue);

    if (index < 27) {
      adx14.add(null);
    } else if (index == 27) {
      adx14.add(
        dx.sublist(14, 28).whereType<double>().reduce((a, b) => a + b) / 14,
      );
    } else {
      adx14.add((adx14[index - 1]! * 13 + dxValue) / 14);
    }
  }

  double? _nextEma(int index, int period, List<double?> output, double value) {
    if (index < period - 1) return null;
    if (index == period - 1) {
      return candles
              .take(period)
              .fold<double>(0, (sum, item) => sum + item.close) /
          period;
    }
    return output[index - 1]! + (value - output[index - 1]!) * 2 / (period + 1);
  }

  void removeLast() {
    if (candles.isEmpty) return;
    for (final list in <List<dynamic>>[
      candles,
      ema20,
      ema50,
      ema200,
      ema12,
      ema26,
      rsi14,
      averageGain,
      averageLoss,
      macd,
      macdSignal,
      macdHistogram,
      trueRange,
      atr14,
      plusDm,
      minusDm,
      adxTrueRange,
      smoothPlusDm,
      smoothMinusDm,
      dx,
      adx14,
      averageVolume20,
    ]) {
      list.removeLast();
    }
    snapshot = null;
  }

  IndicatorSnapshot buildSnapshot() => snapshot ??= IndicatorSnapshot(
    candles: List.unmodifiable(candles),
    ema20: List.unmodifiable(ema20),
    ema50: List.unmodifiable(ema50),
    ema200: List.unmodifiable(ema200),
    rsi14: List.unmodifiable(rsi14),
    macd: List.unmodifiable(macd),
    macdSignal: List.unmodifiable(macdSignal),
    macdHistogram: List.unmodifiable(macdHistogram),
    adx14: List.unmodifiable(adx14),
    atr14: List.unmodifiable(atr14),
    averageVolume20: List.unmodifiable(averageVolume20),
  );

  void _clear() {
    for (final list in <List<dynamic>>[
      candles,
      ema20,
      ema50,
      ema200,
      ema12,
      ema26,
      rsi14,
      averageGain,
      averageLoss,
      macd,
      macdSignal,
      macdHistogram,
      trueRange,
      atr14,
      plusDm,
      minusDm,
      adxTrueRange,
      smoothPlusDm,
      smoothMinusDm,
      dx,
      adx14,
      averageVolume20,
    ]) {
      list.clear();
    }
    snapshot = null;
  }
}
