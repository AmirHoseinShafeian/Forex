import 'dart:math' as math;

import '../domain/market_models.dart';

abstract final class MockMarketData {
  static const currentPrice = 4121.320;

  static final List<Candle> candles = List.generate(72, (index) {
    final trend = 4132 - index * 0.20;
    final wave = math.sin(index * 0.52) * 5.2 + math.cos(index * 0.19) * 2.6;
    final open = trend + wave;
    final close = open + math.sin(index * 1.41) * 3.1;
    final wick = 1.5 + (index % 5) * 0.38;
    return Candle(
      time: DateTime(2025, 10, 8, 0, index * 15),
      open: open,
      high: math.max(open, close) + wick,
      low: math.min(open, close) - wick * .9,
      close: close,
      volume: (40 + (index % 9) * 13.5 + math.sin(index * .8).abs() * 60)
          .round(),
    );
  });

  static const metrics = [
    MarketMetric('Bid', '4,121.120 DEMO', tone: 'sell'),
    MarketMetric('Ask', '4,121.530 DEMO', tone: 'buy'),
    MarketMetric('Spread', '42.0 DEMO', tone: 'warning'),
    MarketMetric('Tick Volume', '10.96K DEMO'),
    MarketMetric('High', '4,122.325 DEMO'),
    MarketMetric('Low', '4,117.885 DEMO'),
  ];

  static const levels = [
    AnalysisLevel('Entry', '4,110 - 4,112 DEMO', 'neutral'),
    AnalysisLevel('Stop Loss', '4,102.00 DEMO', 'sell'),
    AnalysisLevel('TP1', '4,130.90 DEMO', 'buy'),
    AnalysisLevel('TP2', '4,137.10 DEMO', 'buy'),
    AnalysisLevel('TP3', '4,145.00 DEMO', 'buy'),
  ];

  static const timeframes = ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1'];
}
