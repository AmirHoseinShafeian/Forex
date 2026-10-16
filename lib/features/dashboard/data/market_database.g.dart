// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_database.dart';

// ignore_for_file: type=lint
class $StoredCandlesTable extends StoredCandles
    with TableInfo<$StoredCandlesTable, StoredCandle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredCandlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeframeMeta = const VerificationMeta(
    'timeframe',
  );
  @override
  late final GeneratedColumn<String> timeframe = GeneratedColumn<String>(
    'timeframe',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openTimeUtcMeta = const VerificationMeta(
    'openTimeUtc',
  );
  @override
  late final GeneratedColumn<DateTime> openTimeUtc = GeneratedColumn<DateTime>(
    'open_time_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openMeta = const VerificationMeta('open');
  @override
  late final GeneratedColumn<double> open = GeneratedColumn<double>(
    'open',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _highMeta = const VerificationMeta('high');
  @override
  late final GeneratedColumn<double> high = GeneratedColumn<double>(
    'high',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lowMeta = const VerificationMeta('low');
  @override
  late final GeneratedColumn<double> low = GeneratedColumn<double>(
    'low',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closeMeta = const VerificationMeta('close');
  @override
  late final GeneratedColumn<double> close = GeneratedColumn<double>(
    'close',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tickVolumeMeta = const VerificationMeta(
    'tickVolume',
  );
  @override
  late final GeneratedColumn<int> tickVolume = GeneratedColumn<int>(
    'tick_volume',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    symbol,
    timeframe,
    openTimeUtc,
    open,
    high,
    low,
    close,
    tickVolume,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'candles';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredCandle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('timeframe')) {
      context.handle(
        _timeframeMeta,
        timeframe.isAcceptableOrUnknown(data['timeframe']!, _timeframeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeframeMeta);
    }
    if (data.containsKey('open_time_utc')) {
      context.handle(
        _openTimeUtcMeta,
        openTimeUtc.isAcceptableOrUnknown(
          data['open_time_utc']!,
          _openTimeUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openTimeUtcMeta);
    }
    if (data.containsKey('open')) {
      context.handle(
        _openMeta,
        open.isAcceptableOrUnknown(data['open']!, _openMeta),
      );
    } else if (isInserting) {
      context.missing(_openMeta);
    }
    if (data.containsKey('high')) {
      context.handle(
        _highMeta,
        high.isAcceptableOrUnknown(data['high']!, _highMeta),
      );
    } else if (isInserting) {
      context.missing(_highMeta);
    }
    if (data.containsKey('low')) {
      context.handle(
        _lowMeta,
        low.isAcceptableOrUnknown(data['low']!, _lowMeta),
      );
    } else if (isInserting) {
      context.missing(_lowMeta);
    }
    if (data.containsKey('close')) {
      context.handle(
        _closeMeta,
        close.isAcceptableOrUnknown(data['close']!, _closeMeta),
      );
    } else if (isInserting) {
      context.missing(_closeMeta);
    }
    if (data.containsKey('tick_volume')) {
      context.handle(
        _tickVolumeMeta,
        tickVolume.isAcceptableOrUnknown(data['tick_volume']!, _tickVolumeMeta),
      );
    } else if (isInserting) {
      context.missing(_tickVolumeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  StoredCandle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredCandle(
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      timeframe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timeframe'],
      )!,
      openTimeUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}open_time_utc'],
      )!,
      open: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}open'],
      )!,
      high: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}high'],
      )!,
      low: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}low'],
      )!,
      close: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}close'],
      )!,
      tickVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tick_volume'],
      )!,
    );
  }

  @override
  $StoredCandlesTable createAlias(String alias) {
    return $StoredCandlesTable(attachedDatabase, alias);
  }
}

class StoredCandle extends DataClass implements Insertable<StoredCandle> {
  final String symbol;
  final String timeframe;
  final DateTime openTimeUtc;
  final double open;
  final double high;
  final double low;
  final double close;
  final int tickVolume;
  const StoredCandle({
    required this.symbol,
    required this.timeframe,
    required this.openTimeUtc,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.tickVolume,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['timeframe'] = Variable<String>(timeframe);
    map['open_time_utc'] = Variable<DateTime>(openTimeUtc);
    map['open'] = Variable<double>(open);
    map['high'] = Variable<double>(high);
    map['low'] = Variable<double>(low);
    map['close'] = Variable<double>(close);
    map['tick_volume'] = Variable<int>(tickVolume);
    return map;
  }

  StoredCandlesCompanion toCompanion(bool nullToAbsent) {
    return StoredCandlesCompanion(
      symbol: Value(symbol),
      timeframe: Value(timeframe),
      openTimeUtc: Value(openTimeUtc),
      open: Value(open),
      high: Value(high),
      low: Value(low),
      close: Value(close),
      tickVolume: Value(tickVolume),
    );
  }

  factory StoredCandle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredCandle(
      symbol: serializer.fromJson<String>(json['symbol']),
      timeframe: serializer.fromJson<String>(json['timeframe']),
      openTimeUtc: serializer.fromJson<DateTime>(json['openTimeUtc']),
      open: serializer.fromJson<double>(json['open']),
      high: serializer.fromJson<double>(json['high']),
      low: serializer.fromJson<double>(json['low']),
      close: serializer.fromJson<double>(json['close']),
      tickVolume: serializer.fromJson<int>(json['tickVolume']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'timeframe': serializer.toJson<String>(timeframe),
      'openTimeUtc': serializer.toJson<DateTime>(openTimeUtc),
      'open': serializer.toJson<double>(open),
      'high': serializer.toJson<double>(high),
      'low': serializer.toJson<double>(low),
      'close': serializer.toJson<double>(close),
      'tickVolume': serializer.toJson<int>(tickVolume),
    };
  }

  StoredCandle copyWith({
    String? symbol,
    String? timeframe,
    DateTime? openTimeUtc,
    double? open,
    double? high,
    double? low,
    double? close,
    int? tickVolume,
  }) => StoredCandle(
    symbol: symbol ?? this.symbol,
    timeframe: timeframe ?? this.timeframe,
    openTimeUtc: openTimeUtc ?? this.openTimeUtc,
    open: open ?? this.open,
    high: high ?? this.high,
    low: low ?? this.low,
    close: close ?? this.close,
    tickVolume: tickVolume ?? this.tickVolume,
  );
  StoredCandle copyWithCompanion(StoredCandlesCompanion data) {
    return StoredCandle(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      timeframe: data.timeframe.present ? data.timeframe.value : this.timeframe,
      openTimeUtc: data.openTimeUtc.present
          ? data.openTimeUtc.value
          : this.openTimeUtc,
      open: data.open.present ? data.open.value : this.open,
      high: data.high.present ? data.high.value : this.high,
      low: data.low.present ? data.low.value : this.low,
      close: data.close.present ? data.close.value : this.close,
      tickVolume: data.tickVolume.present
          ? data.tickVolume.value
          : this.tickVolume,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredCandle(')
          ..write('symbol: $symbol, ')
          ..write('timeframe: $timeframe, ')
          ..write('openTimeUtc: $openTimeUtc, ')
          ..write('open: $open, ')
          ..write('high: $high, ')
          ..write('low: $low, ')
          ..write('close: $close, ')
          ..write('tickVolume: $tickVolume')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    symbol,
    timeframe,
    openTimeUtc,
    open,
    high,
    low,
    close,
    tickVolume,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredCandle &&
          other.symbol == this.symbol &&
          other.timeframe == this.timeframe &&
          other.openTimeUtc == this.openTimeUtc &&
          other.open == this.open &&
          other.high == this.high &&
          other.low == this.low &&
          other.close == this.close &&
          other.tickVolume == this.tickVolume);
}

class StoredCandlesCompanion extends UpdateCompanion<StoredCandle> {
  final Value<String> symbol;
  final Value<String> timeframe;
  final Value<DateTime> openTimeUtc;
  final Value<double> open;
  final Value<double> high;
  final Value<double> low;
  final Value<double> close;
  final Value<int> tickVolume;
  final Value<int> rowid;
  const StoredCandlesCompanion({
    this.symbol = const Value.absent(),
    this.timeframe = const Value.absent(),
    this.openTimeUtc = const Value.absent(),
    this.open = const Value.absent(),
    this.high = const Value.absent(),
    this.low = const Value.absent(),
    this.close = const Value.absent(),
    this.tickVolume = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredCandlesCompanion.insert({
    required String symbol,
    required String timeframe,
    required DateTime openTimeUtc,
    required double open,
    required double high,
    required double low,
    required double close,
    required int tickVolume,
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       timeframe = Value(timeframe),
       openTimeUtc = Value(openTimeUtc),
       open = Value(open),
       high = Value(high),
       low = Value(low),
       close = Value(close),
       tickVolume = Value(tickVolume);
  static Insertable<StoredCandle> custom({
    Expression<String>? symbol,
    Expression<String>? timeframe,
    Expression<DateTime>? openTimeUtc,
    Expression<double>? open,
    Expression<double>? high,
    Expression<double>? low,
    Expression<double>? close,
    Expression<int>? tickVolume,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (timeframe != null) 'timeframe': timeframe,
      if (openTimeUtc != null) 'open_time_utc': openTimeUtc,
      if (open != null) 'open': open,
      if (high != null) 'high': high,
      if (low != null) 'low': low,
      if (close != null) 'close': close,
      if (tickVolume != null) 'tick_volume': tickVolume,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredCandlesCompanion copyWith({
    Value<String>? symbol,
    Value<String>? timeframe,
    Value<DateTime>? openTimeUtc,
    Value<double>? open,
    Value<double>? high,
    Value<double>? low,
    Value<double>? close,
    Value<int>? tickVolume,
    Value<int>? rowid,
  }) {
    return StoredCandlesCompanion(
      symbol: symbol ?? this.symbol,
      timeframe: timeframe ?? this.timeframe,
      openTimeUtc: openTimeUtc ?? this.openTimeUtc,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      tickVolume: tickVolume ?? this.tickVolume,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (timeframe.present) {
      map['timeframe'] = Variable<String>(timeframe.value);
    }
    if (openTimeUtc.present) {
      map['open_time_utc'] = Variable<DateTime>(openTimeUtc.value);
    }
    if (open.present) {
      map['open'] = Variable<double>(open.value);
    }
    if (high.present) {
      map['high'] = Variable<double>(high.value);
    }
    if (low.present) {
      map['low'] = Variable<double>(low.value);
    }
    if (close.present) {
      map['close'] = Variable<double>(close.value);
    }
    if (tickVolume.present) {
      map['tick_volume'] = Variable<int>(tickVolume.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredCandlesCompanion(')
          ..write('symbol: $symbol, ')
          ..write('timeframe: $timeframe, ')
          ..write('openTimeUtc: $openTimeUtc, ')
          ..write('open: $open, ')
          ..write('high: $high, ')
          ..write('low: $low, ')
          ..write('close: $close, ')
          ..write('tickVolume: $tickVolume, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredEconomicEventsTable extends StoredEconomicEvents
    with TableInfo<$StoredEconomicEventsTable, StoredEconomicEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredEconomicEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _impactMeta = const VerificationMeta('impact');
  @override
  late final GeneratedColumn<String> impact = GeneratedColumn<String>(
    'impact',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledUtcMeta = const VerificationMeta(
    'scheduledUtc',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledUtc = GeneratedColumn<DateTime>(
    'scheduled_utc',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawScheduledTimeMeta = const VerificationMeta(
    'rawScheduledTime',
  );
  @override
  late final GeneratedColumn<String> rawScheduledTime = GeneratedColumn<String>(
    'raw_scheduled_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousMeta = const VerificationMeta(
    'previous',
  );
  @override
  late final GeneratedColumn<double> previous = GeneratedColumn<double>(
    'previous',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _forecastMeta = const VerificationMeta(
    'forecast',
  );
  @override
  late final GeneratedColumn<double> forecast = GeneratedColumn<double>(
    'forecast',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualMeta = const VerificationMeta('actual');
  @override
  late final GeneratedColumn<double> actual = GeneratedColumn<double>(
    'actual',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventStatusMeta = const VerificationMeta(
    'eventStatus',
  );
  @override
  late final GeneratedColumn<String> eventStatus = GeneratedColumn<String>(
    'event_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedUtcMeta = const VerificationMeta(
    'lastUpdatedUtc',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdatedUtc =
      GeneratedColumn<DateTime>(
        'last_updated_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _timeZoneKnownMeta = const VerificationMeta(
    'timeZoneKnown',
  );
  @override
  late final GeneratedColumn<bool> timeZoneKnown = GeneratedColumn<bool>(
    'time_zone_known',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("time_zone_known" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    name,
    currency,
    impact,
    scheduledUtc,
    rawScheduledTime,
    previous,
    forecast,
    actual,
    unit,
    eventStatus,
    source,
    lastUpdatedUtc,
    timeZoneKnown,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'economic_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredEconomicEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('impact')) {
      context.handle(
        _impactMeta,
        impact.isAcceptableOrUnknown(data['impact']!, _impactMeta),
      );
    } else if (isInserting) {
      context.missing(_impactMeta);
    }
    if (data.containsKey('scheduled_utc')) {
      context.handle(
        _scheduledUtcMeta,
        scheduledUtc.isAcceptableOrUnknown(
          data['scheduled_utc']!,
          _scheduledUtcMeta,
        ),
      );
    }
    if (data.containsKey('raw_scheduled_time')) {
      context.handle(
        _rawScheduledTimeMeta,
        rawScheduledTime.isAcceptableOrUnknown(
          data['raw_scheduled_time']!,
          _rawScheduledTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawScheduledTimeMeta);
    }
    if (data.containsKey('previous')) {
      context.handle(
        _previousMeta,
        previous.isAcceptableOrUnknown(data['previous']!, _previousMeta),
      );
    }
    if (data.containsKey('forecast')) {
      context.handle(
        _forecastMeta,
        forecast.isAcceptableOrUnknown(data['forecast']!, _forecastMeta),
      );
    }
    if (data.containsKey('actual')) {
      context.handle(
        _actualMeta,
        actual.isAcceptableOrUnknown(data['actual']!, _actualMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('event_status')) {
      context.handle(
        _eventStatusMeta,
        eventStatus.isAcceptableOrUnknown(
          data['event_status']!,
          _eventStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventStatusMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('last_updated_utc')) {
      context.handle(
        _lastUpdatedUtcMeta,
        lastUpdatedUtc.isAcceptableOrUnknown(
          data['last_updated_utc']!,
          _lastUpdatedUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedUtcMeta);
    }
    if (data.containsKey('time_zone_known')) {
      context.handle(
        _timeZoneKnownMeta,
        timeZoneKnown.isAcceptableOrUnknown(
          data['time_zone_known']!,
          _timeZoneKnownMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeZoneKnownMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  StoredEconomicEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredEconomicEvent(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      impact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}impact'],
      )!,
      scheduledUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_utc'],
      ),
      rawScheduledTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_scheduled_time'],
      )!,
      previous: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}previous'],
      ),
      forecast: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}forecast'],
      ),
      actual: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}actual'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      eventStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      lastUpdatedUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated_utc'],
      )!,
      timeZoneKnown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}time_zone_known'],
      )!,
    );
  }

  @override
  $StoredEconomicEventsTable createAlias(String alias) {
    return $StoredEconomicEventsTable(attachedDatabase, alias);
  }
}

class StoredEconomicEvent extends DataClass
    implements Insertable<StoredEconomicEvent> {
  final String eventId;
  final String name;
  final String currency;
  final String impact;
  final DateTime? scheduledUtc;
  final String rawScheduledTime;
  final double? previous;
  final double? forecast;
  final double? actual;
  final String? unit;
  final String eventStatus;
  final String source;
  final DateTime lastUpdatedUtc;
  final bool timeZoneKnown;
  const StoredEconomicEvent({
    required this.eventId,
    required this.name,
    required this.currency,
    required this.impact,
    this.scheduledUtc,
    required this.rawScheduledTime,
    this.previous,
    this.forecast,
    this.actual,
    this.unit,
    required this.eventStatus,
    required this.source,
    required this.lastUpdatedUtc,
    required this.timeZoneKnown,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['name'] = Variable<String>(name);
    map['currency'] = Variable<String>(currency);
    map['impact'] = Variable<String>(impact);
    if (!nullToAbsent || scheduledUtc != null) {
      map['scheduled_utc'] = Variable<DateTime>(scheduledUtc);
    }
    map['raw_scheduled_time'] = Variable<String>(rawScheduledTime);
    if (!nullToAbsent || previous != null) {
      map['previous'] = Variable<double>(previous);
    }
    if (!nullToAbsent || forecast != null) {
      map['forecast'] = Variable<double>(forecast);
    }
    if (!nullToAbsent || actual != null) {
      map['actual'] = Variable<double>(actual);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['event_status'] = Variable<String>(eventStatus);
    map['source'] = Variable<String>(source);
    map['last_updated_utc'] = Variable<DateTime>(lastUpdatedUtc);
    map['time_zone_known'] = Variable<bool>(timeZoneKnown);
    return map;
  }

  StoredEconomicEventsCompanion toCompanion(bool nullToAbsent) {
    return StoredEconomicEventsCompanion(
      eventId: Value(eventId),
      name: Value(name),
      currency: Value(currency),
      impact: Value(impact),
      scheduledUtc: scheduledUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledUtc),
      rawScheduledTime: Value(rawScheduledTime),
      previous: previous == null && nullToAbsent
          ? const Value.absent()
          : Value(previous),
      forecast: forecast == null && nullToAbsent
          ? const Value.absent()
          : Value(forecast),
      actual: actual == null && nullToAbsent
          ? const Value.absent()
          : Value(actual),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      eventStatus: Value(eventStatus),
      source: Value(source),
      lastUpdatedUtc: Value(lastUpdatedUtc),
      timeZoneKnown: Value(timeZoneKnown),
    );
  }

  factory StoredEconomicEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredEconomicEvent(
      eventId: serializer.fromJson<String>(json['eventId']),
      name: serializer.fromJson<String>(json['name']),
      currency: serializer.fromJson<String>(json['currency']),
      impact: serializer.fromJson<String>(json['impact']),
      scheduledUtc: serializer.fromJson<DateTime?>(json['scheduledUtc']),
      rawScheduledTime: serializer.fromJson<String>(json['rawScheduledTime']),
      previous: serializer.fromJson<double?>(json['previous']),
      forecast: serializer.fromJson<double?>(json['forecast']),
      actual: serializer.fromJson<double?>(json['actual']),
      unit: serializer.fromJson<String?>(json['unit']),
      eventStatus: serializer.fromJson<String>(json['eventStatus']),
      source: serializer.fromJson<String>(json['source']),
      lastUpdatedUtc: serializer.fromJson<DateTime>(json['lastUpdatedUtc']),
      timeZoneKnown: serializer.fromJson<bool>(json['timeZoneKnown']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'name': serializer.toJson<String>(name),
      'currency': serializer.toJson<String>(currency),
      'impact': serializer.toJson<String>(impact),
      'scheduledUtc': serializer.toJson<DateTime?>(scheduledUtc),
      'rawScheduledTime': serializer.toJson<String>(rawScheduledTime),
      'previous': serializer.toJson<double?>(previous),
      'forecast': serializer.toJson<double?>(forecast),
      'actual': serializer.toJson<double?>(actual),
      'unit': serializer.toJson<String?>(unit),
      'eventStatus': serializer.toJson<String>(eventStatus),
      'source': serializer.toJson<String>(source),
      'lastUpdatedUtc': serializer.toJson<DateTime>(lastUpdatedUtc),
      'timeZoneKnown': serializer.toJson<bool>(timeZoneKnown),
    };
  }

  StoredEconomicEvent copyWith({
    String? eventId,
    String? name,
    String? currency,
    String? impact,
    Value<DateTime?> scheduledUtc = const Value.absent(),
    String? rawScheduledTime,
    Value<double?> previous = const Value.absent(),
    Value<double?> forecast = const Value.absent(),
    Value<double?> actual = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    String? eventStatus,
    String? source,
    DateTime? lastUpdatedUtc,
    bool? timeZoneKnown,
  }) => StoredEconomicEvent(
    eventId: eventId ?? this.eventId,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    impact: impact ?? this.impact,
    scheduledUtc: scheduledUtc.present ? scheduledUtc.value : this.scheduledUtc,
    rawScheduledTime: rawScheduledTime ?? this.rawScheduledTime,
    previous: previous.present ? previous.value : this.previous,
    forecast: forecast.present ? forecast.value : this.forecast,
    actual: actual.present ? actual.value : this.actual,
    unit: unit.present ? unit.value : this.unit,
    eventStatus: eventStatus ?? this.eventStatus,
    source: source ?? this.source,
    lastUpdatedUtc: lastUpdatedUtc ?? this.lastUpdatedUtc,
    timeZoneKnown: timeZoneKnown ?? this.timeZoneKnown,
  );
  StoredEconomicEvent copyWithCompanion(StoredEconomicEventsCompanion data) {
    return StoredEconomicEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      name: data.name.present ? data.name.value : this.name,
      currency: data.currency.present ? data.currency.value : this.currency,
      impact: data.impact.present ? data.impact.value : this.impact,
      scheduledUtc: data.scheduledUtc.present
          ? data.scheduledUtc.value
          : this.scheduledUtc,
      rawScheduledTime: data.rawScheduledTime.present
          ? data.rawScheduledTime.value
          : this.rawScheduledTime,
      previous: data.previous.present ? data.previous.value : this.previous,
      forecast: data.forecast.present ? data.forecast.value : this.forecast,
      actual: data.actual.present ? data.actual.value : this.actual,
      unit: data.unit.present ? data.unit.value : this.unit,
      eventStatus: data.eventStatus.present
          ? data.eventStatus.value
          : this.eventStatus,
      source: data.source.present ? data.source.value : this.source,
      lastUpdatedUtc: data.lastUpdatedUtc.present
          ? data.lastUpdatedUtc.value
          : this.lastUpdatedUtc,
      timeZoneKnown: data.timeZoneKnown.present
          ? data.timeZoneKnown.value
          : this.timeZoneKnown,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredEconomicEvent(')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('impact: $impact, ')
          ..write('scheduledUtc: $scheduledUtc, ')
          ..write('rawScheduledTime: $rawScheduledTime, ')
          ..write('previous: $previous, ')
          ..write('forecast: $forecast, ')
          ..write('actual: $actual, ')
          ..write('unit: $unit, ')
          ..write('eventStatus: $eventStatus, ')
          ..write('source: $source, ')
          ..write('lastUpdatedUtc: $lastUpdatedUtc, ')
          ..write('timeZoneKnown: $timeZoneKnown')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    name,
    currency,
    impact,
    scheduledUtc,
    rawScheduledTime,
    previous,
    forecast,
    actual,
    unit,
    eventStatus,
    source,
    lastUpdatedUtc,
    timeZoneKnown,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredEconomicEvent &&
          other.eventId == this.eventId &&
          other.name == this.name &&
          other.currency == this.currency &&
          other.impact == this.impact &&
          other.scheduledUtc == this.scheduledUtc &&
          other.rawScheduledTime == this.rawScheduledTime &&
          other.previous == this.previous &&
          other.forecast == this.forecast &&
          other.actual == this.actual &&
          other.unit == this.unit &&
          other.eventStatus == this.eventStatus &&
          other.source == this.source &&
          other.lastUpdatedUtc == this.lastUpdatedUtc &&
          other.timeZoneKnown == this.timeZoneKnown);
}

class StoredEconomicEventsCompanion
    extends UpdateCompanion<StoredEconomicEvent> {
  final Value<String> eventId;
  final Value<String> name;
  final Value<String> currency;
  final Value<String> impact;
  final Value<DateTime?> scheduledUtc;
  final Value<String> rawScheduledTime;
  final Value<double?> previous;
  final Value<double?> forecast;
  final Value<double?> actual;
  final Value<String?> unit;
  final Value<String> eventStatus;
  final Value<String> source;
  final Value<DateTime> lastUpdatedUtc;
  final Value<bool> timeZoneKnown;
  final Value<int> rowid;
  const StoredEconomicEventsCompanion({
    this.eventId = const Value.absent(),
    this.name = const Value.absent(),
    this.currency = const Value.absent(),
    this.impact = const Value.absent(),
    this.scheduledUtc = const Value.absent(),
    this.rawScheduledTime = const Value.absent(),
    this.previous = const Value.absent(),
    this.forecast = const Value.absent(),
    this.actual = const Value.absent(),
    this.unit = const Value.absent(),
    this.eventStatus = const Value.absent(),
    this.source = const Value.absent(),
    this.lastUpdatedUtc = const Value.absent(),
    this.timeZoneKnown = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredEconomicEventsCompanion.insert({
    required String eventId,
    required String name,
    required String currency,
    required String impact,
    this.scheduledUtc = const Value.absent(),
    required String rawScheduledTime,
    this.previous = const Value.absent(),
    this.forecast = const Value.absent(),
    this.actual = const Value.absent(),
    this.unit = const Value.absent(),
    required String eventStatus,
    required String source,
    required DateTime lastUpdatedUtc,
    required bool timeZoneKnown,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       name = Value(name),
       currency = Value(currency),
       impact = Value(impact),
       rawScheduledTime = Value(rawScheduledTime),
       eventStatus = Value(eventStatus),
       source = Value(source),
       lastUpdatedUtc = Value(lastUpdatedUtc),
       timeZoneKnown = Value(timeZoneKnown);
  static Insertable<StoredEconomicEvent> custom({
    Expression<String>? eventId,
    Expression<String>? name,
    Expression<String>? currency,
    Expression<String>? impact,
    Expression<DateTime>? scheduledUtc,
    Expression<String>? rawScheduledTime,
    Expression<double>? previous,
    Expression<double>? forecast,
    Expression<double>? actual,
    Expression<String>? unit,
    Expression<String>? eventStatus,
    Expression<String>? source,
    Expression<DateTime>? lastUpdatedUtc,
    Expression<bool>? timeZoneKnown,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (name != null) 'name': name,
      if (currency != null) 'currency': currency,
      if (impact != null) 'impact': impact,
      if (scheduledUtc != null) 'scheduled_utc': scheduledUtc,
      if (rawScheduledTime != null) 'raw_scheduled_time': rawScheduledTime,
      if (previous != null) 'previous': previous,
      if (forecast != null) 'forecast': forecast,
      if (actual != null) 'actual': actual,
      if (unit != null) 'unit': unit,
      if (eventStatus != null) 'event_status': eventStatus,
      if (source != null) 'source': source,
      if (lastUpdatedUtc != null) 'last_updated_utc': lastUpdatedUtc,
      if (timeZoneKnown != null) 'time_zone_known': timeZoneKnown,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredEconomicEventsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? name,
    Value<String>? currency,
    Value<String>? impact,
    Value<DateTime?>? scheduledUtc,
    Value<String>? rawScheduledTime,
    Value<double?>? previous,
    Value<double?>? forecast,
    Value<double?>? actual,
    Value<String?>? unit,
    Value<String>? eventStatus,
    Value<String>? source,
    Value<DateTime>? lastUpdatedUtc,
    Value<bool>? timeZoneKnown,
    Value<int>? rowid,
  }) {
    return StoredEconomicEventsCompanion(
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      impact: impact ?? this.impact,
      scheduledUtc: scheduledUtc ?? this.scheduledUtc,
      rawScheduledTime: rawScheduledTime ?? this.rawScheduledTime,
      previous: previous ?? this.previous,
      forecast: forecast ?? this.forecast,
      actual: actual ?? this.actual,
      unit: unit ?? this.unit,
      eventStatus: eventStatus ?? this.eventStatus,
      source: source ?? this.source,
      lastUpdatedUtc: lastUpdatedUtc ?? this.lastUpdatedUtc,
      timeZoneKnown: timeZoneKnown ?? this.timeZoneKnown,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (impact.present) {
      map['impact'] = Variable<String>(impact.value);
    }
    if (scheduledUtc.present) {
      map['scheduled_utc'] = Variable<DateTime>(scheduledUtc.value);
    }
    if (rawScheduledTime.present) {
      map['raw_scheduled_time'] = Variable<String>(rawScheduledTime.value);
    }
    if (previous.present) {
      map['previous'] = Variable<double>(previous.value);
    }
    if (forecast.present) {
      map['forecast'] = Variable<double>(forecast.value);
    }
    if (actual.present) {
      map['actual'] = Variable<double>(actual.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (eventStatus.present) {
      map['event_status'] = Variable<String>(eventStatus.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (lastUpdatedUtc.present) {
      map['last_updated_utc'] = Variable<DateTime>(lastUpdatedUtc.value);
    }
    if (timeZoneKnown.present) {
      map['time_zone_known'] = Variable<bool>(timeZoneKnown.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredEconomicEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('impact: $impact, ')
          ..write('scheduledUtc: $scheduledUtc, ')
          ..write('rawScheduledTime: $rawScheduledTime, ')
          ..write('previous: $previous, ')
          ..write('forecast: $forecast, ')
          ..write('actual: $actual, ')
          ..write('unit: $unit, ')
          ..write('eventStatus: $eventStatus, ')
          ..write('source: $source, ')
          ..write('lastUpdatedUtc: $lastUpdatedUtc, ')
          ..write('timeZoneKnown: $timeZoneKnown, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredAlertsTable extends StoredAlerts
    with TableInfo<$StoredAlertsTable, StoredAlert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredAlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _alertIdMeta = const VerificationMeta(
    'alertId',
  );
  @override
  late final GeneratedColumn<String> alertId = GeneratedColumn<String>(
    'alert_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alertTypeMeta = const VerificationMeta(
    'alertType',
  );
  @override
  late final GeneratedColumn<String> alertType = GeneratedColumn<String>(
    'alert_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtUtcMeta = const VerificationMeta(
    'occurredAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>(
        'occurred_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    alertId,
    alertType,
    title,
    message,
    occurredAtUtc,
    isRead,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredAlert> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('alert_id')) {
      context.handle(
        _alertIdMeta,
        alertId.isAcceptableOrUnknown(data['alert_id']!, _alertIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alertIdMeta);
    }
    if (data.containsKey('alert_type')) {
      context.handle(
        _alertTypeMeta,
        alertType.isAcceptableOrUnknown(data['alert_type']!, _alertTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_alertTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
        _occurredAtUtcMeta,
        occurredAtUtc.isAcceptableOrUnknown(
          data['occurred_at_utc']!,
          _occurredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {alertId};
  @override
  StoredAlert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredAlert(
      alertId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alert_id'],
      )!,
      alertType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alert_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at_utc'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
    );
  }

  @override
  $StoredAlertsTable createAlias(String alias) {
    return $StoredAlertsTable(attachedDatabase, alias);
  }
}

class StoredAlert extends DataClass implements Insertable<StoredAlert> {
  final String alertId;
  final String alertType;
  final String title;
  final String message;
  final DateTime occurredAtUtc;
  final bool isRead;
  const StoredAlert({
    required this.alertId,
    required this.alertType,
    required this.title,
    required this.message,
    required this.occurredAtUtc,
    required this.isRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['alert_id'] = Variable<String>(alertId);
    map['alert_type'] = Variable<String>(alertType);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  StoredAlertsCompanion toCompanion(bool nullToAbsent) {
    return StoredAlertsCompanion(
      alertId: Value(alertId),
      alertType: Value(alertType),
      title: Value(title),
      message: Value(message),
      occurredAtUtc: Value(occurredAtUtc),
      isRead: Value(isRead),
    );
  }

  factory StoredAlert.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredAlert(
      alertId: serializer.fromJson<String>(json['alertId']),
      alertType: serializer.fromJson<String>(json['alertType']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'alertId': serializer.toJson<String>(alertId),
      'alertType': serializer.toJson<String>(alertType),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  StoredAlert copyWith({
    String? alertId,
    String? alertType,
    String? title,
    String? message,
    DateTime? occurredAtUtc,
    bool? isRead,
  }) => StoredAlert(
    alertId: alertId ?? this.alertId,
    alertType: alertType ?? this.alertType,
    title: title ?? this.title,
    message: message ?? this.message,
    occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
    isRead: isRead ?? this.isRead,
  );
  StoredAlert copyWithCompanion(StoredAlertsCompanion data) {
    return StoredAlert(
      alertId: data.alertId.present ? data.alertId.value : this.alertId,
      alertType: data.alertType.present ? data.alertType.value : this.alertType,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredAlert(')
          ..write('alertId: $alertId, ')
          ..write('alertType: $alertType, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(alertId, alertType, title, message, occurredAtUtc, isRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredAlert &&
          other.alertId == this.alertId &&
          other.alertType == this.alertType &&
          other.title == this.title &&
          other.message == this.message &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.isRead == this.isRead);
}

class StoredAlertsCompanion extends UpdateCompanion<StoredAlert> {
  final Value<String> alertId;
  final Value<String> alertType;
  final Value<String> title;
  final Value<String> message;
  final Value<DateTime> occurredAtUtc;
  final Value<bool> isRead;
  final Value<int> rowid;
  const StoredAlertsCompanion({
    this.alertId = const Value.absent(),
    this.alertType = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredAlertsCompanion.insert({
    required String alertId,
    required String alertType,
    required String title,
    required String message,
    required DateTime occurredAtUtc,
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : alertId = Value(alertId),
       alertType = Value(alertType),
       title = Value(title),
       message = Value(message),
       occurredAtUtc = Value(occurredAtUtc);
  static Insertable<StoredAlert> custom({
    Expression<String>? alertId,
    Expression<String>? alertType,
    Expression<String>? title,
    Expression<String>? message,
    Expression<DateTime>? occurredAtUtc,
    Expression<bool>? isRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (alertId != null) 'alert_id': alertId,
      if (alertType != null) 'alert_type': alertType,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (isRead != null) 'is_read': isRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredAlertsCompanion copyWith({
    Value<String>? alertId,
    Value<String>? alertType,
    Value<String>? title,
    Value<String>? message,
    Value<DateTime>? occurredAtUtc,
    Value<bool>? isRead,
    Value<int>? rowid,
  }) {
    return StoredAlertsCompanion(
      alertId: alertId ?? this.alertId,
      alertType: alertType ?? this.alertType,
      title: title ?? this.title,
      message: message ?? this.message,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      isRead: isRead ?? this.isRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (alertId.present) {
      map['alert_id'] = Variable<String>(alertId.value);
    }
    if (alertType.present) {
      map['alert_type'] = Variable<String>(alertType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredAlertsCompanion(')
          ..write('alertId: $alertId, ')
          ..write('alertType: $alertType, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('isRead: $isRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MarketDatabase extends GeneratedDatabase {
  _$MarketDatabase(QueryExecutor e) : super(e);
  $MarketDatabaseManager get managers => $MarketDatabaseManager(this);
  late final $StoredCandlesTable storedCandles = $StoredCandlesTable(this);
  late final $StoredEconomicEventsTable storedEconomicEvents =
      $StoredEconomicEventsTable(this);
  late final $StoredAlertsTable storedAlerts = $StoredAlertsTable(this);
  late final Index candlesSymbolTimeframeTimeIdx = Index(
    'candles_symbol_timeframe_time_idx',
    'CREATE UNIQUE INDEX candles_symbol_timeframe_time_idx ON candles (symbol, timeframe, open_time_utc)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    storedCandles,
    storedEconomicEvents,
    storedAlerts,
    candlesSymbolTimeframeTimeIdx,
  ];
}

typedef $$StoredCandlesTableCreateCompanionBuilder =
    StoredCandlesCompanion Function({
      required String symbol,
      required String timeframe,
      required DateTime openTimeUtc,
      required double open,
      required double high,
      required double low,
      required double close,
      required int tickVolume,
      Value<int> rowid,
    });
typedef $$StoredCandlesTableUpdateCompanionBuilder =
    StoredCandlesCompanion Function({
      Value<String> symbol,
      Value<String> timeframe,
      Value<DateTime> openTimeUtc,
      Value<double> open,
      Value<double> high,
      Value<double> low,
      Value<double> close,
      Value<int> tickVolume,
      Value<int> rowid,
    });

class $$StoredCandlesTableFilterComposer
    extends Composer<_$MarketDatabase, $StoredCandlesTable> {
  $$StoredCandlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeframe => $composableBuilder(
    column: $table.timeframe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openTimeUtc => $composableBuilder(
    column: $table.openTimeUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get open => $composableBuilder(
    column: $table.open,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get high => $composableBuilder(
    column: $table.high,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get low => $composableBuilder(
    column: $table.low,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get close => $composableBuilder(
    column: $table.close,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tickVolume => $composableBuilder(
    column: $table.tickVolume,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredCandlesTableOrderingComposer
    extends Composer<_$MarketDatabase, $StoredCandlesTable> {
  $$StoredCandlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeframe => $composableBuilder(
    column: $table.timeframe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openTimeUtc => $composableBuilder(
    column: $table.openTimeUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get open => $composableBuilder(
    column: $table.open,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get high => $composableBuilder(
    column: $table.high,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get low => $composableBuilder(
    column: $table.low,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get close => $composableBuilder(
    column: $table.close,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tickVolume => $composableBuilder(
    column: $table.tickVolume,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredCandlesTableAnnotationComposer
    extends Composer<_$MarketDatabase, $StoredCandlesTable> {
  $$StoredCandlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get timeframe =>
      $composableBuilder(column: $table.timeframe, builder: (column) => column);

  GeneratedColumn<DateTime> get openTimeUtc => $composableBuilder(
    column: $table.openTimeUtc,
    builder: (column) => column,
  );

  GeneratedColumn<double> get open =>
      $composableBuilder(column: $table.open, builder: (column) => column);

  GeneratedColumn<double> get high =>
      $composableBuilder(column: $table.high, builder: (column) => column);

  GeneratedColumn<double> get low =>
      $composableBuilder(column: $table.low, builder: (column) => column);

  GeneratedColumn<double> get close =>
      $composableBuilder(column: $table.close, builder: (column) => column);

  GeneratedColumn<int> get tickVolume => $composableBuilder(
    column: $table.tickVolume,
    builder: (column) => column,
  );
}

class $$StoredCandlesTableTableManager
    extends
        RootTableManager<
          _$MarketDatabase,
          $StoredCandlesTable,
          StoredCandle,
          $$StoredCandlesTableFilterComposer,
          $$StoredCandlesTableOrderingComposer,
          $$StoredCandlesTableAnnotationComposer,
          $$StoredCandlesTableCreateCompanionBuilder,
          $$StoredCandlesTableUpdateCompanionBuilder,
          (
            StoredCandle,
            BaseReferences<_$MarketDatabase, $StoredCandlesTable, StoredCandle>,
          ),
          StoredCandle,
          PrefetchHooks Function()
        > {
  $$StoredCandlesTableTableManager(
    _$MarketDatabase db,
    $StoredCandlesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredCandlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredCandlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredCandlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> symbol = const Value.absent(),
                Value<String> timeframe = const Value.absent(),
                Value<DateTime> openTimeUtc = const Value.absent(),
                Value<double> open = const Value.absent(),
                Value<double> high = const Value.absent(),
                Value<double> low = const Value.absent(),
                Value<double> close = const Value.absent(),
                Value<int> tickVolume = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredCandlesCompanion(
                symbol: symbol,
                timeframe: timeframe,
                openTimeUtc: openTimeUtc,
                open: open,
                high: high,
                low: low,
                close: close,
                tickVolume: tickVolume,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String symbol,
                required String timeframe,
                required DateTime openTimeUtc,
                required double open,
                required double high,
                required double low,
                required double close,
                required int tickVolume,
                Value<int> rowid = const Value.absent(),
              }) => StoredCandlesCompanion.insert(
                symbol: symbol,
                timeframe: timeframe,
                openTimeUtc: openTimeUtc,
                open: open,
                high: high,
                low: low,
                close: close,
                tickVolume: tickVolume,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredCandlesTable, StoredCandle>(table),
                  BaseReferences<
                    _$MarketDatabase,
                    $StoredCandlesTable,
                    StoredCandle
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredCandlesTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDatabase,
      $StoredCandlesTable,
      StoredCandle,
      $$StoredCandlesTableFilterComposer,
      $$StoredCandlesTableOrderingComposer,
      $$StoredCandlesTableAnnotationComposer,
      $$StoredCandlesTableCreateCompanionBuilder,
      $$StoredCandlesTableUpdateCompanionBuilder,
      (
        StoredCandle,
        BaseReferences<_$MarketDatabase, $StoredCandlesTable, StoredCandle>,
      ),
      StoredCandle,
      PrefetchHooks Function()
    >;
typedef $$StoredEconomicEventsTableCreateCompanionBuilder =
    StoredEconomicEventsCompanion Function({
      required String eventId,
      required String name,
      required String currency,
      required String impact,
      Value<DateTime?> scheduledUtc,
      required String rawScheduledTime,
      Value<double?> previous,
      Value<double?> forecast,
      Value<double?> actual,
      Value<String?> unit,
      required String eventStatus,
      required String source,
      required DateTime lastUpdatedUtc,
      required bool timeZoneKnown,
      Value<int> rowid,
    });
typedef $$StoredEconomicEventsTableUpdateCompanionBuilder =
    StoredEconomicEventsCompanion Function({
      Value<String> eventId,
      Value<String> name,
      Value<String> currency,
      Value<String> impact,
      Value<DateTime?> scheduledUtc,
      Value<String> rawScheduledTime,
      Value<double?> previous,
      Value<double?> forecast,
      Value<double?> actual,
      Value<String?> unit,
      Value<String> eventStatus,
      Value<String> source,
      Value<DateTime> lastUpdatedUtc,
      Value<bool> timeZoneKnown,
      Value<int> rowid,
    });

class $$StoredEconomicEventsTableFilterComposer
    extends Composer<_$MarketDatabase, $StoredEconomicEventsTable> {
  $$StoredEconomicEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get impact => $composableBuilder(
    column: $table.impact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledUtc => $composableBuilder(
    column: $table.scheduledUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawScheduledTime => $composableBuilder(
    column: $table.rawScheduledTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get previous => $composableBuilder(
    column: $table.previous,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get forecast => $composableBuilder(
    column: $table.forecast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get actual => $composableBuilder(
    column: $table.actual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventStatus => $composableBuilder(
    column: $table.eventStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdatedUtc => $composableBuilder(
    column: $table.lastUpdatedUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get timeZoneKnown => $composableBuilder(
    column: $table.timeZoneKnown,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredEconomicEventsTableOrderingComposer
    extends Composer<_$MarketDatabase, $StoredEconomicEventsTable> {
  $$StoredEconomicEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get impact => $composableBuilder(
    column: $table.impact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledUtc => $composableBuilder(
    column: $table.scheduledUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawScheduledTime => $composableBuilder(
    column: $table.rawScheduledTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get previous => $composableBuilder(
    column: $table.previous,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get forecast => $composableBuilder(
    column: $table.forecast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get actual => $composableBuilder(
    column: $table.actual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventStatus => $composableBuilder(
    column: $table.eventStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdatedUtc => $composableBuilder(
    column: $table.lastUpdatedUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get timeZoneKnown => $composableBuilder(
    column: $table.timeZoneKnown,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredEconomicEventsTableAnnotationComposer
    extends Composer<_$MarketDatabase, $StoredEconomicEventsTable> {
  $$StoredEconomicEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get impact =>
      $composableBuilder(column: $table.impact, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledUtc => $composableBuilder(
    column: $table.scheduledUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawScheduledTime => $composableBuilder(
    column: $table.rawScheduledTime,
    builder: (column) => column,
  );

  GeneratedColumn<double> get previous =>
      $composableBuilder(column: $table.previous, builder: (column) => column);

  GeneratedColumn<double> get forecast =>
      $composableBuilder(column: $table.forecast, builder: (column) => column);

  GeneratedColumn<double> get actual =>
      $composableBuilder(column: $table.actual, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get eventStatus => $composableBuilder(
    column: $table.eventStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdatedUtc => $composableBuilder(
    column: $table.lastUpdatedUtc,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get timeZoneKnown => $composableBuilder(
    column: $table.timeZoneKnown,
    builder: (column) => column,
  );
}

class $$StoredEconomicEventsTableTableManager
    extends
        RootTableManager<
          _$MarketDatabase,
          $StoredEconomicEventsTable,
          StoredEconomicEvent,
          $$StoredEconomicEventsTableFilterComposer,
          $$StoredEconomicEventsTableOrderingComposer,
          $$StoredEconomicEventsTableAnnotationComposer,
          $$StoredEconomicEventsTableCreateCompanionBuilder,
          $$StoredEconomicEventsTableUpdateCompanionBuilder,
          (
            StoredEconomicEvent,
            BaseReferences<
              _$MarketDatabase,
              $StoredEconomicEventsTable,
              StoredEconomicEvent
            >,
          ),
          StoredEconomicEvent,
          PrefetchHooks Function()
        > {
  $$StoredEconomicEventsTableTableManager(
    _$MarketDatabase db,
    $StoredEconomicEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredEconomicEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredEconomicEventsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StoredEconomicEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> impact = const Value.absent(),
                Value<DateTime?> scheduledUtc = const Value.absent(),
                Value<String> rawScheduledTime = const Value.absent(),
                Value<double?> previous = const Value.absent(),
                Value<double?> forecast = const Value.absent(),
                Value<double?> actual = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String> eventStatus = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> lastUpdatedUtc = const Value.absent(),
                Value<bool> timeZoneKnown = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredEconomicEventsCompanion(
                eventId: eventId,
                name: name,
                currency: currency,
                impact: impact,
                scheduledUtc: scheduledUtc,
                rawScheduledTime: rawScheduledTime,
                previous: previous,
                forecast: forecast,
                actual: actual,
                unit: unit,
                eventStatus: eventStatus,
                source: source,
                lastUpdatedUtc: lastUpdatedUtc,
                timeZoneKnown: timeZoneKnown,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String name,
                required String currency,
                required String impact,
                Value<DateTime?> scheduledUtc = const Value.absent(),
                required String rawScheduledTime,
                Value<double?> previous = const Value.absent(),
                Value<double?> forecast = const Value.absent(),
                Value<double?> actual = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required String eventStatus,
                required String source,
                required DateTime lastUpdatedUtc,
                required bool timeZoneKnown,
                Value<int> rowid = const Value.absent(),
              }) => StoredEconomicEventsCompanion.insert(
                eventId: eventId,
                name: name,
                currency: currency,
                impact: impact,
                scheduledUtc: scheduledUtc,
                rawScheduledTime: rawScheduledTime,
                previous: previous,
                forecast: forecast,
                actual: actual,
                unit: unit,
                eventStatus: eventStatus,
                source: source,
                lastUpdatedUtc: lastUpdatedUtc,
                timeZoneKnown: timeZoneKnown,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredEconomicEventsTable, StoredEconomicEvent>(
                    table,
                  ),
                  BaseReferences<
                    _$MarketDatabase,
                    $StoredEconomicEventsTable,
                    StoredEconomicEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredEconomicEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDatabase,
      $StoredEconomicEventsTable,
      StoredEconomicEvent,
      $$StoredEconomicEventsTableFilterComposer,
      $$StoredEconomicEventsTableOrderingComposer,
      $$StoredEconomicEventsTableAnnotationComposer,
      $$StoredEconomicEventsTableCreateCompanionBuilder,
      $$StoredEconomicEventsTableUpdateCompanionBuilder,
      (
        StoredEconomicEvent,
        BaseReferences<
          _$MarketDatabase,
          $StoredEconomicEventsTable,
          StoredEconomicEvent
        >,
      ),
      StoredEconomicEvent,
      PrefetchHooks Function()
    >;
typedef $$StoredAlertsTableCreateCompanionBuilder =
    StoredAlertsCompanion Function({
      required String alertId,
      required String alertType,
      required String title,
      required String message,
      required DateTime occurredAtUtc,
      Value<bool> isRead,
      Value<int> rowid,
    });
typedef $$StoredAlertsTableUpdateCompanionBuilder =
    StoredAlertsCompanion Function({
      Value<String> alertId,
      Value<String> alertType,
      Value<String> title,
      Value<String> message,
      Value<DateTime> occurredAtUtc,
      Value<bool> isRead,
      Value<int> rowid,
    });

class $$StoredAlertsTableFilterComposer
    extends Composer<_$MarketDatabase, $StoredAlertsTable> {
  $$StoredAlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get alertId => $composableBuilder(
    column: $table.alertId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredAlertsTableOrderingComposer
    extends Composer<_$MarketDatabase, $StoredAlertsTable> {
  $$StoredAlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get alertId => $composableBuilder(
    column: $table.alertId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredAlertsTableAnnotationComposer
    extends Composer<_$MarketDatabase, $StoredAlertsTable> {
  $$StoredAlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get alertId =>
      $composableBuilder(column: $table.alertId, builder: (column) => column);

  GeneratedColumn<String> get alertType =>
      $composableBuilder(column: $table.alertType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);
}

class $$StoredAlertsTableTableManager
    extends
        RootTableManager<
          _$MarketDatabase,
          $StoredAlertsTable,
          StoredAlert,
          $$StoredAlertsTableFilterComposer,
          $$StoredAlertsTableOrderingComposer,
          $$StoredAlertsTableAnnotationComposer,
          $$StoredAlertsTableCreateCompanionBuilder,
          $$StoredAlertsTableUpdateCompanionBuilder,
          (
            StoredAlert,
            BaseReferences<_$MarketDatabase, $StoredAlertsTable, StoredAlert>,
          ),
          StoredAlert,
          PrefetchHooks Function()
        > {
  $$StoredAlertsTableTableManager(_$MarketDatabase db, $StoredAlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredAlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredAlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredAlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> alertId = const Value.absent(),
                Value<String> alertType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<DateTime> occurredAtUtc = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredAlertsCompanion(
                alertId: alertId,
                alertType: alertType,
                title: title,
                message: message,
                occurredAtUtc: occurredAtUtc,
                isRead: isRead,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String alertId,
                required String alertType,
                required String title,
                required String message,
                required DateTime occurredAtUtc,
                Value<bool> isRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredAlertsCompanion.insert(
                alertId: alertId,
                alertType: alertType,
                title: title,
                message: message,
                occurredAtUtc: occurredAtUtc,
                isRead: isRead,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredAlertsTable, StoredAlert>(table),
                  BaseReferences<
                    _$MarketDatabase,
                    $StoredAlertsTable,
                    StoredAlert
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredAlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDatabase,
      $StoredAlertsTable,
      StoredAlert,
      $$StoredAlertsTableFilterComposer,
      $$StoredAlertsTableOrderingComposer,
      $$StoredAlertsTableAnnotationComposer,
      $$StoredAlertsTableCreateCompanionBuilder,
      $$StoredAlertsTableUpdateCompanionBuilder,
      (
        StoredAlert,
        BaseReferences<_$MarketDatabase, $StoredAlertsTable, StoredAlert>,
      ),
      StoredAlert,
      PrefetchHooks Function()
    >;

class $MarketDatabaseManager {
  final _$MarketDatabase _db;
  $MarketDatabaseManager(this._db);
  $$StoredCandlesTableTableManager get storedCandles =>
      $$StoredCandlesTableTableManager(_db, _db.storedCandles);
  $$StoredEconomicEventsTableTableManager get storedEconomicEvents =>
      $$StoredEconomicEventsTableTableManager(_db, _db.storedEconomicEvents);
  $$StoredAlertsTableTableManager get storedAlerts =>
      $$StoredAlertsTableTableManager(_db, _db.storedAlerts);
}
