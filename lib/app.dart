import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_localizations.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/dashboard_page.dart';

class ForexApp extends StatefulWidget {
  const ForexApp({super.key});

  @override
  State<ForexApp> createState() => _ForexAppState();
}

class _ForexAppState extends State<ForexApp> {
  final _settings = AppSettingsController();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.load();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: _settings,
      child: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => context.l10n.text('appName'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: _settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _ready
              ? const DashboardPage()
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        ),
      ),
    );
  }
}
