import 'package:flutter/material.dart';

import '../models/coffee_price.dart';
import '../services/coffee_price_api.dart';
import '../services/widget_store.dart';
import '../widgets/seven_day_chart.dart';
import 'schedule_screen.dart';

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
        title: const Text('Giá cà phê hôm nay'),
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

    // Bỏ dòng "Tỷ giá USD/VND"
    final domesticItems =
        price.items.where((item) => item.market != 'Tỷ giá USD/VND').toList();

    // Mọi thứ gọn trong 1 khung hình — không cần cuộn.
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeroCard(price: price),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _MiniMarketCard(items: domesticItems)),
              const SizedBox(width: 10),
              Expanded(child: _MiniWorldCard(price: price)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              'Lần làm mới gần nhất gặp lỗi: $_error',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 10),
          const _SectionTitle('Biểu đồ giá 7 ngày qua'),
          const SizedBox(height: 6),
          const SevenDayChart(chartHeight: 130),
        ],
      ),
    );
  }
}

/// Thẻ giá chính (gọn 1 dòng lớn + giờ cập nhật).
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.price});

  final CoffeePrice price;

  @override
  Widget build(BuildContext context) {
    final color = _changeColor();
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
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giá trung bình nội địa',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          price.averagePrice,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Cập nhật: ${price.updatedAt}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Color _changeColor() {
    if (price.isUp) return Colors.green.shade700;
    if (price.isDown) return Colors.red.shade700;
    return Colors.grey.shade600;
  }
}

/// Bảng mini: giá từng tỉnh (cột trái).
class _MiniMarketCard extends StatelessWidget {
  const _MiniMarketCard({required this.items});

  final List<DomesticItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giá nội địa',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 4),
            for (final item in items) _miniRow(item),
          ],
        ),
      ),
    );
  }

  Widget _miniRow(DomesticItem item) {
    final change = item.priceChange.isEmpty ? '' : item.priceChange;
    final up = change.startsWith('+');
    final down = change.startsWith('-');
    final color =
        up ? Colors.green.shade700 : (down ? Colors.red.shade700 : Colors.grey.shade600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.market,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            item.averagePrice,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 52,
            child: Text(
              change,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bảng mini: giá quốc tế (cột phải).
class _MiniWorldCard extends StatelessWidget {
  const _MiniWorldCard({required this.price});

  final CoffeePrice price;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giá thế giới',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 4),
            _worldRow('Robusta London', price.robusta, 'USD/tấn'),
            _worldRow('Arabica NY', price.arabica, 'cent/lb'),
          ],
        ),
      ),
    );
  }

  Widget _worldRow(String label, String? value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value == null || value.isEmpty ? '—' : '$value $unit',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.brown.shade800,
      ),
    );
  }
}
