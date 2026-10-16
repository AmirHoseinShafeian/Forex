import '../analysis_models.dart';
import '../harmonic_models.dart';
import '../market_models.dart';
import '../price_action_models.dart';
import 'fvg_detection_service.dart';
import 'liquidity_analysis_service.dart';
import 'market_structure_engine.dart';
import 'order_block_detection_service.dart';
import 'price_action_engine.dart';

class PriceActionSmcAnalysisService {
  PriceActionSmcAnalysisService({
    MarketStructureEngine? marketStructureEngine,
    OrderBlockDetectionService? orderBlockService,
    FvgDetectionService? fvgService,
    LiquidityAnalysisService? liquidityService,
    PriceActionEngine? priceActionEngine,
  }) : _marketStructureEngine =
           marketStructureEngine ?? const MarketStructureEngine(),
       _orderBlockService =
           orderBlockService ?? const OrderBlockDetectionService(),
       _fvgService = fvgService ?? const FvgDetectionService(),
       _liquidityService = liquidityService ?? const LiquidityAnalysisService(),
       _priceActionEngine = priceActionEngine ?? const PriceActionEngine();

  final MarketStructureEngine _marketStructureEngine;
  final OrderBlockDetectionService _orderBlockService;
  final FvgDetectionService _fvgService;
  final LiquidityAnalysisService _liquidityService;
  final PriceActionEngine _priceActionEngine;
  final Map<String, _CachedAnalysis> _cache = {};

  PriceActionSmcSnapshot analyze({
    required String key,
    required List<Candle> candles,
    required IndicatorSnapshot indicators,
    required List<SwingPoint> swings,
  }) {
    // MT5 includes the currently forming bar. Phase-six detections use only
    // closed candles so confirmed results do not repaint on every tick.
    if (candles.length < 21) return const PriceActionSmcSnapshot.empty();
    final closedCandles = candles.sublist(0, candles.length - 1);
    final closedAtr = indicators.atr14.take(closedCandles.length).toList();
    final confirmedSwings = swings
        .where((swing) => swing.confirmedAtIndex < closedCandles.length)
        .toList();
    final fingerprint = _fingerprint(closedCandles);
    final cached = _cache[key];
    if (cached?.fingerprint == fingerprint) return cached!.snapshot;

    final structure = _marketStructureEngine.analyze(
      closedCandles,
      confirmedSwings,
      closedAtr,
    );
    final snapshot = PriceActionSmcSnapshot(
      structurePoints: structure.points,
      structureBreaks: structure.breaks,
      orderBlocks: _orderBlockService.detect(
        closedCandles,
        structure.breaks,
        closedAtr,
      ),
      fairValueGaps: _fvgService.detect(closedCandles, closedAtr),
      liquiditySweeps: _liquidityService.detect(
        closedCandles,
        confirmedSwings,
        closedAtr,
      ),
      priceActionPatterns: _priceActionEngine.detect(
        closedCandles,
        closedAtr,
        structure.breaks,
      ),
    );
    _cache[key] = _CachedAnalysis(fingerprint, snapshot);
    return snapshot;
  }

  String _fingerprint(List<Candle> candles) {
    final last = candles.last;
    return '${candles.length}:${last.time.microsecondsSinceEpoch}:'
        '${last.open}:${last.high}:${last.low}:${last.close}:${last.volume}';
  }
}

class _CachedAnalysis {
  const _CachedAnalysis(this.fingerprint, this.snapshot);
  final String fingerprint;
  final PriceActionSmcSnapshot snapshot;
}
