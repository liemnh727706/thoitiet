// Lấy đường đi dự báo bão từ JMA bosai (cơ quan chính thức Tây Bắc TBD, JSON công khai).
//   targetTc.json           -> danh sách bão đang hoạt động
//   {id}/forecast.json      -> track (hiện tại + các mốc dự báo) + đường đã đi (preTyphoon)
//   {id}/specifications.json-> phân loại (TD/TS/TY) + gió cực đại (kt) mỗi mốc
import { getCache, setCache } from './cache.service.js';

const UA = { 'User-Agent': 'Mozilla/5.0 (compatible; VNWeatherBot/1.0)' };
const BASE = 'https://www.jma.go.jp/bosai/typhoon/data';
const CACHE_KEY = 'jma:storms';
const CACHE_TTL = 1800; // 30 phút

// Phân loại JMA -> nhãn tiếng Việt
const CATEGORY = {
  TD: 'Áp thấp nhiệt đới',
  TS: 'Bão nhiệt đới',
  STS: 'Bão nhiệt đới mạnh',
  TY: 'Bão',
  L: 'Vùng áp thấp',
};

async function getJson(url) {
  const res = await fetch(url, { headers: UA, signal: AbortSignal.timeout(12_000) });
  if (!res.ok) throw new Error(`JMA ${res.status} @ ${url}`);
  return res.json();
}

function partsWithCenter(forecast) {
  return forecast.filter((p) => Array.isArray(p.center) && p.center.length === 2);
}

async function fetchStorm(id) {
  const [forecast, specs] = await Promise.all([
    getJson(`${BASE}/${id}/forecast.json`),
    getJson(`${BASE}/${id}/specifications.json`).catch(() => []),
  ]);

  const title = forecast.find((p) => p.part === 'title') || {};
  const name = title.typhoonName?.en || null;

  // map advancedHours -> {category, windKt} từ specifications
  const specByHour = {};
  for (const p of specs) {
    if (p.part === 'title') continue;
    const h = p.advancedHours || 0;
    specByHour[h] = {
      category: p.category?.en || null,
      windKt: p.maximumWind?.sustained?.kt ? Number(p.maximumWind.sustained.kt) : null,
    };
  }

  const centers = partsWithCenter(forecast);
  if (!centers.length) return null;

  const track = centers.map((p) => {
    const h = p.advancedHours || 0;
    const spec = specByHour[h] || {};
    return {
      lat: p.center[0],
      lon: p.center[1],
      advancedHours: h,
      forecast: h > 0,
      validtime: p.validtime?.UTC || null,
      category: spec.category || null,
      windKt: spec.windKt ?? null,
    };
  });

  // đường đã đi (preTyphoon) từ part Analysis
  const analysis = centers.find((p) => (p.advancedHours || 0) === 0);
  const past = (analysis?.track?.preTyphoon || []).map((pt) => ({ lat: pt[0], lon: pt[1] }));

  const cur = specByHour[0] || {};
  const catCode = cur.category || 'TD';

  return {
    source: 'JMA',
    id,
    name,
    category: CATEGORY[catCode] || catCode,
    categoryCode: catCode,
    intensity: cur.windKt ? `${cur.windKt} kt` : null,
    center: { lat: track[0].lat, lon: track[0].lon },
    track,
    past,
    issued: title.issue?.UTC || null,
    sourceUrl: `https://www.jma.go.jp/bosai/en/typhoon/`,
  };
}

export async function fetchJmaStorms() {
  const list = await getJson(`${BASE}/targetTc.json`).catch(() => []);
  const ids = (list || []).map((t) => t.tropicalCyclone).filter(Boolean);
  const results = await Promise.allSettled(ids.map((id) => fetchStorm(id)));
  return results
    .filter((r) => r.status === 'fulfilled' && r.value)
    .map((r) => r.value);
}

// Cache 30' (JMA cập nhật vài giờ/lần)
export async function getCachedJmaStorms() {
  const cached = getCache(CACHE_KEY);
  if (cached) return cached;
  const storms = await fetchJmaStorms();
  setCache(CACHE_KEY, storms, CACHE_TTL);
  return storms;
}
