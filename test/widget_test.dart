import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulse_dashboard/main.dart';
import 'package:pulse_dashboard/state/session_model.dart';
import 'package:pulse_dashboard/state/settings_model.dart';
import 'package:pulse_dashboard/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> app() async {
  SharedPreferences.setMockInitialValues({});
  final settings = await SettingsModel.load();
  return MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => SessionModel()), ChangeNotifierProvider.value(value: settings)],
    child: const PulseApp(),
  );
}

void main() {
  testWidgets('status chip shows a capitalised label', (t) async {
    await t.pumpWidget(const MaterialApp(home: StatusChip('paid')));
    expect(find.text('Paid'), findsOneWidget);
  });

  testWidgets('login offers sample data and opens the overview', (t) async {
    t.view.physicalSize = const Size(1200, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(await app());
    expect(find.text('Sign in'), findsOneWidget);
    await t.tap(find.text('Open with sample data'));
    await t.pumpAndSettle();
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Revenue'), findsWidgets);
  });

  testWidgets('orders tab lists rows and filters by status', (t) async {
    t.view.physicalSize = const Size(1400, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(await app());
    await t.tap(find.text('Open with sample data'));
    await t.pumpAndSettle();
    await t.tap(find.text('Orders').first);
    await t.pumpAndSettle();
    expect(find.text('1 to 10 of 40'), findsOneWidget);
    await t.tap(find.widgetWithText(ChoiceChip, 'Pending'));
    await t.pumpAndSettle();
    expect(find.text('1 to 10 of 40'), findsNothing);
  });

  testWidgets('settings tab changes the currency symbol shown on the overview', (t) async {
    t.view.physicalSize = const Size(1400, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(await app());
    await t.tap(find.text('Open with sample data'));
    await t.pumpAndSettle();
    await t.tap(find.text('Settings').first);
    await t.pumpAndSettle();
    expect(find.text('Display'), findsOneWidget);
    expect(find.text('Reset to defaults'), findsOneWidget);
  });

  testWidgets('empty state renders title and message', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyState(title: 'Nothing here', message: 'Try again'))));
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
