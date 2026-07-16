# Kích hoạt Push Notification (FCM) — cảnh báo thời tiết khẩn

Crawler NCHMF đã chạy và **phát hiện cảnh báo mới** (bão/ATNĐ, nắng nóng, không khí lạnh/rét).
Khi có tin mới còn hiệu lực, server gọi `onNewWarnings()` để đẩy FCM. Phần này **chưa bật** vì cần
dự án Firebase của bạn (tôi không tạo tài khoản thay bạn được). Làm theo các bước dưới để bật.

> Trạng thái hiện tại: code server sẵn sàng nhưng **inert** — không cấu hình thì chỉ log, không lỗi.
> App Flutter **chưa** nhúng Firebase (để giữ build CI xanh khi chưa có `google-services.json`).

---

## Phần A — Server (đẩy tin)

1. Tạo project tại https://console.firebase.google.com → bật **Cloud Messaging**.
2. Project Settings → Service accounts → **Generate new private key** → tải file JSON.
3. Đưa file lên VM (KHÔNG commit vào git), ví dụ `/home/ubuntu/thoitiet/secrets/firebase-sa.json`.
4. Sửa `server/.env`:
   ```
   FCM_SERVICE_ACCOUNT=/app/secrets/firebase-sa.json
   FCM_TOPIC=weather-warnings
   ```
5. Cài SDK + mount secret vào container. Thêm vào `docker-compose.yml` service `weather-server`:
   ```yaml
       volumes:
         - ./secrets:/app/secrets:ro
   ```
   và cài trong image: thêm `RUN npm install firebase-admin` — hoặc thêm `firebase-admin` vào
   `server/package.json` rồi `docker compose up -d --build`.
6. Kiểm tra log: `[FCM] Đã khởi tạo, sẽ đẩy tới topic: weather-warnings`.

## Phần B — App Flutter (nhận tin)

1. Cài FlutterFire CLI và cấu hình:
   ```bash
   dart pub global activate flutterfire_cli
   cd app && flutterfire configure    # chọn project Firebase, tạo firebase_options.dart + google-services.json
   ```
2. Thêm dependency vào `app/pubspec.yaml`:
   ```yaml
     firebase_core: ^3.6.0
     firebase_messaging: ^15.1.3
   ```
3. Trong `main.dart`, sau `WidgetsFlutterBinding.ensureInitialized()`:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   await FirebaseMessaging.instance.requestPermission();
   await FirebaseMessaging.instance.subscribeToTopic('weather-warnings');
   FirebaseMessaging.onMessage.listen((m) {
     // hiển thị in-app banner khi app đang mở (tùy chọn)
   });
   ```
4. Android: `flutterfire configure` đã thêm `google-services.json` và plugin Gradle.
   iOS: cần thêm APNs key trong Firebase Console.
5. Build lại APK — giờ máy nào cài app + subscribe topic sẽ nhận cảnh báo khi NCHMF ra tin mới.

## Kiểm thử nhanh
- Gửi thử từ Firebase Console → Cloud Messaging → gửi tới topic `weather-warnings`.
- Hoặc chờ NCHMF ra bản tin mới; server tự đẩy (log `[FCM] Đã đẩy: ...`).

## Bảo mật
- **KHÔNG** commit `firebase-sa.json` hay `google-services.json` chứa khóa. Đã có `.gitignore`
  cho `secrets/` và `**/google-services.json` — kiểm tra trước khi push.
