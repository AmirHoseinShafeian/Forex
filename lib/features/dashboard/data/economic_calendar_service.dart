import '../domain/economic_news_models.dart';
import '../domain/services/news_impact_analysis_service.dart';
import 'forex_factory_calendar_provider.dart';
import 'market_database.dart';

class EconomicCalendarService {
  const EconomicCalendarService({
    required this.database,
    this.provider = const ForexFactoryCalendarProvider(),
    this.analysisService = const NewsImpactAnalysisService(),
  });

  final MarketDatabase database;
  final ForexFactoryCalendarProvider provider;
  final NewsImpactAnalysisService analysisService;

  Future<EconomicCalendarSnapshot> loadCached() async {
    final events = await database.loadEconomicEvents();
    final lastUpdated = events.isEmpty
        ? null
        : events
              .map((event) => event.lastUpdatedUtc)
              .reduce((a, b) => a.isAfter(b) ? a : b);
    return EconomicCalendarSnapshot(
      events: events,
      analyses: _analyze(events),
      status: events.isEmpty
          ? NewsDataStatus.unavailable
          : NewsDataStatus.cached,
      lastUpdatedUtc: lastUpdated,
    );
  }

  Future<EconomicCalendarSnapshot> import(
    String contents,
    String extension,
  ) async {
    final events = provider.parse(contents, extension);
    await database.upsertEconomicEvents(events);
    final merged = await database.loadEconomicEvents();
    return EconomicCalendarSnapshot(
      events: merged,
      analyses: _analyze(merged),
      status: NewsDataStatus.imported,
      lastUpdatedUtc: DateTime.now().toUtc(),
    );
  }

  Future<EconomicCalendarSnapshot> correctTime(
    String eventId,
    DateTime correctedUtc,
  ) async {
    await database.correctEconomicEventTime(eventId, correctedUtc);
    final events = await database.loadEconomicEvents();
    return EconomicCalendarSnapshot(
      events: events,
      analyses: _analyze(events),
      status: NewsDataStatus.imported,
      lastUpdatedUtc: DateTime.now().toUtc(),
    );
  }

  Map<String, NewsImpactAnalysis> _analyze(List<EconomicEvent> events) => {
    for (final event in events) event.id: analysisService.analyze(event),
  };
}
