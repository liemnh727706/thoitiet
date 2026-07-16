// Gửi push notification qua Firebase Cloud Messaging (FCM).
//
// ⚠️ INERT cho tới khi bạn cấu hình Firebase. Chưa cấu hình thì chỉ log, KHÔNG lỗi,
// server vẫn chạy bình thường. Để bật:
//   1. Tạo project Firebase, bật Cloud Messaging.
//   2. Tải service account JSON, đặt đường dẫn vào biến môi trường:
//        FCM_SERVICE_ACCOUNT=/app/secrets/firebase-sa.json
//   3. Cài SDK trong server:   npm install firebase-admin
//   4. App Flutter subscribe topic "weather-warnings" (xem deploy/FCM_SETUP.md).
//
// Khi có cảnh báo ACTIVE mới từ NCHMF, poller gọi onNewWarnings(freshList).

let messaging = null;      // instance firebase-admin messaging (nếu bật)
let initTried = false;

const TOPIC = process.env.FCM_TOPIC || 'weather-warnings';

async function ensureInit() {
  if (initTried) return messaging;
  initTried = true;

  const saPath = process.env.FCM_SERVICE_ACCOUNT;
  if (!saPath) {
    console.log('[FCM] Chưa cấu hình (FCM_SERVICE_ACCOUNT trống) — bỏ qua push.');
    return null;
  }
  try {
    const admin = await import('firebase-admin'); // dynamic: không cần cài nếu không dùng
    const { readFile } = await import('node:fs/promises');
    const sa = JSON.parse(await readFile(saPath, 'utf8'));
    admin.default.initializeApp({ credential: admin.default.credential.cert(sa) });
    messaging = admin.default.messaging();
    console.log('[FCM] Đã khởi tạo, sẽ đẩy tới topic:', TOPIC);
  } catch (e) {
    console.error('[FCM] Khởi tạo thất bại (đã cài firebase-admin chưa?):', e.message);
    messaging = null;
  }
  return messaging;
}

// Khởi tạo sớm khi server chạy để xác nhận cấu hình ngay (không đợi cảnh báo).
export async function initPush() {
  await ensureInit();
}

// Gửi 1 push thử tới topic (dùng cho endpoint test). Ném lỗi nếu chưa cấu hình.
export async function sendTest(title, body) {
  const m = await ensureInit();
  if (!m) throw new Error('FCM chưa cấu hình (FCM_SERVICE_ACCOUNT trống hoặc thiếu firebase-admin)');
  return m.send({
    topic: TOPIC,
    notification: { title, body },
    android: { priority: 'high' },
  });
}

// Được poller gọi khi có cảnh báo NCHMF mới còn hiệu lực.
export async function onNewWarnings(freshWarnings) {
  const m = await ensureInit();
  if (!m) {
    console.log(`[FCM] (inert) ${freshWarnings.length} cảnh báo mới — sẽ đẩy khi cấu hình Firebase.`);
    return;
  }
  for (const w of freshWarnings) {
    try {
      await m.send({
        topic: TOPIC,
        notification: {
          title: `⚠️ ${w.title}`,
          body: (w.summary || '').slice(0, 160),
        },
        data: {
          kind: w.kind,
          severity: w.severity,
          sourceUrl: w.sourceUrl || '',
          issuedAt: w.issuedAt || '',
        },
        android: { priority: 'high' },
      });
      console.log('[FCM] Đã đẩy:', w.title);
    } catch (e) {
      console.error('[FCM] Lỗi đẩy:', w.title, e.message);
    }
  }
}
