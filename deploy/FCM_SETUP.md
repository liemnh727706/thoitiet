# Bật Push Notification (FCM)

Code đã nối dây sẵn ở **cả app lẫn server** (an toàn: chưa cấu hình thì app vẫn chạy, CI vẫn xanh).
Chỉ cần cung cấp khóa Firebase là FCM tự bật. Khi NCHMF ra cảnh báo mới còn hiệu lực,
server tự đẩy tới topic `weather-warnings`; app đã subscribe topic đó.

---

## A. Tạo trên Firebase Console (bạn làm)
1. https://console.firebase.google.com → **Add project**.
2. **Add app → Android**, package name **`com.example.vn_weather`** → tải **`google-services.json`**.
3. ⚙️ **Project settings → Service accounts → Generate new private key** → tải **service account JSON** (khóa bí mật).

## B. Bật FCM cho APK (build qua CI)
`google-services.json` KHÔNG commit vào repo. Nạp qua GitHub Secret:
1. Mã hoá base64:
   - Linux/macOS: `base64 -w0 google-services.json`
   - Windows PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("google-services.json"))`
2. GitHub repo **Settings → Secrets and variables → Actions → New repository secret**:
   - Name: `GOOGLE_SERVICES_JSON`
   - Value: chuỗi base64 vừa tạo.
3. Vào tab **Actions → Build Android APK → Run workflow** (hoặc push commit bất kỳ).
   Workflow sẽ ghi `google-services.json` và build APK **có FCM**. Log hiện `✅ Đã ghi google-services.json`.

> Đã cấu hình sẵn: `minSdk=23`, quyền `POST_NOTIFICATIONS`, plugin Google Services áp **có điều kiện**
> (chỉ khi có file) nên khi CHƯA thêm secret, CI vẫn build APK bình thường (không FCM).

## C. Bật gửi push phía server (trên VM)
`firebase-admin` đã có trong `package.json`. Chỉ cần đưa service account lên VM (KHÔNG commit):
```bash
mkdir -p ~/thoitiet/secrets
# dán nội dung service account JSON vào file này:
nano ~/thoitiet/secrets/firebase-sa.json
```
Sửa `~/thoitiet/server/.env`:
```
FCM_SERVICE_ACCOUNT=/app/secrets/firebase-sa.json
FCM_TOPIC=weather-warnings
```
Mount secret vào container — thêm vào `docker-compose.yml` service `weather-server`:
```yaml
    volumes:
      - ./secrets:/app/secrets:ro
```
Rồi build lại:
```bash
cd ~/thoitiet && git pull && docker compose up -d --build
docker compose logs weather-server | grep FCM   # thấy "[FCM] Đã khởi tạo" là OK
```

## D. Kiểm thử
- **Gửi thử tay:** Firebase Console → **Messaging → New campaign / Send test message** → gửi tới topic `weather-warnings`.
- **Tự động:** khi NCHMF ra bản tin cảnh báo mới, server log `[FCM] Đã đẩy: ...` và điện thoại nhận thông báo.

## Bảo mật
- KHÔNG commit `google-services.json` hay `firebase-sa.json` (đã có trong `.gitignore`).
- `google-services.json` là cấu hình client (đi kèm trong APK) — dùng GitHub Secret cho gọn.
- `firebase-sa.json` là **khóa bí mật** — chỉ để trên VM, quyền đọc hạn chế.

## iOS (sau)
Cần thêm APNs Auth Key trong Firebase + `GoogleService-Info.plist`. Làm sau khi Android chạy ổn.
