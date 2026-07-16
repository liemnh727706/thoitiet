// Lấy metadata radar mưa từ RainViewer (miễn phí, không cần key) + cache ngắn.
// Trả về danh sách frame (quá khứ + nowcast) kèm URL tile mẫu cho flutter_map.
import { getCache, setCache } from './cache.service.js';

const MAPS_URL = 'https://api.rainviewer.com/public/weather-maps.json';
const CACHE_KEY = 'radar:frames';
const CACHE_TTL = 120; // 2 phút (radar cập nhật ~10 phút, cache ngắn cho tươi)

// color=2 (bảng màu phổ biến), options 1_1 = làm mượt + hiển thị tuyết
const TILE_SIZE = 256;
const COLOR = 2;
const OPTIONS = '1_1';

function toFrame(host, f, kind) {
  return {
    time: f.time,                                   // epoch giây
    kind,                                           // 'past' | 'nowcast'
    url: `${host}${f.path}/${TILE_SIZE}/{z}/{x}/{y}/${COLOR}/${OPTIONS}.png`,
  };
}

export async function getRadar() {
  const cached = getCache(CACHE_KEY);
  if (cached) return cached;

  const res = await fetch(MAPS_URL, { signal: AbortSignal.timeout(10_000) });
  if (!res.ok) throw new Error(`RainViewer ${res.status}`);
  const data = await res.json();
  const host = data.host;

  const past = (data.radar?.past || []).map((f) => toFrame(host, f, 'past'));
  const nowcast = (data.radar?.nowcast || []).map((f) => toFrame(host, f, 'nowcast'));
  const frames = [...past, ...nowcast];

  const result = {
    generated: data.generated,
    host,
    frames,
    attribution: 'RainViewer',
  };
  setCache(CACHE_KEY, result, CACHE_TTL);
  return result;
}
