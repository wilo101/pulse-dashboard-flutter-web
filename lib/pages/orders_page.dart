import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../state/dashboard_model.dart';
import '../state/orders_model.dart';
import '../state/session_model.dart';
import '../state/settings_model.dart';
import '../widgets/common.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => OrdersModel(c.read<SessionModel>().api, pageSize: c.read<SettingsModel>().value.pageSize)..load(),
        child: const _OrdersView(),
      );
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    final m = context.watch<OrdersModel>();
    final settings = context.watch<SettingsModel>();
    final page = m.page;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Orders', style: Theme.of(context).textTheme.headlineSmall)),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder()),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Copy CSV'),
            onPressed: () async {
              final csv = await m.exportCsv();
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) toast(context, 'Copied ${csv.trim().split('\n').length - 1} rows as CSV.');
            },
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 260,
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search customer or order number', prefixIcon: Icon(Icons.search)),
              onChanged: m.setSearch,
            ),
          ),
          ChoiceChip(label: const Text('All'), selected: m.query.status == null, onSelected: (_) => m.setStatus(null)),
          for (final s in orderStatuses)
            ChoiceChip(label: Text(capitalize(s)), selected: m.query.status == s, onSelected: (_) => m.setStatus(s)),
        ]),
        const SizedBox(height: 12),
        if (m.selected.isNotEmpty) _BulkBar(model: m),
        if (m.error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: ErrorBanner(m.error!, onRetry: m.load)),
        Expanded(
          child: Card(
            child: m.state == Load.loading && page == null
                ? const Center(child: CircularProgressIndicator())
                : page == null || page.items.isEmpty
                    ? const EmptyState(title: 'No orders match', message: 'Try another search or clear the status filter.')
                    : Stack(children: [
                        SingleChildScrollView(
                          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: _Table(model: m, money: settings.money, dense: settings.value.denseTables)),
                        ),
                        if (m.state == Load.loading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
                      ]),
          ),
        ),
        if (page != null)
          PageFooter(first: page.firstIndex, last: page.lastIndex, total: page.total, page: page.page, pages: page.pages, onPage: m.goTo),
      ]),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.model, required this.money, required this.dense});
  final OrdersModel model;
  final String Function(num) money;
  final bool dense;

  DataColumn _col(String label, String field, {bool numeric = false}) => DataColumn(
        label: Text(label),
        numeric: numeric,
        onSort: (_, __) => model.sortBy(field),
      );

  @override
  Widget build(BuildContext context) {
    final sortField = ['id', 'customer', 'amount', 'status', 'date'].where(model.isSortedBy).firstOrNull;
    return DataTable(
      showCheckboxColumn: model.canWrite,
      dataRowMinHeight: dense ? 36 : 48,
      dataRowMaxHeight: dense ? 40 : 56,
      sortColumnIndex: sortField == null ? null : ['id', 'customer', 'amount', 'status', 'date'].indexOf(sortField),
      sortAscending: !model.sortDescending,
      onSelectAll: model.canWrite ? (_) => model.toggleAllOnPage() : null,
      columns: [
        _col('Order', 'id'),
        _col('Customer', 'customer'),
        _col('Amount', 'amount', numeric: true),
        _col('Status', 'status'),
        _col('Date', 'date'),
      ],
      rows: [
        for (final o in model.items)
          DataRow(
            selected: model.selected.contains(o.id),
            onSelectChanged: model.canWrite ? (_) => model.toggle(o.id) : null,
            cells: [
              DataCell(Text(o.label), onTap: () => _open(context, o)),
              DataCell(Text(o.customer), onTap: () => _open(context, o)),
              DataCell(Text(money(o.amount)), onTap: () => _open(context, o)),
              DataCell(StatusChip(o.status), onTap: () => _open(context, o)),
              DataCell(Text(DateFormat.MMMd().format(o.date)), onTap: () => _open(context, o)),
            ],
          ),
      ],
    );
  }

  void _open(BuildContext context, Order o) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o.id))).then((_) => model.load());
}

class _BulkBar extends StatelessWidget {
  const _BulkBar({required this.model});
  final OrdersModel model;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0x1A14130F),
        child: Row(children: [
          Text('${model.selected.length} selected'),
          const Spacer(),
          const Text('Mark as  '),
          for (final s in ['paid', 'shipped', 'cancelled'])
            TextButton(
              onPressed: () async {
                final n = await model.bulkStatus(s);
                if (context.mounted && n > 0) toast(context, '$n orders marked ${capitalize(s)}.');
              },
              child: Text(capitalize(s)),
            ),
        ]),
      );
}
