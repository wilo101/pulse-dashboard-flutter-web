class Stats {
  const Stats({
    required this.revenue,
    required this.orders,
    required this.pending,
    required this.averageOrder,
    required this.revenueByDay,
    required this.ordersByStatus,
    required this.topCustomers,
    required this.topProducts,
  });

  final double revenue, averageOrder;
  final int orders, pending;

  /// ISO date (YYYY-MM-DD) to revenue, oldest first.
  final Map<String, double> revenueByDay;
  final Map<String, int> ordersByStatus;
  final List<MapEntry<String, double>> topCustomers;
  final List<MapEntry<String, int>> topProducts;

  factory Stats.fromJson(Map<String, dynamic> j) {
    final byDay = {for (final e in ((j['revenueByDay'] ?? {}) as Map).entries) '${e.key}': (e.value as num).toDouble()};
    final sortedKeys = byDay.keys.toList()..sort();
    return Stats(
      revenue: ((j['revenue'] ?? 0) as num).toDouble(),
      orders: (j['orders'] ?? 0) as int,
      pending: (j['pending'] ?? 0) as int,
      averageOrder: ((j['averageOrder'] ?? 0) as num).toDouble(),
      revenueByDay: {for (final k in sortedKeys) k: byDay[k]!},
      ordersByStatus: {for (final e in ((j['ordersByStatus'] ?? {}) as Map).entries) '${e.key}': (e.value as num).toInt()},
      topCustomers: [
        for (final c in (j['topCustomers'] ?? const []) as List) MapEntry('${c['name']}', (c['revenue'] as num).toDouble())
      ],
      topProducts: [for (final p in (j['topProducts'] ?? const []) as List) MapEntry('${p['name']}', (p['units'] as num).toInt())],
    );
  }

  /// The last [days] days that have revenue, for the chart range switch.
  List<MapEntry<String, double>> lastDays(int days) {
    final all = revenueByDay.entries.toList();
    return all.length <= days ? all : all.sublist(all.length - days);
  }
}

class Paged<T> {
  const Paged(this.items, {required this.total, required this.page, required this.perPage});
  final List<T> items;
  final int total, page, perPage;

  int get pages => total == 0 ? 1 : (total + perPage - 1) ~/ perPage;
  bool get hasNext => page < pages;
  bool get hasPrev => page > 1;
  int get firstIndex => total == 0 ? 0 : (page - 1) * perPage + 1;
  int get lastIndex => (page - 1) * perPage + items.length;
}
