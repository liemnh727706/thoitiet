# VN Weather — Flutter App (MVP)

App thời tiết cho người dùng Việt Nam. Lấy dữ liệu real-time từ **Open-Meteo** qua backend aggregator. UI lấy cảm hứng từ [breezy-weather](https://github.com/breezy-weather/breezy-weather): nền gradient động theo thời tiết, chia **3 tầng thông tin**.

## Cấu trúc thông tin (3 tầng)
- **Tầng 1 — Cảnh báo khẩn** (`AlertBanner`): nắng nóng, rét, mưa lớn, gió mạnh, UV. Màu đỏ/cam/vàng theo mức độ.
- **Tầng 2 — Hiện tại** (`CurrentWeatherCard` + `DetailGrid`): nhiệt độ, cảm giác thực, độ ẩm, gió, áp suất, UV.
- **Tầng 3 — Dự báo** (`HourlyForecast` 24h + `DailyForecast` 7 ngày).

## Yêu cầu
- Flutter SDK (bản stable mới nhất) — cài theo https://docs.flutter.dev/get-started/install
- Backend đang chạy (thư mục `../server`, mặc định cổng 4000)

## Chạy lần đầu

```bash
cd app

# 1) Sinh khung nền tảng (android/ios/...) — thư mục này mới chỉ có lib/ + pubspec
flutter create .

# 2) Cài package
flutter pub get

# 3) Chạy (chọn thiết bị/emulator)
#   - Android emulator: backend là http://10.0.2.2:4000 (mặc định, không cần sửa)
#   - Máy Android thật / iOS: trỏ tới IP LAN của máy chạy backend
flutter run --dart-define=API_BASE=http://10.0.2.2:4000
```

> Máy thật: thay bằng IP LAN, ví dụ `--dart-define=API_BASE=http://192.168.1.10:4000`.

## Cấp quyền vị trí (sau khi chạy `flutter create .`)

**Android** — thêm vào `android/app/src/main/AndroidManifest.xml` (trong thẻ `<manifest>`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```
Để gọi được `http://` (không phải https) khi dev, thêm vào thẻ `<application ...>`:
```xml
android:usesCleartextTraffic="true"
```

**iOS** — thêm vào `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ứng dụng cần vị trí để hiển thị thời tiết nơi bạn đang ở.</string>
```

## Cấu trúc mã
```
lib/
  main.dart                # khởi tạo app + Provider
  config.dart              # URL backend, tọa độ mặc định
  models/weather.dart      # model khớp JSON backend
  services/                # api_service, location_service
  state/weather_provider.dart   # quản lý state (ChangeNotifier)
  theme/                   # app_theme, weather_gradients
  utils/                   # weather_icons, formatters
  widgets/                 # alert_banner, current_weather_card, detail_grid,
                           # hourly_forecast, daily_forecast
  screens/                 # home_screen, search_screen
```
