import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulse_dashboard/core/api.dart';
import 'package:pulse_dashboard/core/relay_api.dart';
import 'package:pulse_dashboard/models/customer.dart';
import 'package:pulse_dashboard/models/order.dart';

http.Response json(Object body, [int status = 200, Map<String, String> headers = const {}]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...headers});

const orderJson = {'id': 1, 'customer': 'A', 'amount': 10, 'status': 'paid', 'date': '2026-11-01T00:00:00Z'};

void main() {
  test('sign in stores the role and sends the token afterwards', () async {
    String? auth;
    final api = RelayApi('http://r', client: MockClient((req) async {
      if (req.url.path == '/auth/login') return json({'token': 'T1', 'role': 'admin'});
      auth = req.headers['Authorization'];
      return json([orderJson], 200, {'x-total-count': '1'});
    }));
    await api.signIn('admin', 'pw');
    expect(api.role, 'admin');
    expect(api.canWrite, isTrue);
    await api.orders(const OrderQuery());
    expect(auth, 'Bearer T1');
  });

  test('wrong password becomes a friendly ApiException', () async {
    final api = RelayApi('http://r', client: MockClient((_) async => json({'error': 'invalid credentials'}, 401)));
    expect(() => api.signIn('a', 'b'), throwsA(predicate((e) => e is ApiException && e.message.contains('Wrong'))));
  });

  test('paging comes from response headers', () async {
    final api = RelayApi('http://r', client: MockClient((req) async {
      if (req.url.path == '/auth/login') return json({'token': 'T', 'role': 'viewer'});
      expect(req.url.queryParameters['page'], '2');
      expect(req.url.queryParameters['status'], 'paid');
      return json([orderJson], 200, {'x-total-count': '23', 'x-page': '2', 'x-per-page': '10'});
    }));
    await api.signIn('v', 'p');
    final p = await api.orders(const OrderQuery(status: 'paid', page: 2));
    expect(p.total, 23);
    expect(p.pages, 3);
    expect(p.page, 2);
  });

  test('a 401 triggers one silent re-login and a retry', () async {
    var logins = 0, calls = 0;
    final api = RelayApi('http://r', client: MockClient((req) async {
      if (req.url.path == '/auth/login') {
        logins++;
        return json({'token': 'T$logins', 'role': 'admin'});
      }
      calls++;
      return req.headers['Authorization'] == 'Bearer T2' ? json({'revenue': 1, 'orders': 1, 'pending': 0}) : json({'error': 'unauthorized'}, 401);
    }));
    await api.signIn('a', 'p');
    final s = await api.stats();
    expect(s.orders, 1);
    expect(logins, 2);
    expect(calls, 2);
  });

  test('errors carry the server message and status', () async {
    final api = RelayApi('http://r', client: MockClient((req) async {
      if (req.url.path == '/auth/login') return json({'token': 'T', 'role': 'admin'});
      return json({'error': 'customer has orders and cannot be deleted'}, 409);
    }));
    await api.signIn('a', 'p');
    expect(() => api.customer(1), throwsA(predicate((e) => e is ApiException && e.statusCode == 409 && e.message.contains('has orders'))));
  });

  test('bulk status posts ids and returns the updated count', () async {
    Map? sent;
    final api = RelayApi('http://r', client: MockClient((req) async {
      if (req.url.path == '/auth/login') return json({'token': 'T', 'role': 'admin'});
      sent = jsonDecode(req.body) as Map;
      return json({'updated': [1, 2], 'missing': []});
    }));
    await api.signIn('a', 'p');
    expect(await api.bulkStatus([1, 2], 'shipped'), 2);
    expect(sent!['status'], 'shipped');
  });

  test('csv export drops paging parameters', () async {
    Uri? url;
    final api = RelayApi('http://r', client: MockClient((req) async {
      if (req.url.path == '/auth/login') return json({'token': 'T', 'role': 'admin'});
      url = req.url;
      return http.Response('id,customer\n', 200);
    }));
    await api.signIn('a', 'p');
    await api.ordersCsv(const OrderQuery(status: 'paid', page: 3));
    expect(url!.path, '/orders/export.csv');
    expect(url!.queryParameters.containsKey('page'), isFalse);
    expect(url!.queryParameters['status'], 'paid');
  });

  test('customers parse with totals', () async {
    final api = RelayApi('http://r', client: MockClient((req) async {
      if (req.url.path == '/auth/login') return json({'token': 'T', 'role': 'admin'});
      return json([{'id': 100, 'name': 'Nour', 'email': 'n@x.co', 'orders': 4, 'lifetimeValue': 99.5}], 200, {'x-total-count': '1'});
    }));
    await api.signIn('a', 'p');
    final p = await api.customers(const CustomerQuery());
    expect(p.items.single.lifetimeValue, 99.5);
  });
}
