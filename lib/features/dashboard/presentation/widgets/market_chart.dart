import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/app_settings.dart';
import '../../domain/analysis_models.dart';
import '../../domain/dashboard_state.dart';
import '../../domain/harmonic_models.dart';
import '../../domain/market_models.dart';
import '../../domain/price_action_models.dart';
import '../../domain/trading_decision_models.dart';
import '../dashboard_cubit.dart';
import 'dashboard_card.dart';

class MarketChart extends StatefulWidget {
  const MarketChart({
    required this.timeframe,
    required this.symbol,
    required this.candles,
    required this.status,
    required this.digits,
    required this.indicators,
    required this.zones,
    required this.visibleIndicators,
    required this.advancedMode,
    required this.patterns,
    required this.fibonacci,
    required this.selectedPatternId,
    required this.hiddenPatternIds,
    required this.showAllPatterns,
    required this.marketAnalysis,
    required this.selectedMarketDetectionId,
    required this.tradingDecision,
    super.key,
  });

  final String timeframe;
  final String symbol;
  final List<Candle> candles;
  final MarketStatus status;
  final int digits;
  final IndicatorSnapshot? indicators;
  final List<PriceZone> zones;
  final Set<IndicatorLayer> visibleIndicators;
  final bool advancedMode;
  final List<HarmonicPattern> patterns;
  final FibonacciAnalysis? fibonacci;
  final String? selectedPatternId;
  final Set<String> hiddenPatternIds;
  final bool showAllPatterns;
  final PriceActionSmcSnapshot marketAnalysis;
  final String? selectedMarketDetectionId;
  final TradingDecision tradingDecision;

  @override
  State<MarketChart> createState() => _MarketChartState();
}

class _MarketChartState extends State<MarketChart> {
  final TransformationController _transformationController =
      TransformationController();
  Offset? _crosshairPosition;
  int? _hoveredIndex;
  _DrawingTool _drawingTool = _DrawingTool.cursor;
  final List<_ManualDrawing> _drawings = [];
  final List<_ManualDrawing> _redoDrawings = [];
  final List<_ChartAnchor> _pendingAnchors = [];
  bool _drawingsVisible = true;
  bool _drawingsLocked = false;
  int? _selectedDrawingIndex;

  FlTransformationConfig get _transformation => FlTransformationConfig(
    scaleAxis: FlScaleAxis.horizontal,
    minScale: 1,
    maxScale: 6,
    panEnabled: true,
    scaleEnabled: true,
    trackpadScrollCausesScale: true,
    transformationController: _transformationController,
  );

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MarketChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPatternId != null &&
        widget.selectedPatternId != oldWidget.selectedPatternId) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusSelectedPattern(),
      );
    }
  }

  void _focusSelectedPattern() {
    if (!mounted || widget.candles.length < 2) return;
    final pattern = widget.patterns
        .where((item) => item.id == widget.selectedPatternId)
        .firstOrNull;
    if (pattern == null || pattern.points.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final indices = pattern.points.values.map((point) => point.candleIndex);
    final centerIndex =
        (indices.reduce(math.min) + indices.reduce(math.max)) / 2;
    final plotWidth = math.max(1.0, box.size.width - 58);
    const scale = 2.4;
    final sourceX = centerIndex / (widget.candles.length - 1) * plotWidth;
    final matrix = Matrix4.identity();
    matrix.storage[0] = scale;
    matrix.storage[12] = plotWidth / 2 - sourceX * scale;
    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    final candles = widget.candles;
    if (candles.isEmpty) {
      return DashboardCard(
        child: Center(
          child: widget.status == MarketStatus.loading
              ? const CircularProgressIndicator()
              : Text(
                  widget.status.dataLabel,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    }
    final indicators = widget.indicators;
    final spots = candles.indexed
        .map(
          (entry) => CandlestickSpot(
            x: entry.$1.toDouble(),
            open: entry.$2.open,
            high: entry.$2.high,
            low: entry.$2.low,
            close: entry.$2.close,
          ),
        )
        .toList();
    final minY = candles.map((c) => c.low).reduce(math.min) - 2;
    final maxY = candles.map((c) => c.high).reduce(math.max) + 2;
    final latest = _hoveredIndex != null && _hoveredIndex! < candles.length
        ? candles[_hoveredIndex!]
        : candles.last;
    final modeLabel = widget.status.dataLabel;

    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 8, 13, 4),
            child: Row(
              children: [
                Text(
                  '${widget.symbol} · ${widget.timeframe} · $modeLabel',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'O ${_price(latest.open)}   H ${_price(latest.high)}   L ${_price(latest.low)}   C ${_price(latest.close)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 10,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.text('fitToData'),
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  color: AppColors.muted,
                  onPressed: _resetChart,
                  icon: const Icon(Icons.fit_screen_outlined),
                ),
                if (widget.advancedMode)
                  IconButton(
                    tooltip: context.l10n.text('fullscreen'),
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    color: AppColors.muted,
                    onPressed: () => _openFullscreen(context),
                    icon: const Icon(Icons.fullscreen),
                  ),
                Text(
                  _hoveredIndex == null
                      ? context.l10n.text('zoomPan')
                      : candles[_hoveredIndex!].time.toLocal().toString(),
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _toggle('EMA 20', IndicatorLayer.ema20, AppColors.cyan),
                _toggle('EMA 50', IndicatorLayer.ema50, AppColors.amber),
                _toggle('Volume', IndicatorLayer.volume, AppColors.green),
                if (widget.advancedMode) ...[
                  _toggle('EMA 200', IndicatorLayer.ema200, AppColors.red),
                  _toggle(
                    'S/R',
                    IndicatorLayer.supportResistance,
                    AppColors.purple,
                  ),
                  _toggle('RSI', IndicatorLayer.rsi, AppColors.purple),
                  _toggle('MACD', IndicatorLayer.macd, AppColors.cyan),
                  _toggle('ADX', IndicatorLayer.adx, AppColors.amber),
                  _toggle(
                    'Harmonic',
                    IndicatorLayer.harmonicPatterns,
                    AppColors.purple,
                  ),
                  _toggle(
                    'Fibonacci',
                    IndicatorLayer.fibonacci,
                    AppColors.cyan,
                  ),
                  _toggle(
                    'Trade Setup',
                    IndicatorLayer.tradingSetup,
                    AppColors.green,
                  ),
                  _toggle(
                    'BOS / CHoCH',
                    IndicatorLayer.marketStructure,
                    AppColors.amber,
                  ),
                  _toggle(
                    'Order Block',
                    IndicatorLayer.orderBlocks,
                    AppColors.purple,
                  ),
                  _toggle('FVG', IndicatorLayer.fairValueGaps, AppColors.cyan),
                  _toggle(
                    'Liquidity',
                    IndicatorLayer.liquiditySweeps,
                    AppColors.amber,
                  ),
                  _toggle(
                    'Price Action',
                    IndicatorLayer.priceAction,
                    AppColors.green,
                  ),
                  _drawingTools(),
                ],
                if (widget.advancedMode) ...[
                  _harmonicAction(
                    context.l10n.text('showAllHarmonics'),
                    _showAllHarmonics,
                  ),
                  _harmonicAction(
                    context.l10n.text('hideAllHarmonics'),
                    _hideAllHarmonics,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, chartConstraints) => MouseRegion(
                cursor: SystemMouseCursors.precise,
                onHover: (event) => _updateCrosshair(
                  event.localPosition,
                  chartConstraints.biggest,
                  candles.length,
                ),
                onExit: (_) => setState(() {
                  _crosshairPosition = null;
                  _hoveredIndex = null;
                }),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: _drawingTool == _DrawingTool.cursor
                      ? null
                      : (details) => _handleDrawingTap(
                          details.localPosition,
                          chartConstraints.biggest,
                          minY,
                          maxY,
                          candles,
                        ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: CandlestickChart(
                          CandlestickChartData(
                            candlestickSpots: spots,
                            minX: 0,
                            maxX: (spots.length - 1).toDouble(),
                            minY: minY,
                            maxY: maxY,
                            backgroundColor: AppColors.background,
                            rangeAnnotations: RangeAnnotations(
                              horizontalRangeAnnotations:
                                  widget.visibleIndicators.contains(
                                    IndicatorLayer.supportResistance,
                                  )
                                  ? widget.zones
                                        .map(
                                          (zone) => HorizontalRangeAnnotation(
                                            y1: zone.lower,
                                            y2: zone.upper,
                                            color:
                                                (zone.type ==
                                                            PriceZoneType
                                                                .support
                                                        ? AppColors.green
                                                        : AppColors.red)
                                                    .withValues(alpha: .12),
                                          ),
                                        )
                                        .toList()
                                  : const [],
                            ),
                            candlestickPainter: DefaultCandlestickPainter(
                              candlestickStyleProvider: (spot, _) {
                                final color = spot.isUp
                                    ? AppColors.green
                                    : AppColors.red;
                                return CandlestickStyle(
                                  lineColor: color,
                                  lineWidth: 1,
                                  bodyStrokeColor: color,
                                  bodyStrokeWidth: 1,
                                  bodyFillColor: color.withValues(alpha: .82),
                                  bodyWidth: 5,
                                  bodyRadius: 1,
                                );
                              },
                            ),
                            gridData: FlGridData(
                              verticalInterval: 8,
                              horizontalInterval: 5,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.border.withValues(alpha: .48),
                                strokeWidth: .7,
                              ),
                              getDrawingVerticalLine: (_) => FlLine(
                                color: AppColors.border.withValues(alpha: .35),
                                strokeWidth: .7,
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: AppColors.border),
                            ),
                            titlesData: _titles(showText: true),
                          ),
                          duration: Duration.zero,
                          transformationConfig: _transformation,
                        ),
                      ),
                      if (indicators != null)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: IgnorePointer(
                              child: LineChart(
                                LineChartData(
                                  minX: 0,
                                  maxX: (candles.length - 1).toDouble(),
                                  minY: minY,
                                  maxY: maxY,
                                  lineBarsData: _emaLines(indicators),
                                  titlesData: _titles(showText: false),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  lineTouchData: const LineTouchData(
                                    enabled: false,
                                  ),
                                  backgroundColor: Colors.transparent,
                                  clipData: const FlClipData.all(),
                                ),
                                duration: Duration.zero,
                                transformationConfig: _transformation,
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CurrentPricePainter(
                              price: candles.last.close,
                              candleCount: candles.length,
                              minY: minY,
                              maxY: maxY,
                              digits: widget.digits,
                              controller: _transformationController,
                            ),
                          ),
                        ),
                      ),
                      if (widget.visibleIndicators.contains(
                            IndicatorLayer.tradingSetup,
                          ) &&
                          widget.tradingDecision.hasExecutableSetup)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _TradeSetupPainter(
                                levels: widget.tradingDecision.levels!,
                                action: widget.tradingDecision.action,
                                candleCount: candles.length,
                                minY: minY,
                                maxY: maxY,
                                digits: widget.digits,
                                controller: _transformationController,
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _HarmonicOverlayPainter(
                              candles: candles,
                              patterns: _displayPatterns(),
                              fibonacci: widget.fibonacci,
                              minY: minY,
                              maxY: maxY,
                              controller: _transformationController,
                              showPatterns: widget.visibleIndicators.contains(
                                IndicatorLayer.harmonicPatterns,
                              ),
                              showFibonacci: widget.visibleIndicators.contains(
                                IndicatorLayer.fibonacci,
                              ),
                              selectedPatternId: widget.selectedPatternId,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PriceActionSmcOverlayPainter(
                              analysis: widget.marketAnalysis,
                              candleCount: candles.length,
                              minY: minY,
                              maxY: maxY,
                              controller: _transformationController,
                              visibleIndicators: widget.visibleIndicators,
                              selectedId: widget.selectedMarketDetectionId,
                            ),
                          ),
                        ),
                      ),
                      if (widget.advancedMode && _drawingsVisible)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _ManualDrawingPainter(
                                drawings: List.unmodifiable(_drawings),
                                pendingAnchors: List.unmodifiable(
                                  _pendingAnchors,
                                ),
                                candleCount: candles.length,
                                minY: minY,
                                maxY: maxY,
                                controller: _transformationController,
                                selectedIndex: _selectedDrawingIndex,
                              ),
                            ),
                          ),
                        ),
                      if (_crosshairPosition != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CrosshairPainter(
                                position: _crosshairPosition!,
                                candle: latest,
                                digits: widget.digits,
                                minY: minY,
                                maxY: maxY,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (indicators != null) ...[
            if (widget.visibleIndicators.contains(IndicatorLayer.rsi))
              _IndicatorStrip(
                label: 'RSI 14  ${_value(indicators.latestRsi)}',
                lines: [_series(indicators.rsi14, AppColors.purple)],
                minY: 0,
                maxY: 100,
                controller: _transformationController,
              ),
            if (widget.visibleIndicators.contains(IndicatorLayer.macd))
              _IndicatorStrip(
                label: 'MACD 12/26/9  ${_value(indicators.latestMacd)}',
                lines: [
                  _series(indicators.macd, AppColors.cyan),
                  _series(indicators.macdSignal, AppColors.amber),
                ],
                controller: _transformationController,
              ),
            if (widget.visibleIndicators.contains(IndicatorLayer.adx))
              _IndicatorStrip(
                label: 'ADX 14  ${_value(indicators.latestAdx)}',
                lines: [_series(indicators.adx14, AppColors.amber)],
                minY: 0,
                maxY: 100,
                controller: _transformationController,
              ),
          ],
          if (widget.visibleIndicators.contains(IndicatorLayer.volume))
            _VolumeStrip(
              candles: candles,
              average: indicators?.averageVolume20 ?? const [],
              controller: _transformationController,
            ),
        ],
      ),
    );
  }

  void _resetChart() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _crosshairPosition = null;
      _hoveredIndex = null;
    });
  }

  void _updateCrosshair(Offset position, Size size, int candleCount) {
    final scale = _transformationController.value.storage[0];
    final translation = _transformationController.value.storage[12];
    final plotWidth = math.max(1.0, size.width - 58);
    final rawX = (position.dx - translation) / math.max(.0001, scale);
    final index = (rawX / plotWidth * (candleCount - 1)).round().clamp(
      0,
      candleCount - 1,
    );
    setState(() {
      _crosshairPosition = position;
      _hoveredIndex = index;
    });
  }

  Future<void> _openFullscreen(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    return showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: Dialog.fullscreen(
          backgroundColor: AppColors.background,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: MarketChart(
                  timeframe: widget.timeframe,
                  symbol: widget.symbol,
                  candles: widget.candles,
                  status: widget.status,
                  digits: widget.digits,
                  indicators: widget.indicators,
                  zones: widget.zones,
                  visibleIndicators: widget.visibleIndicators,
                  advancedMode: widget.advancedMode,
                  patterns: widget.patterns,
                  fibonacci: widget.fibonacci,
                  selectedPatternId: widget.selectedPatternId,
                  hiddenPatternIds: widget.hiddenPatternIds,
                  showAllPatterns: widget.showAllPatterns,
                  marketAnalysis: widget.marketAnalysis,
                  selectedMarketDetectionId: widget.selectedMarketDetectionId,
                  tradingDecision: widget.tradingDecision,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: dialogContext.l10n.text('exitFullscreen'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.fullscreen_exit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<HarmonicPattern> _displayPatterns() {
    final visible = widget.patterns
        .where((pattern) => !widget.hiddenPatternIds.contains(pattern.id))
        .toList();
    if (widget.showAllPatterns) return visible;
    final result = visible
        .where((pattern) => pattern.status != HarmonicPatternStatus.invalidated)
        .take(3)
        .toList();
    final selected = visible
        .where((pattern) => pattern.id == widget.selectedPatternId)
        .firstOrNull;
    if (selected != null && !result.any((item) => item.id == selected.id)) {
      if (result.length >= 3) result.removeLast();
      result.add(selected);
    }
    return result;
  }

  Widget _drawingTools() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      InkWell(
        onTap: () => _openLayers(context),
        child: _toolIcon(
          Icons.layers_outlined,
          context.l10n.text('objectTree'),
        ),
      ),
      PopupMenuButton<_DrawingTool>(
        tooltip: context.l10n.text('drawingTools'),
        initialValue: _drawingTool,
        onSelected: (tool) => setState(() {
          _drawingTool = tool;
          _pendingAnchors.clear();
        }),
        itemBuilder: (_) => _DrawingTool.values
            .map(
              (tool) => PopupMenuItem(
                value: tool,
                child: Text(
                  _drawingLabel(context, tool),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            )
            .toList(),
        child: _toolIcon(
          Icons.draw_outlined,
          _drawingLabel(context, _drawingTool),
        ),
      ),
      InkWell(
        onTap: _drawings.isEmpty || _drawingsLocked
            ? null
            : () => setState(() {
                _redoDrawings.add(_drawings.removeLast());
                _pendingAnchors.clear();
              }),
        child: _toolIcon(Icons.undo, 'Undo'),
      ),
      InkWell(
        onTap: _redoDrawings.isEmpty || _drawingsLocked
            ? null
            : () => setState(() => _drawings.add(_redoDrawings.removeLast())),
        child: _toolIcon(Icons.redo, 'Redo'),
      ),
      InkWell(
        onTap: () => setState(() => _drawingsLocked = !_drawingsLocked),
        child: _toolIcon(
          _drawingsLocked ? Icons.lock : Icons.lock_open,
          _drawingsLocked ? 'Unlock drawings' : 'Lock drawings',
        ),
      ),
      InkWell(
        onTap: () => setState(() => _drawingsVisible = !_drawingsVisible),
        child: _toolIcon(
          _drawingsVisible ? Icons.visibility : Icons.visibility_off,
          _drawingsVisible ? 'Hide drawings' : 'Show drawings',
        ),
      ),
      InkWell(
        onTap: _drawings.isEmpty || _drawingsLocked
            ? null
            : () => setState(() {
                _drawings.removeLast();
                _redoDrawings.clear();
              }),
        child: _toolIcon(Icons.delete_outline, 'Delete last drawing'),
      ),
    ],
  );

  Widget _harmonicAction(String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.only(right: 5),
    child: ActionChip(
      visualDensity: const VisualDensity(horizontal: -3, vertical: -4),
      label: Text(label, style: const TextStyle(fontSize: 9)),
      onPressed: action,
    ),
  );

  void _showAllHarmonics() {
    final cubit = context.read<DashboardCubit>();
    final hidden = Set<String>.of(widget.hiddenPatternIds)
      ..removeAll(widget.patterns.map((item) => item.id));
    cubit.setHarmonicDisplaySettings(hiddenPatternIds: hidden, showAll: true);
    if (!cubit.state.visibleIndicators.contains(
      IndicatorLayer.harmonicPatterns,
    )) {
      cubit.toggleIndicator(IndicatorLayer.harmonicPatterns);
    }
    AppSettingsScope.of(
      context,
    ).setHarmonicDisplay(hiddenPatternIds: hidden, showAll: true);
    AppSettingsScope.of(context).setVisibleIndicatorNames(
      cubit.state.visibleIndicators.map((item) => item.name).toSet(),
    );
  }

  void _hideAllHarmonics() {
    final cubit = context.read<DashboardCubit>();
    final hidden = Set<String>.of(widget.hiddenPatternIds)
      ..addAll(widget.patterns.map((item) => item.id));
    cubit.setHarmonicDisplaySettings(
      hiddenPatternIds: hidden,
      showAll: widget.showAllPatterns,
    );
    AppSettingsScope.of(context).setHarmonicDisplay(
      hiddenPatternIds: hidden,
      showAll: widget.showAllPatterns,
    );
  }

  Widget _toolIcon(IconData icon, String tooltip) => Tooltip(
    message: tooltip,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Icon(icon, size: 15, color: AppColors.muted),
    ),
  );

  Future<void> _openLayers(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: context.read<DashboardCubit>(),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) => AlertDialog(
          title: Text(context.l10n.text('objectTree')),
          content: SizedBox(
            width: 430,
            height: 480,
            child: ListView(
              children: [
                for (final item in const [
                  ('Harmonic Patterns', [IndicatorLayer.harmonicPatterns]),
                  ('Fibonacci', [IndicatorLayer.fibonacci]),
                  (
                    'Indicators',
                    [
                      IndicatorLayer.ema20,
                      IndicatorLayer.ema50,
                      IndicatorLayer.ema200,
                      IndicatorLayer.rsi,
                      IndicatorLayer.macd,
                      IndicatorLayer.adx,
                      IndicatorLayer.volume,
                      IndicatorLayer.supportResistance,
                    ],
                  ),
                  ('Price Action', [IndicatorLayer.priceAction]),
                  (
                    'Smart Money',
                    [
                      IndicatorLayer.marketStructure,
                      IndicatorLayer.orderBlocks,
                      IndicatorLayer.fairValueGaps,
                      IndicatorLayer.liquiditySweeps,
                    ],
                  ),
                ])
                  SwitchListTile.adaptive(
                    dense: true,
                    title: Text(item.$1),
                    value: item.$2.every(state.visibleIndicators.contains),
                    onChanged: (enabled) =>
                        _setLayerGroup(context, item.$2, enabled),
                  ),
                SwitchListTile.adaptive(
                  dense: true,
                  title: Text(context.l10n.text('manualDrawings')),
                  value: _drawingsVisible,
                  onChanged: (value) {
                    setState(() => _drawingsVisible = value);
                    Navigator.of(dialogContext).pop();
                    _openLayers(this.context);
                  },
                ),
                for (final entry in _drawings.indexed)
                  ListTile(
                    dense: true,
                    selected: _selectedDrawingIndex == entry.$1,
                    leading: const Icon(Icons.draw, size: 16),
                    title: Text(
                      '${entry.$1 + 1}. ${_drawingLabel(context, entry.$2.type)}',
                    ),
                    onTap: () {
                      setState(() => _selectedDrawingIndex = entry.$1);
                      Navigator.of(dialogContext).pop();
                      _openLayers(this.context);
                    },
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        _nudgeButton(Icons.arrow_back, entry.$1, -1, 0),
                        _nudgeButton(Icons.arrow_forward, entry.$1, 1, 0),
                        _nudgeButton(Icons.arrow_upward, entry.$1, 0, 1),
                        _nudgeButton(Icons.arrow_downward, entry.$1, 0, -1),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 15,
                          onPressed: _drawingsLocked
                              ? null
                              : () {
                                  setState(() {
                                    _drawings.removeAt(entry.$1);
                                    _selectedDrawingIndex = null;
                                  });
                                  Navigator.of(dialogContext).pop();
                                  _openLayers(this.context);
                                },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                for (final pattern in widget.patterns)
                  ListTile(
                    dense: true,
                    selected: state.selectedPatternId == pattern.id,
                    title: Text(
                      '${pattern.displayName} · ${pattern.direction.name} · ${pattern.timeframe}',
                    ),
                    subtitle: Text(
                      '${pattern.status.name} · ${(pattern.geometryScore * 100).round()}%',
                    ),
                    onTap: () => context.read<DashboardCubit>().selectPattern(
                      pattern.id,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        state.hiddenPatternIds.contains(pattern.id)
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        final cubit = context.read<DashboardCubit>();
                        cubit.togglePatternVisibility(pattern.id);
                        AppSettingsScope.of(this.context).setHarmonicDisplay(
                          hiddenPatternIds: cubit.state.hiddenPatternIds,
                          showAll: cubit.state.showAllPatterns,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.text('close')),
            ),
          ],
        ),
      ),
    ),
  );

  void _setLayerGroup(
    BuildContext context,
    List<IndicatorLayer> layers,
    bool enabled,
  ) {
    final cubit = context.read<DashboardCubit>();
    for (final layer in layers) {
      final isVisible = cubit.state.visibleIndicators.contains(layer);
      if (isVisible != enabled) cubit.toggleIndicator(layer);
    }
    AppSettingsScope.of(this.context).setVisibleIndicatorNames(
      cubit.state.visibleIndicators.map((item) => item.name).toSet(),
    );
  }

  String _drawingLabel(BuildContext context, _DrawingTool tool) =>
      context.l10n.text(switch (tool) {
        _DrawingTool.cursor => 'selectPan',
        _DrawingTool.trendline => 'trendline',
        _DrawingTool.horizontalLine => 'horizontalLine',
        _DrawingTool.rectangle => 'rectangleZone',
        _DrawingTool.fibonacciRetracement => 'fibRetracement',
        _DrawingTool.fibonacciExtension => 'fibExtension',
        _DrawingTool.xabcd => 'xabcdDrawing',
        _DrawingTool.measure => 'priceTimeMeasure',
      });

  Widget _nudgeButton(
    IconData icon,
    int drawingIndex,
    int candleDelta,
    int priceDirection,
  ) => IconButton(
    visualDensity: VisualDensity.compact,
    iconSize: 14,
    onPressed: _drawingsLocked
        ? null
        : () {
            _nudgeDrawing(drawingIndex, candleDelta, priceDirection);
            Navigator.of(context, rootNavigator: true).pop();
            _openLayers(context);
          },
    icon: Icon(icon),
  );

  void _nudgeDrawing(int index, int candleDelta, int priceDirection) {
    if (index < 0 || index >= _drawings.length || widget.candles.isEmpty) {
      return;
    }
    final low = widget.candles.map((item) => item.low).reduce(math.min);
    final high = widget.candles.map((item) => item.high).reduce(math.max);
    final priceDelta = (high - low) * .01 * priceDirection;
    final drawing = _drawings[index];
    setState(() {
      _drawings[index] = _ManualDrawing(
        type: drawing.type,
        anchors: drawing.anchors
            .map(
              (anchor) => _ChartAnchor(
                index: (anchor.index + candleDelta).clamp(
                  0,
                  widget.candles.length - 1,
                ),
                price: anchor.price + priceDelta,
              ),
            )
            .toList(growable: false),
      );
      _selectedDrawingIndex = index;
    });
  }

  void _handleDrawingTap(
    Offset position,
    Size size,
    double minY,
    double maxY,
    List<Candle> candles,
  ) {
    if (_drawingsLocked || candles.isEmpty) return;
    final anchor = _toAnchor(position, size, minY, maxY, candles);
    final requiredPoints = switch (_drawingTool) {
      _DrawingTool.horizontalLine => 1,
      _DrawingTool.xabcd => 5,
      _DrawingTool.cursor => 0,
      _ => 2,
    };
    if (requiredPoints == 0) return;
    setState(() {
      _pendingAnchors.add(anchor);
      if (_pendingAnchors.length >= requiredPoints) {
        _drawings.add(
          _ManualDrawing(
            type: _drawingTool,
            anchors: List.unmodifiable(_pendingAnchors),
          ),
        );
        _selectedDrawingIndex = _drawings.length - 1;
        _pendingAnchors.clear();
        _redoDrawings.clear();
      }
    });
  }

  _ChartAnchor _toAnchor(
    Offset position,
    Size size,
    double minY,
    double maxY,
    List<Candle> candles,
  ) {
    final scale = _transformationController.value.storage[0];
    final translation = _transformationController.value.storage[12];
    final plotWidth = math.max(1.0, size.width - 58);
    final rawX = (position.dx - translation) / math.max(.0001, scale);
    final index = (rawX / plotWidth * (candles.length - 1)).round().clamp(
      0,
      candles.length - 1,
    );
    final plotHeight = math.max(1.0, size.height - 22);
    final price =
        maxY - (position.dy.clamp(0, plotHeight) / plotHeight) * (maxY - minY);
    return _ChartAnchor(index: index, price: price);
  }

  Widget _toggle(String label, IndicatorLayer layer, Color color) {
    final selected = widget.visibleIndicators.contains(layer);
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        visualDensity: const VisualDensity(horizontal: -3, vertical: -4),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: selected ? color : AppColors.muted,
          ),
        ),
        backgroundColor: AppColors.background,
        selectedColor: color.withValues(alpha: .13),
        side: BorderSide(
          color: selected ? color.withValues(alpha: .6) : AppColors.border,
        ),
        onSelected: (_) {
          final cubit = context.read<DashboardCubit>();
          cubit.toggleIndicator(
            layer,
            maximumVisible: widget.advancedMode ? null : 2,
          );
          if (widget.advancedMode) {
            AppSettingsScope.of(context).setVisibleIndicatorNames(
              cubit.state.visibleIndicators.map((item) => item.name).toSet(),
            );
          }
        },
      ),
    );
  }

  List<LineChartBarData> _emaLines(IndicatorSnapshot value) => [
    if (widget.visibleIndicators.contains(IndicatorLayer.ema20))
      _series(value.ema20, AppColors.cyan),
    if (widget.visibleIndicators.contains(IndicatorLayer.ema50))
      _series(value.ema50, AppColors.amber),
    if (widget.visibleIndicators.contains(IndicatorLayer.ema200))
      _series(value.ema200, AppColors.red),
  ];

  FlTitlesData _titles({required bool showText}) => FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 52,
        interval: 10,
        getTitlesWidget: (value, meta) => showText
            ? Text(
                value.toStringAsFixed(widget.digits),
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              )
            : const SizedBox.shrink(),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 22,
        interval: 12,
        getTitlesWidget: (value, meta) => showText
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _axisTime(value),
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ),
  );

  String _axisTime(double value) {
    final index = value.round();
    if (index < 0 || index >= widget.candles.length) return '';
    final time = widget.candles[index].time.toUtc();
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _price(double value) => value.toStringAsFixed(widget.digits);
  String _value(double? value) => value?.toStringAsFixed(2) ?? '—';
}

class ChartOverlayMapper {
  const ChartOverlayMapper({
    required this.size,
    required this.candleCount,
    required this.minY,
    required this.maxY,
    required this.transform,
  });

  final Size size;
  final int candleCount;
  final double minY;
  final double maxY;
  final Matrix4 transform;

  Offset map(int candleIndex, double price) {
    final plotWidth = math.max(1.0, size.width - 58);
    final plotHeight = math.max(1.0, size.height - 22);
    final x = candleCount <= 1
        ? 0.0
        : candleIndex / (candleCount - 1) * plotWidth;
    final transformed = MatrixUtils.transformPoint(transform, Offset(x, 0));
    final y = (maxY - price) / math.max(.0000001, maxY - minY) * plotHeight;
    return Offset(transformed.dx, y);
  }

  Rect get clipRect => Rect.fromLTWH(
    0,
    0,
    math.max(1.0, size.width - 58),
    math.max(1.0, size.height - 22),
  );
}

class _HarmonicOverlayPainter extends CustomPainter {
  _HarmonicOverlayPainter({
    required this.candles,
    required this.patterns,
    required this.fibonacci,
    required this.minY,
    required this.maxY,
    required this.controller,
    required this.showPatterns,
    required this.showFibonacci,
    required this.selectedPatternId,
  }) : super(repaint: controller);

  final List<Candle> candles;
  final List<HarmonicPattern> patterns;
  final FibonacciAnalysis? fibonacci;
  final double minY;
  final double maxY;
  final TransformationController controller;
  final bool showPatterns;
  final bool showFibonacci;
  final String? selectedPatternId;

  @override
  void paint(Canvas canvas, Size size) {
    final mapper = ChartOverlayMapper(
      size: size,
      candleCount: candles.length,
      minY: minY,
      maxY: maxY,
      transform: controller.value,
    );
    canvas.save();
    canvas.clipRect(mapper.clipRect);
    if (showFibonacci && fibonacci != null) {
      final startX = mapper.map(fibonacci!.start.candleIndex, minY).dx;
      for (final level in fibonacci!.levels) {
        final y = mapper.map(0, level.price).dy;
        canvas.drawLine(
          Offset(startX, y),
          Offset(mapper.clipRect.right, y),
          Paint()
            ..color = AppColors.cyan.withValues(alpha: .48)
            ..strokeWidth = .8,
        );
        _text(
          canvas,
          '${level.ratio}',
          Offset(startX + 3, y - 11),
          AppColors.cyan,
        );
      }
      for (final zone in fibonacci!.confluenceZones) {
        final top = mapper.map(0, zone.upper).dy;
        final bottom = mapper.map(0, zone.lower).dy;
        canvas.drawRect(
          Rect.fromLTRB(startX, top, mapper.clipRect.right, bottom),
          Paint()..color = AppColors.amber.withValues(alpha: .08),
        );
      }
    }
    if (showPatterns) {
      for (final pattern in patterns) {
        final selected = pattern.id == selectedPatternId;
        final color = pattern.status == HarmonicPatternStatus.invalidated
            ? AppColors.muted
            : pattern.direction == PatternDirection.bullish
            ? AppColors.green
            : AppColors.red;
        final points = pattern.points.entries.toList();
        Offset? previousPoint;
        for (var index = 0; index < points.length; index++) {
          final point = mapper.map(
            points[index].value.candleIndex,
            points[index].value.price,
          );
          if (previousPoint != null) {
            _drawSegment(
              canvas,
              previousPoint,
              point,
              color,
              width: selected ? 3 : 1.5,
              dashed: pattern.status == HarmonicPatternStatus.forming,
            );
            final ratio = index - 1 < pattern.ratios.length
                ? pattern.ratios.entries.elementAt(index - 1)
                : null;
            if (ratio != null) {
              _text(
                canvas,
                '${ratio.key} ${ratio.value.toStringAsFixed(3)}',
                Offset(
                  (previousPoint.dx + point.dx) / 2 + 3,
                  (previousPoint.dy + point.dy) / 2 - 11,
                ),
                color.withValues(alpha: .85),
              );
            }
          }
          canvas.drawCircle(point, selected ? 4 : 3, Paint()..color = color);
          _text(canvas, points[index].key, point + const Offset(4, -14), color);
          previousPoint = point;
        }
        final anchor = points.last.value;
        final anchorPoint = mapper.map(anchor.candleIndex, anchor.price);
        _text(
          canvas,
          '${pattern.displayName} · ${pattern.status.name}',
          anchorPoint + const Offset(7, 5),
          color,
        );
        final top = mapper.map(0, pattern.przUpper).dy;
        final bottom = mapper.map(0, pattern.przLower).dy;
        canvas.drawRect(
          Rect.fromLTRB(anchorPoint.dx, top, mapper.clipRect.right, bottom),
          Paint()..color = color.withValues(alpha: .1),
        );
      }
    }
    canvas.restore();
  }

  void _text(Canvas canvas, String value, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawSegment(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color, {
    required double width,
    required bool dashed,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    if (!dashed) {
      canvas.drawLine(from, to, paint);
      return;
    }
    final delta = to - from;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    for (var offset = 0.0; offset < distance; offset += 9) {
      canvas.drawLine(
        from + direction * offset,
        from + direction * math.min(offset + 5, distance),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HarmonicOverlayPainter oldDelegate) =>
      oldDelegate.patterns != patterns ||
      oldDelegate.fibonacci != fibonacci ||
      oldDelegate.showPatterns != showPatterns ||
      oldDelegate.showFibonacci != showFibonacci ||
      oldDelegate.selectedPatternId != selectedPatternId ||
      oldDelegate.minY != minY ||
      oldDelegate.maxY != maxY;
}

class _TradeSetupPainter extends CustomPainter {
  _TradeSetupPainter({
    required this.levels,
    required this.action,
    required this.candleCount,
    required this.minY,
    required this.maxY,
    required this.digits,
    required this.controller,
  }) : super(repaint: controller);

  final TradeSetupLevels levels;
  final TradingDecisionAction action;
  final int candleCount;
  final double minY;
  final double maxY;
  final int digits;
  final TransformationController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final mapper = ChartOverlayMapper(
      size: size,
      candleCount: candleCount,
      minY: minY,
      maxY: maxY,
      transform: controller.value,
    );
    final values = <(String, double, Color)>[
      ('ENTRY', levels.entry, AppColors.cyan),
      ('SL', levels.stopLoss, AppColors.red),
      ('TP1', levels.takeProfit1, AppColors.green),
      ('TP2', levels.takeProfit2, AppColors.green),
    ];
    canvas.save();
    canvas.clipRect(mapper.clipRect);
    final entryY = mapper.map(0, levels.entry).dy;
    final stopY = mapper.map(0, levels.stopLoss).dy;
    final targetY = mapper.map(0, levels.takeProfit1).dy;
    canvas.drawRect(
      Rect.fromLTRB(
        mapper.clipRect.left,
        math.min(entryY, targetY),
        mapper.clipRect.right,
        math.max(entryY, targetY),
      ),
      Paint()..color = AppColors.green.withValues(alpha: .045),
    );
    canvas.drawRect(
      Rect.fromLTRB(
        mapper.clipRect.left,
        math.min(entryY, stopY),
        mapper.clipRect.right,
        math.max(entryY, stopY),
      ),
      Paint()..color = AppColors.red.withValues(alpha: .045),
    );
    for (final value in values) {
      final y = mapper.map(0, value.$2).dy;
      final paint = Paint()
        ..color = value.$3.withValues(alpha: .85)
        ..strokeWidth = value.$1 == 'ENTRY' ? 1.5 : 1;
      canvas.drawLine(
        Offset(mapper.clipRect.left, y),
        Offset(mapper.clipRect.right, y),
        paint,
      );
      final text = TextPainter(
        text: TextSpan(
          text: '${value.$1} ${value.$2.toStringAsFixed(digits)}',
          style: TextStyle(
            color: value.$3,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(mapper.clipRect.left + 5, y - 13));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TradeSetupPainter oldDelegate) =>
      oldDelegate.levels != levels ||
      oldDelegate.action != action ||
      oldDelegate.minY != minY ||
      oldDelegate.maxY != maxY ||
      oldDelegate.candleCount != candleCount;
}

class _CurrentPricePainter extends CustomPainter {
  _CurrentPricePainter({
    required this.price,
    required this.candleCount,
    required this.minY,
    required this.maxY,
    required this.digits,
    required this.controller,
  }) : super(repaint: controller);

  final double price;
  final int candleCount;
  final double minY;
  final double maxY;
  final int digits;
  final TransformationController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final mapper = ChartOverlayMapper(
      size: size,
      candleCount: candleCount,
      minY: minY,
      maxY: maxY,
      transform: controller.value,
    );
    final y = mapper.map(0, price).dy;
    final paint = Paint()
      ..color = AppColors.green.withValues(alpha: .72)
      ..strokeWidth = .8;
    for (var x = mapper.clipRect.left; x < mapper.clipRect.right; x += 8) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 4, mapper.clipRect.right), y),
        paint,
      );
    }
    final text = TextPainter(
      text: TextSpan(
        text: price.toStringAsFixed(digits),
        style: const TextStyle(color: AppColors.green, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(mapper.clipRect.right - text.width - 3, y - 12));
  }

  @override
  bool shouldRepaint(covariant _CurrentPricePainter oldDelegate) =>
      oldDelegate.price != price ||
      oldDelegate.candleCount != candleCount ||
      oldDelegate.minY != minY ||
      oldDelegate.maxY != maxY ||
      oldDelegate.digits != digits;
}

class _CrosshairPainter extends CustomPainter {
  const _CrosshairPainter({
    required this.position,
    required this.candle,
    required this.digits,
    required this.minY,
    required this.maxY,
  });

  final Offset position;
  final Candle candle;
  final int digits;
  final double minY;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(0, 0, math.max(1, size.width - 58), size.height);
    if (!plot.contains(position)) return;
    final paint = Paint()
      ..color = AppColors.muted.withValues(alpha: .65)
      ..strokeWidth = .7;
    canvas.drawLine(
      Offset(position.dx, plot.top),
      Offset(position.dx, plot.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(plot.left, position.dy),
      Offset(plot.right, position.dy),
      paint,
    );
    final price =
        maxY - (position.dy / math.max(1.0, size.height - 22)) * (maxY - minY);
    final label = price.toStringAsFixed(digits);
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromLTWH(
      plot.right - 1,
      (position.dy - text.height / 2 - 3).clamp(
        0,
        size.height - text.height - 6,
      ),
      text.width + 8,
      text.height + 6,
    );
    canvas.drawRect(rect, Paint()..color = AppColors.surfaceAlt);
    text.paint(canvas, rect.topLeft + const Offset(4, 3));
    final timeText = TextPainter(
      text: TextSpan(
        text: candle.time.toLocal().toString(),
        style: const TextStyle(color: AppColors.text, fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final timeX = (position.dx - timeText.width / 2)
        .clamp(0.0, math.max(0.0, plot.right - timeText.width))
        .toDouble();
    final timeRect = Rect.fromLTWH(
      timeX,
      math.max(0.0, size.height - timeText.height - 4),
      timeText.width + 4,
      timeText.height + 4,
    );
    canvas.drawRect(timeRect, Paint()..color = AppColors.surfaceAlt);
    timeText.paint(canvas, timeRect.topLeft + const Offset(2, 2));
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.candle != candle ||
      oldDelegate.digits != digits ||
      oldDelegate.minY != minY ||
      oldDelegate.maxY != maxY;
}

enum _DrawingTool {
  cursor,
  trendline,
  horizontalLine,
  rectangle,
  fibonacciRetracement,
  fibonacciExtension,
  xabcd,
  measure,
}

class _ChartAnchor {
  const _ChartAnchor({required this.index, required this.price});
  final int index;
  final double price;
}

class _ManualDrawing {
  _ManualDrawing({required this.type, required this.anchors});
  final _DrawingTool type;
  final List<_ChartAnchor> anchors;
}

class _ManualDrawingPainter extends CustomPainter {
  _ManualDrawingPainter({
    required this.drawings,
    required this.pendingAnchors,
    required this.candleCount,
    required this.minY,
    required this.maxY,
    required this.controller,
    required this.selectedIndex,
  }) : super(repaint: controller);

  final List<_ManualDrawing> drawings;
  final List<_ChartAnchor> pendingAnchors;
  final int candleCount;
  final double minY;
  final double maxY;
  final TransformationController controller;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final mapper = ChartOverlayMapper(
      size: size,
      candleCount: candleCount,
      minY: minY,
      maxY: maxY,
      transform: controller.value,
    );
    canvas.save();
    canvas.clipRect(mapper.clipRect);
    for (final entry in drawings.indexed) {
      _paintDrawing(
        canvas,
        mapper,
        entry.$2,
        selected: entry.$1 == selectedIndex,
      );
    }
    for (final anchor in pendingAnchors) {
      canvas.drawCircle(
        mapper.map(anchor.index, anchor.price),
        4,
        Paint()..color = AppColors.amber,
      );
    }
    canvas.restore();
  }

  void _paintDrawing(
    Canvas canvas,
    ChartOverlayMapper mapper,
    _ManualDrawing drawing, {
    required bool selected,
  }) {
    final points = drawing.anchors
        .map((anchor) => mapper.map(anchor.index, anchor.price))
        .toList();
    final paint = Paint()
      ..color = AppColors.cyan.withValues(alpha: .9)
      ..strokeWidth = selected ? 2.4 : 1.2
      ..style = PaintingStyle.stroke;
    if (drawing.type == _DrawingTool.horizontalLine) {
      canvas.drawLine(
        Offset(mapper.clipRect.left, points.first.dy),
        Offset(mapper.clipRect.right, points.first.dy),
        paint,
      );
      return;
    }
    if (points.length < 2) return;
    if (drawing.type == _DrawingTool.rectangle) {
      final rect = Rect.fromPoints(points[0], points[1]);
      canvas.drawRect(
        rect,
        Paint()..color = AppColors.cyan.withValues(alpha: .08),
      );
      canvas.drawRect(rect, paint);
      return;
    }
    if (drawing.type == _DrawingTool.fibonacciRetracement ||
        drawing.type == _DrawingTool.fibonacciExtension) {
      final levels = drawing.type == _DrawingTool.fibonacciRetracement
          ? const [0.0, .236, .382, .5, .618, .786, 1.0]
          : const [0.0, 1.0, 1.272, 1.618, 2.0, 2.618];
      final left = math.min(points[0].dx, points[1].dx);
      final right = mapper.clipRect.right;
      for (final ratio in levels) {
        final y = points[0].dy + (points[1].dy - points[0].dy) * ratio;
        canvas.drawLine(Offset(left, y), Offset(right, y), paint);
        _label(canvas, ratio.toStringAsFixed(3), Offset(left + 3, y - 11));
      }
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
    if (drawing.type == _DrawingTool.xabcd) {
      const labels = ['X', 'A', 'B', 'C', 'D'];
      for (
        var index = 0;
        index < math.min(points.length, labels.length);
        index++
      ) {
        canvas.drawCircle(points[index], 3, Paint()..color = AppColors.cyan);
        _label(canvas, labels[index], points[index] + const Offset(4, -13));
      }
    } else if (drawing.type == _DrawingTool.measure) {
      final a = drawing.anchors.first;
      final b = drawing.anchors.last;
      final delta = b.price - a.price;
      _label(
        canvas,
        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(3)} · ${b.index - a.index} bars',
        Offset(
          (points[0].dx + points[1].dx) / 2,
          (points[0].dy + points[1].dy) / 2,
        ),
      );
    }
  }

  void _label(Canvas canvas, String value, Offset position) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          color: AppColors.cyan,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _ManualDrawingPainter oldDelegate) =>
      oldDelegate.drawings != drawings ||
      oldDelegate.pendingAnchors != pendingAnchors ||
      oldDelegate.candleCount != candleCount ||
      oldDelegate.minY != minY ||
      oldDelegate.maxY != maxY ||
      oldDelegate.selectedIndex != selectedIndex;
}

LineChartBarData _series(List<double?> values, Color color) => LineChartBarData(
  spots: values.indexed
      .where((entry) => entry.$2 != null)
      .map((entry) => FlSpot(entry.$1.toDouble(), entry.$2!))
      .toList(),
  color: color,
  barWidth: 1.2,
  dotData: const FlDotData(show: false),
  isCurved: false,
);

class _IndicatorStrip extends StatelessWidget {
  const _IndicatorStrip({
    required this.label,
    required this.lines,
    required this.controller,
    this.minY,
    this.maxY,
  });

  final String label;
  final List<LineChartBarData> lines;
  final TransformationController controller;
  final double? minY;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    final all = lines
        .expand((line) => line.spots.map((spot) => spot.y))
        .toList();
    final low = minY ?? (all.isEmpty ? -1 : all.reduce(math.min));
    final high = maxY ?? (all.isEmpty ? 1 : all.reduce(math.max));
    final padding = high == low ? 1.0 : (high - low) * .12;
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IgnorePointer(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: lines
                      .expand((line) => line.spots)
                      .fold<double>(0, (max, spot) => math.max(max, spot.x)),
                  minY: minY ?? low - padding,
                  maxY: maxY ?? high + padding,
                  lineBarsData: lines,
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                ),
                duration: Duration.zero,
                transformationConfig: FlTransformationConfig(
                  scaleAxis: FlScaleAxis.horizontal,
                  minScale: 1,
                  maxScale: 6,
                  transformationController: controller,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 4,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeStrip extends StatelessWidget {
  const _VolumeStrip({
    required this.candles,
    required this.average,
    required this.controller,
  });

  final List<Candle> candles;
  final List<double?> average;
  final TransformationController controller;

  @override
  Widget build(BuildContext context) {
    final maxVolume = candles.map((c) => c.volume).reduce(math.max).toDouble();
    final transform = FlTransformationConfig(
      scaleAxis: FlScaleAxis.horizontal,
      minScale: 1,
      maxScale: 6,
      transformationController: controller,
    );
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: math.max(1, maxVolume * 1.15),
                alignment: BarChartAlignment.spaceAround,
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 52),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barTouchData: BarTouchData(enabled: false),
                barGroups: candles.indexed
                    .map(
                      (entry) => BarChartGroupData(
                        x: entry.$1,
                        barRods: [
                          BarChartRodData(
                            toY: entry.$2.volume.toDouble(),
                            width: 4,
                            color:
                                (entry.$2.close >= entry.$2.open
                                        ? AppColors.green
                                        : AppColors.red)
                                    .withValues(alpha: .65),
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
              duration: Duration.zero,
              transformationConfig: transform,
            ),
          ),
          if (average.any((value) => value != null))
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IgnorePointer(
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (candles.length - 1).toDouble(),
                      minY: 0,
                      maxY: math.max(1, maxVolume * 1.15),
                      lineBarsData: [_series(average, AppColors.amber)],
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                    ),
                    duration: Duration.zero,
                    transformationConfig: transform,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 8,
            top: 4,
            child: Text(
              'Volume ${candles.last.volume}   Avg20 ${average.isEmpty || average.last == null ? '—' : average.last!.toStringAsFixed(1)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceActionSmcOverlayPainter extends CustomPainter {
  _PriceActionSmcOverlayPainter({
    required this.analysis,
    required this.candleCount,
    required this.minY,
    required this.maxY,
    required this.controller,
    required this.visibleIndicators,
    required this.selectedId,
  }) : super(repaint: controller);

  final PriceActionSmcSnapshot analysis;
  final int candleCount;
  final double minY;
  final double maxY;
  final TransformationController controller;
  final Set<IndicatorLayer> visibleIndicators;
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    if (candleCount == 0) return;
    final mapper = ChartOverlayMapper(
      size: size,
      candleCount: candleCount,
      minY: minY,
      maxY: maxY,
      transform: controller.value,
    );
    canvas.save();
    canvas.clipRect(mapper.clipRect);

    if (visibleIndicators.contains(IndicatorLayer.orderBlocks)) {
      for (final zone in analysis.orderBlocks) {
        final color = _directionColor(zone.direction);
        final start = mapper.map(zone.candleIndex, zone.upper).dx;
        final top = mapper.map(0, zone.upper).dy;
        final bottom = mapper.map(0, zone.lower).dy;
        final selected = zone.id == selectedId;
        canvas.drawRect(
          Rect.fromLTRB(start, top, mapper.clipRect.right, bottom),
          Paint()
            ..color = color.withValues(
              alpha: zone.status == ZoneStatus.mitigated ? .07 : .13,
            )
            ..style = PaintingStyle.fill,
        );
        canvas.drawLine(
          Offset(start, top),
          Offset(mapper.clipRect.right, top),
          Paint()
            ..color = color.withValues(alpha: .7)
            ..strokeWidth = selected ? 2.2 : 1,
        );
        _label(canvas, 'OB', Offset(start + 3, top + 2), color, selected);
      }
    }

    if (visibleIndicators.contains(IndicatorLayer.fairValueGaps)) {
      for (final gap in analysis.fairValueGaps) {
        final color = _directionColor(gap.direction);
        final start = mapper.map(gap.candleIndex, gap.upper).dx;
        final top = mapper.map(0, gap.upper).dy;
        final bottom = mapper.map(0, gap.lower).dy;
        final selected = gap.id == selectedId;
        final opacity = switch (gap.status) {
          FairValueGapStatus.unfilled => .12,
          FairValueGapStatus.partiallyFilled => .07,
          FairValueGapStatus.filled => .025,
        };
        canvas.drawRect(
          Rect.fromLTRB(start, top, mapper.clipRect.right, bottom),
          Paint()..color = color.withValues(alpha: opacity),
        );
        if (selected) {
          canvas.drawRect(
            Rect.fromLTRB(start, top, mapper.clipRect.right, bottom),
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        _label(canvas, 'FVG', Offset(start + 3, top + 2), color, selected);
      }
    }

    if (visibleIndicators.contains(IndicatorLayer.marketStructure)) {
      for (final marketBreak in analysis.structureBreaks) {
        final color = _directionColor(marketBreak.direction);
        final start = mapper.map(
          marketBreak.sourceCandleIndex,
          marketBreak.level,
        );
        final end = mapper.map(marketBreak.breakCandleIndex, marketBreak.level);
        final selected = marketBreak.id == selectedId;
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = color.withValues(alpha: .85)
            ..strokeWidth = selected ? 2.5 : 1.2,
        );
        _label(
          canvas,
          marketBreak.type == StructureBreakType.changeOfCharacter
              ? 'CHoCH'
              : 'BOS',
          Offset(end.dx - 30, end.dy - 14),
          color,
          selected,
        );
      }
    }

    if (visibleIndicators.contains(IndicatorLayer.liquiditySweeps)) {
      for (final sweep in analysis.liquiditySweeps) {
        final color = _directionColor(sweep.direction);
        final point = mapper.map(sweep.sweepCandleIndex, sweep.level);
        final selected = sweep.id == selectedId;
        canvas.drawCircle(
          point,
          selected ? 6 : 4,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = selected ? 2.5 : 1.5,
        );
        _label(canvas, 'SWEEP', point + const Offset(5, -13), color, selected);
      }
    }

    if (visibleIndicators.contains(IndicatorLayer.priceAction)) {
      for (final pattern in analysis.priceActionPatterns) {
        final direction = pattern.direction;
        final color = direction == null
            ? AppColors.amber
            : _directionColor(direction);
        final point = mapper.map(pattern.candleIndex, pattern.level);
        final selected = pattern.id == selectedId;
        final path = Path()
          ..moveTo(point.dx, point.dy - (selected ? 7 : 5))
          ..lineTo(point.dx - (selected ? 6 : 4), point.dy + 3)
          ..lineTo(point.dx + (selected ? 6 : 4), point.dy + 3)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: pattern.lowConfidence ? .45 : .9),
        );
      }
    }
    canvas.restore();
  }

  Color _directionColor(MarketDirection direction) =>
      direction == MarketDirection.bullish ? AppColors.green : AppColors.red;

  void _label(
    Canvas canvas,
    String value,
    Offset offset,
    Color color,
    bool selected,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: selected ? 10 : 8,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _PriceActionSmcOverlayPainter oldDelegate) =>
      oldDelegate.analysis != analysis ||
      oldDelegate.visibleIndicators != visibleIndicators ||
      oldDelegate.selectedId != selectedId ||
      oldDelegate.minY != minY ||
      oldDelegate.maxY != maxY ||
      oldDelegate.candleCount != candleCount;
}
