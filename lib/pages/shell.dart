import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/session_model.dart';
import '../theme.dart';
import 'customers_page.dart';
import 'dashboard_page.dart';
import 'orders_page.dart';
import 'settings_page.dart';

/// Navigation rail on wide screens, bottom bar on narrow ones. Pages stay alive when you switch tabs.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  static const _items = [
    (Icons.insights_outlined, Icons.insights, 'Overview'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
    (Icons.people_outline, Icons.people, 'Customers'),
    (Icons.tune_outlined, Icons.tune, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionModel>();
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final body = IndexedStack(index: _index, children: const [DashboardPage(), OrdersPage(), CustomersPage(), SettingsPage()]);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Pulse.', style: serif.copyWith(fontSize: 26)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(session.api.isLive ? '${session.username} (${session.api.role})' : 'Sample data (${session.api.role})',
                  style: Theme.of(context).textTheme.labelMedium),
            ),
          ),
          IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: session.signOut),
        ],
      ),
      body: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                destinations: [for (final i in _items) NavigationRailDestination(icon: Icon(i.$1), selectedIcon: Icon(i.$2), label: Text(i.$3))],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ])
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              backgroundColor: paper,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [for (final i in _items) NavigationDestination(icon: Icon(i.$1), selectedIcon: Icon(i.$2), label: i.$3)],
            ),
    );
  }
}
