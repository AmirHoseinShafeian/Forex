import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/dashboard_state.dart';
import 'dashboard_cubit.dart';
import 'widgets/analysis_panel.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/bottom_panels.dart';
import 'widgets/market_chart.dart';
import 'widgets/market_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1180;
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
                            child: stackAnalysis
                                ? ListView(
                                    children: [
                                      SizedBox(
                                        height: 500,
                                        child: MarketChart(
                                          timeframe: state.timeframe,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const SizedBox(
                                        height: 570,
                                        child: AnalysisPanel(),
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
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const SizedBox(
                                        width: 330,
                                        child: AnalysisPanel(),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 8),
                          const BottomPanels(),
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
    );
  }
}
