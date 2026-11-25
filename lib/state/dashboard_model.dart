import 'package:flutter/foundation.dart';
import '../core/api.dart';
import '../models/order.dart';
import '../models/stats.dart';

enum Load { idle, loading, ready, failed }

/// Numbers, chart and recent orders for the overview screen.
class DashboardModel extends ChangeNotifier {
  DashboardModel(this._api);
  final PulseApi _api;

  Load state = Load.idle;
  Stats? stats;
  List<Order> recent = [];
  String insight = '';
  String? error;
  int rangeDays = 14;

  static const ranges = [7, 14, 30];

  Future<void> load() async {
    state = Load.loading;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.stats(),
        _api.orders(const OrderQuery(perPage: 6)),
      ]);
      stats = results[0] as Stats;
      recent = (results[1] as Paged<Order>).items;
      state = Load.ready;
      notifyListeners();
      // The AI summary is slow and optional, so it never blocks the numbers.
      _api.insights().then((s) {
        insight = s;
        notifyListeners();
      }).catchError((_) {});
    } on ApiException catch (e) {
      error = e.friendly;
      state = Load.failed;
      notifyListeners();
    } catch (_) {
      error = 'Could not load the dashboard.';
      state = Load.failed;
      notifyListeners();
    }
  }

  void setRange(int days) {
    if (days == rangeDays) return;
    rangeDays = days;
    notifyListeners();
  }

  List<MapEntry<String, double>> get series => stats?.lastDays(rangeDays) ?? const [];

  double get rangeRevenue => series.fold(0, (a, e) => a + e.value);

  /// Change versus the previous window of the same length, or null when there is nothing to compare.
  double? get trend {
    final s = stats;
    if (s == null) return null;
    final all = s.revenueByDay.values.toList();
    if (all.length < rangeDays * 2) return null;
    final current = all.sublist(all.length - rangeDays).fold<double>(0, (a, v) => a + v);
    final before = all.sublist(all.length - rangeDays * 2, all.length - rangeDays).fold<double>(0, (a, v) => a + v);
    return before == 0 ? null : (current - before) / before;
  }
}
