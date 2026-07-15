// Cache đơn giản có TTL. Mặc định in-memory (không cần cài gì).
// Khi có REDIS_URL, có thể thay bằng Redis ở giai đoạn sau mà không đổi API.
import { config } from '../config.js';

const store = new Map(); // key -> { value, expiresAt }

export function getCache(key) {
  const hit = store.get(key);
  if (!hit) return null;
  if (Date.now() > hit.expiresAt) {
    store.delete(key);
    return null;
  }
  return hit.value;
}

export function setCache(key, value, ttlSeconds = config.cacheTtlSeconds) {
  store.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
}

// Dọn key hết hạn định kỳ để tránh phình bộ nhớ
setInterval(() => {
  const now = Date.now();
  for (const [k, v] of store.entries()) {
    if (now > v.expiresAt) store.delete(k);
  }
}, 60_000).unref();
