import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/api.dart';
import '../models/customer.dart';
import '../models/stats.dart';
import 'dashboard_model.dart';

/// Customer list with infinite scroll: each call to [loadMore] appends the next page.
class CustomersModel extends ChangeNotifier {
  CustomersModel(this._api, {this.debounce = const Duration(milliseconds: 300)});
  final PulseApi _api;
  final Duration debounce;

  CustomerQuery query = const CustomerQuery();
  Load state = Load.idle;
  final List<Customer> items = [];
  int total = 0;
  bool loadingMore = false;
  String? error;
  Timer? _timer;
  int _request = 0;

  bool get canWrite => _api.canWrite;
  bool get hasMore => items.length < total;

  Future<void> load() async {
    final mine = ++_request;
    state = Load.loading;
    error = null;
    notifyListeners();
    try {
      final Paged<Customer> p = await _api.customers(query.copyWith(page: 1));
      if (mine != _request) return;
      items
        ..clear()
        ..addAll(p.items);
      total = p.total;
      query = query.copyWith(page: 1);
      state = Load.ready;
    } on ApiException catch (e) {
      if (mine != _request) return;
      error = e.friendly;
      state = Load.failed;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore || state != Load.ready) return;
    loadingMore = true;
    notifyListeners();
    try {
      final next = query.copyWith(page: query.page + 1);
      final p = await _api.customers(next);
      items.addAll(p.items);
      total = p.total;
      query = next;
    } on ApiException catch (e) {
      error = e.friendly;
    }
    loadingMore = false;
    notifyListeners();
  }

  void setSearch(String text) {
    _timer?.cancel();
    _timer = Timer(debounce, () {
      query = query.copyWith(text: text.trim());
      load();
    });
  }

  void setTag(String? tag) {
    query = tag == null ? query.copyWith(clearTag: true) : query.copyWith(tag: tag);
    load();
  }

  void setSort(String sort) {
    query = query.copyWith(sort: sort);
    load();
  }

  /// Returns an error message to show, or null on success.
  Future<String?> create(String name, String email, String city) async {
    if (name.trim().isEmpty) return 'Name is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) return 'Enter a valid email.';
    try {
      await _api.createCustomer(name.trim(), email.trim(), city.trim());
      await load();
      return null;
    } on ApiException catch (e) {
      return e.friendly;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
