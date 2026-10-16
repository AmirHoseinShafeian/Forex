import '../economic_news_models.dart';

class NewsRiskFilter {
  const NewsRiskFilter({
    this.before = const Duration(minutes: 30),
    this.after = const Duration(minutes: 15),
  });

  final Duration before;
  final Duration after;

  NewsRiskSnapshot evaluate({
    required List<EconomicEvent> events,
    required NewsDataStatus status,
    required DateTime nowUtc,
  }) {
    if (status == NewsDataStatus.demo) {
      return NewsRiskSnapshot(
        level: NewsRiskLevel.none,
        reasons: const ['DEMO news is excluded from live decisions'],
        evaluatedAtUtc: nowUtc,
      );
    }
    final candidates = events.where((event) {
      if (event.currency != 'USD' ||
          event.impact != NewsImpact.high ||
          event.scheduledUtc == null) {
        return false;
      }
      final delta = event.scheduledUtc!.difference(nowUtc);
      return delta <= before && delta >= -after;
    }).toList()..sort((a, b) => a.scheduledUtc!.compareTo(b.scheduledUtc!));
    if (candidates.isEmpty) return NewsRiskSnapshot.none();
    final event = candidates.first;
    final released = nowUtc.isAfter(event.scheduledUtc!);
    return NewsRiskSnapshot(
      level: NewsRiskLevel.blocked,
      reasons: [
        released
            ? 'High-impact USD news was released within the risk window'
            : 'High-impact USD news is approaching',
        '${event.name} @ ${event.scheduledUtc!.toIso8601String()}',
      ],
      evaluatedAtUtc: nowUtc,
      event: event,
    );
  }
}
