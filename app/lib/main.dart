import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const GiaCaPheApp());
}

/// Màu "hạt giống" dự phòng — dùng cho WEB và mọi nền tảng không có
/// Material You. Cố ý chọn gam XÁM XANH trung tính, KHÔNG dùng tông nâu
/// để nền không bị ngả vàng/nâu ở cả chế độ Sáng lẫn Tối.
const Color _kSeed = Color(0xFF455A64); // blue-grey 700

/// Bảng màu trung tính: `neutral` làm surface gần như xám thuần
/// (trắng ở chế độ Sáng, xám đậm ở chế độ Tối) — chỉ giữ chút màu
/// cho app bar / nút nhấn.
ColorScheme _fallbackScheme(Brightness brightness) => ColorScheme.fromSeed(
      seedColor: _kSeed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    );

/// App báo giá cà phê — Phase 1: gọi API và hiện giá.
class GiaCaPheApp extends StatelessWidget {
  const GiaCaPheApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Android 12+ (Material You): tự lấy màu theo theme/wallpaper của máy.
    // Trên WEB plugin không hỗ trợ -> trả null -> dùng bảng màu trung tính.
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final light = lightDynamic ?? _fallbackScheme(Brightness.light);
        final dark = darkDynamic ?? _fallbackScheme(Brightness.dark);
        return MaterialApp(
          title: 'Giá cà phê',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(light),
          darkTheme: _buildTheme(dark),
          // Theo đúng chế độ Sáng/Tối của HỆ THỐNG.
          // Trên web = cài đặt giao diện của trình duyệt / hệ điều hành.
          themeMode: ThemeMode.system,
          home: const HomeScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        // Nền lấy thẳng từ surface của bảng màu (không bị pha màu).
        scaffoldBackgroundColor: scheme.surface,
        // Tắt lớp tint của M3 để app bar giữ đúng màu nền khi cuộn.
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
      );
}
