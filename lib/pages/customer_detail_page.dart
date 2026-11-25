import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/stats.dart';
import '../state/session_model.dart';
import '../state/settings_model.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'order_detail_page.dart';

class CustomerDetailPage extends StatefulWidget {
  const CustomerDetailPage({super.key, required this.customerId});
  final int customerId;
  @override
  State<CustomerDetailPage> createState() => _State();
}

class _State extends State<CustomerDetailPage> {
  late final Future<(Customer, Paged<Order>)> _data;

  @override
  void initState() {
    super.initState();
    final api = context.read<SessionModel>().api;
    _data = () async {
      final c = await api.customer(widget.customerId);
      final o = await api.orders(OrderQuery(customerId: widget.customerId, perPage: 20));
      return (c, o);
    }();
  }

  @override
  Widget build(BuildContext context) {
    final money = context.watch<SettingsModel>().money;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text('Customer', style: serif.copyWith(fontSize: 24))),
      body: FutureBuilder(
        future: _data,
        builder: (context, snap) {
          if (snap.hasError) {
            final e = snap.error;
            return Padding(padding: const EdgeInsets.all(20), child: ErrorBanner(e is ApiException ? e.friendly : 'Could not load this customer.'));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final (c, orders) = snap.data!;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [
              CircleAvatar(radius: 28, backgroundColor: ink, foregroundColor: paper, child: Text(c.initials, style: const TextStyle(fontSize: 20))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: Theme.of(context).textTheme.headlineSmall),
                Text('${c.email}${c.city.isEmpty ? '' : '  |  ${c.city}'}'),
              ])),
            ]),
            if (c.tags.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(spacing: 6, children: [for (final t in c.tags) Chip(label: Text(t.toUpperCase()))])),
            const SizedBox(height: 16),
            Wrap(spacing: 16, runSpacing: 16, children: [
              KpiCard('Lifetime value', money(c.lifetimeValue)),
              KpiCard('Orders', '${c.orders}'),
              KpiCard('Last order', c.lastOrderAt == null ? 'None' : DateFormat.MMMd().format(c.lastOrderAt!)),
            ]),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Orders', style: Theme.of(context).textTheme.titleLarge),
                  if (orders.items.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('No orders yet.')),
                  for (final o in orders.items)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(o.label),
                      subtitle: Text(DateFormat.yMMMd().format(o.date)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(money(o.amount)), const SizedBox(width: 10), StatusChip(o.status)]),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o.id))),
                    ),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
