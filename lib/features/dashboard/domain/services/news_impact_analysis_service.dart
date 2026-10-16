import '../economic_news_models.dart';

class NewsImpactAnalysisService {
  const NewsImpactAnalysisService();

  NewsImpactAnalysis analyze(EconomicEvent event) {
    final name = event.name.toLowerCase();
    if (event.currency != 'USD') {
      return NewsImpactAnalysis(
        eventId: event.id,
        usdImpact: PotentialImpact.uncertain,
        xauUsdImpact: PotentialImpact.uncertain,
        reason: 'Non-USD event; cross-market impact is not inferred',
        uncertainty: 'High',
      );
    }
    if (_textual.any(name.contains)) {
      return NewsImpactAnalysis(
        eventId: event.id,
        usdImpact: PotentialImpact.uncertain,
        xauUsdImpact: PotentialImpact.uncertain,
        reason: 'Manual interpretation required for textual events',
        uncertainty: 'High',
      );
    }
    if (event.actual == null || event.forecast == null) {
      return NewsImpactAnalysis(
        eventId: event.id,
        usdImpact: PotentialImpact.uncertain,
        xauUsdImpact: PotentialImpact.uncertain,
        reason: 'Actual and forecast values are both required',
        uncertainty: 'High',
      );
    }
    final surprise = event.actual! - event.forecast!;
    if (surprise == 0) {
      return NewsImpactAnalysis(
        eventId: event.id,
        surprise: 0,
        usdImpact: PotentialImpact.neutral,
        xauUsdImpact: PotentialImpact.neutral,
        reason: 'Actual matched forecast',
        uncertainty: 'Medium',
      );
    }
    final inverse =
        name.contains('unemployment') || name.contains('jobless claims');
    final usdPositive = inverse ? surprise < 0 : surprise > 0;
    return NewsImpactAnalysis(
      eventId: event.id,
      surprise: surprise,
      usdImpact: usdPositive
          ? PotentialImpact.positive
          : PotentialImpact.negative,
      xauUsdImpact: usdPositive
          ? PotentialImpact.negative
          : PotentialImpact.positive,
      reason: inverse
          ? 'Lower-than-forecast value is conventionally USD-supportive for this indicator'
          : 'Potential impact is based on the event-specific forecast surprise',
      uncertainty: event.impact == NewsImpact.high ? 'Medium' : 'High',
    );
  }
}

const _textual = <String>['speech', 'statement', 'minutes', 'press conference'];
