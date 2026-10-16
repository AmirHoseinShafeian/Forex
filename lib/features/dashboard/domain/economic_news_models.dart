enum NewsImpact { high, medium, low, unknown }

enum EconomicEventStatus { upcoming, released, revised }

enum NewsDataStatus { loading, live, imported, cached, demo, unavailable }

enum PotentialImpact { positive, negative, neutral, uncertain }

enum NewsRiskLevel { none, elevated, blocked }

class EconomicEvent {
  const EconomicEvent({
    required this.id,
    required this.name,
    required this.currency,
    required this.impact,
    required this.status,
    required this.source,
    required this.lastUpdatedUtc,
    required this.rawScheduledTime,
    this.scheduledUtc,
    this.previous,
    this.forecast,
    this.actual,
    this.unit,
    this.timeZoneKnown = true,
  });

  final String id;
  final String name;
  final String currency;
  final NewsImpact impact;
  final DateTime? scheduledUtc;
  final String rawScheduledTime;
  final double? previous;
  final double? forecast;
  final double? actual;
  final String? unit;
  final EconomicEventStatus status;
  final String source;
  final DateTime lastUpdatedUtc;
  final bool timeZoneKnown;

  EconomicEvent copyWith({
    DateTime? scheduledUtc,
    bool? timeZoneKnown,
    double? previous,
    double? forecast,
    double? actual,
    EconomicEventStatus? status,
    DateTime? lastUpdatedUtc,
  }) => EconomicEvent(
    id: id,
    name: name,
    currency: currency,
    impact: impact,
    scheduledUtc: scheduledUtc ?? this.scheduledUtc,
    rawScheduledTime: rawScheduledTime,
    previous: previous ?? this.previous,
    forecast: forecast ?? this.forecast,
    actual: actual ?? this.actual,
    unit: unit,
    status: status ?? this.status,
    source: source,
    lastUpdatedUtc: lastUpdatedUtc ?? this.lastUpdatedUtc,
    timeZoneKnown: timeZoneKnown ?? this.timeZoneKnown,
  );
}

class NewsImpactAnalysis {
  const NewsImpactAnalysis({
    required this.eventId,
    required this.usdImpact,
    required this.xauUsdImpact,
    required this.reason,
    required this.uncertainty,
    this.surprise,
  });

  final String eventId;
  final double? surprise;
  final PotentialImpact usdImpact;
  final PotentialImpact xauUsdImpact;
  final String reason;
  final String uncertainty;
}

class NewsRiskSnapshot {
  const NewsRiskSnapshot({
    required this.level,
    required this.reasons,
    required this.evaluatedAtUtc,
    this.event,
  });

  const NewsRiskSnapshot.none()
    : level = NewsRiskLevel.none,
      reasons = const [],
      evaluatedAtUtc = null,
      event = null;

  final NewsRiskLevel level;
  final List<String> reasons;
  final DateTime? evaluatedAtUtc;
  final EconomicEvent? event;

  bool get blocksNewEntries => level == NewsRiskLevel.blocked;
}

enum AlertType {
  newsThirtyMinutes,
  newsFifteenMinutes,
  newsFiveMinutes,
  newsRelease,
  newsActual,
  newsRevision,
  decisionChanged,
  priceNearEntry,
  stopLossReached,
  takeProfitReached,
  harmonicConfirmed,
  structureConfirmed,
  abnormalSpread,
  mt5Disconnected,
  mt5Reconnected,
}

class AppAlert {
  const AppAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.occurredAtUtc,
    this.read = false,
  });

  final String id;
  final AlertType type;
  final String title;
  final String message;
  final DateTime occurredAtUtc;
  final bool read;
}

class EconomicCalendarSnapshot {
  const EconomicCalendarSnapshot({
    this.events = const [],
    this.analyses = const {},
    this.status = NewsDataStatus.unavailable,
    this.lastUpdatedUtc,
    this.errorMessage = '',
  });

  final List<EconomicEvent> events;
  final Map<String, NewsImpactAnalysis> analyses;
  final NewsDataStatus status;
  final DateTime? lastUpdatedUtc;
  final String errorMessage;
}
