import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../state/session_model.dart';
import '../state/settings_model.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<SettingsModel>();
    final s = m.value;
    final session = context.watch<SessionModel>();
    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...children,
              ]),
            ),
          ),
        );
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      section('Display', [
        Row(children: [
          const Expanded(child: Text('Currency')),
          DropdownButton<String>(
            value: s.currencyCode,
            underline: const SizedBox.shrink(),
            items: [for (final c in currencies) DropdownMenuItem(value: c.code, child: Text('${c.code}  ${c.symbol}  ${c.name}'))],
            onChanged: (v) => v == null ? null : m.update(s.copyWith(currencyCode: v)),
          ),
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Compact numbers'),
          subtitle: Text('Shows ${m.money(12400)} instead of ${s.currency.symbol}12,400'),
          value: s.compactNumbers,
          onChanged: (v) => m.update(s.copyWith(compactNumbers: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Dense tables'),
          value: s.denseTables,
          onChanged: (v) => m.update(s.copyWith(denseTables: v)),
        ),
        Row(children: [
          const Expanded(child: Text('Rows per page (applies when you reopen Orders)')),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [for (final n in SettingsModel.pageSizes) ButtonSegment(value: n, label: Text('$n'))],
            selected: {s.pageSize},
            onSelectionChanged: (v) => m.update(s.copyWith(pageSize: v.first)),
          ),
        ]),
      ]),
      section('Alerts', [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Warn me about pending orders'),
          subtitle: const Text('Shown at the top of the overview.'),
          value: s.pendingAlert,
          onChanged: (v) => m.update(s.copyWith(pendingAlert: v)),
        ),
        if (s.pendingAlert)
          Row(children: [
            Expanded(child: Text('Warn at ${s.pendingThreshold} or more')),
            Slider(
              value: s.pendingThreshold.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              activeColor: vermilion,
              label: '${s.pendingThreshold}',
              onChanged: (v) => m.update(s.copyWith(pendingThreshold: v.round())),
            ),
          ]),
      ]),
      section('Connection', [
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Source'), subtitle: Text(session.api.isLive ? session.serverUrl : 'Sample data (in memory)')),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Signed in as'), subtitle: Text('${session.username}, role ${session.api.role}')),
      ]),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder()),
          onPressed: () async {
            await m.reset();
            if (context.mounted) toast(context, 'Settings reset.');
          },
          child: const Text('Reset to defaults'),
        ),
      ),
    ]);
  }
}
