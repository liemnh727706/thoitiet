import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../utils/weather_icons.dart';

// TẦNG 2 (chính): Thời tiết hiện tại - nhiệt độ lớn + icon.
class CurrentWeatherCard extends StatelessWidget {
  final CurrentWeather current;
  const CurrentWeatherCard({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          weatherIcon(current.icon, isDay: current.isDay),
          size: 96,
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        Text(
          '${current.temperature ?? '--'}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 88,
            fontWeight: FontWeight.w200,
            height: 1.0,
          ),
        ),
        Text(
          current.condition,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Cảm giác như ${current.apparentTemperature ?? '--'}°',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
        ),
      ],
    );
  }
}
