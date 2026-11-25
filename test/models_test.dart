import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_dashboard/core/api.dart';
import 'package:pulse_dashboard/models/customer.dart';
import 'package:pulse_dashboard/models/order.dart';
import 'package:pulse_dashboard/models/stats.dart';

void main() {
  group('Order', () {
    test('parses the list shape', () {
      final o = Order.fromJson({'id': 1001, 'customer': 'Nour', 'customerId': 100, 'amount': 42, 'status': 'paid', 'date': '2026-11-01T10:00:00Z', 'itemCount': 2});
      expect(o.label, '#1001');
      expect(o.amount, 42.0);
      expect(o.itemCount, 2);
      expect(o.items, isEmpty);
    });

    test('parses the detail shape with items and history', () {
      final o = Order.fromJson({
        'id': 1,
        'customer': 'A',
        'amount': 30,
        'status': 'shipped',
        'date': '2026-11-01T10:00:00Z',
        'items': [{'sku': 'X', 'name': 'Mug', 'qty': 2, 'price': 15}],
        'history': [{'status': 'pending', 'at': '2026-11-01T10:00:00Z', 'by': 'system'}],
        'note': 'gift',
      });
      expect(o.items.single.total, 30);
      expect(o.history.single.status, 'pending');
      expect(o.itemCount, 1);
      expect(o.note, 'gift');
    });

    test('copyWith keeps everything else', () {
      final o = Order(id: 1, customer: 'A', amount: 5, status: 'pending', date: DateTime(2026), customerId: 7);
      final p = o.copyWith(status: 'paid');
      expect(p.status, 'paid');
      expect(p.customerId, 7);
      expect(p.amount, 5);
    });

    test('capitalize', () {
      expect(capitalize('paid'), 'Paid');
      expect(capitalize(''), '');
    });
  });

  group('OrderQuery', () {
    test('only sends what is set', () {
      expect(const OrderQuery().toParams(), {'sort': '-date', 'page': '1', 'per_page': '10'});
      final q = const OrderQuery().copyWith(status: 'paid', text: 'nour', page: 2);
      expect(q.toParams()['status'], 'paid');
      expect(q.toParams()['q'], 'nour');
      expect(q.toParams()['page'], '2');
    });

    test('clearStatus removes the filter', () {
      expect(const OrderQuery(status: 'paid').copyWith(clearStatus: true).status, isNull);
    });
  });

  group('Customer', () {
    test('initials', () {
      Customer c(String n) => Customer(id: 1, name: n, email: 'a@b.co');
      expect(c('Nour Hassan').initials, 'NH');
      expect(c('Madonna').initials, 'M');
      expect(c('  ').initials, '?');
      expect(c('Ana Maria Lopez').initials, 'AL');
    });

    test('parses totals and tags', () {
      final c = Customer.fromJson({'id': 1, 'name': 'A', 'email': 'a@b.co', 'tags': ['vip'], 'orders': 3, 'lifetimeValue': 120.5, 'lastOrderAt': '2026-11-01T00:00:00Z'});
      expect(c.isVip, isTrue);
      expect(c.lifetimeValue, 120.5);
      expect(c.lastOrderAt, isNotNull);
    });
  });

  group('Stats and Paged', () {
    final stats = Stats.fromJson({
      'revenue': 100,
      'orders': 4,
      'pending': 1,
      'averageOrder': 25,
      'revenueByDay': {'2026-11-03': 30, '2026-11-01': 10, '2026-11-02': 20},
      'ordersByStatus': {'paid': 3, 'pending': 1},
      'topCustomers': [{'name': 'Nour', 'revenue': 60}],
      'topProducts': [{'name': 'Mug', 'units': 5}],
    });

    test('revenue by day is sorted by date', () => expect(stats.revenueByDay.keys.toList(), ['2026-11-01', '2026-11-02', '2026-11-03']));
    test('lastDays takes the newest days', () => expect(stats.lastDays(2).map((e) => e.key), ['2026-11-02', '2026-11-03']));
    test('lastDays with a big window returns everything', () => expect(stats.lastDays(30).length, 3));
    test('top lists parse', () {
      expect(stats.topCustomers.single.value, 60);
      expect(stats.topProducts.single.key, 'Mug');
    });

    test('paged math', () {
      const p = Paged<int>([1, 2, 3], total: 23, page: 3, perPage: 10);
      expect(p.pages, 3);
      expect(p.hasNext, isFalse);
      expect(p.hasPrev, isTrue);
      expect(p.firstIndex, 21);
      expect(p.lastIndex, 23);
      expect(const Paged<int>([], total: 0, page: 1, perPage: 10).pages, 1);
    });
  });

  test('ApiException gives friendly messages', () {
    expect(ApiException(401, 'x').friendly, contains('sign in'));
    expect(ApiException(403, 'x').friendly, contains('read-only'));
    expect(ApiException(429, 'x').friendly, contains('Too many'));
    expect(ApiException(500, 'x').friendly, contains('server'));
    expect(ApiException(400, 'Bad email').friendly, 'Bad email');
  });
}
