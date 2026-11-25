import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/dashboard_model.dart';
import '../state/session_model.dart';
import '../state/settings_model.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/revenue_chart.dart';
import 'order_detail_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => DashboardModel(c.read<SessionModel>().api)..load(),
        child: const _DashboardView(),
      );
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final m = context.watch<DashboardModel>();
    final settings = context.watch<SettingsModel>();
    final money = settings.money;
    if (m.state == Load.loading && m.stats == null) return const Center(child: CircularProgressIndicator());
    if (m.state == Load.failed && m.stats == null) {
      return Padding(padding: const EdgeInsets.all(20), child: ErrorBanner(m.error ?? 'Could not load.', onRetry: m.load));
    }
    final s = m.stats!;
    final trend = m.trend;
    final showAlert = settings.value.pendingAlert && s.pending >= settings.value.pendingThreshold;
    return RefreshIndicator(
      onRefresh: m.load,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > 900;
        final chart = Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Revenue, last ${m.rangeDays} days', style: Theme.of(context).textTheme.titleLarge)),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [for (final r in DashboardModel.ranges) ButtonSegment(value: r, label: Text('${r}d'))],
                  selected: {m.rangeDays},
                  onSelectionChanged: (v) => m.setRange(v.first),
                ),
              ]),
              const SizedBox(height: 4),
              Text(money(m.rangeRevenue), style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              RevenueChart(points: m.series),
            ]),
          ),
        );
        final recent = Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recent orders', style: Theme.of(context).textTheme.titleLarge),
              for (final o in m.recent)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${o.label}  ${o.customer}'),
                  subtitle: Text(DateFormat.MMMd().format(o.date)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(money(o.amount)), const SizedBox(width: 10), StatusChip(o.status)]),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o.id))),
                ),
            ]),
          ),
        );
        final breakdown = Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Orders by status', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              BarList(entries: [for (final e in s.ordersByStatus.entries) MapEntry(capitalize(e.key), e.value)]),
              const SizedBox(height: 20),
              Text('Top customers', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              BarList(entries: s.topCustomers, color: vermilion, format: money),
            ]),
          ),
        );
        return ListView(padding: const EdgeInsets.all(20), children: [
          Wrap(spacing: 16, runSpacing: 16, children: [
            KpiCard('Revenue', money(s.revenue),
                note: trend == null ? null : '${trend >= 0 ? '+' : ''}${(trend * 100).toStringAsFixed(0)}% vs previous ${m.rangeDays} days'),
            KpiCard('Orders', '${s.orders}'),
            KpiCard('Pending', '${s.pending}'),
            KpiCard('Average order', money(s.averageOrder)),
          ]),
          if (showAlert)
            Padding(padding: const EdgeInsets.only(top: 16), child: ErrorBanner('${s.pending} orders are waiting. Your alert threshold is ${settings.value.pendingThreshold}.')),
          if (m.insight.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(child: ListTile(leading: const Icon(Icons.circle, size: 8, color: vermilion), title: Text(m.insight))),
            ),
          const SizedBox(height: 20),
          wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: Column(children: [chart, const SizedBox(height: 16), recent])),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: breakdown),
                ])
              : Column(children: [chart, const SizedBox(height: 16), breakdown, const SizedBox(height: 16), recent]),
        ]);
      }),
    );
  }
}
