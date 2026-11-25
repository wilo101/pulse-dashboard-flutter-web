import 'package:flutter/material.dart';

const paper = Color(0xFFF3EFE6);
const ink = Color(0xFF14130F);
const vermilion = Color(0xFFD8472B);
const hairline = Color(0x2214130F);
const serif = TextStyle(fontFamily: 'Georgia', fontFamilyFallback: ['Gentium Plus', 'serif']);

/// Status colors stay inside the paper and ink palette, with vermilion reserved for what needs attention.
Color statusColor(String status) => switch (status) {
      'paid' => const Color(0xFF2F6B4F),
      'shipped' => const Color(0xFF2B5C8A),
      'pending' => const Color(0xFFB8860B),
      'refunded' => vermilion,
      'cancelled' => const Color(0xFF6B6860),
      _ => ink,
    };

ThemeData buildTheme({bool dense = false}) => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
      colorScheme: const ColorScheme.light(primary: ink, secondary: vermilion, surface: paper, onSurface: ink),
      scaffoldBackgroundColor: paper,
      dividerColor: hairline,
      cardTheme: const CardTheme(
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: hairline)),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: paper,
        indicatorColor: Color(0x1AD8472B),
        selectedIconTheme: IconThemeData(color: vermilion),
        selectedLabelTextStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: hairline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: hairline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: ink)),
        isDense: true,
      ),
      textTheme: ThemeData.light().textTheme.copyWith(
            headlineMedium: serif.copyWith(fontSize: 44, fontWeight: FontWeight.w400, letterSpacing: -1),
            headlineSmall: serif.copyWith(fontSize: 28, fontWeight: FontWeight.w400),
            titleLarge: serif.copyWith(fontSize: 22),
          ),
    );
