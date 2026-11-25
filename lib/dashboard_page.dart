import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'data.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<DashboardModel>();
    final money = NumberFormat.compactCurrency(symbol: '\$');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse.', style: TextStyle(fontFamily: 'Georgia', fontFamilyFallback: ['Gentium Plus', 'serif'], fontSize: 26)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF3EFE6),
        child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > 900;
        final kpis = [
          _Kpi('Revenue', money.format(m.revenue)),
          _Kpi('Orders', '${m.orders.length}'),
          _Kpi('Pending', '${m.pending}'),
        ];
        return ListView(padding: const EdgeInsets.all(20), children: [
          Wrap(spacing: 16, runSpacing: 16, children: kpis),
          if (m.insight.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(child: ListTile(leading: const Icon(Icons.circle, size: 8, color: Color(0xFFD8472B)), title: Text(m.insight))),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(m.live ? 'Live data from Relay API' : 'Offline demo data (Relay not reachable)',
                style: Theme.of(context).textTheme.labelSmall),
          ),
          const SizedBox(height: 20),
          wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _Chart(values: m.weekly)),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _Table(model: m)),
                ])
              : Column(children: [_Chart(values: m.weekly), const SizedBox(height: 16), _Table(model: m)]),
        ]);
      })),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ]),
          ),
        ),
      );
}

class _Chart extends StatelessWidget {
  const _Chart({required this.values});
  final List<double> values;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 260,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  barWidth: 2,
                  color: const Color(0xFF14130F),
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                  spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
                ),
              ],
            )),
          ),
        ),
      );
}

class _Table extends StatelessWidget {
  const _Table({required this.model});
  final DashboardModel model;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Search orders', prefixIcon: Icon(Icons.search)),
                  onChanged: model.setQuery,
                ),
              ),
              IconButton(tooltip: 'Sort by amount', icon: const Icon(Icons.sort), onPressed: model.toggleSort),
            ]),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Order')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Status')),
                ],
                rows: [
                  for (final o in model.visible.take(10))
                    DataRow(cells: [
                      DataCell(Text(o.id)),
                      DataCell(Text(o.customer)),
                      DataCell(Text('\$${o.amount.toStringAsFixed(0)}')),
                      DataCell(Text(o.status)),
                    ]),
                ],
              ),
            ),
          ]),
        ),
      );
}
