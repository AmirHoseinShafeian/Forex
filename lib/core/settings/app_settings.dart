import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DashboardDisplayMode { simple, advanced }

class AppSettingsController extends ChangeNotifier {
  static const _localeKey = 'locale';
  static const _displayModeKey = 'dashboard_display_mode';
  static const _sidebarCollapsedKey = 'sidebar_collapsed';
  static const _visibleIndicatorsKey = 'visible_indicators';
  static const _hiddenHarmonicPatternsKey = 'hidden_harmonic_patterns';
  static const _showAllHarmonicPatternsKey = 'show_all_harmonic_patterns';
  static const _newsTimeZoneKey = 'news_time_zone';
  static const _newsRiskBeforeKey = 'news_risk_before_minutes';
  static const _newsRiskAfterKey = 'news_risk_after_minutes';
  static const _newsCurrenciesKey = 'news_currencies';
  static const _newsImpactsKey = 'news_impacts';
  static const _silentAlertsKey = 'silent_alerts';
  static const _alertSoundKey = 'alert_sound';
  static const _windowsNotificationsKey = 'windows_notifications';
  static const _enabledAlertTypesKey = 'enabled_alert_types';

  Locale _locale = const Locale('en');
  DashboardDisplayMode _displayMode = DashboardDisplayMode.simple;
  bool _sidebarCollapsed = false;
  Set<String> _visibleIndicatorNames = const {};
  Set<String> _hiddenHarmonicPatternIds = const {};
  bool _showAllHarmonicPatterns = false;
  String _newsTimeZone = 'Asia/Tehran';
  int _newsRiskBeforeMinutes = 30;
  int _newsRiskAfterMinutes = 15;
  Set<String> _newsCurrencies = const {'USD'};
  Set<String> _newsImpacts = const {'high', 'medium'};
  bool _silentAlerts = false;
  bool _alertSound = false;
  bool _windowsNotifications = false;
  Set<String> _enabledAlertTypes = const {
    'newsThirtyMinutes',
    'newsFifteenMinutes',
    'newsFiveMinutes',
    'newsRelease',
    'newsActual',
    'newsRevision',
    'decisionChanged',
    'priceNearEntry',
    'stopLossReached',
    'takeProfitReached',
    'harmonicConfirmed',
    'structureConfirmed',
    'abnormalSpread',
    'mt5Disconnected',
    'mt5Reconnected',
  };

  Locale get locale => _locale;
  DashboardDisplayMode get displayMode => _displayMode;
  bool get sidebarCollapsed => _sidebarCollapsed;
  bool get isAdvanced => _displayMode == DashboardDisplayMode.advanced;
  Set<String> get visibleIndicatorNames => _visibleIndicatorNames;
  Set<String> get hiddenHarmonicPatternIds => _hiddenHarmonicPatternIds;
  bool get showAllHarmonicPatterns => _showAllHarmonicPatterns;
  String get newsTimeZone => _newsTimeZone;
  int get newsRiskBeforeMinutes => _newsRiskBeforeMinutes;
  int get newsRiskAfterMinutes => _newsRiskAfterMinutes;
  Set<String> get newsCurrencies => _newsCurrencies;
  Set<String> get newsImpacts => _newsImpacts;
  bool get silentAlerts => _silentAlerts;
  bool get alertSound => _alertSound;
  bool get windowsNotifications => _windowsNotifications;
  Set<String> get enabledAlertTypes => _enabledAlertTypes;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _locale = Locale(preferences.getString(_localeKey) ?? 'en');
    _displayMode = preferences.getString(_displayModeKey) == 'advanced'
        ? DashboardDisplayMode.advanced
        : DashboardDisplayMode.simple;
    _sidebarCollapsed = preferences.getBool(_sidebarCollapsedKey) ?? false;
    _visibleIndicatorNames =
        preferences.getStringList(_visibleIndicatorsKey)?.toSet() ?? const {};
    _hiddenHarmonicPatternIds =
        preferences.getStringList(_hiddenHarmonicPatternsKey)?.toSet() ??
        const {};
    _showAllHarmonicPatterns =
        preferences.getBool(_showAllHarmonicPatternsKey) ?? false;
    _newsTimeZone = preferences.getString(_newsTimeZoneKey) ?? 'Asia/Tehran';
    _newsRiskBeforeMinutes = preferences.getInt(_newsRiskBeforeKey) ?? 30;
    _newsRiskAfterMinutes = preferences.getInt(_newsRiskAfterKey) ?? 15;
    _newsCurrencies =
        preferences.getStringList(_newsCurrenciesKey)?.toSet() ?? const {'USD'};
    _newsImpacts =
        preferences.getStringList(_newsImpactsKey)?.toSet() ??
        const {'high', 'medium'};
    _silentAlerts = preferences.getBool(_silentAlertsKey) ?? false;
    _alertSound = preferences.getBool(_alertSoundKey) ?? false;
    _windowsNotifications =
        preferences.getBool(_windowsNotificationsKey) ?? false;
    _enabledAlertTypes =
        preferences.getStringList(_enabledAlertTypesKey)?.toSet() ??
        _enabledAlertTypes;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, locale.languageCode);
  }

  Future<void> setDisplayMode(DashboardDisplayMode mode) async {
    if (_displayMode == mode) return;
    _displayMode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_displayModeKey, mode.name);
  }

  Future<void> toggleSidebar() async {
    _sidebarCollapsed = !_sidebarCollapsed;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_sidebarCollapsedKey, _sidebarCollapsed);
  }

  Future<void> setVisibleIndicatorNames(Set<String> names) async {
    _visibleIndicatorNames = Set.unmodifiable(names);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_visibleIndicatorsKey, names.toList());
  }

  Future<void> setHarmonicDisplay({
    required Set<String> hiddenPatternIds,
    required bool showAll,
  }) async {
    _hiddenHarmonicPatternIds = Set.unmodifiable(hiddenPatternIds);
    _showAllHarmonicPatterns = showAll;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _hiddenHarmonicPatternsKey,
      hiddenPatternIds.toList(),
    );
    await preferences.setBool(_showAllHarmonicPatternsKey, showAll);
  }

  Future<void> setNewsTimeZone(String value) async {
    if (value != 'Asia/Tehran' && value != 'UTC') return;
    _newsTimeZone = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_newsTimeZoneKey, value);
  }

  Future<void> setNewsRiskWindow({
    required int beforeMinutes,
    required int afterMinutes,
  }) async {
    _newsRiskBeforeMinutes = beforeMinutes.clamp(0, 180);
    _newsRiskAfterMinutes = afterMinutes.clamp(0, 180);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_newsRiskBeforeKey, _newsRiskBeforeMinutes);
    await preferences.setInt(_newsRiskAfterKey, _newsRiskAfterMinutes);
  }

  Future<void> setNewsFilters({
    required Set<String> currencies,
    required Set<String> impacts,
  }) async {
    _newsCurrencies = Set.unmodifiable(currencies);
    _newsImpacts = Set.unmodifiable(impacts);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_newsCurrenciesKey, currencies.toList());
    await preferences.setStringList(_newsImpactsKey, impacts.toList());
  }

  Future<void> setAlertPreferences({
    required bool silent,
    required bool sound,
    required bool windowsNotifications,
  }) async {
    _silentAlerts = silent;
    _alertSound = sound;
    _windowsNotifications = windowsNotifications;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_silentAlertsKey, silent);
    await preferences.setBool(_alertSoundKey, sound);
    await preferences.setBool(_windowsNotificationsKey, windowsNotifications);
  }

  Future<void> setEnabledAlertTypes(Set<String> values) async {
    _enabledAlertTypes = Set.unmodifiable(values);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_enabledAlertTypesKey, values.toList());
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    required AppSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()!.notifier!;
}
