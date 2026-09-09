import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/coffee_price.dart';

/// Cầu nối Flutter -> Android để lưu giá cho widget đọc.
///
/// Khi chạy trên web (không có channel Android) các lỗi sẽ bị bỏ qua.
class WidgetStore {
  WidgetStore._();

  static const MethodChannel _channel = MethodChannel('com.giacaphe/coffee_widget');

  static Future<void> save({required CoffeePrice price}) async {
    final items = price.items
        .map((e) => <String, String>{
              'm': e.market,
              'p': e.averagePrice,
              'c': e.priceChange,
            })
        .toList();

    try {
      await _channel.invokeMethod('save', <String, String>{
        'avg': price.averagePrice,
        'change': price.priceChange,
        'updated': price.updatedAt,
        'items': jsonEncode(items),
      });
    } on MissingPluginException {
      // Chạy trên nền tảng không có Android (web...) -> bỏ qua.
    } on PlatformException {
      // Bỏ qua lỗi, không làm hỏng luồng lấy giá.
    }
  }
}
