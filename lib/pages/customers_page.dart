import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/customers_model.dart';
import '../state/dashboard_model.dart';
import '../state/session_model.dart';
import '../state/settings_model.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'customer_detail_page.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => CustomersModel(c.read<SessionModel>().api)..load(),
        child: const _View(),
      );
}

class _View extends StatefulWidget {
  const _View();
  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) context.read<CustomersModel>().loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<CustomersModel>();
    final money = context.watch<SettingsModel>().money;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Customers', style: Theme.of(context).textTheme.headlineSmall)),
          if (m.canWrite)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: ink, shape: const RoundedRectangleBorder()),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add customer'),
              onPressed: () => _add(context, m),
            ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: 260, child: TextField(decoration: const InputDecoration(hintText: 'Search name or email', prefixIcon: Icon(Icons.search)), onChanged: m.setSearch)),
          ChoiceChip(label: const Text('All'), selected: m.query.tag == null, onSelected: (_) => m.setTag(null)),
          for (final t in const ['vip', 'wholesale']) ChoiceChip(label: Text(t.toUpperCase()), selected: m.query.tag == t, onSelected: (_) => m.setTag(t)),
          DropdownButton<String>(
            value: m.query.sort,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'name', child: Text('Name')),
              DropdownMenuItem(value: '-lifetimeValue', child: Text('Top spenders')),
              DropdownMenuItem(value: '-orders', child: Text('Most orders')),
            ],
            onChanged: (v) => v == null ? null : m.setSort(v),
          ),
        ]),
        const SizedBox(height: 12),
        if (m.error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: ErrorBanner(m.error!, onRetry: m.load)),
        Expanded(
          child: m.state == Load.loading && m.items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : m.items.isEmpty
                  ? const EmptyState(title: 'No customers found', message: 'Try a different search.', icon: Icons.people_outline)
                  : Card(
                      child: ListView.separated(
                        controller: _scroll,
                        itemCount: m.items.length + (m.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          if (i >= m.items.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                          final c = m.items[i];
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: ink, foregroundColor: paper, child: Text(c.initials)),
                            title: Row(children: [Flexible(child: Text(c.name)), if (c.isVip) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.star, size: 14, color: vermilion))]),
                            subtitle: Text('${c.city.isEmpty ? 'No city' : c.city}  |  ${c.orders} orders'
                                '${c.lastOrderAt == null ? '' : '  |  last ${DateFormat.MMMd().format(c.lastOrderAt!)}'}'),
                            trailing: Text(money(c.lifetimeValue), style: Theme.of(context).textTheme.titleMedium),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerDetailPage(customerId: c.id))),
                          );
                        },
                      ),
                    ),
        ),
        Padding(padding: const EdgeInsets.only(top: 8), child: Text('${m.items.length} of ${m.total} customers', style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }

  Future<void> _add(BuildContext context, CustomersModel m) async {
    final name = TextEditingController(), email = TextEditingController(), city = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add customer'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: vermilion))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final e = await m.create(name.text, email.text, city.text);
                if (e == null) {
                  if (ctx.mounted) Navigator.pop(ctx);
                } else {
                  setState(() => error = e);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
