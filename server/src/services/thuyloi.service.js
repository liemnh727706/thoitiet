// Nguồn Cục Thủy lợi VN (GeoServer WFS công khai, không cần key) — dùng cho
// XÂM NHẬP MẶN (115+ trạm đo nội đồng ĐBSCL) và NGẬP ÚNG (bản tin tuần theo tỉnh).
// Nguồn này do repo dbscl-gis của người dùng kiểm chứng.
//   Base: https://gs.vbeta.net/geoserver/dubaonguonnuoc/wfs
//   - tramdomnnoidongscl : trạm đo mặn (mnhientai = độ mặn g/l, populated mùa khô 12-5)
//   - bantin_bandongapung: bản tin ngập/hạn theo tỉnh (dientichngap = diện tích ngập ha)
import { getCache, setCache } from './cache.service.js';
import { provinceRegion } from '../utils/vnRegion.js';

const WFS = process.env.THUYLOI_WFS_URL || 'https://gs.vbeta.net/geoserver/dubaonguonnuoc/wfs';
const CACHE_KEY = 'thuyloi:data';
const CACHE_TTL = 7200; // 2 giờ (cập nhật theo ngày/tuần)

const num = (v) => {
  if (v == null) return null;
  const n = Number(String(v).replace(',', '.'));
  return isFinite(n) ? n : null;
};

async function wfs(layer, extra = '') {
  const url = `${WFS}?service=WFS&version=2.0.0&request=GetFeature&typeNames=${layer}` +
    `&outputFormat=application/json&srsName=EPSG:4326${extra}`;
  const res = await fetch(url, { headers: { accept: 'application/json' }, signal: AbortSignal.timeout(15000) });
  if (!res.ok) throw new Error(`geoserver ${res.status}`);
  return res.json();
}

// Trạm đo mặn ĐBSCL -> [{name, ma, lat, lon, salinity_gl, subregion, time}]
function parseSalinity(fc) {
  const out = [];
  for (const f of (fc.features || [])) {
    const p = f.properties || {};
    const c = f.geometry && f.geometry.coordinates;
    const lon = num(p.x) ?? (c ? num(c[0]) : null);
    const lat = num(p.y) ?? (c ? num(c[1]) : null);
    if (lon == null || lat == null) continue;
    if (!(lon > 104 && lon < 107.6 && lat > 8 && lat < 11.6)) continue; // khung ĐBSCL
    out.push({
      name: p.tram || null,
      code: p.ma || null,
      lat, lon,
      salinity_gl: num(p.mnhientai),
      subregion: p.tieuvung || null,
      time: p.thoigian || null,
    });
  }
  return out;
}

// Bản tin ngập/hạn theo tỉnh -> [{province, region, floodedArea, droughtArea, period, from, to}]
function parseFlood(fc) {
  const out = [];
  for (const f of (fc.features || [])) {
    const p = f.properties || {};
    if (!p.name) continue;
    out.push({
      province: p.name,
      region: provinceRegion(p.name),
      floodedArea: num(p.dientichngap),   // ha
      droughtArea: num(p.dientichhan),    // ha
      floodRisk: p.nguycongap || null,
      period: p.makybaocao || null,
      from: p.tungay || null,
      to: p.denngay || null,
    });
  }
  return out;
}

export async function fetchThuyloi() {
  const [sal, flood] = await Promise.allSettled([
    wfs('dubaonguonnuoc:tramdomnnoidongscl'),
    wfs('dubaonguonnuoc:bantin_bandongapung',
      '&propertyName=name,dientichngap,dientichhan,nguycongap,nguycohan,makybaocao,tungay,denngay'),
  ]);
  const salinityStations = sal.status === 'fulfilled' ? parseSalinity(sal.value) : [];
  const floodProvinces = flood.status === 'fulfilled' ? parseFlood(flood.value) : [];
  return { salinityStations, floodProvinces, fetchedAt: new Date().toISOString() };
}

// Đọc cache không chặn (dùng khi ghép vào /api/weather)
export function peekThuyloi() {
  return getCache(CACHE_KEY) || { salinityStations: [], floodProvinces: [], fetchedAt: null };
}

export async function getCachedThuyloi() {
  const c = getCache(CACHE_KEY);
  if (c) return c;
  const data = await fetchThuyloi();
  setCache(CACHE_KEY, data, CACHE_TTL);
  return data;
}

export function startThuyloiPoll() {
  const tick = async () => {
    try {
      const data = await fetchThuyloi();
      setCache(CACHE_KEY, data, CACHE_TTL);
      const measured = data.salinityStations.filter((s) => s.salinity_gl != null).length;
      const flooded = data.floodProvinces.filter((p) => (p.floodedArea || 0) > 0).length;
      console.log(`[Thủy lợi] ${data.salinityStations.length} trạm mặn (${measured} có số liệu), ${flooded} tỉnh có diện tích ngập`);
    } catch (e) {
      console.error('[Thủy lợi] lỗi:', e.message);
    }
  };
  tick();
  const timer = setInterval(tick, CACHE_TTL * 1000);
  timer.unref?.();
  return timer;
}

// -------- Helper truy vấn theo vị trí --------
function haversineKm(a, b, c, d) {
  const R = 6371, r = Math.PI / 180;
  const dLat = (c - a) * r, dLon = (d - b) * r;
  const s = Math.sin(dLat / 2) ** 2 + Math.cos(a * r) * Math.cos(c * r) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(s));
}

export function salinityLevel(gl) {
  if (gl == null) return null;
  if (gl < 0.5) return 'Ngọt';
  if (gl < 1) return 'Nhẹ';
  if (gl < 4) return 'Trung bình';
  if (gl < 10) return 'Cao';
  return 'Rất cao';
}

// Trạm mặn gần nhất (trong bán kính ~60km) + bản tin ngập theo vùng người dùng.
export function hydroFor(lat, lon, regionCode) {
  const data = peekThuyloi();
  let nearest = null;
  let best = Infinity;
  for (const s of data.salinityStations) {
    const d = haversineKm(lat, lon, s.lat, s.lon);
    if (d < best) { best = d; nearest = s; }
  }
  const salinity = (nearest && best <= 60)
    ? { ...nearest, distanceKm: Math.round(best * 10) / 10, level: salinityLevel(nearest.salinity_gl) }
    : null;

  // tỉnh đang có diện tích ngập trong vùng người dùng
  const flood = data.floodProvinces
    .filter((p) => (p.floodedArea || 0) > 0 && (!regionCode || p.region === regionCode))
    .sort((a, b) => (b.floodedArea || 0) - (a.floodedArea || 0))
    .slice(0, 5);

  if (!salinity && !flood.length) return null;
  return { salinity, flood, source: 'Cục Thủy lợi VN', updatedAt: data.fetchedAt };
}
