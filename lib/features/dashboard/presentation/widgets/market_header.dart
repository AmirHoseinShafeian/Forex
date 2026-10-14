import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/mock_market_data.dart';
import '../../domain/dashboard_state.dart';
import '../dashboard_cubit.dart';
import 'dashboard_card.dart';

class MarketHeader extends StatelessWidget {
  const MarketHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Text(
                      'XAUUSD',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Gold Spot / U.S. Dollar',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    SizedBox(width: 10),
                    DemoBadge(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: .35),
                  ),
                ),
                child: const Text(
                  '●  داده متصل (DEMO)',
                  style: TextStyle(color: AppColors.green, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) => Row(
                  children: MockMarketData.timeframes.map((timeframe) {
                    final selected = timeframe == state.timeframe;
                    return Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: InkWell(
                        key: ValueKey('timeframe-$timeframe'),
                        onTap: () => context
                            .read<DashboardCubit>()
                            .selectTimeframe(timeframe),
                        borderRadius: BorderRadius.circular(7),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF0A477C)
                                : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: selected
                                  ? AppColors.cyan
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            timeframe,
                            style: TextStyle(
                              fontSize: 11,
                              color: selected ? Colors.white : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Spacer(),
              const Text(
                'قیمت فعلی',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              const SizedBox(width: 8),
              const Text(
                '4,121.320 DEMO',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '+4.305  (+0.10%)',
                style: TextStyle(color: AppColors.green, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: MockMarketData.metrics.map((metric) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.label,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metric.value,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: toneColor(metric.tone),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
