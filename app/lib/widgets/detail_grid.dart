import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

// TẦNG 2 (chi tiết): lưới các chỉ số - độ ẩm, gió, áp suất, UV...
class DetailGrid extends StatelessWidget {
  final CurrentWeather current;
  final DailyItem? today;
  const DetailGrid({super.key, required this.current, this.today});

  @override
  Widget build(BuildContext context) {
    final items = <_Metric>[
      _Metric(Icons.water_drop_outlined, 'Độ ẩm', '${current.humidity ?? '--'}%'),
      _Metric(Icons.air_rounded, 'Gió',
          '${current.wind.speed ?? '--'} km/h ${current.wind.direction}'),
      _Metric(Icons.compress_rounded, 'Áp suất', '${current.pressure ?? '--'} hPa'),
      _Metric(Icons.wb_sunny_outlined, 'Tia UV', uvLabel(today?.uvIndexMax)),
      _Metric(Icons.speed_rounded, 'Gió giật', '${current.wind.gust ?? '--'} km/h'),
      _Metric(Icons.umbrella_outlined, 'Khả năng mưa',
          '${today?.precipitationProbability ?? '--'}%'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: items.map((m) => _MetricTile(metric: m)).toList(),
    );
  }
}

class _Metric {
  final IconData icon;
  final String label;
  final String value;
  _Metric(this.icon, this.label, this.value);
}

class _MetricTile extends StatelessWidget {
  final _Metric metric;
  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppTheme.glassCard,
      child: Row(
        children: [
          Icon(metric.icon, color: Colors.white.withValues(alpha: 0.9), size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.label,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                const SizedBox(height: 2),
                Text(metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
