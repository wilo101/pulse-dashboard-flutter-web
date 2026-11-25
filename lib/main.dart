import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/shell.dart';
import 'state/session_model.dart';
import 'state/settings_model.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsModel.load();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SessionModel()),
      ChangeNotifierProvider.value(value: settings),
    ],
    child: const PulseApp(),
  ));
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionModel>();
    final dense = context.select<SettingsModel, bool>((s) => s.value.denseTables);
    return MaterialApp(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(dense: dense),
      // Rebuilding the shell on sign-in gives every tab fresh models bound to the new API.
      home: session.signedIn ? Shell(key: ValueKey(session.username)) : const LoginPage(),
    );
  }
}
