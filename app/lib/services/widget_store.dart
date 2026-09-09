import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/coffee_price.dart';

/// Cầu nối Flutter -> Android để lưu giá cho widget + cấu hình lịch nền.
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

  /// Lưu lịch tự động cập nhật (bật/tắt, các giờ HH:mm, tối đa số lần/ngày).
  static Future<void> setSchedule({
    required bool enabled,
    required List<String> times,
    required int maxPerDay,
  }) async {
    try {
      await _channel.invokeMethod('setSchedule', <String, Object>{
        'enabled': enabled,
        'times': times.join(','),
        'max': maxPerDay,
      });
    } on MissingPluginException {
      // Chạy trên nền tảng không có Android (web...) -> bỏ qua.
    } on PlatformException {
      // Bỏ qua lỗi, không làm hỏng luồng lấy giá.
    }
  }

  /// Đọc lịch hiện tại -> Map {enabled, times (String), max}.
  static Future<Map<String, Object?>> getSchedule() async {
    try {
      final r = await _channel.invokeMethod<Map<Object?, Object?>>('getSchedule');
      return r?.map((k, v) => MapEntry(k.toString(), v)) ?? {};
    } on MissingPluginException {
      return {};
    } on PlatformException {
      return {};
    }
  }

  /// Yêu cầu chạy cập nhật nền ngay (test).
  static Future<void> runNow() async {
    try {
      await _channel.invokeMethod('runNow');
    } on MissingPluginException {
      // Chạy trên nền tảng không có Android (web...) -> bỏ qua.
    } on PlatformException {
      // Bỏ qua lỗi, không làm hỏng luồng lấy giá.
    }
  }
}
