import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data.dart';
import 'dashboard_page.dart';

void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => DashboardModel()..load(),
        child: const PulseApp(),
      ),
    );

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Pulse Dashboard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: const Color(0xFF3DDC97),
          scaffoldBackgroundColor: const Color(0xFF070B09),
          cardTheme: CardTheme(
            color: Colors.white.withOpacity(.05),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: Colors.white.withOpacity(.09)),
            ),
          ),
          textTheme: ThemeData.dark().textTheme.copyWith(
                headlineMedium: const TextStyle(fontSize: 44, fontWeight: FontWeight.w200, letterSpacing: -1.5),
              ),
        ),
        home: const DashboardPage(),
      );
}
