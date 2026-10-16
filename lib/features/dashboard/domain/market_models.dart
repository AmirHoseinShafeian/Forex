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
  final int volume;

  factory Candle.fromJson(Map<String, dynamic> json) {
    final openTime = DateTime.tryParse(json['openTimeUtc'] as String? ?? '');
    final open = _number(json, 'open');
    final high = _number(json, 'high');
    final low = _number(json, 'low');
    final close = _number(json, 'close');
    final volume = json['tickVolume'];
    if (openTime == null ||
        volume is! num ||
        volume < 0 ||
        high < open ||
        high < close ||
        low > open ||
        low > close) {
      throw const FormatException('Invalid candle payload');
    }
    return Candle(
      time: openTime.toUtc(),
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume.toInt(),
    );
  }
}

class MarketTick {
  const MarketTick({
    required this.symbol,
    required this.timeUtc,
    required this.bid,
    required this.ask,
    required this.last,
    required this.lastPriceSource,
    required this.spreadPrice,
    required this.spreadPoints,
    required this.digits,
    required this.point,
  });

  final String symbol;
  final DateTime timeUtc;
  final double bid;
  final double ask;
  final double last;
  final String lastPriceSource;
  final double spreadPrice;
  final double spreadPoints;
  final int digits;
  final double point;

  factory MarketTick.fromJson(Map<String, dynamic> json) {
    final time = DateTime.tryParse(json['timeUtc'] as String? ?? '');
    final bid = _number(json, 'bid');
    final ask = _number(json, 'ask');
    final last = _number(json, 'last');
    final point = _number(json, 'point');
    final digits = json['digits'];
    if (time == null ||
        bid <= 0 ||
        ask < bid ||
        last <= 0 ||
        point <= 0 ||
        digits is! num) {
      throw const FormatException('Invalid tick payload');
    }
    return MarketTick(
      symbol: json['symbol'] as String? ?? '',
      timeUtc: time.toUtc(),
      bid: bid,
      ask: ask,
      last: last,
      lastPriceSource: json['lastPriceSource'] as String? ?? 'last',
      spreadPrice: _number(json, 'spreadPrice'),
      spreadPoints: _number(json, 'spreadPoints'),
      digits: digits.toInt(),
      point: point,
    );
  }

  String format(double value) => value.toStringAsFixed(digits);
}

class MarketSymbol {
  const MarketSymbol({
    required this.name,
    required this.digits,
    required this.description,
    required this.visible,
  });

  final String name;
  final int digits;
  final String description;
  final bool visible;

  factory MarketSymbol.fromJson(Map<String, dynamic> json) => MarketSymbol(
    name: json['name'] as String? ?? '',
    digits: (json['digits'] as num?)?.toInt() ?? 0,
    description: json['description'] as String? ?? '',
    visible: json['visible'] as bool? ?? false,
  );
}

class BridgeHealth {
  const BridgeHealth({
    required this.connected,
    required this.mode,
    this.errorMessage,
  });

  final bool connected;
  final String mode;
  final String? errorMessage;

  bool get isMock => mode == 'mock';

  factory BridgeHealth.fromJson(Map<String, dynamic> json) {
    final mode = json['mode'];
    if (json['connected'] is! bool || (mode != 'live' && mode != 'mock')) {
      throw const FormatException('Invalid health payload');
    }
    return BridgeHealth(
      connected: json['connected'] as bool,
      mode: mode as String,
      errorMessage: json['error'] as String?,
    );
  }
}

double _number(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('Invalid numeric field: $key');
  }
  return value.toDouble();
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
