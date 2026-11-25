import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_dashboard/data.dart';

void main() {
  test('search filters orders and sort orders by amount', () async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final m = DashboardModel()..load(); // falls back to demo data without a server
    m.setQuery('nour');
    expect(m.visible.every((o) => o.customer == 'Nour'), true);
    m.setQuery('');
    m.toggleSort();
    final a = m.visible.map((o) => o.amount).toList();
    expect(a, [...a]..sort((x, y) => y.compareTo(x)));
  });
}
