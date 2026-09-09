import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/coffee_price.dart';

/// Gọi API giá cà phê của chocaphe.vn.
class CoffeePriceApi {
  CoffeePriceApi._(); // không cho khởi tạo

  static const String baseUrl = 'https://api.chocaphe.vn/v1/prices';

  /// Lấy giá mới nhất.
  /// Ném [Exception] nếu lỗi mạng hoặc máy chủ trả lỗi.
  static Future<CoffeePrice> fetch() async {
    final res = await http
        .get(
          Uri.parse(baseUrl),
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
}
