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
    return MaterialApp(
      title: 'Giá cà phê',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Gam màu nâu cà phê.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF795548)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
