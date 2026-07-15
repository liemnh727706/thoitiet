class AppConfig {
  // URL backend aggregator.
  //  - Android Emulator:  http://10.0.2.2:4000
  //  - iOS Simulator / web / desktop:  http://localhost:4000
  //  - Máy thật: đổi thành IP LAN của máy chạy backend, vd http://192.168.1.10:4000
  //
  // Có thể override khi build:  flutter run --dart-define=API_BASE=http://192.168.1.10:4000
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:4000',
  );

  // Tọa độ mặc định khi chưa có GPS (TP.HCM)
  static const double defaultLat = 10.7626;
  static const double defaultLon = 106.6602;
  static const String defaultPlace = 'TP. Hồ Chí Minh';
}
