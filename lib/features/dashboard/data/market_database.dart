import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../domain/market_models.dart' as domain;
import '../domain/economic_news_models.dart' as news;

part 'market_database.g.dart';

@TableIndex(
  name: 'candles_symbol_timeframe_time_idx',
  columns: {#symbol, #timeframe, #openTimeUtc},
  unique: true,
)
class StoredCandles extends Table {
  TextColumn get symbol => text()();
  TextColumn get timeframe => text()();
  DateTimeColumn get openTimeUtc => dateTime()();
  RealColumn get open => real()();
  RealColumn get high => real()();
  RealColumn get low => real()();
  RealColumn get close => real()();
  IntColumn get tickVolume => integer()();

  @override
  String get tableName => 'candles';
}

class StoredEconomicEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get name => text()();
  TextColumn get currency => text()();
  TextColumn get impact => text()();
  DateTimeColumn get scheduledUtc => dateTime().nullable()();
  TextColumn get rawScheduledTime => text()();
  RealColumn get previous => real().nullable()();
  RealColumn get forecast => real().nullable()();
  RealColumn get actual => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get eventStatus => text()();
  TextColumn get source => text()();
  DateTimeColumn get lastUpdatedUtc => dateTime()();
  BoolColumn get timeZoneKnown => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {eventId};

  @override
  String get tableName => 'economic_events';
}

class StoredAlerts extends Table {
  TextColumn get alertId => text()();
  TextColumn get alertType => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  DateTimeColumn get occurredAtUtc => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {alertId};

  @override
  String get tableName => 'alerts';
}

@DriftDatabase(tables: [StoredCandles, StoredEconomicEvents, StoredAlerts])
class MarketDatabase extends _$MarketDatabase {
  MarketDatabase() : super(_openDatabase());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(storedEconomicEvents);
        await migrator.createTable(storedAlerts);
      }
    },
  );

  Future<void> upsertCandles(
    String symbol,
    String timeframe,
    List<domain.Candle> values,
  ) async {
    if (values.isEmpty) return;
    await batch((batch) {
      for (final candle in values) {
        batch.insert(
          storedCandles,
          StoredCandlesCompanion.insert(
            symbol: symbol,
            timeframe: timeframe,
            openTimeUtc: candle.time.toUtc(),
            open: candle.open,
            high: candle.high,
            low: candle.low,
            close: candle.close,
            tickVolume: candle.volume,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<domain.Candle>> loadCandles(
    String symbol,
    String timeframe, {
    int limit = 500,
  }) async {
    final query = select(storedCandles)
      ..where(
        (row) => row.symbol.equals(symbol) & row.timeframe.equals(timeframe),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.openTimeUtc)])
      ..limit(limit);
    final rows = await query.get();
    return rows.reversed
        .map(
          (row) => domain.Candle(
            time: row.openTimeUtc.toUtc(),
            open: row.open,
            high: row.high,
            low: row.low,
            close: row.close,
            volume: row.tickVolume,
          ),
        )
        .toList();
  }

  Future<void> upsertEconomicEvents(List<news.EconomicEvent> events) async {
    await batch((batch) {
      for (final event in events) {
        batch.insert(
          storedEconomicEvents,
          StoredEconomicEventsCompanion.insert(
            eventId: event.id,
            name: event.name,
            currency: event.currency,
            impact: event.impact.name,
            scheduledUtc: Value(event.scheduledUtc),
            rawScheduledTime: event.rawScheduledTime,
            previous: Value(event.previous),
            forecast: Value(event.forecast),
            actual: Value(event.actual),
            unit: Value(event.unit),
            eventStatus: event.status.name,
            source: event.source,
            lastUpdatedUtc: event.lastUpdatedUtc,
            timeZoneKnown: event.timeZoneKnown,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<news.EconomicEvent>> loadEconomicEvents() async {
    final query = select(storedEconomicEvents)
      ..orderBy([(row) => OrderingTerm.asc(row.scheduledUtc)]);
    final rows = await query.get();
    return rows.map((row) {
      return news.EconomicEvent(
        id: row.eventId,
        name: row.name,
        currency: row.currency,
        impact: news.NewsImpact.values.byName(row.impact),
        scheduledUtc: row.scheduledUtc?.toUtc(),
        rawScheduledTime: row.rawScheduledTime,
        previous: row.previous,
        forecast: row.forecast,
        actual: row.actual,
        unit: row.unit,
        status: news.EconomicEventStatus.values.byName(row.eventStatus),
        source: row.source,
        lastUpdatedUtc: row.lastUpdatedUtc.toUtc(),
        timeZoneKnown: row.timeZoneKnown,
      );
    }).toList();
  }

  Future<void> correctEconomicEventTime(
    String eventId,
    DateTime correctedUtc,
  ) async {
    await (update(
      storedEconomicEvents,
    )..where((row) => row.eventId.equals(eventId))).write(
      StoredEconomicEventsCompanion(
        scheduledUtc: Value(correctedUtc.toUtc()),
        timeZoneKnown: const Value(true),
        lastUpdatedUtc: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> insertAlerts(List<news.AppAlert> alerts) async {
    await batch((batch) {
      for (final alert in alerts) {
        batch.insert(
          storedAlerts,
          StoredAlertsCompanion.insert(
            alertId: alert.id,
            alertType: alert.type.name,
            title: alert.title,
            message: alert.message,
            occurredAtUtc: alert.occurredAtUtc,
            isRead: Value(alert.read),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<List<news.AppAlert>> loadAlerts() async {
    final query = select(storedAlerts)
      ..orderBy([(row) => OrderingTerm.desc(row.occurredAtUtc)])
      ..limit(200);
    final rows = await query.get();
    return rows
        .map(
          (row) => news.AppAlert(
            id: row.alertId,
            type: news.AlertType.values.byName(row.alertType),
            title: row.title,
            message: row.message,
            occurredAtUtc: row.occurredAtUtc.toUtc(),
            read: row.isRead,
          ),
        )
        .toList();
  }

  Future<void> clearReadAlerts() =>
      (delete(storedAlerts)..where((row) => row.isRead.equals(true))).go();

  Future<void> markAlertRead(String alertId) =>
      (update(storedAlerts)..where((row) => row.alertId.equals(alertId))).write(
        const StoredAlertsCompanion(isRead: Value(true)),
      );
}

LazyDatabase _openDatabase() => LazyDatabase(() async {
  final root = Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
  final directory = Directory('$root${Platform.pathSeparator}XauUsdAnalytics');
  await directory.create(recursive: true);
  return NativeDatabase.createInBackground(
    File('${directory.path}${Platform.pathSeparator}market.sqlite'),
  );
});
