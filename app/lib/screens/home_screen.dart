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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(price: price),
          const SizedBox(height: 16),
          if (price.robusta != null || price.arabica != null) ...[
            const _SectionTitle('Giá quốc tế'),
            const SizedBox(height: 8),
            _InternationalCard(price: price),
            const SizedBox(height: 16),
          ],
          const _SectionTitle('Giá nội địa từng tỉnh'),
          const SizedBox(height: 8),
          // Bỏ qua dòng "Tỷ giá USD/VND"
          ...price.items
              .where((item) => item.market != 'Tỷ giá USD/VND')
              .map((item) => _MarketRow(item: item)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              'Lần làm mới gần nhất gặp lỗi: $_error',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          // Biểu đồ 7 ngày (cùng 1 màn hình)
          const SizedBox(height: 20),
          const _SectionTitle('Biểu đồ giá 7 ngày qua'),
          const SizedBox(height: 8),
          const SevenDayChart(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Thẻ lớn: giá trung bình + chip tăng/giảm + giờ cập nhật.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.price});

  final CoffeePrice price;

  @override
  Widget build(BuildContext context) {
    final color = _changeColor();
    final change = price.priceChange.isEmpty ? 'Không đổi' : price.priceChange;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Giá trung bình nội địa',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                price.averagePrice,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Chip(
              avatar: Icon(
                price.isUp
                    ? Icons.arrow_upward
                    : price.isDown
                        ? Icons.arrow_downward
                        : Icons.remove,
                color: color,
                size: 18,
              ),
              label: Text(
                change,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              backgroundColor: color.withValues(alpha: 0.12),
              side: BorderSide.none,
            ),
            const SizedBox(height: 12),
            Text(
              'Cập nhật: ${price.updatedAt}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

/// Thẻ nhỏ: Robusta London + Arabica New York.
class _InternationalCard extends StatelessWidget {
  const _InternationalCard({required this.price});

  final CoffeePrice price;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            _IntlRow(
              label: 'Robusta London',
              value: price.robusta,
              unit: 'USD/tấn',
            ),
            const Divider(height: 1),
            _IntlRow(
              label: 'Arabica New York',
              value: price.arabica,
              unit: 'cent/lb',
            ),
          ],
        ),
      ),
    );
  }
}

class _IntlRow extends StatelessWidget {
  const _IntlRow({required this.label, this.value, required this.unit});

  final String label;
  final String? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          if (value == null || value!.isEmpty)
            const Text('—', style: TextStyle(color: Colors.grey))
          else
            Text(
              '$value $unit',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
        ],
      ),
    );
  }
}

/// 1 dòng trong bảng giá từng tỉnh / thị trường.
class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.item});

  final DomesticItem item;

  @override
  Widget build(BuildContext context) {
    final change = item.priceChange.isEmpty ? '' : item.priceChange;
    final up = item.priceChange.startsWith('+');
    final down = item.priceChange.startsWith('-');
    final color =
        up ? Colors.green.shade700 : (down ? Colors.red.shade700 : Colors.grey.shade600);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(item.market, style: const TextStyle(fontSize: 15)),
            ),
            Text(
              item.averagePrice,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: Text(
                change,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.brown.shade800,
      ),
    );
  }
}
