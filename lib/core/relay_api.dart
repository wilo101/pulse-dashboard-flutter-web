import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import '../models/order.dart';
import '../models/stats.dart';
import 'api.dart';

/// Client for the Relay backend: bearer token, one silent re-login on 401, paging read from response headers.
class RelayApi extends PulseApi {
  RelayApi(this.baseUrl, {http.Client? client}) : _c = client ?? http.Client();

  static const defaultUrl = String.fromEnvironment('RELAY_URL', defaultValue: 'http://localhost:8080');

  final String baseUrl;
  final http.Client _c;
  String? _token, _user, _pass;
  String _role = 'viewer';

  @override
  bool get isLive => true;
  @override
  String get role => _role;

  Uri _u(String path, [Map<String, String>? q]) => Uri.parse('$baseUrl$path').replace(queryParameters: q);

  Map<String, String> get _h => {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'};

  @override
  Future<void> signIn(String username, String password) async {
    final r = await _c
        .post(_u('/auth/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': username, 'password': password}))
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) throw ApiException(r.statusCode, r.statusCode == 401 ? 'Wrong username or password.' : 'Sign in failed.');
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    _token = b['token'] as String;
    _role = '${b['role'] ?? 'viewer'}';
    _user = username;
    _pass = password;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    var r = await call().timeout(const Duration(seconds: 10));
    if (r.statusCode == 401 && _user != null) {
      await signIn(_user!, _pass!);
      r = await call().timeout(const Duration(seconds: 10));
    }
    if (r.statusCode >= 400) {
      var msg = 'Request failed';
      try {
        msg = '${(jsonDecode(r.body) as Map)['error']}';
      } catch (_) {}
      throw ApiException(r.statusCode, msg);
    }
    return r;
  }

  Paged<T> _paged<T>(http.Response r, T Function(Map<String, dynamic>) parse, int page, int perPage) => Paged(
        [for (final j in jsonDecode(r.body) as List) parse(j as Map<String, dynamic>)],
        total: int.tryParse(r.headers['x-total-count'] ?? '') ?? 0,
        page: int.tryParse(r.headers['x-page'] ?? '') ?? page,
        perPage: int.tryParse(r.headers['x-per-page'] ?? '') ?? perPage,
      );

  @override
  Future<Paged<Order>> orders(OrderQuery q) async =>
      _paged(await _send(() => _c.get(_u('/orders', q.toParams()), headers: _h)), Order.fromJson, q.page, q.perPage);

  @override
  Future<Order> order(int id) async =>
      Order.fromJson(jsonDecode((await _send(() => _c.get(_u('/orders/$id'), headers: _h))).body) as Map<String, dynamic>);

  @override
  Future<Order> setStatus(int id, String status) async => Order.fromJson(jsonDecode(
          (await _send(() => _c.patch(_u('/orders/$id'), headers: _h, body: jsonEncode({'status': status})))).body)
      as Map<String, dynamic>);

  @override
  Future<int> bulkStatus(List<int> ids, String status) async {
    final r = await _send(() => _c.post(_u('/orders/bulk-status'), headers: _h, body: jsonEncode({'ids': ids, 'status': status})));
    return ((jsonDecode(r.body) as Map)['updated'] as List).length;
  }

  @override
  Future<String> ordersCsv(OrderQuery q) async =>
      (await _send(() => _c.get(_u('/orders/export.csv', {...q.toParams()..remove('page')..remove('per_page')}), headers: _h))).body;

  @override
  Future<Paged<Customer>> customers(CustomerQuery q) async =>
      _paged(await _send(() => _c.get(_u('/customers', q.toParams()), headers: _h)), Customer.fromJson, q.page, q.perPage);

  @override
  Future<Customer> customer(int id) async =>
      Customer.fromJson(jsonDecode((await _send(() => _c.get(_u('/customers/$id'), headers: _h))).body) as Map<String, dynamic>);

  @override
  Future<Customer> createCustomer(String name, String email, String city) async => Customer.fromJson(jsonDecode((await _send(
          () => _c.post(_u('/customers'), headers: _h, body: jsonEncode({'name': name, 'email': email, 'city': city})))).body)
      as Map<String, dynamic>);

  @override
  Future<Stats> stats() async =>
      Stats.fromJson(jsonDecode((await _send(() => _c.get(_u('/stats'), headers: _h))).body) as Map<String, dynamic>);

  @override
  Future<String> insights() async =>
      (jsonDecode((await _send(() => _c.post(_u('/ai/insights'), headers: _h))).body) as Map)['summary'] as String;
}
