import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/theme_provider.dart';
import 'screens/record/record_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lifelog',
      themeMode: themeProvider.mode,

      theme: _lightTheme,
      darkTheme: _darkTheme,

      home: const RecordScreen(),
    );
  }
}

final ThemeData _lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Pretendard',
  textTheme: const TextTheme(
    // Section / App titles
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
    titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),

    // Transcript (가독성 최우선)
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
      letterSpacing: -0.1,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.55,
      letterSpacing: -0.1,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),

    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  ),
);

final ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Pretendard',
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
    titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),

    // 다크모드에서 살짝 두껍게
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
      letterSpacing: -0.1,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.55,
      letterSpacing: -0.1,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),

    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  ),
);