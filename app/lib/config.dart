class AppConfig {
  // URL backend aggregator. Mặc định trỏ backend production (HTTPS).
  // Dev local có thể override:
  //   flutter run --dart-define=API_BASE=http://10.0.2.2:4000   (Android emulator)
  //   flutter run --dart-define=API_BASE=http://localhost:4000  (web/desktop)
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://cropnlu.duckdns.org/weather',
  );

  // Tọa độ mặc định khi chưa có GPS (TP.HCM)
  static const double defaultLat = 10.7626;
  static const double defaultLon = 106.6602;
  static const String defaultPlace = 'TP. Hồ Chí Minh';
}
