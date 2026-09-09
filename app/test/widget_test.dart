import 'package:flutter_test/flutter_test.dart';

import 'package:gia_ca_phe/models/coffee_price.dart';

/// Unit test: parse đúng dữ liệu JSON mẫu của API chocaphe.vn.
void main() {
  test('CoffeePrice.fromJson parse đúng JSON API chocaphe', () {
    final json = {
      'date': '2026-09-09',
      'domestic_price': {
        'date': '2026-09-09',
        'item': [
          {
            'market': 'Đắk Lắk',
            'average_price': '95,500',
            'price_change': '+1,300'
          },
          {
            'market': 'Lâm Đồng',
            'average_price': '95,000',
            'price_change': '+1,300'
          },
          {
            'market': 'Gia Lai',
            'average_price': '95,500',
            'price_change': '+1,300'
          },
          {
            'market': 'Đắk Nông',
            'average_price': '95,800',
            'price_change': '+1,300'
          },
          {
            'market': 'Hồ tiêu',
            'average_price': '141,000',
            'price_change': ' '
          },
          {
            'market': 'Tỷ giá USD/VND',
            'average_price': '25,750',
            'price_change': '-20'
          },
        ],
        'price_change': '+1,300',
        'average_price': '95,600đ/kg',
      },
      'international_price': {
        'coffee_ice': [
          {
            'Ask': '318.45',
            'Month': '09/26',
            'Change': '-5.80',
            'PtcChange': '-1.79%'
          }
        ],
        'coffee_liffe': [
          {
            'Ask': '3,347',
            'Month': '09/26',
            'Change': '-28',
            'PtcChange': '-0.83%'
          }
        ],
      },
      'updated_at': '18:31 09/09/2026',
    };

    final p = CoffeePrice.fromJson(json);

    expect(p.averagePrice, '95,600đ/kg');
    expect(p.priceChange, '+1,300');
    expect(p.isUp, isTrue);
    expect(p.isDown, isFalse);
    expect(p.robusta, '3,347');
    expect(p.arabica, '318.45');
    expect(p.items.length, 6);
    expect(p.items.first.market, 'Đắk Lắk');
    expect(p.items.last.market, 'Tỷ giá USD/VND');
    expect(p.items.last.priceChange, '-20');
    expect(p.updatedAt, '18:31 09/09/2026');
  });
}
