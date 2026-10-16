import '../dashboard_state.dart';
import '../economic_news_models.dart';
import '../trading_decision_models.dart';
import '../market_models.dart';
import '../harmonic_models.dart';
import '../price_action_models.dart';

class AlertEngine {
  final Set<String> _emitted = {};
  TradingDecisionAction? _lastDecision;
  MarketStatus? _lastMarketStatus;

  List<AppAlert> evaluate({
    required DateTime nowUtc,
    required List<EconomicEvent> events,
    required TradingDecision decision,
    required MarketStatus marketStatus,
    MarketTick? tick,
    double? atr,
    List<HarmonicPattern> patterns = const [],
    PriceActionSmcSnapshot marketAnalysis =
        const PriceActionSmcSnapshot.empty(),
  }) {
    final alerts = <AppAlert>[];
    for (final event in events) {
      final scheduled = event.scheduledUtc;
      if (scheduled == null) continue;
      final minutes = scheduled.difference(nowUtc).inMinutes;
      for (final threshold in const [30, 15, 5, 0]) {
        if (minutes != threshold) continue;
        final type = switch (threshold) {
          30 => AlertType.newsThirtyMinutes,
          15 => AlertType.newsFifteenMinutes,
          5 => AlertType.newsFiveMinutes,
          _ => AlertType.newsRelease,
        };
        _add(
          alerts,
          AppAlert(
            id: 'news:${event.id}:$threshold',
            type: type,
            title: event.name,
            message: threshold == 0
                ? 'Economic event is being released'
                : '$threshold minutes until ${event.impact.name} impact news',
            occurredAtUtc: nowUtc,
          ),
        );
      }
      if (event.actual != null) {
        _add(
          alerts,
          AppAlert(
            id: 'actual:${event.id}:${event.actual}',
            type: AlertType.newsActual,
            title: event.name,
            message: 'Actual: ${event.actual}${event.unit ?? ''}',
            occurredAtUtc: nowUtc,
          ),
        );
      }
    }
    if (_lastDecision != null && _lastDecision != decision.action) {
      _add(
        alerts,
        AppAlert(
          id: 'decision:${decision.symbol}:${decision.timeframe}:${decision.updatedAtUtc?.millisecondsSinceEpoch}',
          type: AlertType.decisionChanged,
          title: 'Trading decision changed',
          message: '${_lastDecision!.name} → ${decision.action.name}',
          occurredAtUtc: nowUtc,
        ),
      );
    }
    if (_lastMarketStatus != null && _lastMarketStatus != marketStatus) {
      final connected =
          marketStatus == MarketStatus.live ||
          marketStatus == MarketStatus.demo;
      _add(
        alerts,
        AppAlert(
          id: 'mt5:${marketStatus.name}:${nowUtc.millisecondsSinceEpoch}',
          type: connected
              ? AlertType.mt5Reconnected
              : AlertType.mt5Disconnected,
          title: connected ? 'MT5 reconnected' : 'MT5 disconnected',
          message: marketStatus.connectionLabel,
          occurredAtUtc: nowUtc,
        ),
      );
    }
    final levels = decision.levels;
    if (tick != null && levels != null) {
      final price = tick.last;
      final tolerance = (levels.entry - levels.stopLoss).abs() * .1;
      if ((price - levels.entry).abs() <= tolerance) {
        _add(
          alerts,
          AppAlert(
            id: 'entry:${decision.symbol}:${decision.timeframe}:${levels.entry}',
            type: AlertType.priceNearEntry,
            title: 'Price near entry',
            message: '$price near ${levels.entry}',
            occurredAtUtc: nowUtc,
          ),
        );
      }
      final bullish = decision.action == TradingDecisionAction.buy;
      if (bullish ? price <= levels.stopLoss : price >= levels.stopLoss) {
        _levelAlert(
          alerts,
          nowUtc,
          'sl',
          AlertType.stopLossReached,
          'Stop loss reached',
          price,
        );
      }
      if (bullish ? price >= levels.takeProfit1 : price <= levels.takeProfit1) {
        _levelAlert(
          alerts,
          nowUtc,
          'tp1',
          AlertType.takeProfitReached,
          'Take profit 1 reached',
          price,
        );
      }
      if (bullish ? price >= levels.takeProfit2 : price <= levels.takeProfit2) {
        _levelAlert(
          alerts,
          nowUtc,
          'tp2',
          AlertType.takeProfitReached,
          'Take profit 2 reached',
          price,
        );
      }
    }
    final harmonic = patterns
        .where((item) => item.status == HarmonicPatternStatus.completed)
        .lastOrNull;
    if (harmonic != null) {
      _add(
        alerts,
        AppAlert(
          id: 'harmonic:${harmonic.id}',
          type: AlertType.harmonicConfirmed,
          title: '${harmonic.displayName} confirmed',
          message: harmonic.direction.name,
          occurredAtUtc: nowUtc,
        ),
      );
    }
    final structure = marketAnalysis.structureBreaks.lastOrNull;
    if (structure != null) {
      _add(
        alerts,
        AppAlert(
          id: 'structure:${structure.id}',
          type: AlertType.structureConfirmed,
          title: structure.type == StructureBreakType.changeOfCharacter
              ? 'CHoCH confirmed'
              : 'BOS confirmed',
          message: structure.direction.name,
          occurredAtUtc: nowUtc,
        ),
      );
    }
    if (tick != null && atr != null && tick.spreadPrice > atr * .08) {
      _add(
        alerts,
        AppAlert(
          id: 'spread:${decision.symbol}:${nowUtc.hour}',
          type: AlertType.abnormalSpread,
          title: 'Abnormal spread',
          message: '${tick.spreadPrice} vs ATR $atr',
          occurredAtUtc: nowUtc,
        ),
      );
    }
    _lastDecision = decision.action;
    _lastMarketStatus = marketStatus;
    return alerts;
  }

  void _add(List<AppAlert> target, AppAlert alert) {
    if (_emitted.add(alert.id)) target.add(alert);
  }

  void _levelAlert(
    List<AppAlert> target,
    DateTime nowUtc,
    String id,
    AlertType type,
    String title,
    double price,
  ) => _add(
    target,
    AppAlert(
      id: '$id:${nowUtc.year}-${nowUtc.month}-${nowUtc.day}',
      type: type,
      title: title,
      message: 'Price: $price',
      occurredAtUtc: nowUtc,
    ),
  );
}
