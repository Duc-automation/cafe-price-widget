/// Dữ liệu giá 1 thị trường trong bảng giá nội địa (Đắk Lắk, Lâm Đồng, ...).
class DomesticItem {
  final String market; // tên thị trường / tỉnh
  final String averagePrice; // giá trung bình, VD "95,500"
  final String priceChange; // thay đổi, VD "+1,300" / "-20" / " "

  DomesticItem({
    required this.market,
    required this.averagePrice,
    required this.priceChange,
  });

  factory DomesticItem.fromJson(Map<String, dynamic> json) {
    return DomesticItem(
      market: (json['market'] ?? '').toString().trim(),
      averagePrice: (json['average_price'] ?? '').toString().trim(),
      priceChange: (json['price_change'] ?? '').toString().trim(),
    );
  }
}

/// Giá cà phê lấy từ API `https://api.chocaphe.vn/v1/prices`.
class CoffeePrice {
  final String date; // ngày của bản ghi, VD "2026-09-09"
  final String averagePrice; // giá trung bình nội địa, VD "95,600đ/kg"
  final String priceChange; // VD "+1,300" (đã trim khoảng trắng)
  final String updatedAt; // giờ cập nhật, VD "18:31 09/09/2026"
  final List<DomesticItem> items; // giá từng tỉnh / thị trường
  final String? robusta; // Robusta London (USD/tấn), kỳ hạn gần nhất
  final String? arabica; // Arabica New York (cent/lb), kỳ hạn gần nhất

  CoffeePrice({
    required this.date,
    required this.averagePrice,
    required this.priceChange,
    required this.updatedAt,
    required this.items,
    this.robusta,
    this.arabica,
  });

  factory CoffeePrice.fromJson(Map<String, dynamic> json) {
    final domestic = (json['domestic_price'] as Map<String, dynamic>?) ?? {};
    final intl = (json['international_price'] as Map<String, dynamic>?) ?? {};

    final items = ((domestic['item'] as List?) ?? [])
        .map((e) => DomesticItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // Lấy giá "Ask" của phần tử đầu tiên (kỳ hạn gần nhất) trong 1 nhóm.
    String? askOf(List? list) {
      if (list == null || list.isEmpty) return null;
      final first = list.first as Map<String, dynamic>;
      return (first['Ask'] ?? '').toString().trim();
    }

    return CoffeePrice(
      date: (json['date'] ?? '').toString(),
      averagePrice: (domestic['average_price'] ?? '').toString().trim(),
      priceChange: (domestic['price_change'] ?? '').toString().trim(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      items: items,
      robusta: askOf(intl['coffee_liffe'] as List?),
      arabica: askOf(intl['coffee_ice'] as List?),
    );
  }

  /// Giá có tăng không? (priceChange bắt đầu bằng "+")
  bool get isUp => priceChange.startsWith('+');

  /// Giá có giảm không? (priceChange bắt đầu bằng "-")
  bool get isDown => priceChange.startsWith('-');
}
