import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/weather_icons.dart';

// TẦNG 3: Dự báo 24 giờ tới - cuộn ngang.
class HourlyForecast extends StatelessWidget {
  final List<HourlyItem> hourly;
  const HourlyForecast({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Text('DỰ BÁO 24 GIỜ',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: hourly.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => _HourCell(item: hourly[i], isFirst: i == 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourCell extends StatelessWidget {
  final HourlyItem item;
  final bool isFirst;
  const _HourCell({required this.item, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final rain = item.precipitationProbability ?? 0;
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isFirst ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isFirst ? 'Bây giờ' : formatHour(item.time),
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          Icon(weatherIcon(item.icon), color: Colors.white, size: 26),
          if (rain > 10)
            Text('$rain%',
                style: const TextStyle(color: Color(0xFF9DD6FF), fontSize: 11, fontWeight: FontWeight.w600))
          else
            const SizedBox(height: 14),
          Text('${item.temperature ?? '--'}°',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
