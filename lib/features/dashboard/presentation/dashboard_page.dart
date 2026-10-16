import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../core/settings/app_settings.dart';
import '../domain/dashboard_state.dart';
import '../domain/analysis_models.dart';
import '../domain/harmonic_models.dart';
import '../domain/price_action_models.dart';
import 'dashboard_cubit.dart';
import 'widgets/analysis_panel.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/bottom_panels.dart';
import 'widgets/market_chart.dart';
import 'widgets/market_header.dart';
import 'widgets/trading_decision_panel.dart';
import 'widgets/economic_calendar_panel.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final savedIndicators = IndicatorLayer.values
        .where((layer) => settings.visibleIndicatorNames.contains(layer.name))
        .toSet();
    return BlocProvider(
      create: (_) => DashboardCubit()
        ..setAdvancedMode(
          settings.isAdvanced,
          advancedIndicators: savedIndicators,
        )
        ..setHarmonicDisplaySettings(
          hiddenPatternIds: settings.hiddenHarmonicPatternIds,
          showAll: settings.showAllHarmonicPatterns,
        )
        ..configureNewsRisk(
          beforeMinutes: settings.newsRiskBeforeMinutes,
          afterMinutes: settings.newsRiskAfterMinutes,
        )
        ..configureAlerts(settings.enabledAlertTypes)
        ..initializeNews()
        ..initialize(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return BlocListener<DashboardCubit, DashboardState>(
      listenWhen: (previous, current) =>
          current.alerts.isNotEmpty &&
          current.alerts.length > previous.alerts.length &&
          DateTime.now().toUtc().difference(
                current.alerts.first.occurredAtUtc,
              ) <
              const Duration(seconds: 5),
      listener: (context, state) {
        if (settings.silentAlerts) return;
        final alert = state.alerts.first;
        if (settings.alertSound) {
          SystemSound.play(SystemSoundType.alert);
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${alert.title}: ${alert.message}'),
              duration: const Duration(seconds: 4),
            ),
          );
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                settings.sidebarCollapsed || constraints.maxWidth < 1180;
            final stackAnalysis = constraints.maxWidth < 980;
            return Row(
              children: [
                if (constraints.maxWidth >= 720) AppSidebar(compact: compact),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: BlocBuilder<DashboardCubit, DashboardState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            const MarketHeader(),
                            const SizedBox(height: 8),
                            Expanded(
                              child: state.selectedMenu == 'news'
                                  ? const EconomicCalendarPanel()
                                  : state.selectedMenu == 'alerts'
                                  ? const AlertsPanel()
                                  : stackAnalysis
                                  ? ListView(
                                      children: [
                                        SizedBox(
                                          height: 500,
                                          child: MarketChart(
                                            timeframe: state.timeframe,
                                            symbol: state.selectedSymbol,
                                            candles: state.candles,
                                            status: state.marketStatus,
                                            digits: state.tick?.digits ?? 3,
                                            indicators: state.indicators,
                                            zones: state.zones,
                                            visibleIndicators:
                                                state.visibleIndicators,
                                            advancedMode: settings.isAdvanced,
                                            patterns:
                                                state.patternsByTimeframe[state
                                                    .timeframe] ??
                                                const [],
                                            fibonacci: state.fibonacci,
                                            selectedPatternId:
                                                state.selectedPatternId,
                                            hiddenPatternIds:
                                                state.hiddenPatternIds,
                                            showAllPatterns:
                                                state.showAllPatterns,
                                            marketAnalysis:
                                                state
                                                    .marketAnalysisByTimeframe[state
                                                    .timeframe] ??
                                                const PriceActionSmcSnapshot.empty(),
                                            selectedMarketDetectionId:
                                                state.selectedMarketDetectionId,
                                            tradingDecision:
                                                state.tradingDecision,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 350,
                                          child: TradingDecisionPanel(
                                            decision: state.tradingDecision,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 570,
                                          child: AnalysisPanel(
                                            analysis:
                                                state.timeframeTrends[state
                                                    .timeframe],
                                            timeframeTrends:
                                                state.timeframeTrends,
                                            indicators: state.indicators,
                                            marketAnalysis:
                                                state
                                                    .marketAnalysisByTimeframe[state
                                                    .timeframe] ??
                                                const PriceActionSmcSnapshot.empty(),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: MarketChart(
                                            timeframe: state.timeframe,
                                            symbol: state.selectedSymbol,
                                            candles: state.candles,
                                            status: state.marketStatus,
                                            digits: state.tick?.digits ?? 3,
                                            indicators: state.indicators,
                                            zones: state.zones,
                                            visibleIndicators:
                                                state.visibleIndicators,
                                            advancedMode: settings.isAdvanced,
                                            patterns:
                                                state.patternsByTimeframe[state
                                                    .timeframe] ??
                                                const [],
                                            fibonacci: state.fibonacci,
                                            selectedPatternId:
                                                state.selectedPatternId,
                                            hiddenPatternIds:
                                                state.hiddenPatternIds,
                                            showAllPatterns:
                                                state.showAllPatterns,
                                            marketAnalysis:
                                                state
                                                    .marketAnalysisByTimeframe[state
                                                    .timeframe] ??
                                                const PriceActionSmcSnapshot.empty(),
                                            selectedMarketDetectionId:
                                                state.selectedMarketDetectionId,
                                            tradingDecision:
                                                state.tradingDecision,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 330,
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 350,
                                                child: TradingDecisionPanel(
                                                  decision:
                                                      state.tradingDecision,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: AnalysisPanel(
                                                  analysis:
                                                      state
                                                          .timeframeTrends[state
                                                          .timeframe],
                                                  timeframeTrends:
                                                      state.timeframeTrends,
                                                  indicators: state.indicators,
                                                  marketAnalysis:
                                                      state
                                                          .marketAnalysisByTimeframe[state
                                                          .timeframe] ??
                                                      const PriceActionSmcSnapshot.empty(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            if (settings.isAdvanced) ...[
                              const SizedBox(height: 8),
                              BottomPanels(
                                indicators: state.indicators,
                                patterns:
                                    state.patternsByTimeframe[state
                                        .timeframe] ??
                                    const [],
                                selectedPatternId: state.selectedPatternId,
                                hiddenPatternIds: state.hiddenPatternIds,
                                harmonicDiagnostics:
                                    state.harmonicDiagnosticsByTimeframe[state
                                        .timeframe] ??
                                    const [],
                                harmonicDebug:
                                    state.harmonicDebugByTimeframe[state
                                        .timeframe] ??
                                    const HarmonicDebugSnapshot.empty(),
                                marketAnalysis:
                                    state.marketAnalysisByTimeframe[state
                                        .timeframe] ??
                                    const PriceActionSmcSnapshot.empty(),
                                selectedMarketDetectionId:
                                    state.selectedMarketDetectionId,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
