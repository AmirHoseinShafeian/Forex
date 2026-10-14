import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/mock_market_data.dart';
import 'dashboard_card.dart';

class AnalysisPanel extends StatelessWidget {
  const AnalysisPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(11),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.purple, size: 19),
                SizedBox(width: 7),
                Text(
                  'AI Signal / تحلیل نهایی',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                Spacer(),
                DemoBadge(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A65A), Color(0xFF00E58B)],
                      ),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFF4BFFB1)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x3300E58B), blurRadius: 14),
                      ],
                    ),
                    child: const Text(
                      'BUY',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Container(
                  height: 58,
                  width: 100,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'امتیاز تحلیل',
                        style: TextStyle(color: AppColors.green, fontSize: 9),
                      ),
                      Text(
                        '82 / 100',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            const Row(
              children: [
                Expanded(
                  child: _QuickStat(label: 'تایم پیشنهادی', value: 'M15'),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: _QuickStat(
                    label: 'قدرت صعودی',
                    value: 'متوسط',
                    color: AppColors.cyan,
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: _QuickStat(
                    label: 'وضعیت فعلی',
                    value: 'PRZ',
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ...MockMarketData.levels.map(
              (level) => Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Text(
                      level.label,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      level.value,
                      style: TextStyle(
                        color: toneColor(level.tone),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Text(
                    'Risk / Reward',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  Spacer(),
                  Text(
                    '1 : 2.5',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '💡 تحلیل هوشمند مصنوعی (DEMO)',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'الگوی Bullish Gartley در محدوده PRZ شناسایی شده است. تثبیت قیمت بالای ۴٬۱۱۲ می‌تواند احتمال حرکت صعودی تا اهداف مشخص‌شده را افزایش دهد. این داده صرفاً نمایشی است.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: AppColors.muted,
                height: 1.65,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'وضعیت تایم‌فریم‌ها',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TimeframeSignal('M1', 'WAIT', AppColors.amber),
                _TimeframeSignal('M5', 'BUY', AppColors.green),
                _TimeframeSignal('M15', 'BUY', AppColors.green),
                _TimeframeSignal('M30', 'BUY', AppColors.green),
                _TimeframeSignal('H1', 'SELL', AppColors.red),
                _TimeframeSignal('H4', 'SELL', AppColors.red),
                _TimeframeSignal('D1', 'SELL', AppColors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.label,
    required this.value,
    this.color = AppColors.text,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

class _TimeframeSignal extends StatelessWidget {
  const _TimeframeSignal(this.timeframe, this.signal, this.color);
  final String timeframe;
  final String signal;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 91,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Text(
          timeframe,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
        ),
        const Spacer(),
        Text(
          signal,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 9,
          ),
        ),
      ],
    ),
  );
}
