import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/market_models.dart';

class BridgeApiException implements Exception {
  const BridgeApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class BridgeApiClient {
  BridgeApiClient({Uri? baseUri})
    : baseUri = baseUri ?? Uri.parse('http://127.0.0.1:8765'),
      _client = HttpClient()..connectionTimeout = const Duration(seconds: 3);

  final Uri baseUri;
  final HttpClient _client;

  Future<BridgeHealth> health() async =>
      BridgeHealth.fromJson(await _get('/health'));

  Future<List<MarketSymbol>> symbols() async {
    final json = await _get('/symbols');
    final values = json['symbols'];
    if (values is! List) throw const FormatException('Invalid symbols payload');
    return values
        .whereType<Map<String, dynamic>>()
        .map(MarketSymbol.fromJson)
        .where((symbol) => symbol.name.isNotEmpty)
        .toList();
  }

  Future<MarketTick> tick(String symbol) async {
    return MarketTick.fromJson(await _get('/tick', {'symbol': symbol}));
  }

  Future<List<Candle>> candles(
    String symbol,
    String timeframe, {
    int count = 500,
  }) async {
    final json = await _get('/candles', {
      'symbol': symbol,
      'timeframe': timeframe,
      'count': '$count',
    });
    final values = json['candles'];
    if (values is! List) throw const FormatException('Invalid candles payload');
    return values
        .whereType<Map<String, dynamic>>()
        .map(Candle.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    final uri = baseUri.replace(path: path, queryParameters: query);
    try {
      final request = await _client
          .getUrl(uri)
          .timeout(const Duration(seconds: 4));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      final body = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = decoded is Map<String, dynamic>
            ? decoded['detail']
            : null;
        final message = detail is Map<String, dynamic>
            ? detail['message']?.toString()
            : detail?.toString();
        throw BridgeApiException(
          message ?? 'Bridge returned HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Bridge response must be a JSON object');
      }
      return decoded;
    } on BridgeApiException {
      rethrow;
    } on TimeoutException {
      throw const BridgeApiException('Bridge request timed out');
    } on SocketException {
      throw const BridgeApiException('Local MT5 Bridge is unavailable');
    }
  }

  void close() => _client.close(force: true);
}
