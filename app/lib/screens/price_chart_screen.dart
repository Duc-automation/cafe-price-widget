import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/price_point.dart';
import '../services/coffee_price_api.dart';

/// Biểu đồ giá trung bình nội địa 7 ngày gần nhất.
class PriceChartScreen extends StatefulWidget {
  const PriceChartScreen({super.key});

  @override
  State<PriceChartScreen> createState() => _PriceChartScreenState();
}

class _PriceChartScreenState extends State<PriceChartScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Biểu đồ giá 7 ngày'), centerTitle: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null && _points.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ]),
      );
    }

    if (_points.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Chưa đủ dữ liệu 2 ngày để vẽ biểu đồ.'),
        ),
      );
    }

    final values = _points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b) - 1500;
    final maxV = values.reduce((a, b) => a > b ? a : b) + 1500;
    final latest = _points.last;
    final maxPoint =
        _points.reduce((a, b) => a.value > b.value ? a : b);
    final minPoint =
        _points.reduce((a, b) => a.value < b.value ? a : b);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Tóm tắt
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(label: 'Hôm nay', value: '${latest.value}đ'),
                  _Stat(
                    label: 'Cao nhất',
                    value: '${maxPoint.value}đ',
                    date: _short(maxPoint.date),
                  ),
                  _Stat(
                    label: 'Thấp nhất',
                    value: '${minPoint.value}đ',
                    date: _short(minPoint.date),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Biểu đồ
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      'Giá trung bình nội địa (đ/kg)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 260,
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
                          border: Border.all(
                            color: Colors.brown.shade100,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 52,
                              getTitlesWidget: (v, meta) => Text(
                                '${v.toInt()}đ',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
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
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    show ? _short(_points[i].date) : '',
                                    style: const TextStyle(fontSize: 10),
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
                                FlSpot(
                                  i.toDouble(),
                                  _points[i].value.toDouble(),
                                ),
                            ],
                            isCurved: true,
                            preventCurveOverShooting: true,
                            color: const Color(0xFF6D4C41),
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF6D4C41)
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dữ liệu lấy từ chocaphe.vn theo từng ngày.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.date});

  final String label;
  final String value;
  final String? date;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        if (date != null)
          Text(date!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}
