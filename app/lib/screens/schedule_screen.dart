import 'package:flutter/material.dart';

import '../services/widget_store.dart';

/// Màn hình cấu hình "tự động cập nhật giá theo lịch".
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _enabled = false;
  List<String> _times = [];
  int _max = 5;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await WidgetStore.getSchedule();
    if (!mounted) return;
    setState(() {
      _enabled = s['enabled'] == true;
      final times = s['times'] as String? ?? '';
      _times = times
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _max = (s['max'] as int?) ?? 5;
      _loading = false;
    });
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Chọn giờ tự động cập nhật',
    );
    if (picked == null) return;
    final s = _fmt(picked);
    if (_times.contains(s)) return;
    setState(() => _times.add(s));
  }

  Future<void> _save() async {
    await WidgetStore.setSchedule(
      enabled: _enabled,
      times: _times,
      maxPerDay: _max,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu lịch cập nhật tự động')),
    );
  }

  Future<void> _runNow() async {
    await WidgetStore.runNow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang cập nhật nền... kiểm tra widget sau vài giây')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cập nhật tự động')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Bật cập nhật tự động'),
                  subtitle: const Text(
                      'Đúng giờ đã đặt, app sẽ tự lấy giá và cập nhật widget (không cần mở app)'),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                const SizedBox(height: 8),
                const Text('Giờ trong ngày (mỗi giờ tối đa 1 lần):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _times)
                      InputChip(
                        label: Text(t),
                        onDeleted: () => setState(() => _times.remove(t)),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm giờ'),
                      onPressed: _addTime,
                    ),
                  ],
                ),
                if (_times.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Chưa có giờ nào (mặc định 07:30, 12:00, 18:00)',
                        style: TextStyle(color: Colors.grey)),
                  ),
                const SizedBox(height: 16),
                Text('Tối đa số lần/ngày: $_max',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _max.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_max',
                  onChanged: (v) => setState(() => _max = v.round()),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Lưu lịch'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _runNow,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Chạy thử cập nhật nền ngay'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ghi chú: Android chỉ cho chạy nền tối thiểu ~15 phút một lần. '
                  'Vì vậy giờ đặt sẽ được kích hoạt trong khoảng ± vài phút. '
                  'Hệ thống cũng có thể trì hoãn khi pin yếu.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
    );
  }
}
