import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/forex_factory_calendar_provider.dart';
import '../../domain/dashboard_state.dart';
import '../../domain/economic_news_models.dart';
import '../dashboard_cubit.dart';
import 'dashboard_card.dart';

enum _DateFilter { today, tomorrow, week, custom, all }

class EconomicCalendarPanel extends StatefulWidget {
  const EconomicCalendarPanel({this.compact = false, super.key});
  final bool compact;

  @override
  State<EconomicCalendarPanel> createState() => _EconomicCalendarPanelState();
}

class _EconomicCalendarPanelState extends State<EconomicCalendarPanel> {
  _DateFilter _dateFilter = _DateFilter.week;
  String _search = '';
  bool _releasedOnly = false;
  bool _sortByImpact = false;
  DateTime? _customDate;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (previous, current) =>
          previous.economicCalendar != current.economicCalendar ||
          previous.newsRisk != current.newsRisk ||
          previous.alerts != current.alerts,
      builder: (context, state) {
        final calendar = state.economicCalendar;
        final events = _filtered(calendar.events, settings);
        return DashboardCard(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, state, settings),
              if (!widget.compact && settings.isAdvanced) ...[
                const SizedBox(height: 8),
                _filters(context),
              ],
              const SizedBox(height: 7),
              if (calendar.errorMessage.isNotEmpty)
                Text(
                  calendar.errorMessage,
                  style: const TextStyle(color: AppColors.red, fontSize: 9),
                ),
              Expanded(
                child: events.isEmpty
                    ? _empty(context, calendar.status)
                    : _table(context, events, calendar.analyses, settings),
              ),
              if (!widget.compact) _footer(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _header(
    BuildContext context,
    DashboardState state,
    AppSettingsController settings,
  ) => Row(
    children: [
      const Icon(Icons.newspaper, color: AppColors.red, size: 18),
      const SizedBox(width: 7),
      Text(
        _t(context, 'تقویم اقتصادی', 'Economic Calendar'),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(width: 7),
      _StatusBadge(state.economicCalendar.status),
      if (state.newsRisk.blocksNewEntries) ...[
        const SizedBox(width: 5),
        const _MiniBadge('NEWS RISK', AppColors.red),
      ],
      const Spacer(),
      if (!widget.compact) ...[
        IconButton(
          tooltip: _t(context, 'تنظیمات خبر', 'News settings'),
          onPressed: () => _settings(context, settings),
          icon: const Icon(Icons.tune, size: 17),
        ),
        IconButton(
          tooltip: _t(context, 'بازکردن Forex Factory', 'Open Forex Factory'),
          onPressed: _openOfficialCalendar,
          icon: const Icon(Icons.open_in_new, size: 17),
        ),
      ],
      FilledButton.tonalIcon(
        onPressed: state.economicCalendar.status == NewsDataStatus.loading
            ? null
            : () => _import(context),
        icon: const Icon(Icons.file_upload_outlined, size: 15),
        label: Text(
          _t(context, 'ورود فایل', 'Import'),
          style: const TextStyle(fontSize: 9),
        ),
      ),
    ],
  );

  Widget _filters(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final filter in _DateFilter.values)
        ChoiceChip(
          label: Text(
            _dateLabel(context, filter),
            style: const TextStyle(fontSize: 9),
          ),
          selected: _dateFilter == filter,
          onSelected: (_) async {
            if (filter == _DateFilter.custom) {
              final value = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
                initialDate: _customDate ?? DateTime.now(),
              );
              if (value == null || !mounted) return;
              setState(() {
                _customDate = value;
                _dateFilter = filter;
              });
            } else {
              setState(() => _dateFilter = filter);
            }
          },
          visualDensity: VisualDensity.compact,
        ),
      SizedBox(
        width: 190,
        height: 34,
        child: TextField(
          onChanged: (value) => setState(() => _search = value),
          style: const TextStyle(fontSize: 10),
          decoration: InputDecoration(
            hintText: _t(context, 'جستجوی خبر', 'Search events'),
            prefixIcon: const Icon(Icons.search, size: 16),
            contentPadding: const EdgeInsets.symmetric(vertical: 5),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      FilterChip(
        label: Text(
          _t(context, 'منتشرشده', 'Released'),
          style: const TextStyle(fontSize: 9),
        ),
        selected: _releasedOnly,
        onSelected: (value) => setState(() => _releasedOnly = value),
      ),
      FilterChip(
        label: Text(
          _t(context, 'مرتب‌سازی اهمیت', 'Sort by impact'),
          style: const TextStyle(fontSize: 9),
        ),
        selected: _sortByImpact,
        onSelected: (value) => setState(() => _sortByImpact = value),
      ),
    ],
  );

  Widget _table(
    BuildContext context,
    List<EconomicEvent> events,
    Map<String, NewsImpactAnalysis> analyses,
    AppSettingsController settings,
  ) {
    if (widget.compact) {
      return ListView.builder(
        itemCount: events.length.clamp(0, 4),
        itemBuilder: (context, index) => _compactRow(
          context,
          events[index],
          analyses[events[index].id],
          settings,
        ),
      );
    }
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 32,
          dataRowMinHeight: 39,
          dataRowMaxHeight: 46,
          columnSpacing: 20,
          columns:
              [
                    'Time',
                    'Currency',
                    'Impact',
                    'Event',
                    'Actual',
                    'Forecast',
                    'Previous',
                  ]
                  .map(
                    (label) => DataColumn(
                      label: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          rows: events.map((event) {
            final impact = analyses[event.id];
            return DataRow(
              onSelectChanged: (_) =>
                  _details(context, event, impact, settings),
              cells: [
                DataCell(
                  Text(
                    _time(event, settings),
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
                DataCell(
                  Text(
                    event.currency,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: event.currency == 'USD'
                          ? FontWeight.w900
                          : FontWeight.normal,
                      color: event.currency == 'USD' ? AppColors.cyan : null,
                    ),
                  ),
                ),
                DataCell(_ImpactBadge(event.impact)),
                DataCell(
                  SizedBox(
                    width: 230,
                    child: Text(
                      event.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
                DataCell(_number(event.actual, event.forecast, event.unit)),
                DataCell(_plainNumber(event.forecast, event.unit)),
                DataCell(_plainNumber(event.previous, event.unit)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _compactRow(
    BuildContext context,
    EconomicEvent event,
    NewsImpactAnalysis? analysis,
    AppSettingsController settings,
  ) => ListTile(
    dense: true,
    visualDensity: const VisualDensity(vertical: -4),
    contentPadding: EdgeInsets.zero,
    leading: SizedBox(
      width: 58,
      child: Text(
        _time(event, settings),
        style: const TextStyle(color: AppColors.muted, fontSize: 8),
      ),
    ),
    title: Text(
      '${event.currency}  ${event.name}',
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      _countdown(context, event),
      style: const TextStyle(color: AppColors.muted, fontSize: 8),
    ),
    trailing: _ImpactBadge(event.impact),
    onTap: () => _details(context, event, analysis, settings),
  );

  List<EconomicEvent> _filtered(
    List<EconomicEvent> source,
    AppSettingsController settings,
  ) {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final advanced = settings.isAdvanced && !widget.compact;
    final result = source.where((event) {
      if (!advanced &&
          (event.currency != 'USD' || event.impact != NewsImpact.high)) {
        return false;
      }
      if (advanced &&
          settings.newsCurrencies.isNotEmpty &&
          !settings.newsCurrencies.contains(event.currency)) {
        return false;
      }
      if (advanced &&
          settings.newsImpacts.isNotEmpty &&
          !settings.newsImpacts.contains(event.impact.name)) {
        return false;
      }
      if (_releasedOnly && event.actual == null) return false;
      if (_search.isNotEmpty &&
          !event.name.toLowerCase().contains(_search.toLowerCase()) &&
          !event.currency.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      final date = event.scheduledUtc;
      if (date == null || !advanced) return true;
      final day = DateTime.utc(date.year, date.month, date.day);
      return switch (_dateFilter) {
        _DateFilter.today => day == today,
        _DateFilter.tomorrow => day == today.add(const Duration(days: 1)),
        _DateFilter.week =>
          day.difference(today).inDays >= 0 && day.difference(today).inDays < 7,
        _DateFilter.custom =>
          _customDate != null &&
              day ==
                  DateTime.utc(
                    _customDate!.year,
                    _customDate!.month,
                    _customDate!.day,
                  ),
        _DateFilter.all => true,
      };
    }).toList();
    result.sort((a, b) {
      if (_sortByImpact) {
        final impact = _impactRank(b.impact).compareTo(_impactRank(a.impact));
        if (impact != 0) return impact;
      }
      if (a.scheduledUtc == null) return 1;
      if (b.scheduledUtc == null) return -1;
      return a.scheduledUtc!.compareTo(b.scheduledUtc!);
    });
    return result;
  }

  Widget _footer(BuildContext context, DashboardState state) => Row(
    children: [
      Text(
        '${_t(context, 'آخرین بروزرسانی', 'Last updated')}: '
        '${state.economicCalendar.lastUpdatedUtc?.toLocal() ?? '—'}',
        style: const TextStyle(color: AppColors.muted, fontSize: 8),
      ),
      const Spacer(),
      Text(
        '${state.alerts.where((item) => !item.read).length} alerts',
        style: const TextStyle(color: AppColors.amber, fontSize: 8),
      ),
    ],
  );

  Widget _empty(BuildContext context, NewsDataStatus status) => Center(
    child: Text(
      status == NewsDataStatus.loading
          ? _t(context, 'در حال بارگذاری...', 'Loading...')
          : _t(
              context,
              'فایل JSON یا CSV رسمی را وارد کنید.',
              'Import an official JSON or CSV export.',
            ),
      style: const TextStyle(color: AppColors.muted),
    ),
  );

  Future<void> _import(BuildContext context) async {
    const group = XTypeGroup(
      label: 'Economic calendar',
      extensions: ['json', 'csv'],
    );
    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null || !context.mounted) return;
    final contents = await file.readAsString();
    if (!context.mounted) return;
    final extension = file.name.split('.').last;
    await context.read<DashboardCubit>().importEconomicCalendar(
      contents,
      extension,
    );
  }

  Future<void> _openOfficialCalendar() => Process.start('explorer.exe', [
    ForexFactoryCalendarProvider.calendarUrl,
  ], mode: ProcessStartMode.detached);

  Future<void> _details(
    BuildContext context,
    EconomicEvent event,
    NewsImpactAnalysis? analysis,
    AppSettingsController settings,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(event.name),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${event.currency} • ${event.impact.name.toUpperCase()}'),
            Text('${_t(context, 'زمان', 'Time')}: ${_time(event, settings)}'),
            Text('${_t(context, 'منبع', 'Source')}: ${event.source}'),
            Text(
              'Actual ${event.actual ?? '—'}  Forecast ${event.forecast ?? '—'}  Previous ${event.previous ?? '—'}',
            ),
            const Divider(),
            Text(
              'Potential USD Impact: ${analysis?.usdImpact.name ?? 'uncertain'}',
            ),
            Text(
              'Potential XAUUSD Impact: ${analysis?.xauUsdImpact.name ?? 'uncertain'}',
            ),
            Text('Surprise: ${analysis?.surprise ?? '—'} ${event.unit ?? ''}'),
            Text(analysis?.reason ?? 'No directional interpretation'),
            Text('Uncertainty: ${analysis?.uncertainty ?? 'High'}'),
            if (!event.timeZoneKnown)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: FilledButton.tonal(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _correctTime(context, event, settings);
                  },
                  child: Text(
                    _t(context, 'اصلاح دستی زمان', 'Correct time manually'),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _correctTime(
    BuildContext context,
    EconomicEvent event,
    AppSettingsController settings,
  ) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !context.mounted) return;
    var corrected = DateTime.utc(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (settings.newsTimeZone == 'Asia/Tehran') {
      corrected = corrected.subtract(const Duration(hours: 3, minutes: 30));
    }
    await context.read<DashboardCubit>().correctEconomicEventTime(
      event.id,
      corrected,
    );
  }

  Future<void> _settings(
    BuildContext context,
    AppSettingsController settings,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(_t(context, 'اخبار و هشدارها', 'Economic News & Alerts')),
      content: StatefulBuilder(
        builder: (context, setDialogState) => SizedBox(
          width: 460,
          height: 650,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const ListTile(
                  dense: true,
                  title: Text('Provider: Forex Factory Manual Export'),
                  subtitle: Text('Auto Fetch: NOT AUTHORIZED'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: settings.newsTimeZone,
                  decoration: const InputDecoration(labelText: 'Time Zone'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Asia/Tehran',
                      child: Text('Asia/Tehran'),
                    ),
                    DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                  ],
                  onChanged: (value) {
                    if (value != null) settings.setNewsTimeZone(value);
                  },
                ),
                ListTile(
                  dense: true,
                  title: Text(
                    'News risk before: ${settings.newsRiskBeforeMinutes} min',
                  ),
                  subtitle: Slider(
                    value: settings.newsRiskBeforeMinutes.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 12,
                    onChanged: (value) {
                      settings.setNewsRiskWindow(
                        beforeMinutes: value.round(),
                        afterMinutes: settings.newsRiskAfterMinutes,
                      );
                      context.read<DashboardCubit>().configureNewsRisk(
                        beforeMinutes: value.round(),
                        afterMinutes: settings.newsRiskAfterMinutes,
                      );
                      setDialogState(() {});
                    },
                  ),
                ),
                ListTile(
                  dense: true,
                  title: Text(
                    'News risk after: ${settings.newsRiskAfterMinutes} min',
                  ),
                  subtitle: Slider(
                    value: settings.newsRiskAfterMinutes.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 12,
                    onChanged: (value) {
                      settings.setNewsRiskWindow(
                        beforeMinutes: settings.newsRiskBeforeMinutes,
                        afterMinutes: value.round(),
                      );
                      context.read<DashboardCubit>().configureNewsRisk(
                        beforeMinutes: settings.newsRiskBeforeMinutes,
                        afterMinutes: value.round(),
                      );
                      setDialogState(() {});
                    },
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Wrap(
                    spacing: 5,
                    children: ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD']
                        .map(
                          (currency) => FilterChip(
                            label: Text(currency),
                            selected: settings.newsCurrencies.contains(
                              currency,
                            ),
                            onSelected: (selected) {
                              final currencies = Set<String>.of(
                                settings.newsCurrencies,
                              );
                              selected
                                  ? currencies.add(currency)
                                  : currencies.remove(currency);
                              settings.setNewsFilters(
                                currencies: currencies,
                                impacts: settings.newsImpacts,
                              );
                              setDialogState(() {});
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Wrap(
                    spacing: 5,
                    children: NewsImpact.values
                        .map(
                          (impact) => FilterChip(
                            label: Text(impact.name.toUpperCase()),
                            selected: settings.newsImpacts.contains(
                              impact.name,
                            ),
                            onSelected: (selected) {
                              final impacts = Set<String>.of(
                                settings.newsImpacts,
                              );
                              selected
                                  ? impacts.add(impact.name)
                                  : impacts.remove(impact.name);
                              settings.setNewsFilters(
                                currencies: settings.newsCurrencies,
                                impacts: impacts,
                              );
                              setDialogState(() {});
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Alert types'),
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: AlertType.values.map((type) {
                        final enabled = settings.enabledAlertTypes.contains(
                          type.name,
                        );
                        return FilterChip(
                          label: Text(
                            type.name,
                            style: const TextStyle(fontSize: 8),
                          ),
                          selected: enabled,
                          onSelected: (selected) {
                            final values = Set<String>.of(
                              settings.enabledAlertTypes,
                            );
                            selected
                                ? values.add(type.name)
                                : values.remove(type.name);
                            settings.setEnabledAlertTypes(values);
                            context.read<DashboardCubit>().configureAlerts(
                              values,
                            );
                            setDialogState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Silent alerts'),
                  value: settings.silentAlerts,
                  onChanged: (value) {
                    settings.setAlertPreferences(
                      silent: value,
                      sound: settings.alertSound,
                      windowsNotifications: settings.windowsNotifications,
                    );
                    setDialogState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Alert sound'),
                  value: settings.alertSound,
                  onChanged: (value) {
                    settings.setAlertPreferences(
                      silent: settings.silentAlerts,
                      sound: value,
                      windowsNotifications: settings.windowsNotifications,
                    );
                    setDialogState(() {});
                  },
                ),
                const SwitchListTile(
                  title: Text('Windows notifications'),
                  subtitle: Text('Not configured'),
                  value: false,
                  onChanged: null,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  String _time(EconomicEvent event, AppSettingsController settings) {
    final utc = event.scheduledUtc;
    if (utc == null) return 'TZ UNKNOWN';
    final value = settings.newsTimeZone == 'Asia/Tehran'
        ? utc.add(const Duration(hours: 3, minutes: 30))
        : utc;
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.month)}/${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
  }

  String _countdown(BuildContext context, EconomicEvent event) {
    if (event.scheduledUtc == null) {
      return _t(context, 'منطقه زمانی نامشخص', 'Time zone unknown');
    }
    final delta = event.scheduledUtc!.difference(DateTime.now().toUtc());
    if (delta.isNegative) return _t(context, 'منتشرشده', 'Released');
    if (delta.inDays > 0) return '${delta.inDays}d ${delta.inHours % 24}h';
    return '${delta.inHours}h ${delta.inMinutes % 60}m ${delta.inSeconds % 60}s';
  }

  Widget _number(double? actual, double? forecast, String? unit) {
    final color = actual == null || forecast == null
        ? AppColors.muted
        : actual > forecast
        ? AppColors.green
        : actual < forecast
        ? AppColors.red
        : AppColors.muted;
    return Text(
      actual == null ? '—' : '$actual${unit ?? ''}',
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
    );
  }

  Widget _plainNumber(double? value, String? unit) => Text(
    value == null ? '—' : '$value${unit ?? ''}',
    style: const TextStyle(fontSize: 9),
  );
}

class AlertsPanel extends StatelessWidget {
  const AlertsPanel({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) => DashboardCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_none, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text(
                    _t(context, 'تاریخچه هشدارها', 'Notification History'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: context.read<DashboardCubit>().clearReadAlerts,
                    child: Text(
                      _t(context, 'پاک‌کردن خوانده‌شده‌ها', 'Clear read'),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: state.alerts.isEmpty
                    ? Center(
                        child: Text(
                          _t(context, 'هشداری ثبت نشده است', 'No alerts yet'),
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.alerts.length,
                        itemBuilder: (context, index) {
                          final alert = state.alerts[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.circle,
                              size: 8,
                              color: alert.read
                                  ? AppColors.muted
                                  : AppColors.amber,
                            ),
                            title: Text(alert.title),
                            subtitle: Text(alert.message),
                            trailing: Text(
                              alert.occurredAtUtc.toLocal().toString(),
                              style: const TextStyle(fontSize: 8),
                            ),
                            onTap: () => context
                                .read<DashboardCubit>()
                                .markAlertRead(alert.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final NewsDataStatus status;
  @override
  Widget build(BuildContext context) =>
      _MiniBadge(status.name.toUpperCase(), switch (status) {
        NewsDataStatus.live => AppColors.green,
        NewsDataStatus.imported => AppColors.cyan,
        NewsDataStatus.cached => AppColors.amber,
        NewsDataStatus.demo => AppColors.purple,
        NewsDataStatus.loading => AppColors.amber,
        NewsDataStatus.unavailable => AppColors.red,
      });
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge(this.impact);
  final NewsImpact impact;
  @override
  Widget build(BuildContext context) =>
      _MiniBadge(impact.name.toUpperCase(), switch (impact) {
        NewsImpact.high => AppColors.red,
        NewsImpact.medium => AppColors.amber,
        NewsImpact.low => AppColors.green,
        NewsImpact.unknown => AppColors.muted,
      });
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w800),
    ),
  );
}

int _impactRank(NewsImpact impact) => switch (impact) {
  NewsImpact.high => 3,
  NewsImpact.medium => 2,
  NewsImpact.low => 1,
  NewsImpact.unknown => 0,
};

String _dateLabel(BuildContext context, _DateFilter value) => switch (value) {
  _DateFilter.today => _t(context, 'امروز', 'Today'),
  _DateFilter.tomorrow => _t(context, 'فردا', 'Tomorrow'),
  _DateFilter.week => _t(context, 'این هفته', 'This week'),
  _DateFilter.custom => _t(context, 'تاریخ دلخواه', 'Custom date'),
  _DateFilter.all => _t(context, 'همه', 'All'),
};

String _t(BuildContext context, String fa, String en) =>
    context.l10n.isPersian ? fa : en;
