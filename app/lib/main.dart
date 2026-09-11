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

/// Bảng màu trung tính dùng cho WEB và mọi nền tảng không có Material You.
/// Màu ở đây chỉ còn ảnh hưởng tới MÀU NHẤN (chữ tiêu đề, nút, đường biểu
/// đồ) vì nền đã bị ép về đen/trắng ở [_buildTheme].
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

  /// Nền ĐEN TUYỆT ĐỐI ở chế độ Tối, TRẮNG TUYỆT ĐỐI ở chế độ Sáng.
  /// Bảng màu gốc không còn được dùng cho nền nữa (nếu dùng, M3 sẽ pha
  /// thêm sắc xám/nâu vào nền).
  ThemeData _buildTheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final bg = dark ? Colors.black : Colors.white;
    // Card nhích hơn nền một chút + viền mảnh, để các khối vẫn tách được
    // nhau (nền đen mà card cũng đen tuyệt đối thì sẽ dính thành 1 khối).
    final cardBg = dark ? const Color(0xFF121212) : Colors.white;
    final line = dark ? const Color(0xFF2E2E2E) : const Color(0xFFE3E3E3);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        surface: bg,
        // Các lớp "surface container" của M3 (Card, AppBar, menu... đều
        // lấy từ chúng) phải theo nền, nếu không sẽ quay về màu xám gốc.
        surfaceContainerLowest: bg,
        surfaceContainerLow: cardBg,
        surfaceContainer: cardBg,
        surfaceContainerHigh: cardBg,
        surfaceContainerHighest: cardBg,
        outlineVariant: line,
      ),
      scaffoldBackgroundColor: bg,
      // App bar hoà vào nền, không lấy lớp tint khi cuộn trang.
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: line),
        ),
      ),
      dividerTheme: DividerThemeData(color: line),
    );
  }
}
