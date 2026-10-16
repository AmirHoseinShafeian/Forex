import 'dart:convert';

import '../domain/economic_news_models.dart';

class CalendarImportException implements Exception {
  const CalendarImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ForexFactoryCalendarProvider {
  const ForexFactoryCalendarProvider();

  static const calendarUrl = 'https://www.forexfactory.com/calendar';
  static const autoFetchAuthorized = false;

  List<EconomicEvent> parse(String contents, String extension) {
    final normalized = extension.toLowerCase().replaceFirst('.', '');
    final rows = normalized == 'json'
        ? _jsonRows(contents)
        : normalized == 'csv'
        ? _csvRows(contents)
        : throw const CalendarImportException(
            'Only JSON and CSV are supported',
          );
    if (rows.isEmpty) {
      throw const CalendarImportException(
        'The calendar file contains no events',
      );
    }
    final now = DateTime.now().toUtc();
    final events = rows.map((row) => _event(row, now)).toList();
    return {for (final event in events) event.id: event}.values.toList()
      ..sort((a, b) {
        if (a.scheduledUtc == null) return 1;
        if (b.scheduledUtc == null) return -1;
        return a.scheduledUtc!.compareTo(b.scheduledUtc!);
      });
  }

  List<Map<String, dynamic>> _jsonRows(String contents) {
    try {
      final decoded = jsonDecode(contents);
      final values = decoded is List
          ? decoded
          : decoded is Map<String, dynamic>
          ? decoded['events']
          : null;
      if (values is! List) {
        throw const CalendarImportException(
          'JSON must be an event list or contain an events list',
        );
      }
      return values
          .whereType<Map>()
          .map((value) => value.map((key, value) => MapEntry('$key', value)))
          .toList();
    } on FormatException {
      throw const CalendarImportException('The JSON file is malformed');
    }
  }

  List<Map<String, dynamic>> _csvRows(String contents) {
    final lines = const LineSplitter().convert(contents);
    if (lines.length < 2) {
      throw const CalendarImportException(
        'CSV must contain a header and events',
      );
    }
    final headers = _csvLine(lines.first).map((value) => value.trim()).toList();
    return lines.skip(1).where((line) => line.trim().isNotEmpty).map((line) {
      final values = _csvLine(line);
      return <String, dynamic>{
        for (var index = 0; index < headers.length; index++)
          headers[index]: index < values.length ? values[index].trim() : '',
      };
    }).toList();
  }

  List<String> _csvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var index = 0; index < line.length; index++) {
      final value = line[index];
      if (value == '"') {
        if (quoted && index + 1 < line.length && line[index + 1] == '"') {
          buffer.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (value == ',' && !quoted) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(value);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  EconomicEvent _event(Map<String, dynamic> row, DateTime now) {
    String field(List<String> names) {
      for (final name in names) {
        final entry = row.entries
            .where((item) => item.key.toLowerCase() == name.toLowerCase())
            .firstOrNull;
        if (entry != null) return entry.value?.toString().trim() ?? '';
      }
      return '';
    }

    final name = field(const ['title', 'event', 'name']);
    final currency = field(const ['country', 'currency']).toUpperCase();
    if (name.isEmpty || currency.isEmpty) {
      throw const CalendarImportException(
        'Each event requires a name/title and currency/country',
      );
    }
    final datePart = field(const ['datetime', 'scheduled', 'date']);
    final timePart = field(const ['time']);
    final rawDate = datePart.isNotEmpty && timePart.isNotEmpty
        ? '$datePart $timePart'
        : datePart.isNotEmpty
        ? datePart
        : timePart;
    final parsed = DateTime.tryParse(rawDate);
    final hasZone = RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(rawDate);
    final scheduled = parsed != null && hasZone ? parsed.toUtc() : null;
    final actual = _numeric(field(const ['actual']));
    final forecast = _numeric(field(const ['forecast']));
    final previous = _numeric(field(const ['previous']));
    final idSource =
        '$name|$currency|${scheduled?.toIso8601String() ?? rawDate}';
    return EconomicEvent(
      id: field(const ['id', 'eventId']).isNotEmpty
          ? field(const ['id', 'eventId'])
          : 'ff-${_stableHash(idSource)}',
      name: name,
      currency: currency,
      impact: _impact(field(const ['impact'])),
      scheduledUtc: scheduled,
      rawScheduledTime: rawDate,
      previous: previous,
      forecast: forecast,
      actual: actual,
      unit: _unit(field(const ['actual']), field(const ['forecast'])),
      status: actual == null
          ? EconomicEventStatus.upcoming
          : EconomicEventStatus.released,
      source: 'Forex Factory manual export',
      lastUpdatedUtc: now,
      timeZoneKnown: scheduled != null,
    );
  }

  double? _numeric(String raw) {
    if (raw.isEmpty || raw == '-' || raw == '—') return null;
    final normalized = raw.replaceAll(',', '').replaceAll('%', '').trim();
    return double.tryParse(normalized);
  }

  String? _unit(String actual, String forecast) {
    final value = actual.isNotEmpty ? actual : forecast;
    if (value.contains('%')) return '%';
    final suffix = RegExp(r'[KMB]$', caseSensitive: false).firstMatch(value);
    return suffix?.group(0)?.toUpperCase();
  }

  NewsImpact _impact(String value) => switch (value.toLowerCase()) {
    'high' || 'red' => NewsImpact.high,
    'medium' || 'med' || 'orange' => NewsImpact.medium,
    'low' || 'yellow' => NewsImpact.low,
    _ => NewsImpact.unknown,
  };

  int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final code in utf8.encode(value.toLowerCase())) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
