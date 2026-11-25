import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Line chart of revenue per day with a tooltip. Dates are shown on the first, middle and last tick.
class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key, required this.points, this.height = 260});
  final List<MapEntry<String, double>> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return SizedBox(height: height, child: const Center(child: Text('No paid orders in this range.')));
    final maxY = points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final ticks = {0, points.length ~/ 2, points.length - 1};
    return SizedBox(
      height: height,
      child: LineChart(LineChartData(
        minY: 0,
        maxY: maxY * 1.15,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (!ticks.contains(i) || i >= points.length) return const SizedBox.shrink();
                final d = points[i].key;
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(d.substring(5), style: const TextStyle(fontSize: 11)));
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem('${points[s.x.toInt()].key}\n\$${s.y.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 2,
            color: ink,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: vermilion.withOpacity(0.08)),
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value)],
          ),
        ],
      )),
    );
  }
}

/// Horizontal bars for a status or product breakdown.
class BarList extends StatelessWidget {
  const BarList({super.key, required this.entries, this.color = ink, this.format});
  final List<MapEntry<String, num>> entries;
  final Color color;
  final String Function(num)? format;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const Text('Nothing yet.');
    final max = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Column(children: [
      for (final e in entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(width: 110, child: Text(e.key, overflow: TextOverflow.ellipsis)),
            Expanded(
              child: LayoutBuilder(
                builder: (_, c) => Align(
                  alignment: Alignment.centerLeft,
                  child: Container(height: 10, width: max == 0 ? 0 : c.maxWidth * (e.value / max), color: color),
                ),
              ),
            ),
            SizedBox(width: 70, child: Text(format?.call(e.value) ?? '${e.value}', textAlign: TextAlign.right)),
          ]),
        ),
    ]);
  }
}
