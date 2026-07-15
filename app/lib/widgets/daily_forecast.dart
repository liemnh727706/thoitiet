import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/weather_icons.dart';

// TẦNG 3: Dự báo 7 ngày.
class DailyForecast extends StatelessWidget {
  final List<DailyItem> daily;
  const DailyForecast({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    // Tính min/max cả tuần để vẽ thanh nhiệt độ tương đối
    final mins = daily.map((d) => d.tempMin ?? 0).toList();
    final maxs = daily.map((d) => d.tempMax ?? 0).toList();
    final weekMin = mins.isEmpty ? 0 : mins.reduce((a, b) => a < b ? a : b);
    final weekMax = maxs.isEmpty ? 1 : maxs.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text('DỰ BÁO 7 NGÀY',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          ...daily.map((d) => _DayRow(
                item: d,
                weekMin: weekMin.toDouble(),
                weekMax: weekMax.toDouble(),
              )),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final DailyItem item;
  final double weekMin;
  final double weekMax;
  const _DayRow({required this.item, required this.weekMin, required this.weekMax});

  @override
  Widget build(BuildContext context) {
    final rain = item.precipitationProbability ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(formatDayLabel(item.date),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Icon(weatherIcon(item.icon), color: Colors.white, size: 22),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            child: rain > 10
                ? Text('$rain%',
                    style: const TextStyle(color: Color(0xFF9DD6FF), fontSize: 11))
                : const SizedBox.shrink(),
          ),
          const Spacer(),
          Text('${item.tempMin ?? '--'}°',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(width: 8),
          _TempBar(min: item.tempMin?.toDouble() ?? 0, max: item.tempMax?.toDouble() ?? 0,
              weekMin: weekMin, weekMax: weekMax),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text('${item.tempMax ?? '--'}°',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// Thanh nhiệt độ gradient thể hiện khoảng min-max trong tuần
class _TempBar extends StatelessWidget {
  final double min, max, weekMin, weekMax;
  const _TempBar({required this.min, required this.max, required this.weekMin, required this.weekMax});

  @override
  Widget build(BuildContext context) {
    const barWidth = 70.0;
    final range = (weekMax - weekMin).clamp(1, 1000);
    final left = ((min - weekMin) / range) * barWidth;
    final width = ((max - min) / range) * barWidth;
    return Container(
      width: barWidth,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          Positioned(
            left: left.clamp(0, barWidth),
            child: Container(
              width: width.clamp(6, barWidth),
              height: 6,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFFFFB74D)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
