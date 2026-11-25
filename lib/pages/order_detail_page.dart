import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../state/dashboard_model.dart';
import '../state/order_detail_model.dart';
import '../state/session_model.dart';
import '../state/settings_model.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => OrderDetailModel(c.read<SessionModel>().api, orderId)..load(),
        child: const _View(),
      );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final m = context.watch<OrderDetailModel>();
    final money = context.watch<SettingsModel>().money;
    final o = m.order;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text('Order #${m.id}', style: serif.copyWith(fontSize: 24))),
      body: switch (m.state) {
        Load.idle || Load.loading => const Center(child: CircularProgressIndicator()),
        Load.failed => Padding(padding: const EdgeInsets.all(20), child: ErrorBanner(m.error ?? 'Could not load.', onRetry: m.load)),
        Load.ready => ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [
              Expanded(child: Text(o!.customer, style: Theme.of(context).textTheme.headlineSmall)),
              StatusChip(o.status),
            ]),
            Text(DateFormat.yMMMMd().add_jm().format(o.date.toLocal())),
            if (m.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: ErrorBanner(m.error!)),
            const SizedBox(height: 16),
            if (m.canWrite)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Text('Status'),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: o.status,
                      underline: const SizedBox.shrink(),
                      items: [for (final s in orderStatuses) DropdownMenuItem(value: s, child: Text(capitalize(s)))],
                      onChanged: m.saving
                          ? null
                          : (v) async {
                              if (v == null) return;
                              final ok = await m.changeStatus(v);
                              if (ok && context.mounted) toast(context, 'Marked ${capitalize(v)}.');
                            },
                    ),
                    if (m.saving) const Padding(padding: EdgeInsets.only(left: 12), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                  ]),
                ),
              )
            else
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Read-only role: you can see this order but not change it.'))),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Items', style: Theme.of(context).textTheme.titleLarge),
                  for (final i in o.items)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(i.name),
                      subtitle: Text('${i.sku}  x${i.qty}  at ${money(i.price)}'),
                      trailing: Text(money(i.total)),
                    ),
                  const Divider(),
                  Row(children: [const Text('Total'), const Spacer(), Text(money(o.amount), style: Theme.of(context).textTheme.titleLarge)]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('History', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final h in o.history.reversed) _Step(h),
                ]),
              ),
            ),
          ]),
      },
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.change);
  final StatusChange change;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColor(change.status), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(capitalize(change.status), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text('by ${change.by}'),
          const Spacer(),
          Text(DateFormat.MMMd().add_jm().format(change.at.toLocal()), style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}
