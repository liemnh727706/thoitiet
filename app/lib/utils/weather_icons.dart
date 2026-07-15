import 'package:flutter/material.dart';

// Ánh xạ khóa icon (từ backend) -> Material Icon.
// MVP dùng Material Icons cho gọn nhẹ (không cần asset).
// Giai đoạn sau có thể thay bằng bộ icon động đẹp hơn (kiểu breezy-weather).
IconData weatherIcon(String key, {bool isDay = true}) {
  switch (key) {
    case 'clear':
      return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    case 'mostly_clear':
      return isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined;
    case 'partly_cloudy':
      return isDay ? Icons.wb_cloudy_outlined : Icons.cloud_outlined;
    case 'cloudy':
      return Icons.cloud_rounded;
    case 'fog':
      return Icons.foggy;
    case 'drizzle':
      return Icons.grain_rounded;
    case 'rain':
      return Icons.water_drop_outlined;
    case 'heavy_rain':
      return Icons.water_drop_rounded;
    case 'showers':
      return Icons.grain;
    case 'sleet':
      return Icons.ac_unit_outlined;
    case 'snow':
      return Icons.ac_unit_rounded;
    case 'thunderstorm':
      return Icons.thunderstorm_rounded;
    default:
      return Icons.cloud_rounded;
  }
}

// Icon cho từng loại cảnh báo (tier 1)
IconData alertIcon(String kind) {
  switch (kind) {
    case 'heat':
      return Icons.local_fire_department_rounded;
    case 'cold':
      return Icons.ac_unit_rounded;
    case 'rain':
      return Icons.water_rounded;
    case 'wind':
      return Icons.air_rounded;
    case 'uv':
      return Icons.wb_sunny_rounded;
    case 'storm':
      return Icons.cyclone_rounded;
    case 'flood':
      return Icons.flood_rounded;
    case 'salinity':
      return Icons.water_drop_rounded;
    default:
      return Icons.warning_amber_rounded;
  }
}
