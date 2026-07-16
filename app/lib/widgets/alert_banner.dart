import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../theme/weather_gradients.dart';
import '../utils/weather_icons.dart';

// TẦNG 1: Cảnh báo khẩn - luôn hiển thị trên cùng nếu có.
class AlertBanner extends StatelessWidget {
  final List<WeatherAlert> alerts;
  const AlertBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      children: alerts.map((a) => _AlertTile(alert: a)).toList(),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final WeatherAlert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final bg = AlertColors.background(alert.severity);
    final fg = AlertColors.foreground(alert.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(alertIcon(alert.kind), color: fg, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AlertColors.label(alert.severity),
                        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.title,
                        style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(alert.message, style: TextStyle(color: fg.withValues(alpha: 0.95), fontSize: 13, height: 1.3)),
                if (alert.official) _officialFooter(fg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dòng nguồn chính thức + thời gian phát tin (chỉ cho bản tin NCHMF)
  Widget _officialFooter(Color fg) {
    final parts = <String>['Nguồn chính thức: NCHMF'];
    if (alert.issuedAt != null) {
      parts.add('phát ${DateFormat('HH:mm dd/MM').format(alert.issuedAt!.toLocal())}');
    }
    if (alert.regions.isNotEmpty) {
      parts.add('ảnh hưởng: ${alert.regionsLabel}');
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: fg.withValues(alpha: 0.9), size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(parts.join(' · '),
                style: TextStyle(
                    color: fg.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}
