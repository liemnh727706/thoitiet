import 'package:flutter/material.dart';

// Gradient nền động theo thời tiết + ngày/đêm, phân biệt rõ:
// nắng / nhiều mây / mưa nhỏ / mưa lớn / dông, và biến thể ban đêm.
class WeatherGradients {
  static List<Color> forCondition(String icon, {required bool isDay}) {
    if (!isDay) return _night(icon);
    return _day(icon);
  }

  static List<Color> _day(String icon) {
    switch (icon) {
      case 'clear':
        return const [Color(0xFF1E6FE0), Color(0xFF4A9BF0), Color(0xFF8FC8FF)];
      case 'mostly_clear':
        return const [Color(0xFF2E7BD6), Color(0xFF5CA3E8), Color(0xFF9AC8F0)];
      case 'partly_cloudy':
        return const [Color(0xFF4E85B8), Color(0xFF7FA8CC), Color(0xFFA9C4DA)];
      case 'cloudy':
        return const [Color(0xFF63717F), Color(0xFF8493A1), Color(0xFFAAB6C1)];
      case 'fog':
        return const [Color(0xFF8A97A3), Color(0xFFAAB5BF), Color(0xFFCAD2D9)];
      case 'drizzle':
        return const [Color(0xFF5A7686), Color(0xFF7C97A7), Color(0xFF9DB2BF)];
      case 'rain':
      case 'showers':
        return const [Color(0xFF3E5563), Color(0xFF5B7686), Color(0xFF7A93A1)];
      case 'heavy_rain':
        return const [Color(0xFF2A3A45), Color(0xFF3E5462), Color(0xFF556B78)];
      case 'thunderstorm':
        return const [Color(0xFF23262F), Color(0xFF3A4150), Color(0xFF515A6B)];
      case 'snow':
      case 'sleet':
        return const [Color(0xFF7E93A6), Color(0xFFA6B8C8), Color(0xFFD2DDE6)];
      default:
        return const [Color(0xFF4E85B8), Color(0xFF7FA8CC), Color(0xFFA9C4DA)];
    }
  }

  static List<Color> _night(String icon) {
    switch (icon) {
      case 'clear':
      case 'mostly_clear':
        return const [Color(0xFF07152F), Color(0xFF122246), Color(0xFF24365F)];
      case 'partly_cloudy':
        return const [Color(0xFF10203A), Color(0xFF1E3352), Color(0xFF35496A)];
      case 'cloudy':
      case 'fog':
        return const [Color(0xFF1C232D), Color(0xFF2E3A48), Color(0xFF44515F)];
      case 'drizzle':
      case 'rain':
      case 'showers':
        return const [Color(0xFF12222B), Color(0xFF1E3540), Color(0xFF2E4A56)];
      case 'heavy_rain':
      case 'thunderstorm':
        return const [Color(0xFF0C1116), Color(0xFF1A2029), Color(0xFF2A323F)];
      case 'snow':
      case 'sleet':
        return const [Color(0xFF243244), Color(0xFF39495E), Color(0xFF556678)];
      default:
        return const [Color(0xFF0F2027), Color(0xFF1B2E38), Color(0xFF2C4A57)];
    }
  }
}

// Màu theo mức độ cảnh báo
class AlertColors {
  static Color background(String severity) {
    switch (severity) {
      case 'danger':
        return const Color(0xFFD32F2F);
      case 'warning':
        return const Color(0xFFF57C00);
      case 'watch':
      default:
        return const Color(0xFFFBC02D);
    }
  }

  static Color foreground(String severity) {
    return severity == 'watch' ? const Color(0xFF3E2E00) : Colors.white;
  }

  static String label(String severity) {
    switch (severity) {
      case 'danger':
        return 'NGUY HIỂM';
      case 'warning':
        return 'CẢNH BÁO';
      case 'watch':
      default:
        return 'THEO DÕI';
    }
  }
}
