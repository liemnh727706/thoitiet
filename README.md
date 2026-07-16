# VN Weather — MVP

App thời tiết cho người dùng Việt Nam (Android/iOS) với kiến trúc **backend aggregator + Flutter app**.

Giai đoạn MVP: dữ liệu real-time từ **Open-Meteo** (mô hình ECMWF/GFS/ICON, miễn phí, không cần API key). Các giai đoạn sau bổ sung NCHMF (bão, ATNĐ, nắng nóng, không khí lạnh), radar mưa, xâm nhập mặn (SIWRR/MRC).

## Kiến trúc
```
Flutter app  ──1 request──►  Node backend (aggregator)  ──►  Open-Meteo
 (GPS, UI 3 tầng)              (chuẩn hóa, cache, sinh cảnh báo)
```
App chỉ gọi **1 API duy nhất** của backend → nhanh, nhẹ, giấu được API key, dễ thêm nguồn mới.

## Thành phần
| Thư mục | Mô tả | Trạng thái |
|---|---|---|
| `server/` | Node + Express, gọi Open-Meteo, cache TTL, sinh cảnh báo theo ngưỡng, geocoding | ✅ chạy & test được |
| `app/`    | Flutter app, UI 3 tầng (cảnh báo / hiện tại / dự báo), GPS, tìm địa điểm | ✅ code đầy đủ (cần cài Flutter) |

## Chạy nhanh

**1. Backend**
```bash
cd server
npm install
cp .env.example .env
npm start          # http://localhost:4000
```
Kiểm tra:
```bash
curl "http://localhost:4000/api/weather?lat=10.76&lon=106.68&place=TP.HCM"
```

**2. App** — xem [app/README.md](app/README.md).

## Endpoint backend
- `GET /api/weather?lat=&lon=&place=` — thời tiết 3 tầng + cảnh báo NCHMF **lọc theo vùng GPS**
- `GET /api/warnings` — cảnh báo chính thức NCHMF toàn quốc (kèm vùng ảnh hưởng)
- `GET /api/radar` — frame radar mưa RainViewer (tile cho bản đồ)
- `GET /api/storm` — vị trí + đường đi + cấp gió bão/ATNĐ (từ bản tin NCHMF)
- `GET /api/geocode?q=` — tìm địa danh

## Lộ trình
1. ✅ **MVP** — Open-Meteo, UI 3 tầng, GPS + tìm kiếm.
2. ✅ **Crawler NCHMF** (bão/ATNĐ, nắng nóng, không khí lạnh) ghép vào cảnh báo chính thức.
   Push **FCM** đã sẵn code phía server (inert) — kích hoạt theo [deploy/FCM_SETUP.md](deploy/FCM_SETUP.md).
3. ✅ **Lọc cảnh báo theo vùng GPS** + **bản đồ radar mưa RainViewer** + **vị trí/đường đi bão** (màn hình `RadarScreen`, `flutter_map`).
4. ⏭ Bão **JMA/JTWC** (đường đi dự báo nhiều điểm) — hiện lấy vị trí tâm từ NCHMF.
5. ⏭ **Xâm nhập mặn** (SIWRR/MRC) + ngập lụt.
