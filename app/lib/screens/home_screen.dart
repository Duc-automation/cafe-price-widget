import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/coffee_price.dart';
import '../services/coffee_price_api.dart';
import '../services/widget_store.dart';
import '../widgets/seven_day_chart.dart';
import 'schedule_screen.dart';

/// Màu báo TĂNG. Nền tối cần tone nhạt hơn (400) cho đủ tương phản,
/// nền sáng dùng tone đậm (700).
Color _upColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade700;

/// Màu báo GIẢM — cùng quy tắc đổi tone theo nền như [_upColor].
Color _downColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.red.shade400
        : Colors.red.shade700;

/// Màn hình chính: hiện giá cà phê lấy từ API chocaphe.vn.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  CoffeePrice? _price;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Gọi API lấy giá. Giữ giá cũ trên màn hình nếu lần refresh lỗi.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final price = await CoffeePriceApi.fetch();
      if (!mounted) return;
      // Lưu giá xuống Android để widget trên màn hình chính đọc được.
      await WidgetStore.save(price: price);
      setState(() {
        _price = price;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIÁ CÀ PHÊ HÔM NAY'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cập nhật tự động theo lịch',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScheduleScreen()),
            ),
            icon: const Icon(Icons.schedule_outlined),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Lần đầu đang tải -> vòng xoay
    if (_loading && _price == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Lần đầu lỗi (chưa có giá nào) -> màn hình báo lỗi + nút thử lại
    if (_error != null && _price == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Không lấy được giá cà phê',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final price = _price!;

    // Responsive: dùng đầy màn hình — tự phóng to theo kích thước thiết bị.
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale =
            (math.min(constraints.maxWidth, constraints.maxHeight) / 400)
                .clamp(1.0, 1.5)
                .toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Giá TB thu nhỏ (cả chữ lẫn ô) để nhường chỗ cho bảng + biểu đồ.
              _HeroCard(price: price, scale: scale),
              SizedBox(height: 6 * scale),
              // MỘT bảng full-width duy nhất, chữ to cho người lớn tuổi.
              _PriceTableCard(price: price, scale: scale),
              if (_error != null) ...[
                SizedBox(height: 4),
                Text(
                  'Lần làm mới gần nhất gặp lỗi: $_error',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              SizedBox(height: 6 * scale),
              _SectionTitle('Biểu đồ giá 7 ngày qua', scale: scale),
              SizedBox(height: 4),
              // Biểu đồ nở đầy chiều cao còn lại => dùng hết màn hình.
              Expanded(child: SevenDayChart(scale: scale)),
            ],
          ),
        );
      },
    );
  }
}

/// Dải giá TB THU NHỎ (cả chữ lẫn ô) — gọn 1 dòng, nhường chỗ cho bảng + chart.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.price, required this.scale});

  final CoffeePrice price;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final cs = Theme.of(context).colorScheme;
    final color = _changeColor(context);
    final arrow = price.isUp
        ? '▲ '
        : price.isDown
            ? '▼ '
            : '';
    final change = price.priceChange.isEmpty
        ? 'Không đổi'
        : '$arrow${price.priceChange}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12 * s, 5 * s, 12 * s, 5 * s),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Giá trung bình nội địa',
                    style: TextStyle(
                      fontSize: 12 * s,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      price.averagePrice,
                      style: TextStyle(
                        fontSize: 24 * s,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Cập nhật: ${price.updatedAt}',
                    style: TextStyle(fontSize: 11 * s, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              change,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15 * s,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _changeColor(BuildContext context) {
    if (price.isUp) return _upColor(context);
    if (price.isDown) return _downColor(context);
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

/// MỘT bảng full-width duy nhất: nội địa + Hồ tiêu + giá thế giới.
/// Giá nội địa chữ TO (20-22) cho người lớn tuổi dễ đọc;
/// giá THẾ GIỚI thu nhỏ hơn; mọi giá được canh sát mép PHẢI.
class _PriceTableCard extends StatelessWidget {
  const _PriceTableCard({required this.price, required this.scale});

  final CoffeePrice price;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final cs = Theme.of(context).colorScheme;
    // Bỏ dòng "Tỷ giá USD/VND"
    final domesticItems =
        price.items.where((item) => item.market != 'Tỷ giá USD/VND').toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12 * s, 6 * s, 12 * s, 6 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupHeader(context, 'GIÁ NỘI ĐỊA (đ/kg)', s),
            for (final item in domesticItems)
              _bigRow(
                context,
                item.market,
                item.averagePrice,
                item.priceChange,
                null,
                s,
              ),
            Divider(height: 8 * s, thickness: 1, color: cs.outlineVariant),
            _groupHeader(context, 'GIÁ THẾ GIỚI', s),
            _bigRow(context, 'Robusta London', price.robusta, '', 'USD/tấn', s,
                small: true),
            _bigRow(context, 'Arabica NY', price.arabica, '', 'cent/lb', s,
                small: true),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(BuildContext context, String text, double s) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3 * s),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14 * s,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Một dòng bảng: tên bên trái, GIÁ đẩy sát mép phải.
  /// `small = true` cho giá thế giới (chữ nhỏ hơn, dòng gọn hơn).
  Widget _bigRow(
    BuildContext context,
    String name,
    String? value,
    String change,
    String? unit,
    double s, {
    bool small = false,
  }) {
    final up = change.startsWith('+');
    final down = change.startsWith('-');
    final color = up
        ? _upColor(context)
        : (down
            ? _downColor(context)
            : Theme.of(context).colorScheme.onSurfaceVariant);
    final val = value == null || value.isEmpty
        ? '—'
        : (unit == null ? value : '$value $unit');

    final nameSize = small ? 14 * s : 17 * s;
    final valueSize = small ? 16 * s : 22 * s;
    final changeSize = small ? 13 * s : 17 * s;
    final vPad = small ? 1.5 * s : 3 * s;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tên khu vực ăn hết khoảng trống còn lại => giá tự dồn về mép phải.
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: 6 * s),
          Text(
            val,
            style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w800),
          ),
          if (change.isNotEmpty) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 72 * s,
              child: Text(
                change,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: changeSize,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.scale = 1.0});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15 * scale,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
