import '../analysis_models.dart';
import '../market_models.dart';

class TrendAnalysisService {
  const TrendAnalysisService({this.swingWindow = 3});

  final int swingWindow;

  TrendAnalysis analyze(List<Candle> candles, IndicatorSnapshot indicators) {
    final ema20 = indicators.latestEma20;
    final ema50 = indicators.latestEma50;
    final ema200 = indicators.latestEma200;
    final adx = indicators.latestAdx;
    if (candles.length < 200 ||
        ema20 == null ||
        ema50 == null ||
        ema200 == null ||
        adx == null) {
      return const TrendAnalysis.unknown();
    }

    final reasons = <String>[];
    final emaBullish = ema20 > ema50 && ema50 > ema200;
    final emaBearish = ema20 < ema50 && ema50 < ema200;
    if (emaBullish) reasons.add('چیدمان EMAها صعودی است');
    if (emaBearish) reasons.add('چیدمان EMAها نزولی است');

    final swings = _swings(candles);
    final risingStructure =
        swings.highs.length >= 2 &&
        swings.lows.length >= 2 &&
        swings.highs.last > swings.highs[swings.highs.length - 2] &&
        swings.lows.last > swings.lows[swings.lows.length - 2];
    final fallingStructure =
        swings.highs.length >= 2 &&
        swings.lows.length >= 2 &&
        swings.highs.last < swings.highs[swings.highs.length - 2] &&
        swings.lows.last < swings.lows[swings.lows.length - 2];
    if (risingStructure) reasons.add('ساختار سقف و کف بالاتر است');
    if (fallingStructure) reasons.add('ساختار سقف و کف پایین‌تر است');

    if (adx < 20) {
      reasons.add('ADX کمتر از ۲۰ است');
      return TrendAnalysis(
        direction: TrendDirection.sideways,
        strength: TrendStrength.weak,
        reasons: reasons,
      );
    }

    final direction = emaBullish && risingStructure
        ? TrendDirection.bullish
        : emaBearish && fallingStructure
        ? TrendDirection.bearish
        : emaBullish && !fallingStructure
        ? TrendDirection.bullish
        : emaBearish && !risingStructure
        ? TrendDirection.bearish
        : TrendDirection.sideways;
    final strength = adx >= 40
        ? TrendStrength.strong
        : adx >= 25
        ? TrendStrength.moderate
        : TrendStrength.weak;
    reasons.add('ADX برابر ${adx.toStringAsFixed(1)} است');
    if (direction == TrendDirection.sideways) {
      reasons.add('EMA و ساختار قیمت هم‌جهت نیستند');
    }
    return TrendAnalysis(
      direction: direction,
      strength: strength,
      reasons: reasons,
    );
  }

  ({List<double> highs, List<double> lows}) _swings(List<Candle> candles) {
    final highs = <double>[];
    final lows = <double>[];
    for (var current = 0; current < candles.length; current++) {
      final candidate = current - swingWindow;
      if (candidate < swingWindow) continue;
      var high = true;
      var low = true;
      for (
        var index = candidate - swingWindow;
        index <= candidate + swingWindow;
        index++
      ) {
        if (index == candidate) continue;
        if (candles[index].high >= candles[candidate].high) high = false;
        if (candles[index].low <= candles[candidate].low) low = false;
      }
      if (high) highs.add(candles[candidate].high);
      if (low) lows.add(candles[candidate].low);
    }
    return (highs: highs, lows: lows);
  }
}
