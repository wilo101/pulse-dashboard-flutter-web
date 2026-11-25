import 'dart:math';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/stats.dart';
import 'api.dart';

/// In-memory backend used when Relay is not reachable (and by the tests).
/// It follows the same rules as Relay: filters, sorting, paging, status history and read-only viewers.
class SampleApi extends PulseApi {
  SampleApi({this.asRole = 'admin', DateTime? now}) {
    _seed(now ?? DateTime.now());
  }

  final String asRole;
  final List<Customer> _customers = [];
  final List<Order> _orders = [];

  @override
  bool get isLive => false;
  @override
  String get role => asRole;

  void _seed(DateTime now) {
    final r = Random(7);
    const people = [
      ('Nour Hassan', 'Cairo', ['vip']),
      ('Omar Adel', 'Giza', <String>[]),
      ('Salma Fathy', 'Alexandria', ['wholesale']),
      ('Youssef Samir', 'Cairo', <String>[]),
      ('Mariam Khaled', 'Mansoura', ['vip']),
      ('Karim Nabil', 'Giza', <String>[]),
      ('Laila Mostafa', 'Cairo', <String>[]),
      ('Hady Tarek', 'Luxor', ['wholesale']),
    ];
    for (var i = 0; i < people.length; i++) {
      final p = people[i];
      _customers.add(Customer(
          id: 100 + i, name: p.$1, email: '${p.$1.split(' ').first.toLowerCase()}@example.com', city: p.$2, tags: p.$3));
    }
    const catalog = [('Linen shirt', 38.0), ('Canvas tote', 22.0), ('Ceramic mug', 14.5), ('Notebook set', 18.0)];
    for (var i = 0; i < 40; i++) {
      final c = _customers[i % _customers.length];
      final a = catalog[r.nextInt(catalog.length)];
      final b = catalog[r.nextInt(catalog.length)];
      final qty = 1 + r.nextInt(3);
      final status = orderStatuses[r.nextInt(orderStatuses.length)];
      final date = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: 39 - i));
      _orders.add(Order(
        id: 1000 + i,
        customer: c.name,
        customerId: c.id,
        amount: double.parse((a.$2 * qty + b.$2).toStringAsFixed(2)),
        status: status,
        date: date,
        itemCount: 2,
        items: [
          OrderItem(sku: 'SKU-${a.$1.length}', name: a.$1, qty: qty, price: a.$2),
          OrderItem(sku: 'SKU-${b.$1.length}', name: b.$1, qty: 1, price: b.$2),
        ],
        history: [StatusChange('pending', date, 'system'), if (status != 'pending') StatusChange(status, date.add(const Duration(hours: 3)), 'admin')],
      ));
    }
  }

  @override
  Future<void> signIn(String username, String password) async {}

  Paged<T> _page<T>(List<T> all, int page, int perPage) {
    final start = (page - 1) * perPage;
    final slice = start >= all.length ? <T>[] : all.sublist(start, min(all.length, start + perPage));
    return Paged(slice, total: all.length, page: page, perPage: perPage);
  }

  List<Order> _filtered(OrderQuery q) {
    final t = q.text.toLowerCase();
    final list = _orders
        .where((o) =>
            (q.status == null || o.status == q.status) &&
            (q.customerId == null || o.customerId == q.customerId) &&
            (t.isEmpty || o.customer.toLowerCase().contains(t) || '${o.id}'.contains(t)))
        .toList();
    final desc = q.sort.startsWith('-');
    final field = desc ? q.sort.substring(1) : q.sort;
    int cmp(Order a, Order b) => switch (field) {
          'amount' => a.amount.compareTo(b.amount),
          'customer' => a.customer.compareTo(b.customer),
          'status' => a.status.compareTo(b.status),
          _ => a.date.compareTo(b.date),
        };
    list.sort((a, b) => desc ? cmp(b, a) : cmp(a, b));
    return list;
  }

  @override
  Future<Paged<Order>> orders(OrderQuery q) async => _page(_filtered(q), q.page, q.perPage);

  @override
  Future<Order> order(int id) async {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i < 0) throw ApiException(404, 'not found');
    return _orders[i];
  }

  void _requireWrite() {
    if (!canWrite) throw ApiException(403, 'admin role required');
  }

  @override
  Future<Order> setStatus(int id, String status) async {
    _requireWrite();
    if (!orderStatuses.contains(status)) throw ApiException(400, 'invalid status');
    final i = _orders.indexWhere((o) => o.id == id);
    if (i < 0) throw ApiException(404, 'not found');
    final o = _orders[i];
    if (o.status == status) return o;
    _orders[i] = o.copyWith(status: status, history: [...o.history, StatusChange(status, DateTime.now().toUtc(), 'admin')]);
    return _orders[i];
  }

  @override
  Future<int> bulkStatus(List<int> ids, String status) async {
    var n = 0;
    for (final id in ids) {
      try {
        await setStatus(id, status);
        n++;
      } on ApiException catch (e) {
        if (e.statusCode != 404) rethrow;
      }
    }
    return n;
  }

  @override
  Future<String> ordersCsv(OrderQuery q) async {
    final b = StringBuffer('id,customer,amount,status,date\n');
    for (final o in _filtered(q)) {
      b.writeln('${o.id},"${o.customer}",${o.amount.toStringAsFixed(2)},${o.status},${o.date.toIso8601String()}');
    }
    return b.toString();
  }

  Customer _withTotals(Customer c) {
    final mine = _orders.where((o) => o.customerId == c.id).toList()..sort((a, b) => b.date.compareTo(a.date));
    final spent = mine.where((o) => o.status == 'paid' || o.status == 'shipped').fold<double>(0, (a, o) => a + o.amount);
    return Customer(
        id: c.id,
        name: c.name,
        email: c.email,
        city: c.city,
        tags: c.tags,
        orders: mine.length,
        lifetimeValue: spent,
        lastOrderAt: mine.isEmpty ? null : mine.first.date);
  }

  @override
  Future<Paged<Customer>> customers(CustomerQuery q) async {
    final t = q.text.toLowerCase();
    final list = _customers
        .where((c) => (q.tag == null || c.tags.contains(q.tag)) && (t.isEmpty || c.name.toLowerCase().contains(t) || c.email.contains(t)))
        .map(_withTotals)
        .toList();
    final desc = q.sort.startsWith('-');
    final field = desc ? q.sort.substring(1) : q.sort;
    int cmp(Customer a, Customer b) => switch (field) {
          'lifetimeValue' => a.lifetimeValue.compareTo(b.lifetimeValue),
          'orders' => a.orders.compareTo(b.orders),
          _ => a.name.compareTo(b.name),
        };
    list.sort((a, b) => desc ? cmp(b, a) : cmp(a, b));
    return _page(list, q.page, q.perPage);
  }

  @override
  Future<Customer> customer(int id) async {
    final i = _customers.indexWhere((c) => c.id == id);
    if (i < 0) throw ApiException(404, 'not found');
    return _withTotals(_customers[i]);
  }

  @override
  Future<Customer> createCustomer(String name, String email, String city) async {
    _requireWrite();
    if (_customers.any((c) => c.email.toLowerCase() == email.toLowerCase())) throw ApiException(400, 'That email already exists.');
    final c = Customer(id: 100 + _customers.length, name: name, email: email, city: city);
    _customers.add(c);
    return _withTotals(c);
  }

  @override
  Future<Stats> stats() async {
    final paid = _orders.where((o) => o.status == 'paid' || o.status == 'shipped').toList();
    final byDay = <String, double>{};
    final byStatus = <String, int>{};
    final byCustomer = <String, double>{};
    final bySku = <String, int>{};
    for (final o in _orders) {
      byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
    }
    for (final o in paid) {
      final d = o.date.toIso8601String().substring(0, 10);
      byDay[d] = (byDay[d] ?? 0) + o.amount;
      byCustomer[o.customer] = (byCustomer[o.customer] ?? 0) + o.amount;
      for (final i in o.items) {
        bySku[i.name] = (bySku[i.name] ?? 0) + i.qty;
      }
    }
    final revenue = paid.fold<double>(0, (a, o) => a + o.amount);
    final days = byDay.keys.toList()..sort();
    return Stats(
      revenue: revenue,
      orders: _orders.length,
      pending: _orders.where((o) => o.status == 'pending').length,
      averageOrder: paid.isEmpty ? 0 : revenue / paid.length,
      revenueByDay: {for (final d in days) d: byDay[d]!},
      ordersByStatus: byStatus,
      topCustomers: (byCustomer.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).toList(),
      topProducts: (bySku.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).toList(),
    );
  }

  @override
  Future<String> insights() async {
    final s = await stats();
    return 'Revenue is ${s.revenue.toStringAsFixed(0)} across ${s.orders} orders, ${s.pending} still pending.';
  }
}
