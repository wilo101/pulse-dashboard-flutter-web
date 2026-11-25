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
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF14130F),
            secondary: Color(0xFFD8472B),
            surface: Color(0xFFF3EFE6),
            onSurface: Color(0xFF14130F),
          ),
          scaffoldBackgroundColor: const Color(0xFFF3EFE6),
          dividerColor: const Color(0x2214130F),
          cardTheme: const CardTheme(
            color: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: Color(0x2214130F)),
            ),
          ),
          textTheme: ThemeData.light().textTheme.copyWith(
                headlineMedium: const TextStyle(fontFamily: 'Georgia', fontFamilyFallback: ['Gentium Plus', 'serif'], fontSize: 48, fontWeight: FontWeight.w400, letterSpacing: -1),
              ),
        ),
        home: const DashboardPage(),
      );
}
