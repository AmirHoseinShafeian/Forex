import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/bridge_api_client.dart';
import '../data/market_database.dart';
import '../data/mock_market_data.dart';
import '../data/economic_calendar_service.dart';
import '../domain/dashboard_state.dart';
import '../domain/analysis_models.dart';
import '../domain/market_models.dart';
import '../domain/harmonic_models.dart';
import '../domain/price_action_models.dart';
import '../domain/trading_decision_models.dart';
import '../domain/economic_news_models.dart';
import '../domain/services/fibonacci_analysis_service.dart';
import '../domain/services/harmonic_pattern_engine.dart';
import '../domain/services/indicator_engine.dart';
import '../domain/services/support_resistance_service.dart';
import '../domain/services/trend_analysis_service.dart';
import '../domain/services/trading_decision_engine.dart';
import '../domain/services/swing_detection_service.dart';
import '../domain/services/price_action_smc_analysis_service.dart';
import '../domain/services/news_risk_filter.dart';
import '../domain/services/alert_engine.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    BridgeApiClient? apiClient,
    MarketDatabase? database,
    IndicatorEngine? indicatorEngine,
    TrendAnalysisService? trendAnalysisService,
    SupportResistanceService? supportResistanceService,
    SwingDetectionService? swingDetectionService,
    HarmonicPatternEngine? harmonicPatternEngine,
    FibonacciAnalysisService? fibonacciAnalysisService,
    PriceActionSmcAnalysisService? priceActionSmcAnalysisService,
    TradingDecisionEngine? tradingDecisionEngine,
    EconomicCalendarService? economicCalendarService,
    this.pollingInterval = const Duration(seconds: 1),
  }) : _apiClient = apiClient ?? BridgeApiClient(),
       _database = database ?? MarketDatabase(),
       _indicatorEngine = indicatorEngine ?? IndicatorEngine(),
       _trendAnalysisService =
           trendAnalysisService ?? const TrendAnalysisService(),
       _supportResistanceService =
           supportResistanceService ?? const SupportResistanceService(),
       _swingDetectionService =
           swingDetectionService ?? const SwingDetectionService(),
       _harmonicPatternEngine =
           harmonicPatternEngine ?? const HarmonicPatternEngine(),
       _fibonacciAnalysisService =
           fibonacciAnalysisService ?? const FibonacciAnalysisService(),
       _priceActionSmcAnalysisService =
           priceActionSmcAnalysisService ?? PriceActionSmcAnalysisService(),
       _tradingDecisionEngine =
           tradingDecisionEngine ?? const TradingDecisionEngine(),
       super(const DashboardState()) {
    _economicCalendarService =
        economicCalendarService ?? EconomicCalendarService(database: _database);
  }

  final BridgeApiClient _apiClient;
  final MarketDatabase _database;
  final IndicatorEngine _indicatorEngine;
  final TrendAnalysisService _trendAnalysisService;
  final SupportResistanceService _supportResistanceService;
  final SwingDetectionService _swingDetectionService;
  final HarmonicPatternEngine _harmonicPatternEngine;
  final FibonacciAnalysisService _fibonacciAnalysisService;
  final PriceActionSmcAnalysisService _priceActionSmcAnalysisService;
  final TradingDecisionEngine _tradingDecisionEngine;
  late final EconomicCalendarService _economicCalendarService;
  NewsRiskFilter _newsRiskFilter = const NewsRiskFilter();
  final AlertEngine _alertEngine = AlertEngine();
  Set<String> _enabledAlertTypes = AlertType.values
      .map((item) => item.name)
      .toSet();
  final Duration pollingInterval;

  Timer? _timer;
  bool _requestInFlight = false;
  bool _pendingFullRefresh = false;
  int _requestEpoch = 0;
  int _retryCount = 0;
  bool _disposed = false;
  bool _bridgeIsMock = false;
  String? _multiTimeframeSymbol;
  final Map<String, _HarmonicCacheEntry> _harmonicCache = {};

  Future<void> initializeNews() async {
    try {
      final calendar = await _economicCalendarService.loadCached();
      final alerts = await _database.loadAlerts();
      emit(state.copyWith(economicCalendar: calendar, alerts: alerts));
    } catch (error) {
      emit(
        state.copyWith(
          economicCalendar: EconomicCalendarSnapshot(
            status: NewsDataStatus.unavailable,
            errorMessage: error.toString(),
          ),
        ),
      );
    }
  }

  void configureNewsRisk({
    required int beforeMinutes,
    required int afterMinutes,
  }) {
    _newsRiskFilter = NewsRiskFilter(
      before: Duration(minutes: beforeMinutes),
      after: Duration(minutes: afterMinutes),
    );
  }

  void configureAlerts(Set<String> enabledTypes) {
    _enabledAlertTypes = Set.unmodifiable(enabledTypes);
  }

  Future<void> importEconomicCalendar(String contents, String extension) async {
    emit(
      state.copyWith(
        economicCalendar: EconomicCalendarSnapshot(
          events: state.economicCalendar.events,
          analyses: state.economicCalendar.analyses,
          status: NewsDataStatus.loading,
          lastUpdatedUtc: state.economicCalendar.lastUpdatedUtc,
        ),
      ),
    );
    try {
      final calendar = await _economicCalendarService.import(
        contents,
        extension,
      );
      final risk = _newsRiskFilter.evaluate(
        events: calendar.events,
        status: calendar.status,
        nowUtc: DateTime.now().toUtc(),
      );
      final previousById = {
        for (final event in state.economicCalendar.events) event.id: event,
      };
      final revisionAlerts = <AppAlert>[];
      for (final event in calendar.events) {
        final previous = previousById[event.id];
        if (previous == null) continue;
        if (previous.actual != event.actual ||
            previous.forecast != event.forecast ||
            previous.previous != event.previous) {
          revisionAlerts.add(
            AppAlert(
              id: 'revision:${event.id}:${event.actual}:${event.forecast}:${event.previous}',
              type: AlertType.newsRevision,
              title: '${event.name} revised',
              message: 'Actual/Forecast/Previous values changed',
              occurredAtUtc: DateTime.now().toUtc(),
            ),
          );
        }
      }
      final eventAlerts = _alertEngine.evaluate(
        nowUtc: DateTime.now().toUtc(),
        events: calendar.events,
        decision: state.tradingDecision,
        marketStatus: state.marketStatus,
      );
      final newAlerts = [
        ...revisionAlerts,
        ...eventAlerts,
      ].where((alert) => _enabledAlertTypes.contains(alert.type.name)).toList();
      if (newAlerts.isNotEmpty) await _database.insertAlerts(newAlerts);
      emit(
        state.copyWith(
          economicCalendar: calendar,
          newsRisk: risk,
          alerts: newAlerts.isEmpty ? state.alerts : _mergeAlerts(newAlerts),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          economicCalendar: EconomicCalendarSnapshot(
            events: state.economicCalendar.events,
            analyses: state.economicCalendar.analyses,
            status: state.economicCalendar.events.isEmpty
                ? NewsDataStatus.unavailable
                : NewsDataStatus.cached,
            lastUpdatedUtc: state.economicCalendar.lastUpdatedUtc,
            errorMessage: error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> correctEconomicEventTime(
    String eventId,
    DateTime correctedUtc,
  ) async {
    final calendar = await _economicCalendarService.correctTime(
      eventId,
      correctedUtc,
    );
    emit(state.copyWith(economicCalendar: calendar));
  }

  Future<void> clearReadAlerts() async {
    await _database.clearReadAlerts();
    emit(state.copyWith(alerts: await _database.loadAlerts()));
  }

  Future<void> markAlertRead(String alertId) async {
    await _database.markAlertRead(alertId);
    emit(state.copyWith(alerts: await _database.loadAlerts()));
  }

  Future<void> initialize() async {
    await _showCachedIfAvailable();
    try {
      final health = await _apiClient.health();
      if (!health.connected) {
        throw BridgeApiException(
          health.errorMessage ?? 'MT5 terminal is not connected',
        );
      }
      _bridgeIsMock = health.isMock;
      final symbols = await _apiClient.symbols();
      final selected = _chooseSymbol(symbols, state.selectedSymbol);
      emit(state.copyWith(symbols: symbols, selectedSymbol: selected));
      await _refresh(fullHistory: true);
    } catch (error) {
      await _handleFailure(error);
    }
  }

  void selectMenu(String value) => emit(state.copyWith(selectedMenu: value));

  void toggleIndicator(IndicatorLayer indicator, {int? maximumVisible}) {
    final visible = Set<IndicatorLayer>.of(state.visibleIndicators);
    if (visible.contains(indicator)) {
      visible.remove(indicator);
    } else {
      if (maximumVisible != null && visible.length >= maximumVisible) return;
      visible.add(indicator);
    }
    emit(state.copyWith(visibleIndicators: visible));
  }

  void setAdvancedMode(
    bool enabled, {
    Set<IndicatorLayer>? advancedIndicators,
  }) {
    emit(
      state.copyWith(
        visibleIndicators: enabled
            ? advancedIndicators == null || advancedIndicators.isEmpty
                  ? IndicatorLayer.values.toSet()
                  : advancedIndicators
            : const {IndicatorLayer.ema20, IndicatorLayer.volume},
      ),
    );
  }

  void selectPattern(String id) => emit(state.copyWith(selectedPatternId: id));

  void setHarmonicDisplaySettings({
    required Set<String> hiddenPatternIds,
    required bool showAll,
  }) => emit(
    state.copyWith(
      hiddenPatternIds: hiddenPatternIds,
      showAllPatterns: showAll,
    ),
  );

  void selectMarketDetection(String id) =>
      emit(state.copyWith(selectedMarketDetectionId: id));

  void togglePatternVisibility(String id) {
    final hidden = Set<String>.of(state.hiddenPatternIds);
    hidden.contains(id) ? hidden.remove(id) : hidden.add(id);
    emit(state.copyWith(hiddenPatternIds: hidden));
  }

  void toggleShowAllPatterns() =>
      emit(state.copyWith(showAllPatterns: !state.showAllPatterns));

  Future<void> selectTimeframe(String value) async {
    if (value == state.timeframe) return;
    _requestEpoch++;
    _timer?.cancel();
    emit(
      state.copyWith(
        timeframe: value,
        marketStatus: MarketStatus.loading,
        candles: const [],
        errorMessage: '',
        clearSelectedPattern: true,
      ),
    );
    await _showCachedIfAvailable();
    _pendingFullRefresh = true;
    await _refresh(fullHistory: true);
  }

  Future<void> selectSymbol(String value) async {
    if (value == state.selectedSymbol || value.isEmpty) return;
    _requestEpoch++;
    _harmonicCache.clear();
    _multiTimeframeSymbol = null;
    _timer?.cancel();
    emit(
      state.copyWith(
        selectedSymbol: value,
        marketStatus: MarketStatus.loading,
        candles: const [],
        errorMessage: '',
        clearIndicators: true,
        zones: const [],
        timeframeTrends: const {},
        swings: const [],
        patternsByTimeframe: const {},
        harmonicDiagnosticsByTimeframe: const {},
        harmonicDebugByTimeframe: const {},
        marketAnalysisByTimeframe: const {},
        clearFibonacci: true,
        clearTick: true,
        clearLastUpdated: true,
        clearSelectedPattern: true,
        clearSelectedMarketDetection: true,
      ),
    );
    await _showCachedIfAvailable();
    _pendingFullRefresh = true;
    await _refresh(fullHistory: true);
  }

  Future<void> reconnect() async {
    _retryCount = 0;
    _requestEpoch++;
    emit(state.copyWith(marketStatus: MarketStatus.loading));
    await initialize();
  }

  Future<void> _refresh({required bool fullHistory}) async {
    if (_requestInFlight) {
      _pendingFullRefresh = _pendingFullRefresh || fullHistory;
      return;
    }
    _requestInFlight = true;
    final epoch = _requestEpoch;
    final symbol = state.selectedSymbol;
    final timeframe = state.timeframe;
    try {
      final tick = await _apiClient.tick(symbol);
      final incoming = await _apiClient.candles(
        symbol,
        timeframe,
        count: fullHistory ? 500 : 2,
      );
      if (epoch != _requestEpoch ||
          _disposed ||
          symbol != state.selectedSymbol ||
          timeframe != state.timeframe) {
        return;
      }
      if (incoming.isEmpty) {
        throw const FormatException('Bridge returned no candles');
      }
      if (!_bridgeIsMock) {
        await _database.upsertCandles(symbol, timeframe, incoming);
      }
      final candles = fullHistory
          ? incoming
          : _mergeCandles(state.candles, incoming);
      final analysis = _analyze(symbol, timeframe, candles);
      final trends = Map<String, TrendAnalysis>.of(state.timeframeTrends)
        ..[timeframe] = analysis.trend;
      final patterns = Map<String, List<HarmonicPattern>>.of(
        state.patternsByTimeframe,
      )..[timeframe] = analysis.patterns;
      final diagnostics = Map<String, List<HarmonicDiagnostic>>.of(
        state.harmonicDiagnosticsByTimeframe,
      )..[timeframe] = analysis.harmonicDiagnostics;
      final harmonicDebug = Map<String, HarmonicDebugSnapshot>.of(
        state.harmonicDebugByTimeframe,
      )..[timeframe] = analysis.harmonicDebug;
      final marketAnalysis = Map<String, PriceActionSmcSnapshot>.of(
        state.marketAnalysisByTimeframe,
      )..[timeframe] = analysis.marketAnalysis;
      final now = DateTime.now().toUtc();
      final liveStatus = _bridgeIsMock ? MarketStatus.demo : MarketStatus.live;
      final newsRisk = _newsRiskFilter.evaluate(
        events: state.economicCalendar.events,
        status: state.economicCalendar.status,
        nowUtc: now,
      );
      final decision = _decision(
        symbol: symbol,
        timeframe: timeframe,
        status: liveStatus,
        candles: candles,
        tick: tick,
        analysis: analysis,
        timeframeTrends: trends,
        newsRisk: newsRisk,
      );
      final generatedAlerts = _alertEngine.evaluate(
        nowUtc: now,
        events: state.economicCalendar.events,
        decision: decision,
        marketStatus: liveStatus,
        tick: tick,
        atr: analysis.indicators.latestAtr,
        patterns: analysis.patterns,
        marketAnalysis: analysis.marketAnalysis,
      );
      final newAlerts = generatedAlerts
          .where((alert) => _enabledAlertTypes.contains(alert.type.name))
          .toList();
      if (newAlerts.isNotEmpty) await _database.insertAlerts(newAlerts);
      _retryCount = 0;
      emit(
        state.copyWith(
          tick: tick,
          candles: candles,
          marketStatus: liveStatus,
          lastUpdatedUtc: now,
          errorMessage: '',
          indicators: analysis.indicators,
          zones: analysis.zones,
          timeframeTrends: trends,
          swings: analysis.swings,
          patternsByTimeframe: patterns,
          harmonicDiagnosticsByTimeframe: diagnostics,
          harmonicDebugByTimeframe: harmonicDebug,
          marketAnalysisByTimeframe: marketAnalysis,
          fibonacci: analysis.fibonacci,
          clearFibonacci: analysis.fibonacci == null,
          tradingDecision: decision,
          newsRisk: newsRisk,
          alerts: newAlerts.isEmpty ? state.alerts : _mergeAlerts(newAlerts),
        ),
      );
      if (fullHistory && _multiTimeframeSymbol != symbol) {
        await _loadMultiTimeframeTrends(symbol, timeframe, epoch);
        if (epoch == _requestEpoch) _multiTimeframeSymbol = symbol;
      }
      _schedule(pollingInterval, () => _refresh(fullHistory: false));
    } catch (error) {
      if (epoch == _requestEpoch) await _handleFailure(error);
    } finally {
      _requestInFlight = false;
      if (_pendingFullRefresh) {
        _pendingFullRefresh = false;
        _schedule(Duration.zero, () => _refresh(fullHistory: true));
      }
    }
  }

  Future<void> _handleFailure(Object error) async {
    _retryCount++;
    final currentDataCanBeCached =
        state.marketStatus == MarketStatus.live && state.candles.isNotEmpty;
    final loadedFromDatabase = await _showCachedIfAvailable();
    final hasCachedData = currentDataCanBeCached || loadedFromDatabase;
    final failedStatus = hasCachedData
        ? MarketStatus.cached
        : MarketStatus.disconnected;
    final failedDecision = TradingDecision(
      symbol: state.selectedSymbol,
      timeframe: state.timeframe,
      action: TradingDecisionAction.noTrade,
      setupQualityScore: 0,
      trendAlignment: false,
      groups: const [],
      reasonsFor: const [],
      reasonsAgainst: [error.toString()],
      missingConfirmations: const [],
      warnings: const ['No new trade setup is issued'],
      dataQuality: hasCachedData
          ? DecisionDataQuality.stale
          : DecisionDataQuality.unavailable,
      sourceStatus: failedStatus,
      updatedAtUtc: DateTime.now().toUtc(),
      riskPercent: .5,
    );
    final generatedAlerts = _alertEngine.evaluate(
      nowUtc: DateTime.now().toUtc(),
      events: state.economicCalendar.events,
      decision: failedDecision,
      marketStatus: failedStatus,
    );
    final newAlerts = generatedAlerts
        .where((alert) => _enabledAlertTypes.contains(alert.type.name))
        .toList();
    if (newAlerts.isNotEmpty) await _database.insertAlerts(newAlerts);
    emit(
      state.copyWith(
        marketStatus: failedStatus,
        candles: hasCachedData ? state.candles : const [],
        clearTick: !hasCachedData,
        errorMessage: error.toString(),
        tradingDecision: failedDecision,
        alerts: newAlerts.isEmpty ? state.alerts : _mergeAlerts(newAlerts),
      ),
    );
    final seconds = math.min(30, math.pow(2, _retryCount - 1).toInt());
    _schedule(Duration(seconds: seconds), () => _refresh(fullHistory: true));
  }

  List<AppAlert> _mergeAlerts(List<AppAlert> incoming) {
    final byId = <String, AppAlert>{
      for (final alert in incoming) alert.id: alert,
      for (final alert in state.alerts) alert.id: alert,
    };
    final values = byId.values.toList()
      ..sort((a, b) => b.occurredAtUtc.compareTo(a.occurredAtUtc));
    return values.take(200).toList();
  }

  Future<bool> _showCachedIfAvailable() async {
    final cached = await _database.loadCandles(
      state.selectedSymbol,
      state.timeframe,
    );
    if (cached.isNotEmpty) {
      final analysis = _analyze(state.selectedSymbol, state.timeframe, cached);
      final trends = Map<String, TrendAnalysis>.of(state.timeframeTrends)
        ..[state.timeframe] = analysis.trend;
      final patterns = Map<String, List<HarmonicPattern>>.of(
        state.patternsByTimeframe,
      )..[state.timeframe] = analysis.patterns;
      final diagnostics = Map<String, List<HarmonicDiagnostic>>.of(
        state.harmonicDiagnosticsByTimeframe,
      )..[state.timeframe] = analysis.harmonicDiagnostics;
      final harmonicDebug = Map<String, HarmonicDebugSnapshot>.of(
        state.harmonicDebugByTimeframe,
      )..[state.timeframe] = analysis.harmonicDebug;
      final marketAnalysis = Map<String, PriceActionSmcSnapshot>.of(
        state.marketAnalysisByTimeframe,
      )..[state.timeframe] = analysis.marketAnalysis;
      emit(
        state.copyWith(
          candles: cached,
          marketStatus: MarketStatus.cached,
          indicators: analysis.indicators,
          zones: analysis.zones,
          timeframeTrends: trends,
          swings: analysis.swings,
          patternsByTimeframe: patterns,
          harmonicDiagnosticsByTimeframe: diagnostics,
          harmonicDebugByTimeframe: harmonicDebug,
          marketAnalysisByTimeframe: marketAnalysis,
          fibonacci: analysis.fibonacci,
          clearFibonacci: analysis.fibonacci == null,
        ),
      );
      return true;
    }
    return false;
  }

  List<Candle> _mergeCandles(List<Candle> current, List<Candle> incoming) {
    final merged = <int, Candle>{
      for (final candle in current) candle.time.millisecondsSinceEpoch: candle,
      for (final candle in incoming) candle.time.millisecondsSinceEpoch: candle,
    };
    final sorted = merged.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return sorted.length <= 500 ? sorted : sorted.sublist(sorted.length - 500);
  }

  String _chooseSymbol(List<MarketSymbol> symbols, String preferred) {
    if (symbols.any((symbol) => symbol.name == preferred)) return preferred;
    final candidates = symbols.where((symbol) {
      final name = symbol.name.toUpperCase();
      return name.contains('XAU') || name.contains('GOLD');
    }).toList();
    return candidates.isNotEmpty ? candidates.first.name : preferred;
  }

  ({
    IndicatorSnapshot indicators,
    TrendAnalysis trend,
    List<PriceZone> zones,
    List<SwingPoint> swings,
    List<HarmonicPattern> patterns,
    List<HarmonicDiagnostic> harmonicDiagnostics,
    HarmonicDebugSnapshot harmonicDebug,
    FibonacciAnalysis? fibonacci,
    PriceActionSmcSnapshot marketAnalysis,
  })
  _analyze(String symbol, String timeframe, List<Candle> candles) {
    final indicators = _indicatorEngine.calculate(
      '$symbol:$timeframe',
      candles,
    );
    final harmonic = _analyzeHarmonics(symbol, timeframe, candles);
    final swings = harmonic.swings;
    final patterns = harmonic.patterns;
    final harmonicDiagnostics = harmonic.diagnostics;
    final marketAnalysis =
        const {'M5', 'M15', 'M30', 'H1', 'H4'}.contains(timeframe)
        ? _priceActionSmcAnalysisService.analyze(
            key: '$symbol:$timeframe',
            candles: candles,
            indicators: indicators,
            swings: swings,
          )
        : const PriceActionSmcSnapshot.empty();
    return (
      indicators: indicators,
      trend: _trendAnalysisService.analyze(candles, indicators),
      zones: _supportResistanceService.detect(candles),
      swings: swings,
      patterns: patterns,
      harmonicDiagnostics: harmonicDiagnostics,
      harmonicDebug: harmonic.debug,
      fibonacci: _fibonacciAnalysisService.analyze(swings, patterns: patterns),
      marketAnalysis: marketAnalysis,
    );
  }

  TradingDecision _decision({
    required String symbol,
    required String timeframe,
    required MarketStatus status,
    required List<Candle> candles,
    required MarketTick tick,
    required ({
      IndicatorSnapshot indicators,
      TrendAnalysis trend,
      List<PriceZone> zones,
      List<SwingPoint> swings,
      List<HarmonicPattern> patterns,
      List<HarmonicDiagnostic> harmonicDiagnostics,
      HarmonicDebugSnapshot harmonicDebug,
      FibonacciAnalysis? fibonacci,
      PriceActionSmcSnapshot marketAnalysis,
    })
    analysis,
    required Map<String, TrendAnalysis> timeframeTrends,
    required NewsRiskSnapshot newsRisk,
  }) => _tradingDecisionEngine.evaluate(
    TradingDecisionInput(
      symbol: symbol,
      timeframe: timeframe,
      status: status,
      candles: candles,
      tick: tick,
      indicators: analysis.indicators,
      trend: analysis.trend,
      timeframeTrends: timeframeTrends,
      zones: analysis.zones,
      patterns: analysis.patterns,
      fibonacci: analysis.fibonacci,
      marketAnalysis: analysis.marketAnalysis,
      timestampUtc: DateTime.now().toUtc(),
      newsRisk: newsRisk,
    ),
  );

  _HarmonicCacheEntry _analyzeHarmonics(
    String symbol,
    String timeframe,
    List<Candle> candles,
  ) {
    final confirmedCandles = candles.length > 1
        ? candles.sublist(0, candles.length - 1)
        : const <Candle>[];
    final last = confirmedCandles.lastOrNull;
    final signature = last == null
        ? 'empty'
        : '${confirmedCandles.length}:${last.time.millisecondsSinceEpoch}:'
              '${last.open}:${last.high}:${last.low}:${last.close}';
    final key = '$symbol:$timeframe';
    final cached = _harmonicCache[key];
    if (cached != null && cached.signature == signature) return cached;

    final swingScales = _swingDetectionService.detectMultiScale(
      confirmedCandles,
      timeframe,
    );
    final swings = swingScales.isEmpty
        ? const <SwingPoint>[]
        : swingScales[swingScales.length ~/ 2];
    final detected = <String, HarmonicPattern>{};
    final harmonicDiagnostics = <HarmonicDiagnostic>[];
    final swingCounts = <String, int>{};
    var combinationsChecked = 0;
    for (final entry in swingScales.indexed) {
      final scale = entry.$2;
      swingCounts['scale${entry.$1 + 1}'] = scale.length;
      final result = _harmonicPatternEngine.analyze(
        scale,
        timeframe,
        candles: confirmedCandles,
      );
      combinationsChecked += result.combinationsChecked;
      for (final rawPattern in result.patterns) {
        final pattern = rawPattern.scoped(symbol);
        final existing = detected[pattern.id];
        if (existing == null ||
            pattern.geometryScore > existing.geometryScore) {
          detected[pattern.id] = pattern;
        }
      }
      harmonicDiagnostics.addAll(result.diagnostics);
    }
    final patterns = detected.values.toList()
      ..sort((a, b) {
        final time = b.detectedAtUtc.compareTo(a.detectedAtUtc);
        return time != 0 ? time : b.geometryScore.compareTo(a.geometryScore);
      });
    final result = _HarmonicCacheEntry(
      signature: signature,
      swings: swings,
      patterns: List.unmodifiable(patterns),
      diagnostics: List.unmodifiable(
        {
          for (final item in harmonicDiagnostics)
            '${item.reason.name}:${item.detail}': item,
        }.values,
      ),
      debug: HarmonicDebugSnapshot(
        candleCount: confirmedCandles.length,
        swingCounts: Map.unmodifiable(swingCounts),
        combinationsChecked: combinationsChecked,
        validPatternCount: patterns.length,
        diagnostics: List.unmodifiable(
          {
            for (final item in harmonicDiagnostics)
              '${item.reason.name}:${item.detail}': item,
          }.values,
        ),
      ),
    );
    _harmonicCache[key] = result;
    return result;
  }

  Future<void> _loadMultiTimeframeTrends(
    String symbol,
    String selectedTimeframe,
    int epoch,
  ) async {
    final trends = Map<String, TrendAnalysis>.of(state.timeframeTrends);
    final patterns = Map<String, List<HarmonicPattern>>.of(
      state.patternsByTimeframe,
    );
    final diagnostics = Map<String, List<HarmonicDiagnostic>>.of(
      state.harmonicDiagnosticsByTimeframe,
    );
    final harmonicDebug = Map<String, HarmonicDebugSnapshot>.of(
      state.harmonicDebugByTimeframe,
    );
    final marketAnalysis = Map<String, PriceActionSmcSnapshot>.of(
      state.marketAnalysisByTimeframe,
    );
    for (final timeframe in MockMarketData.timeframes) {
      if (timeframe == selectedTimeframe ||
          epoch != _requestEpoch ||
          _disposed) {
        continue;
      }
      try {
        final candles = await _apiClient.candles(symbol, timeframe, count: 250);
        if (!_bridgeIsMock) {
          await _database.upsertCandles(symbol, timeframe, candles);
        }
        final analysis = _analyze(symbol, timeframe, candles);
        trends[timeframe] = analysis.trend;
        patterns[timeframe] = analysis.patterns;
        diagnostics[timeframe] = analysis.harmonicDiagnostics;
        harmonicDebug[timeframe] = analysis.harmonicDebug;
        marketAnalysis[timeframe] = analysis.marketAnalysis;
      } catch (_) {
        final cached = await _database.loadCandles(
          symbol,
          timeframe,
          limit: 250,
        );
        if (cached.isNotEmpty) {
          final analysis = _analyze(symbol, timeframe, cached);
          trends[timeframe] = analysis.trend;
          patterns[timeframe] = analysis.patterns;
          diagnostics[timeframe] = analysis.harmonicDiagnostics;
          harmonicDebug[timeframe] = analysis.harmonicDebug;
          marketAnalysis[timeframe] = analysis.marketAnalysis;
        }
      }
    }
    if (epoch == _requestEpoch && !_disposed) {
      emit(
        state.copyWith(
          timeframeTrends: trends,
          patternsByTimeframe: patterns,
          harmonicDiagnosticsByTimeframe: diagnostics,
          harmonicDebugByTimeframe: harmonicDebug,
          marketAnalysisByTimeframe: marketAnalysis,
        ),
      );
    }
  }

  void _schedule(Duration delay, Future<void> Function() action) {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  @override
  Future<void> close() async {
    _disposed = true;
    _timer?.cancel();
    _apiClient.close();
    await _database.close();
    return super.close();
  }
}

class _HarmonicCacheEntry {
  const _HarmonicCacheEntry({
    required this.signature,
    required this.swings,
    required this.patterns,
    required this.diagnostics,
    required this.debug,
  });

  final String signature;
  final List<SwingPoint> swings;
  final List<HarmonicPattern> patterns;
  final List<HarmonicDiagnostic> diagnostics;
  final HarmonicDebugSnapshot debug;
}
