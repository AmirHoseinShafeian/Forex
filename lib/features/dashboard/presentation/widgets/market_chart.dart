import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/mock_market_data.dart';
import 'dashboard_card.dart';

class MarketChart extends StatelessWidget {
  const MarketChart({required this.timeframe, super.key});

  final String timeframe;

  @override
  Widget build(BuildContext context) {
    final candles = MockMarketData.candles;
    final spots = candles.indexed
        .map(
          (entry) => CandlestickSpot(
            x: entry.$1.toDouble(),
            open: entry.$2.open,
            high: entry.$2.high,
            low: entry.$2.low,
            close: entry.$2.close,
          ),
        )
        .toList();
    final minY = candles.map((c) => c.low).reduce(math.min) - 2;
    final maxY = candles.map((c) => c.high).reduce(math.max) + 2;

    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 5),
            child: Row(
              children: [
                Text(
                  'XAUUSD · $timeframe · DEMO',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
                const Text(
                  'O 4,117.885   H 4,122.325   L 4,117.855   C 4,121.320',
                  style: TextStyle(color: AppColors.green, fontSize: 10),
                ),
                const Spacer(),
                const Icon(Icons.zoom_in, size: 17, color: AppColors.muted),
                const SizedBox(width: 5),
                const Text(
                  'Scroll: Zoom  •  Drag: Pan',
                  style: TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CandlestickChart(
                    CandlestickChartData(
                      candlestickSpots: spots,
                      minX: 0,
                      maxX: (spots.length - 1).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      backgroundColor: AppColors.background,
                      candlestickPainter: DefaultCandlestickPainter(
                        candlestickStyleProvider: (spot, _) {
                          final color = spot.isUp
                              ? AppColors.green
                              : AppColors.red;
                          return CandlestickStyle(
                            lineColor: color,
                            lineWidth: 1,
                            bodyStrokeColor: color,
                            bodyStrokeWidth: 1,
                            bodyFillColor: color.withValues(alpha: .82),
                            bodyWidth: 5,
                            bodyRadius: 1,
                          );
                        },
                      ),
                      gridData: FlGridData(
                        verticalInterval: 8,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.border.withValues(alpha: .48),
                          strokeWidth: .7,
                        ),
                        getDrawingVerticalLine: (_) => FlLine(
                          color: AppColors.border.withValues(alpha: .35),
                          strokeWidth: .7,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppColors.border),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            interval: 10,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 12,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${(value ~/ 4).toString().padLeft(2, '0')}:00',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    duration: Duration.zero,
                    transformationConfig: const FlTransformationConfig(
                      scaleAxis: FlScaleAxis.horizontal,
                      minScale: 1,
                      maxScale: 6,
                      panEnabled: true,
                      scaleEnabled: true,
                      trackpadScrollCausesScale: true,
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: TechnicalOverlayPainter()),
                  ),
                ),
                const Positioned(
                  left: 12,
                  top: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMA 20   4,119.842',
                        style: TextStyle(color: AppColors.cyan, fontSize: 9),
                      ),
                      Text(
                        'EMA 50   4,123.156',
                        style: TextStyle(color: AppColors.amber, fontSize: 9),
                      ),
                      Text(
                        'EMA 200  4,135.421',
                        style: TextStyle(color: AppColors.red, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 82,
            padding: const EdgeInsets.fromLTRB(8, 4, 55, 4),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: 22,
                    alignment: BarChartAlignment.spaceAround,
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 7,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.border.withValues(alpha: .35),
                        strokeWidth: .6,
                      ),
                    ),
                    barTouchData: BarTouchData(enabled: false),
                    barGroups: candles.indexed.map((entry) {
                      final up = entry.$2.close >= entry.$2.open;
                      return BarChartGroupData(
                        x: entry.$1,
                        barRods: [
                          BarChartRodData(
                            toY: entry.$2.volume,
                            width: 4,
                            color: (up ? AppColors.green : AppColors.red)
                                .withValues(alpha: .65),
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  duration: Duration.zero,
                ),
                const Positioned(
                  left: 6,
                  top: 3,
                  child: Text(
                    'Volume  10.96K DEMO',
                    style: TextStyle(color: AppColors.muted, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TechnicalOverlayPainter extends CustomPainter {
  const TechnicalOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(18, 15, size.width - 78, size.height - 32);
    Offset p(double x, double y) =>
        Offset(chart.left + chart.width * x, chart.top + chart.height * y);

    final ema = Paint()
      ..color = AppColors.cyan.withValues(alpha: .75)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final emaPath = Path()..moveTo(p(0, .44).dx, p(0, .44).dy);
    for (var i = 1; i <= 40; i++) {
      final x = i / 40;
      final y = .46 + math.sin(i * .33) * .035 + x * .05;
      emaPath.lineTo(p(x, y).dx, p(x, y).dy);
    }
    canvas.drawPath(emaPath, ema);

    for (final level in <(double, Color)>[
      (.19, AppColors.green),
      (.31, AppColors.green),
      (.47, AppColors.green),
      (.82, AppColors.red),
    ]) {
      canvas.drawLine(
        p(.61, level.$1),
        p(1, level.$1),
        Paint()
          ..color = level.$2.withValues(alpha: .72)
          ..strokeWidth = 1,
      );
    }

    final prz = Rect.fromPoints(p(.67, .65), p(.97, .76));
    canvas.drawRect(
      prz,
      Paint()..color = AppColors.green.withValues(alpha: .13),
    );
    canvas.drawRect(
      prz,
      Paint()
        ..color = AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    _label(canvas, p(.82, .685), 'PRZ  4,108 - 4,112', AppColors.green);

    const harmonic = <(double, double)>[
      (.25, .23),
      (.39, .72),
      (.48, .46),
      (.58, .69),
      (.68, .57),
    ];
    final path = Path()
      ..moveTo(
        p(harmonic.first.$1, harmonic.first.$2).dx,
        p(harmonic.first.$1, harmonic.first.$2).dy,
      );
    for (final point in harmonic.skip(1)) {
      path.lineTo(p(point.$1, point.$2).dx, p(point.$1, point.$2).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.purple
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < harmonic.length; i++) {
      _label(
        canvas,
        p(harmonic[i].$1, harmonic[i].$2),
        ['X', 'A', 'B', 'C', 'D'][i],
        AppColors.purple,
      );
    }
    _label(canvas, p(.43, .17), 'Bullish Gartley', AppColors.purple);
    _label(canvas, p(.87, .17), 'TP3  4,145', AppColors.green);
    _label(canvas, p(.87, .29), 'TP2  4,137', AppColors.green);
    _label(canvas, p(.87, .45), 'TP1  4,130', AppColors.green);
    _label(canvas, p(.87, .80), 'SL  4,102', AppColors.red);
  }

  void _label(Canvas canvas, Offset point, String text, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        point.dx - 3,
        point.dy - painter.height / 2 - 3,
        painter.width + 7,
        painter.height + 6,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: .82));
    painter.paint(canvas, Offset(point.dx, point.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
