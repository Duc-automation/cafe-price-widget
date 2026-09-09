import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const GiaCaPheApp());
}

/// App báo giá cà phê — Phase 1: gọi API và hiện giá.
class GiaCaPheApp extends StatelessWidget {
  const GiaCaPheApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Android 12+ (Material You): tự lấy màu theo theme/wallpaper của máy.
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Máy không hỗ trợ Material You -> về gam nâu cà phê mặc định.
        final light = lightDynamic ??
            ColorScheme.fromSeed(seedColor: const Color(0xFF795548));
        final dark = darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF795548),
              brightness: Brightness.dark,
            );
        return MaterialApp(
          title: 'Giá cà phê',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorScheme: light, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: dark, useMaterial3: true),
          themeMode: ThemeMode.system,
          home: const HomeScreen(),
        );
      },
    );
  }
}
