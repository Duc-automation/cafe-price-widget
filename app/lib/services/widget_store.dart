import 'package:flutter/services.dart';

/// Cầu nối Flutter -> Android để lưu giá cho widget đọc.
///
/// Khi chạy trên web (không có channel Android) các lỗi sẽ bị bỏ qua.
class WidgetStore {
  WidgetStore._();

  static const MethodChannel _channel = MethodChannel('com.giacaphe/coffee_widget');

  static Future<void> save({
    required String averagePrice,
    required String priceChange,
    required String updatedAt,
  }) async {
    try {
      await _channel.invokeMethod('save', <String, String>{
        'avg': averagePrice,
        'change': priceChange,
        'updated': updatedAt,
      });
    } on MissingPluginException {
      // Chạy trên nền tảng không có Android (web...) -> bỏ qua.
    } on PlatformException {
      // Bỏ qua lỗi, không làm hỏng luồng lấy giá.
    }
  }
}
