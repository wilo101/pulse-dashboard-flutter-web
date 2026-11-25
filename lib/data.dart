import 'dart:math';
import 'package:flutter/foundation.dart';
import 'api.dart';

class Order {
  Order(this.id, this.customer, this.amount, this.status, this.date);
  final String id, customer, status;
  final double amount;
  final DateTime date;
}

/// Demo data source. Swap `load()` for a REST call (see Relay project) to use real data.
class DashboardModel extends ChangeNotifier {
  List<double> weekly = [];
  List<Order> orders = [];
  String query = '';
  bool sortByAmount = false;

  final RelayApi api = RelayApi();
  String insight = '';
  bool live = false;

  /// Loads from the Relay backend; falls back to local demo data if it is unreachable.
  Future<void> load() async {
    try {
      await api.login();
      orders = await api.orders();
      final s = await api.stats();
      weekly = (s['revenueByDay'] as Map).values.map((v) => (v as num).toDouble()).toList();
      insight = await api.insights();
      live = true;
      notifyListeners();
    } catch (_) {
      live = false;
      _demo();
    }
  }

  Future<void> addOrder(String customer, double amount) async {
    if (live) {
      await api.addOrder(customer, amount);
      await load();
    }
  }

  void _demo() {
    final r = Random(7);
    weekly = List.generate(12, (i) => 40 + r.nextInt(60).toDouble());
    const names = ['Nour', 'Omar', 'Salma', 'Youssef', 'Mariam', 'Karim', 'Laila', 'Hady'];
    const states = ['Paid', 'Pending', 'Refunded'];
    orders = List.generate(
      24,
      (i) => Order('#${1000 + i}', names[i % names.length], 20 + r.nextInt(480).toDouble(),
          states[r.nextInt(3)], DateTime(2026, 11, 1).add(Duration(days: i))),
    );
    notifyListeners();
  }

  double get revenue => orders.where((o) => o.status == 'Paid').fold(0, (a, o) => a + o.amount);
  int get pending => orders.where((o) => o.status == 'Pending').length;

  List<Order> get visible {
    final q = query.toLowerCase();
    final list = orders.where((o) => o.customer.toLowerCase().contains(q) || o.id.contains(q)).toList();
    if (sortByAmount) list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void toggleSort() {
    sortByAmount = !sortByAmount;
    notifyListeners();
  }
}
