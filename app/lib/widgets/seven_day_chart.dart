import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/price_point.dart';
import '../services/coffee_price_api.dart';

/// Biểu đồ giá trung bình nội địa 7 ngày. Nở đầy chiều cao mẹ cấp cho nó
/// (cha bọc trong Expanded → biểu đồ to, dùng hết khoảng trống màn hình).
class SevenDayChart extends StatefulWidget {
  const SevenDayChart({super.key, this.scale = 1.0});

  /// Hệ số phóng to chữ theo màn hình.
  final double scale;

  @override
  State<SevenDayChart> createState() => _SevenDayChartState();
}

class _SevenDayChartState extends State<SevenDayChart> {
  bool _loading = true;
  String? _error;
  List<PricePoint> _points = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pts = await CoffeePriceApi.fetchAverageHistory(days: 7);
      if (!mounted) return;
      setState(() {
        _points = pts;
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

  String _short(String date) => date.length >= 10
      ? '${date.substring(8, 10)}/${date.substring(5, 7)}'
      : date;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10 * s, 6 * s, 10 * s, 4 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Giá TB nội địa 7 ngày (đ/kg)',
                    style: TextStyle(
                        fontSize: 13 * s, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Tải lại biểu đồ',
                  visualDensity: VisualDensity.compact,
                  onPressed: _loading ? null : _load,
                  icon: Icon(Icons.refresh, size: 18 * s),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Phần nội dung nở đầy toàn bộ chiều cao còn lại.
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final s = widget.scale;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _points.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Không tải được, thử lại'),
        ),
      );
    }

    if (_points.length < 2) {
      return const Center(
        child: Text('Chưa đủ dữ liệu 2 ngày để vẽ biểu đồ.'),
      );
    }

    final values = _points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b) - 1500;
    final maxV = values.reduce((a, b) => a > b ? a : b) + 1500;

    return Column(
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (_points.length - 1).toDouble(),
                minY: minV.toDouble(),
                maxY: maxV.toDouble(),
                gridData: const FlGridData(
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.brown.shade100),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52 * s,
                      getTitlesWidget: (v, meta) => Text(
                        '${v.toInt()}đ',
                        style: TextStyle(fontSize: 10 * s),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= _points.length) {
                          return const SizedBox.shrink();
                        }
                        final step = (_points.length ~/ 3).clamp(1, 3);
                        final show = i == 0 ||
                            i == _points.length - 1 ||
                            i % step == 0;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            show ? _short(_points[i].date) : '',
                            style: TextStyle(fontSize: 10 * s),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < _points.length; i++)
                        FlSpot(i.toDouble(), _points[i].value.toDouble()),
                    ],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFFA1887F),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFA1887F).withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Nguồn: chocaphe.vn',
            style: TextStyle(fontSize: 10 * s, color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }
}
