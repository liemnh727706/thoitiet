import 'package:flutter/material.dart';

// Gradient nền động theo tình trạng thời tiết + ngày/đêm.
// Cảm hứng từ breezy-weather: nền chuyển màu theo cảnh vật.
class WeatherGradients {
  static List<Color> forCondition(String icon, {required bool isDay}) {
    if (!isDay) {
      // Ban đêm: tông xanh đêm cho hầu hết trạng thái
      switch (icon) {
        case 'thunderstorm':
          return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
        case 'rain':
        case 'heavy_rain':
        case 'showers':
        case 'drizzle':
          return [const Color(0xFF203A43), const Color(0xFF2C5364)];
        default:
          return [const Color(0xFF0F2027), const Color(0xFF203A43)];
      }
    }
    switch (icon) {
      case 'clear':
      case 'mostly_clear':
        return [const Color(0xFF2196F3), const Color(0xFF64B5F6)];
      case 'partly_cloudy':
        return [const Color(0xFF4B79A1), const Color(0xFF7EA6C7)];
      case 'cloudy':
      case 'fog':
        return [const Color(0xFF616E7D), const Color(0xFF8A99A8)];
      case 'drizzle':
      case 'rain':
      case 'showers':
        return [const Color(0xFF3A6073), const Color(0xFF5B8CA5)];
      case 'heavy_rain':
      case 'thunderstorm':
        return [const Color(0xFF2C3E50), const Color(0xFF4A6278)];
      case 'snow':
      case 'sleet':
        return [const Color(0xFF6D8299), const Color(0xFFA5B8C9)];
      default:
        return [const Color(0xFF4B79A1), const Color(0xFF7EA6C7)];
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
