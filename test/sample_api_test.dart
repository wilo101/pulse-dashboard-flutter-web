import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_dashboard/core/api.dart';
import 'package:pulse_dashboard/core/sample_api.dart';
import 'package:pulse_dashboard/models/customer.dart';
import 'package:pulse_dashboard/models/order.dart';

void main() {
  late SampleApi api;
  setUp(() => api = SampleApi(now: DateTime.utc(2026, 11, 25)));

  test('pages orders and reports the total', () async {
    final p = await api.orders(const OrderQuery(perPage: 15, page: 3));
    expect(p.total, 40);
    expect(p.items.length, 10);
    expect(p.pages, 3);
  });

  test('filters by status and customer', () async {
    final paid = await api.orders(const OrderQuery(status: 'paid', perPage: 50));
    expect(paid.items.every((o) => o.status == 'paid'), isTrue);
    final mine = await api.orders(const OrderQuery(customerId: 100, perPage: 50));
    expect(mine.items.every((o) => o.customerId == 100), isTrue);
    expect(mine.total, 5);
  });

  test('search matches customer name and order number', () async {
    final byName = await api.orders(const OrderQuery(text: 'nour', perPage: 50));
    expect(byName.items.every((o) => o.customer.toLowerCase().contains('nour')), isTrue);
    final byId = await api.orders(const OrderQuery(text: '1005'));
    expect(byId.items.single.id, 1005);
  });

  test('sorts by amount both ways', () async {
    final asc = (await api.orders(const OrderQuery(sort: 'amount', perPage: 50))).items.map((o) => o.amount).toList();
    expect(asc, [...asc]..sort());
    final desc = (await api.orders(const OrderQuery(sort: '-amount', perPage: 50))).items.map((o) => o.amount).toList();
    expect(desc, [...desc]..sort((a, b) => b.compareTo(a)));
  });

  test('changing status adds a history step', () async {
    final before = (await api.order(1001)).history.length;
    final o = await api.setStatus(1001, 'refunded');
    expect(o.status, 'refunded');
    expect(o.history.length, before + 1);
    expect((await api.order(1001)).status, 'refunded');
  });

  test('same status is a no-op and bad status is rejected', () async {
    final o = await api.order(1002);
    expect((await api.setStatus(1002, o.status)).history.length, o.history.length);
    expect(() => api.setStatus(1002, 'nope'), throwsA(isA<ApiException>()));
    expect(() => api.order(5), throwsA(isA<ApiException>()));
  });

  test('viewer cannot write', () async {
    final v = SampleApi(asRole: 'viewer');
    expect(v.canWrite, isFalse);
    expect(() => v.setStatus(1000, 'paid'), throwsA(predicate((e) => e is ApiException && e.isForbidden)));
    expect(() => v.createCustomer('A', 'a@b.co', ''), throwsA(isA<ApiException>()));
    expect((await v.orders(const OrderQuery())).items, isNotEmpty);
  });

  test('bulk status counts only what exists', () async {
    expect(await api.bulkStatus([1000, 1001, 99999], 'shipped'), 2);
    expect((await api.order(1000)).status, 'shipped');
  });

  test('customers have totals and filter by tag and text', () async {
    final vip = await api.customers(const CustomerQuery(tag: 'vip'));
    expect(vip.items.length, 2);
    expect(vip.items.first.orders, greaterThan(0));
    final q = await api.customers(const CustomerQuery(text: 'salma'));
    expect(q.items.single.name, 'Salma Fathy');
  });

  test('top spenders sort puts the biggest first', () async {
    final p = await api.customers(const CustomerQuery(sort: '-lifetimeValue'));
    expect(p.items.first.lifetimeValue >= p.items.last.lifetimeValue, isTrue);
  });

  test('create customer rejects a duplicate email', () async {
    final c = await api.createCustomer('Lina', 'lina@example.com', 'Cairo');
    expect(c.name, 'Lina');
    expect(() => api.createCustomer('Lina 2', 'LINA@example.com', ''), throwsA(isA<ApiException>()));
  });

  test('stats add up', () async {
    final s = await api.stats();
    expect(s.orders, 40);
    expect(s.ordersByStatus.values.fold<int>(0, (a, b) => a + b), 40);
    expect(s.revenueByDay.values.fold<double>(0, (a, b) => a + b), closeTo(s.revenue, 0.01));
    expect(s.topCustomers.length, lessThanOrEqualTo(5));
  });

  test('csv export respects the filter', () async {
    final csv = await api.ordersCsv(const OrderQuery(status: 'pending'));
    expect(csv.trim().split('\n').skip(1).every((l) => l.contains(',pending,')), isTrue);
  });
}
