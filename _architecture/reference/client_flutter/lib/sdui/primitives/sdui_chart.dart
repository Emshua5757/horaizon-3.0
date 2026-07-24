import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

/// SduiChart - Type ID 26
/// 
/// High-performance data visualization primitive mapping Cartesian/Circular series
/// dynamically from HBP payloads using syncfusion_flutter_charts.
class SduiChart extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiChart({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiChart> createState() => _SduiChartState();
}

class _SduiChartState extends ConsumerState<SduiChart> {
  List<SduiChartDataPoint> _parsedData = [];
  dynamic _rawLastData;
  bool _isEditing = false;
  late TextEditingController _dataController;

  @override
  void initState() {
    super.initState();
    _parseData();
    _dataController = TextEditingController(text: _getRawDataString());
  }

  @override
  void didUpdateWidget(covariant SduiChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _parseData();
    if (widget.node.id != oldWidget.node.id) {
      _dataController.text = _getRawDataString();
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  String _getRawDataString() {
    final String bindKey = widget.node.behavior<String>(HbpBehavior.BIND_KEY) ?? widget.node.id;
    final vaultValue = ref.read(sduiStateVaultProvider)[bindKey];
    final rawData = (vaultValue is String && vaultValue.isNotEmpty) ? vaultValue : widget.node.contentVal<dynamic>(HbpContent.DATA);

    if (rawData == null) return '';

    if (rawData is String) {
      final trimmed = rawData.trim();
      if ((trimmed.startsWith('[') && trimmed.endsWith(']')) || (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            final points = decoded.map((item) {
              if (item is Map) return SduiChartDataPoint.fromMap(item);
              return SduiChartDataPoint(x: '', y: 0.0);
            }).toList();
            return _formatPointsToText(points);
          }
        } catch (_) {
          // Fallback to raw string if parsing fails
        }
      }
      return rawData;
    }

    if (rawData is List) {
      final points = rawData.map((item) {
        if (item is Map) return SduiChartDataPoint.fromMap(item);
        return SduiChartDataPoint(x: '', y: 0.0);
      }).toList();
      return _formatPointsToText(points);
    }

    return '';
  }

  String _formatPointsToText(List<SduiChartDataPoint> points) {
    return points.map((pt) {
      return '${pt.x}: ${pt.y}';
    }).join('\n');
  }

  void _parseData() {
    final String bindKey = widget.node.behavior<String>(HbpBehavior.BIND_KEY) ?? widget.node.id;
    final vaultValue = ref.read(sduiStateVaultProvider)[bindKey];
    final rawData = (vaultValue is String && vaultValue.isNotEmpty) ? vaultValue : widget.node.contentVal<dynamic>(HbpContent.DATA);

    if (rawData == _rawLastData) return;
    _rawLastData = rawData;

    if (rawData == null) {
      _parsedData = [];
      return;
    }

    try {
      List<dynamic> list;
      if (rawData is String) {
        try {
          list = jsonDecode(rawData) as List<dynamic>;
          _parsedData = list.map((item) {
            if (item is Map) {
              return SduiChartDataPoint.fromMap(item);
            }
            return SduiChartDataPoint(x: '', y: 0.0);
          }).toList();
          return;
        } catch (_) {
          _parseFromTextLines(rawData);
          return;
        }
      } else if (rawData is List) {
        list = rawData;
        _parsedData = list.map((item) {
          if (item is Map) {
            return SduiChartDataPoint.fromMap(item);
          }
          return SduiChartDataPoint(x: '', y: 0.0);
        }).toList();
      } else {
        _parsedData = [];
      }
    } catch (e) {
      _parsedData = [];
    }
  }

  void _parseFromTextLines(String text) {
    final lines = text.split('\n');
    final List<SduiChartDataPoint> parsedPoints = [];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final index = line.indexOf(RegExp(r'[:|,]'));
      if (index != -1) {
        final xVal = line.substring(0, index).trim();
        final yStr = line.substring(index + 1).trim();
        final yVal = double.tryParse(yStr) ?? 0.0;
        
        final numX = num.tryParse(xVal);
        parsedPoints.add(SduiChartDataPoint(
          x: numX ?? xVal,
          y: yVal,
        ));
      } else {
        parsedPoints.add(SduiChartDataPoint(x: line, y: 0.0));
      }
    }

    _parsedData = parsedPoints;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;
    final String bindKey = node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;

    // Sizing and styling behaviors
    final double? width = node.behavior<double>(HbpBehavior.WIDTH) ?? node.behavior<int>(HbpBehavior.WIDTH)?.toDouble();
    final double? height = node.behavior<double>(HbpBehavior.HEIGHT) ?? node.behavior<int>(HbpBehavior.HEIGHT)?.toDouble();
    final double borderRadiusVal = node.behavior<double>(HbpBehavior.BORDER_RADIUS) ?? node.behavior<int>(HbpBehavior.BORDER_RADIUS)?.toDouble() ?? 8.0;
    
    // Chart visual controls: 0=line (spline area), 1=bar (column), 2=pie, 3=candlestick
    final int chartType = node.behavior<int>(HbpBehavior.CHART_TYPE) ?? 0;
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 1;
    final int? accentColorToken = node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final Color accentColor = SduiStyleResolver.resolveColor(context, accentColorToken) ?? colorScheme.primary;

    final String? title = node.contentVal<String>(HbpContent.LABEL);

    ref.watch(sduiStateVaultProvider.select((s) => s[bindKey]));
    _parseData();

    Widget chartWidget;
    if (_parsedData.isEmpty) {
      chartWidget = _buildEmptyState(colorScheme, theme);
    } else {
      switch (chartType) {
        case 1:
          chartWidget = _buildColumnChart(accentColor, colorScheme, theme);
          break;
        case 2:
          chartWidget = _buildPieChart(colorScheme, theme);
          break;
        case 3:
          chartWidget = _buildCandlestickChart(colorScheme, theme);
          break;
        case 0:
        default:
          chartWidget = _buildSplineAreaChart(accentColor, colorScheme, theme);
          break;
      }
    }

    if (interactiveMode == 1 && _isEditing) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusVal),
          side: BorderSide(color: colorScheme.outline.withAlpha(60), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Chart Data Editor',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _parseData();
                      });
                    },
                    tooltip: 'Done Editing',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _dataController,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Chart Data (JSON or Plain Text)',
                  border: OutlineInputBorder(),
                  helperText: 'JSON or Text: "Mon: 10" or "Mon, 10" line-by-line',
                ),
                onChanged: (val) {
                  widget.dispatcher.onStateChange(bindKey, val);
                },
              ),
            ],
          ),
        ),
      );
    }

    Widget contentCard = Container(
      width: width ?? double.infinity,
      height: height ?? 220.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(borderRadiusVal),
        border: Border.all(
          color: colorScheme.outline.withAlpha(50),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null && title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                )
              else
                const SizedBox(),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(child: chartWidget),
        ],
      ),
    );

    if (interactiveMode == 1) {
      return Stack(
        children: [
          contentCard,
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: colorScheme.primary.withAlpha(30),
              child: IconButton(
                icon: Icon(Icons.edit_outlined, size: 14, color: colorScheme.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: 'Edit Chart Data',
              ),
            ),
          ),
        ],
      );
    }

    return RepaintBoundary(child: contentCard);
  }

  Widget _buildSplineAreaChart(Color accentColor, ColorScheme colorScheme, ThemeData theme) {
    final bool isNumericX = _parsedData.isNotEmpty && _parsedData.first.x is num;
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      primaryXAxis: isNumericX ? const NumericAxis() : const CategoryAxis(),
      primaryYAxis: const NumericAxis(),
      plotAreaBorderWidth: 0,
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<SduiChartDataPoint, dynamic>>[
        SplineAreaSeries<SduiChartDataPoint, dynamic>(
          dataSource: _parsedData,
          xValueMapper: (pt, _) => pt.x,
          yValueMapper: (pt, _) => pt.y,
          animationDuration: 800,
          gradient: LinearGradient(
            colors: [
              accentColor.withAlpha(80),
              accentColor.withAlpha(0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderColor: accentColor,
          borderWidth: 2,
        ),
      ],
    );
  }

  Widget _buildColumnChart(Color accentColor, ColorScheme colorScheme, ThemeData theme) {
    final bool isNumericX = _parsedData.isNotEmpty && _parsedData.first.x is num;
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      primaryXAxis: isNumericX ? const NumericAxis() : const CategoryAxis(),
      primaryYAxis: const NumericAxis(),
      plotAreaBorderWidth: 0,
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<SduiChartDataPoint, dynamic>>[
        ColumnSeries<SduiChartDataPoint, dynamic>(
          dataSource: _parsedData,
          xValueMapper: (pt, _) => pt.x,
          yValueMapper: (pt, _) => pt.y,
          color: accentColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
          animationDuration: 800,
        ),
      ],
    );
  }

  Widget _buildPieChart(ColorScheme colorScheme, ThemeData theme) {
    return SfCircularChart(
      margin: EdgeInsets.zero,
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CircularSeries<SduiChartDataPoint, dynamic>>[
        PieSeries<SduiChartDataPoint, dynamic>(
          dataSource: _parsedData,
          xValueMapper: (pt, _) => pt.x,
          yValueMapper: (pt, _) => pt.y,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
          ),
          enableTooltip: true,
          animationDuration: 800,
        ),
      ],
    );
  }

  Widget _buildCandlestickChart(ColorScheme colorScheme, ThemeData theme) {
    final bool isNumericX = _parsedData.isNotEmpty && _parsedData.first.x is num;
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      primaryXAxis: isNumericX ? const NumericAxis() : const CategoryAxis(),
      primaryYAxis: const NumericAxis(),
      plotAreaBorderWidth: 0,
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<SduiChartDataPoint, dynamic>>[
        CandleSeries<SduiChartDataPoint, dynamic>(
          dataSource: _parsedData,
          xValueMapper: (pt, _) => pt.x,
          highValueMapper: (pt, _) => pt.high ?? pt.y,
          lowValueMapper: (pt, _) => pt.low ?? pt.y,
          openValueMapper: (pt, _) => pt.open ?? pt.y,
          closeValueMapper: (pt, _) => pt.close ?? pt.y,
          bullColor: Colors.green,
          bearColor: Colors.red,
          animationDuration: 800,
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            color: colorScheme.onSurfaceVariant.withAlpha(128),
            size: 36,
          ),
          const SizedBox(height: 6),
          Text(
            'No Chart Data',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }
}

class SduiChartDataPoint {
  final dynamic x;
  final double y;
  final double? high;
  final double? low;
  final double? open;
  final double? close;

  SduiChartDataPoint({
    required this.x,
    required this.y,
    this.high,
    this.low,
    this.open,
    this.close,
  });

  factory SduiChartDataPoint.fromMap(Map<dynamic, dynamic> map) {
    final xVal = map['x'];
    final yVal = (map['y'] ?? map['value'] ?? map['close'] ?? 0.0).toDouble();
    return SduiChartDataPoint(
      x: xVal,
      y: yVal,
      high: map['high']?.toDouble(),
      low: map['low']?.toDouble(),
      open: map['open']?.toDouble(),
      close: map['close']?.toDouble() ?? yVal,
    );
  }
}
