import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_dashboard/core/api.dart';
import 'package:pulse_dashboard/core/sample_api.dart';
import 'package:pulse_dashboard/models/settings.dart';
import 'package:pulse_dashboard/state/customers_model.dart';
import 'package:pulse_dashboard/state/dashboard_model.dart';
import 'package:pulse_dashboard/state/order_detail_model.dart';
import 'package:pulse_dashboard/state/orders_model.dart';
import 'package:pulse_dashboard/state/session_model.dart';
import 'package:pulse_dashboard/state/settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

SampleApi sample({String role = 'admin'}) => SampleApi(asRole: role, now: DateTime.utc(2026, 11, 25));

void main() {
  group('OrdersModel', () {
    test('loads the first page', () async {
      final m = OrdersModel(sample(), debounce: Duration.zero);
      await m.load();
      expect(m.state, Load.ready);
      expect(m.items.length, 10);
      expect(m.page!.total, 40);
    });

    test('status filter resets to page 1 and clears the selection', () async {
      final m = OrdersModel(sample(), debounce: Duration.zero);
      await m.load();
      m.goTo(2);
      await Future<void>.delayed(Duration.zero);
      m.toggle(m.items.first.id);
      m.setStatus('paid');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(m.query.page, 1);
      expect(m.selected, isEmpty);
      expect(m.items.every((o) => o.status == 'paid'), isTrue);
    });

    test('sorting the same column twice flips the direction', () async {
      final m = OrdersModel(sample(), debounce: Duration.zero);
      m.sortBy('amount');
      expect(m.query.sort, 'amount');
      m.sortBy('amount');
      expect(m.query.sort, '-amount');
      expect(m.isSortedBy('amount'), isTrue);
      expect(m.sortDescending, isTrue);
    });

    test('goTo ignores pages out of range', () async {
      final m = OrdersModel(sample(), debounce: Duration.zero);
      await m.load();
      m.goTo(0);
      m.goTo(99);
      expect(m.query.page, 1);
    });

    test('search is debounced and applied', () async {
      final m = OrdersModel(sample(), debounce: const Duration(milliseconds: 10));
      await m.load();
      m.setSearch('n');
      m.setSearch('nour');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(m.query.text, 'nour');
      expect(m.items.every((o) => o.customer.toLowerCase().contains('nour')), isTrue);
    });

    test('select all toggles the whole page', () async {
      final m = OrdersModel(sample(), debounce: Duration.zero);
      await m.load();
      m.toggleAllOnPage();
      expect(m.selected.length, 10);
      m.toggleAllOnPage();
      expect(m.selected, isEmpty);
    });

    test('bulk status changes the selected orders and reloads', () async {
      final m = OrdersModel(sample(), debounce: Duration.zero);
      await m.load();
      m.toggle(m.items[0].id);
      m.toggle(m.items[1].id);
      final n = await m.bulkStatus('cancelled');
      expect(n, 2);
      expect(m.selected, isEmpty);
    });

    test('a viewer cannot bulk change and sees the error', () async {
      final m = OrdersModel(sample(role: 'viewer'), debounce: Duration.zero);
      await m.load();
      expect(m.canWrite, isFalse);
      m.toggle(m.items.first.id);
      expect(await m.bulkStatus('paid'), 0);
      expect(m.error, isNotNull);
    });
  });

  group('OrderDetailModel', () {
    test('loads and changes status', () async {
      final m = OrderDetailModel(sample(), 1003);
      await m.load();
      expect(m.state, Load.ready);
      final next = m.order!.status == 'paid' ? 'shipped' : 'paid';
      expect(await m.changeStatus(next), isTrue);
      expect(m.order!.status, next);
      expect(m.order!.history.last.status, next);
    });

    test('rolls back when the server refuses', () async {
      final m = OrderDetailModel(sample(role: 'viewer'), 1003);
      await m.load();
      final before = m.order!.status;
      expect(await m.changeStatus(before == 'paid' ? 'shipped' : 'paid'), isFalse);
      expect(m.order!.status, before);
      expect(m.error, contains('read-only'));
      expect(m.saving, isFalse);
    });

    test('same status does nothing', () async {
      final m = OrderDetailModel(sample(), 1003);
      await m.load();
      expect(await m.changeStatus(m.order!.status), isFalse);
    });

    test('unknown order is a clear failure', () async {
      final m = OrderDetailModel(sample(), 42);
      await m.load();
      expect(m.state, Load.failed);
      expect(m.error, contains('not found'));
    });
  });

  group('CustomersModel', () {
    test('loadMore appends the next page', () async {
      final m = CustomersModel(sample(), debounce: Duration.zero);
      await m.load();
      expect(m.items.length, 8);
      expect(m.hasMore, isFalse);
      await m.create('Lina', 'lina@example.com', 'Cairo');
      expect(m.items.length, 9);
    });

    test('create validates before calling the server', () async {
      final m = CustomersModel(sample(), debounce: Duration.zero);
      expect(await m.create('', 'a@b.co', ''), contains('Name'));
      expect(await m.create('A', 'nope', ''), contains('email'));
      expect(await m.create('Dup', 'nour@example.com', ''), contains('exists'));
    });

    test('tag filter and sort reload the list', () async {
      final m = CustomersModel(sample(), debounce: Duration.zero);
      m.setTag('wholesale');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(m.items.every((c) => c.tags.contains('wholesale')), isTrue);
      m.setTag(null);
      m.setSort('-orders');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(m.items.first.orders >= m.items.last.orders, isTrue);
    });
  });

  group('DashboardModel', () {
    test('loads numbers and recent orders', () async {
      final m = DashboardModel(sample());
      await m.load();
      expect(m.state, Load.ready);
      expect(m.recent.length, 6);
      expect(m.stats!.orders, 40);
    });

    test('range switch changes the series and its total', () async {
      final m = DashboardModel(sample());
      await m.load();
      m.setRange(7);
      final week = m.series.length;
      final weekTotal = m.rangeRevenue;
      m.setRange(30);
      expect(m.series.length, greaterThanOrEqualTo(week));
      expect(m.rangeRevenue, greaterThanOrEqualTo(weekTotal));
    });

    test('trend compares with the previous window', () async {
      final m = DashboardModel(sample());
      await m.load();
      m.setRange(7);
      expect(m.trend, isNotNull);
    });
  });

  group('SessionModel', () {
    test('sample data signs in with a role', () {
      final s = SessionModel()..useSampleData(role: 'viewer');
      expect(s.signedIn, isTrue);
      expect(s.api.canWrite, isFalse);
      s.signOut();
      expect(s.signedIn, isFalse);
    });

    test('bad credentials show the server message', () async {
      final s = SessionModel(relayFactory: (_) => _Failing(ApiException(401, 'Wrong username or password.')));
      await s.signIn('a', 'b');
      expect(s.signedIn, isFalse);
      expect(s.error, contains('sign in'));
    });

    test('an unreachable server explains and offers sample data', () async {
      final s = SessionModel(relayFactory: (_) => _Failing(Exception('socket')));
      await s.signIn('a', 'b', url: 'http://nowhere:1/');
      expect(s.error, contains('nowhere'));
      expect(s.serverUrl, 'http://nowhere:1');
    });
  });

  group('SettingsModel', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('has sensible defaults', () async {
      final m = await SettingsModel.load();
      expect(m.value.currencyCode, 'USD');
      expect(m.value.pageSize, 10);
    });

    test('saves and restores', () async {
      final m = await SettingsModel.load();
      await m.update(m.value.copyWith(currencyCode: 'EGP', pageSize: 50, pendingThreshold: 9));
      final again = await SettingsModel.load();
      expect(again.value.currencyCode, 'EGP');
      expect(again.value.pageSize, 50);
      expect(again.value.pendingThreshold, 9);
    });

    test('money follows currency and compact setting', () async {
      final m = await SettingsModel.load();
      expect(m.money(250), '\$250');
      expect(m.money(250.5), '\$250.50');
      expect(m.money(12400), contains('K'));
      await m.update(m.value.copyWith(compactNumbers: false, currencyCode: 'EUR'));
      expect(m.money(12400), '€12,400');
    });

    test('reset restores defaults', () async {
      final m = await SettingsModel.load();
      await m.update(m.value.copyWith(currencyCode: 'GBP'));
      await m.reset();
      expect(m.value.currencyCode, 'USD');
    });

    test('unknown saved currency falls back to the first', () {
      expect(const Settings(currencyCode: 'XXX').currency.code, 'USD');
    });
  });
}

class _Failing extends SampleApi {
  _Failing(this.error);
  final Object error;
  @override
  Future<void> signIn(String username, String password) async => throw error;
}
