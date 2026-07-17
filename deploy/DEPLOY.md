# Deploy backend weather lên VM Oracle Cloud (chạy chung với app khác)

Backend weather rất nhẹ (Node stateless, không DB) nên **chạy chung VM với app khác thoải mái**.
Nguyên tắc: **không đụng app đang chạy** — dùng cổng riêng (4000), bind localhost, cho nginx proxy vào.

> Thay `<VM_PUBLIC_IP>` bằng IP thật của VM và `<domain>` bằng domain của bạn khi thao tác.

---

## Bước 0 — Nắm hiện trạng VM (chạy trên VM qua SSH)
```bash
ssh ubuntu@<VM_PUBLIC_IP>          # hoặc user bạn đang dùng
docker ps                          # xem app cũ chạy container nào, cổng nào
sudo ss -tlnp | grep -E ':(80|443|4000)'   # cổng nào đang bận
which nginx && nginx -v            # có nginx trên host không?
```
- Nếu app cũ đã có **nginx** (host hoặc container) đang giữ 80/443 → weather **dùng chung** nginx đó (Cách B bên dưới).
- Cổng **4000 phải trống** (nếu bận, đổi trong `docker-compose.yml` + `.env`).

## Bước 1 — Lấy code lên VM
```bash
cd ~ && git clone https://github.com/liemnh727706/thoitiet.git
cd thoitiet
cp server/.env.example server/.env      # sửa nếu cần (PORT, CACHE_TTL_SECONDS)
```

## Bước 2 — Chạy backend bằng Docker
```bash
docker compose up -d --build
docker compose ps
curl http://127.0.0.1:4000/health       # {"status":"ok",...} là OK
curl "http://127.0.0.1:4000/api/weather?lat=10.76&lon=106.68"
```
> Backend giờ chạy nền, tự khởi động lại khi reboot (`restart: unless-stopped`).

## Bước 3 — Cho nginx proxy vào (chọn 1 cách trong `deploy/nginx-weather.conf`)

**Cách A – Subdomain riêng** `weather.<domain>` (khuyến nghị nếu có domain):
```bash
sudo cp deploy/nginx-weather.conf /etc/nginx/sites-available/weather
# sửa server_name thành subdomain thật, rồi:
sudo ln -s /etc/nginx/sites-available/weather /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

**Cách B – Dùng chung domain app cũ, thêm path `/weather/`:**
Trước tiên xác định nginx app cũ chạy dạng nào:
```bash
docker ps        # có container nginx không? ghi lại TÊN container + network
```

- **B1 — nginx là tiến trình HOST** (`which nginx` có, không thấy container nginx):
  giữ nguyên `docker-compose.yml` (bind `127.0.0.1:4000`). Thêm vào `server{}` khối 443 của app cũ:
  ```nginx
  location /weather/ { proxy_pass http://127.0.0.1:4000/; proxy_set_header Host $host; }
  ```
  `sudo nginx -t && sudo systemctl reload nginx`

- **B2 — nginx là CONTAINER Docker** (phổ biến với compose): `127.0.0.1` trong container KHÔNG phải host,
  nên phải cho weather **vào chung network** rồi proxy theo tên container. Tìm network:
  ```bash
  docker inspect <nginx_container> --format '{{json .NetworkSettings.Networks}}'
  ```
  Sửa `docker-compose.yml` của weather: bỏ `ports`, thêm:
  ```yaml
      networks: [shared_net]
  networks:
    shared_net:
      external: true
      name: <ten_network_cua_app_cu>
  ```
  Trong nginx app cũ thêm: `location /weather/ { proxy_pass http://weather_server:4000/; proxy_set_header Host $host; }`
  rồi `docker exec <nginx_container> nginx -s reload`.

> Dấu `/` cuối trong `proxy_pass .../` sẽ cắt tiền tố `/weather` → backend nhận đúng `/api/...`.
> App gọi `https://<domain>/weather/api/...` (đặt `API_BASE=https://<domain>/weather`).

## Bước 4 — HTTPS (bắt buộc cho app production trên Play Store)
- **Có domain:** dùng Let's Encrypt:
  ```bash
  sudo apt install certbot python3-certbot-nginx
  sudo certbot --nginx -d weather.<domain>
  ```
- **Chỉ có IP, chưa có domain:** Let's Encrypt KHÔNG cấp cert cho IP trần. Cách nhanh & free:
  dùng hostname wildcard trỏ về IP qua **sslip.io** — hostname có dạng `<IP-thay-chấm-bằng-gạch>.sslip.io`
  (nó tự resolve về đúng IP), rồi chạy `sudo certbot --nginx -d <IP-dạng-gạch>.sslip.io`
  → có ngay HTTPS hợp lệ mà không cần mua domain.

## Bước 5 — ⚠️ MỞ CỔNG (lỗi hay gặp nhất trên Oracle — phải làm CẢ HAI nơi)
1. **Oracle Console** → Networking → VCN → Security List (hoặc NSG) của subnet → **Add Ingress Rule**: cho phép TCP 80 và 443 (source 0.0.0.0/0). *Không mở 4000 nếu chỉ dùng qua nginx.*
2. **Firewall trong VM** (Oracle Ubuntu image mặc định chặn bằng iptables):
   ```bash
   sudo iptables -I INPUT 5 -p tcp --dport 443 -j ACCEPT
   sudo iptables -I INPUT 5 -p tcp --dport 80 -j ACCEPT
   sudo netfilter-persistent save      # giữ qua reboot
   ```
   (nếu VM dùng firewalld: `sudo firewall-cmd --add-service=https --permanent && sudo firewall-cmd --reload`)

## Bước 6 — Trỏ app Flutter vào backend rồi build lại APK
Trong GitHub Actions build với biến môi trường, hoặc sửa mặc định ở `app/lib/config.dart`.
Cách gọn: build APK trỏ thẳng domain:
```bash
flutter build apk --release --dart-define=API_BASE=https://weather.<domain>
# hoặc Cách B:   --dart-define=API_BASE=https://<domain>/weather
```
> Khi đã có HTTPS, có thể bỏ `android:usesCleartextTraffic="true"` trong AndroidManifest cho an toàn hơn.

## Kiểm tra cuối
```bash
curl "https://weather.<domain>/api/weather?lat=10.76&lon=106.68"   # từ máy bất kỳ
```
Mở app trên điện thoại (khác WiFi/4G) → phải ra dữ liệu.

---

## Cập nhật code sau này
```bash
cd ~/thoitiet && git pull && docker compose up -d --build && docker restart cropguard_nginx
```

> ⚠️ **Vì sao phải `docker restart cropguard_nginx`?** nginx (chạy trong container B2)
> phân giải tên `weather_server` MỘT LẦN lúc khởi động và nhớ IP. Mỗi lần
> `docker compose up -d --build` tạo lại container weather_server với **IP mới**,
> nginx vẫn trỏ IP cũ → **502 Bad Gateway**. Restart nginx để nó phân giải lại IP hiện tại.
> (Cách triệt để: thêm `resolver 127.0.0.11 valid=30s;` + dùng biến trong `proxy_pass`
> để nginx phân giải mỗi request, khỏi cần restart.)
