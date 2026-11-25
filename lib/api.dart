import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data.dart';

/// Client for the Relay backend. Base URL and demo login come from --dart-define.
class RelayApi {
  RelayApi({http.Client? client})
      : _c = client ?? http.Client();
  static const baseUrl = String.fromEnvironment('RELAY_URL', defaultValue: 'http://localhost:8080');
  static const user = String.fromEnvironment('RELAY_USER', defaultValue: 'admin');
  static const pass = String.fromEnvironment('RELAY_PASS', defaultValue: 'admin123');
  final http.Client _c;
  String? _token;

  Map<String, String> get _h => {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'};

  Future<void> login() async {
    final r = await _c.post(Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': user, 'password': pass}));
    if (r.statusCode != 200) throw Exception('login failed (${r.statusCode})');
    _token = jsonDecode(r.body)['token'] as String;
  }

  Future<List<Order>> orders() async {
    final r = await _c.get(Uri.parse('$baseUrl/orders'), headers: _h);
    return [
      for (final o in jsonDecode(r.body) as List)
        Order('#${o['id']}', o['customer'], (o['amount'] as num).toDouble(), _cap(o['status']), DateTime.parse(o['date']))
    ];
  }

  Future<Map<String, dynamic>> stats() async =>
      jsonDecode((await _c.get(Uri.parse('$baseUrl/stats'), headers: _h)).body) as Map<String, dynamic>;

  Future<String> insights() async =>
      jsonDecode((await _c.post(Uri.parse('$baseUrl/ai/insights'), headers: _h)).body)['summary'] as String;

  Future<void> addOrder(String customer, double amount) =>
      _c.post(Uri.parse('$baseUrl/orders'), headers: _h, body: jsonEncode({'customer': customer, 'amount': amount}));

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
