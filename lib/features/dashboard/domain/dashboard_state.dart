import 'package:equatable/equatable.dart';

import 'market_models.dart';
import 'analysis_models.dart';
import 'harmonic_models.dart';
import 'price_action_models.dart';
import 'trading_decision_models.dart';
import 'economic_news_models.dart';

enum MarketStatus { loading, live, demo, cached, disconnected }

extension MarketStatusDetails on MarketStatus {
  String get dataLabel => switch (this) {
    MarketStatus.loading => 'LOADING',
    MarketStatus.live => 'LIVE',
    MarketStatus.demo => 'DEMO',
    MarketStatus.cached => 'CACHED',
    MarketStatus.disconnected => 'DISCONNECTED',
  };

  String get connectionLabel => switch (this) {
    MarketStatus.loading => 'Connecting',
    MarketStatus.live || MarketStatus.demo => 'Connected',
    MarketStatus.cached || MarketStatus.disconnected => 'Disconnected',
  };

  bool get canReconnect =>
      this == MarketStatus.cached || this == MarketStatus.disconnected;
}

class DashboardState extends Equatable {
  const DashboardState({
    this.selectedMenu = 'Dashboard',
    this.timeframe = 'M15',
    this.selectedSymbol = 'XAUUSD.',
    this.symbols = const [],
    this.marketStatus = MarketStatus.loading,
    this.candles = const [],
    this.tick,
    this.lastUpdatedUtc,
    this.errorMessage = '',
    this.indicators,
    this.zones = const [],
    this.timeframeTrends = const {},
    this.visibleIndicators = const {
      IndicatorLayer.ema20,
      IndicatorLayer.volume,
    },
    this.swings = const [],
    this.patternsByTimeframe = const {},
    this.harmonicDiagnosticsByTimeframe = const {},
    this.harmonicDebugByTimeframe = const {},
    this.marketAnalysisByTimeframe = const {},
    this.fibonacci,
    this.selectedPatternId,
    this.selectedMarketDetectionId,
    this.hiddenPatternIds = const {},
    this.showAllPatterns = false,
    this.tradingDecision = const TradingDecision.unavailable(),
    this.economicCalendar = const EconomicCalendarSnapshot(),
    this.newsRisk = const NewsRiskSnapshot.none(),
    this.alerts = const [],
  });

  final String selectedMenu;
  final String timeframe;
  final String selectedSymbol;
  final List<MarketSymbol> symbols;
  final MarketStatus marketStatus;
  final List<Candle> candles;
  final MarketTick? tick;
  final DateTime? lastUpdatedUtc;
  final String errorMessage;
  final IndicatorSnapshot? indicators;
  final List<PriceZone> zones;
  final Map<String, TrendAnalysis> timeframeTrends;
  final Set<IndicatorLayer> visibleIndicators;
  final List<SwingPoint> swings;
  final Map<String, List<HarmonicPattern>> patternsByTimeframe;
  final Map<String, List<HarmonicDiagnostic>> harmonicDiagnosticsByTimeframe;
  final Map<String, HarmonicDebugSnapshot> harmonicDebugByTimeframe;
  final Map<String, PriceActionSmcSnapshot> marketAnalysisByTimeframe;
  final FibonacciAnalysis? fibonacci;
  final String? selectedPatternId;
  final String? selectedMarketDetectionId;
  final Set<String> hiddenPatternIds;
  final bool showAllPatterns;
  final TradingDecision tradingDecision;
  final EconomicCalendarSnapshot economicCalendar;
  final NewsRiskSnapshot newsRisk;
  final List<AppAlert> alerts;

  DashboardState copyWith({
    String? selectedMenu,
    String? timeframe,
    String? selectedSymbol,
    List<MarketSymbol>? symbols,
    MarketStatus? marketStatus,
    List<Candle>? candles,
    MarketTick? tick,
    bool clearTick = false,
    DateTime? lastUpdatedUtc,
    bool clearLastUpdated = false,
    String? errorMessage,
    IndicatorSnapshot? indicators,
    bool clearIndicators = false,
    List<PriceZone>? zones,
    Map<String, TrendAnalysis>? timeframeTrends,
    Set<IndicatorLayer>? visibleIndicators,
    List<SwingPoint>? swings,
    Map<String, List<HarmonicPattern>>? patternsByTimeframe,
    Map<String, List<HarmonicDiagnostic>>? harmonicDiagnosticsByTimeframe,
    Map<String, HarmonicDebugSnapshot>? harmonicDebugByTimeframe,
    Map<String, PriceActionSmcSnapshot>? marketAnalysisByTimeframe,
    FibonacciAnalysis? fibonacci,
    bool clearFibonacci = false,
    String? selectedPatternId,
    bool clearSelectedPattern = false,
    String? selectedMarketDetectionId,
    bool clearSelectedMarketDetection = false,
    Set<String>? hiddenPatternIds,
    bool? showAllPatterns,
    TradingDecision? tradingDecision,
    EconomicCalendarSnapshot? economicCalendar,
    NewsRiskSnapshot? newsRisk,
    List<AppAlert>? alerts,
  }) {
    return DashboardState(
      selectedMenu: selectedMenu ?? this.selectedMenu,
      timeframe: timeframe ?? this.timeframe,
      selectedSymbol: selectedSymbol ?? this.selectedSymbol,
      symbols: symbols ?? this.symbols,
      marketStatus: marketStatus ?? this.marketStatus,
      candles: candles ?? this.candles,
      tick: clearTick ? null : tick ?? this.tick,
      lastUpdatedUtc: clearLastUpdated
          ? null
          : lastUpdatedUtc ?? this.lastUpdatedUtc,
      errorMessage: errorMessage ?? this.errorMessage,
      indicators: clearIndicators ? null : indicators ?? this.indicators,
      zones: zones ?? this.zones,
      timeframeTrends: timeframeTrends ?? this.timeframeTrends,
      visibleIndicators: visibleIndicators ?? this.visibleIndicators,
      swings: swings ?? this.swings,
      patternsByTimeframe: patternsByTimeframe ?? this.patternsByTimeframe,
      harmonicDiagnosticsByTimeframe:
          harmonicDiagnosticsByTimeframe ?? this.harmonicDiagnosticsByTimeframe,
      harmonicDebugByTimeframe:
          harmonicDebugByTimeframe ?? this.harmonicDebugByTimeframe,
      marketAnalysisByTimeframe:
          marketAnalysisByTimeframe ?? this.marketAnalysisByTimeframe,
      fibonacci: clearFibonacci ? null : fibonacci ?? this.fibonacci,
      selectedPatternId: clearSelectedPattern
          ? null
          : selectedPatternId ?? this.selectedPatternId,
      selectedMarketDetectionId: clearSelectedMarketDetection
          ? null
          : selectedMarketDetectionId ?? this.selectedMarketDetectionId,
      hiddenPatternIds: hiddenPatternIds ?? this.hiddenPatternIds,
      showAllPatterns: showAllPatterns ?? this.showAllPatterns,
      tradingDecision: tradingDecision ?? this.tradingDecision,
      economicCalendar: economicCalendar ?? this.economicCalendar,
      newsRisk: newsRisk ?? this.newsRisk,
      alerts: alerts ?? this.alerts,
    );
  }

  @override
  List<Object?> get props => [
    selectedMenu,
    timeframe,
    selectedSymbol,
    symbols,
    marketStatus,
    candles,
    tick,
    lastUpdatedUtc,
    errorMessage,
    indicators,
    zones,
    timeframeTrends,
    visibleIndicators,
    swings,
    patternsByTimeframe,
    harmonicDiagnosticsByTimeframe,
    harmonicDebugByTimeframe,
    marketAnalysisByTimeframe,
    fibonacci,
    selectedPatternId,
    selectedMarketDetectionId,
    hiddenPatternIds,
    showAllPatterns,
    tradingDecision,
    economicCalendar,
    newsRisk,
    alerts,
  ];
}
