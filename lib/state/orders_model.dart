import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/api.dart';
import '../models/order.dart';
import '../models/stats.dart';
import 'dashboard_model.dart';

/// The orders table: search with debounce, status filter, sorting, paging, multi-select and bulk status change.
class OrdersModel extends ChangeNotifier {
  OrdersModel(this._api, {int pageSize = 10, this.debounce = const Duration(milliseconds: 300), OrderQuery? base})
      : query = (base ?? const OrderQuery()).copyWith(perPage: pageSize);

  final PulseApi _api;
  final Duration debounce;

  OrderQuery query;
  Load state = Load.idle;
  Paged<Order>? page;
  String? error;
  final Set<int> selected = {};
  Timer? _timer;
  int _request = 0;

  bool get canWrite => _api.canWrite;
  List<Order> get items => page?.items ?? const [];

  Future<void> load() async {
    final mine = ++_request;
    state = Load.loading;
    error = null;
    notifyListeners();
    try {
      final result = await _api.orders(query);
      if (mine != _request) return; // a newer request replaced this one
      page = result;
      state = Load.ready;
    } on ApiException catch (e) {
      if (mine != _request) return;
      error = e.friendly;
      state = Load.failed;
    }
    notifyListeners();
  }

  void setSearch(String text) {
    _timer?.cancel();
    _timer = Timer(debounce, () {
      query = query.copyWith(text: text.trim(), page: 1);
      selected.clear();
      load();
    });
  }

  void setStatus(String? status) {
    query = status == null ? query.copyWith(clearStatus: true, page: 1) : query.copyWith(status: status, page: 1);
    selected.clear();
    load();
  }

  /// Clicking the same column flips the direction.
  void sortBy(String field) {
    final next = query.sort == field ? '-$field' : field;
    query = query.copyWith(sort: next, page: 1);
    load();
  }

  bool isSortedBy(String field) => query.sort == field || query.sort == '-$field';
  bool get sortDescending => query.sort.startsWith('-');

  void goTo(int p) {
    final max = page?.pages ?? 1;
    if (p < 1 || p > max || p == query.page) return;
    query = query.copyWith(page: p);
    load();
  }

  void toggle(int id) {
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    notifyListeners();
  }

  void toggleAllOnPage() {
    final ids = items.map((o) => o.id);
    if (ids.every(selected.contains)) {
      selected.removeAll(ids);
    } else {
      selected.addAll(ids);
    }
    notifyListeners();
  }

  /// Returns how many orders changed. The list reloads so the table shows what the server says.
  Future<int> bulkStatus(String status) async {
    if (selected.isEmpty) return 0;
    try {
      final n = await _api.bulkStatus(selected.toList(), status);
      selected.clear();
      await load();
      return n;
    } on ApiException catch (e) {
      error = e.friendly;
      notifyListeners();
      return 0;
    }
  }

  Future<String> exportCsv() => _api.ordersCsv(query);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
