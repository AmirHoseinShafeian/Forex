class Candle {
  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}

class MarketMetric {
  const MarketMetric(this.label, this.value, {this.tone = 'neutral'});
  final String label;
  final String value;
  final String tone;
}

class AnalysisLevel {
  const AnalysisLevel(this.label, this.value, this.tone);
  final String label;
  final String value;
  final String tone;
}
