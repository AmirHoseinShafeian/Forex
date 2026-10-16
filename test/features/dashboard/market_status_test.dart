import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forex/features/dashboard/domain/dashboard_state.dart';
import 'package:forex/features/dashboard/presentation/widgets/app_sidebar.dart';

void main() {
  test('market status exposes one consistent data and connection state', () {
    expect(const DashboardState().marketStatus, MarketStatus.loading);
    expect(MarketStatus.live.dataLabel, 'LIVE');
    expect(MarketStatus.live.connectionLabel, 'Connected');
    expect(MarketStatus.cached.dataLabel, 'CACHED');
    expect(MarketStatus.cached.connectionLabel, 'Disconnected');
    expect(MarketStatus.disconnected.canReconnect, isTrue);
  });

  testWidgets('sidebar shows mock mode only for demo data', (tester) async {
    Future<void> pumpStatus(MarketStatus status) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StatusBadge(status: status)),
      ),
    );

    await pumpStatus(MarketStatus.live);
    expect(find.textContaining('LIVE'), findsOneWidget);
    expect(find.textContaining('MOCK MODE'), findsNothing);

    await pumpStatus(MarketStatus.demo);
    expect(find.textContaining('MOCK MODE'), findsOneWidget);

    await pumpStatus(MarketStatus.cached);
    expect(find.textContaining('CACHED'), findsOneWidget);
    expect(find.textContaining('MOCK MODE'), findsNothing);
  });
}
