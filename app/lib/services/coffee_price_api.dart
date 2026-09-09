import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/coffee_price.dart';
import '../models/price_point.dart';

/// Gọi API giá cà phê của chocaphe.vn.
class CoffeePriceApi {
  CoffeePriceApi._();

  static const String baseUrl = 'https://api.chocaphe.vn/v1/prices';

  /// Lấy giá mới nhất (không cần tham số).
  static Future<CoffeePrice> fetch() => fetchForDate(null);

  /// Lấy giá của 1 ngày cụ thể (yyyy-MM-dd); null = bản ghi mới nhất.
  /// Ném [Exception] nếu lỗi mạng hoặc máy chủ trả lỗi.
  static Future<CoffeePrice> fetchForDate(String? date) async {
    final uri = date == null
        ? Uri.parse(baseUrl)
        : Uri.parse('$baseUrl?date=$date');
    final res = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'gia-ca-phe-widget/1.0',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('Máy chủ trả lỗi HTTP ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['status_code'] != 200) {
      throw Exception(body['message'] ?? 'API trả về lỗi');
    }

    return CoffeePrice.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Gom giá trung bình nội địa của [days] ngày gần nhất
  /// (tự bỏ qua ngày không có dữ liệu), sắp tăng dần theo ngày.
  static Future<List<PricePoint>> fetchAverageHistory({int days = 7}) async {
    final today = DateTime.now();
    final points = <PricePoint>[];

    for (var i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final date = formatDate(d);
      try {
        final p = await fetchForDate(date);
        final value = parsePriceVnd(p.averagePrice);
        if (value != null) points.add(PricePoint(date: date, value: value));
      } catch (_) {
        // Ngày nghỉ / không có dữ liệu -> bỏ qua.
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Bóc số nguyên từ "95,600đ/kg" -> 95600.
  static int? parsePriceVnd(String s) {
    final digits = RegExp(r'\d').allMatches(s).map((e) => e.group(0)!).join();
    return digits.isEmpty ? null : int.parse(digits);
  }
}
