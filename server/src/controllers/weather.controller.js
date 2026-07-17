import { fetchForecast, geocode } from '../services/openMeteo.service.js';
import { getCache, setCache } from '../services/cache.service.js';
import { getCachedWarnings, peekWarnings } from '../services/nchmf.service.js';
import { getRadar } from '../services/radar.service.js';
import { getCachedJmaStorms } from '../services/jma.service.js';
import { sendTest } from '../services/push.service.js';
import { resolveRegion, isRelevant } from '../utils/vnRegion.js';
import { hydroFor } from '../services/thuyloi.service.js';
import { aggregate } from '../utils/aggregate.js';

// Chuẩn hoá bão NCHMF về cùng shape với JMA (cho /api/storms)
function nchmfToStorm(w) {
  const s = w.storm;
  return {
    source: 'NCHMF',
    id: null,
    name: w.title,
    category: 'Bão/ATNĐ (NCHMF)',
    intensity: s.intensity ? `cấp ${s.intensity}` : null,
    movement: s.movement || null,
    center: s.center,
    track: (s.track || []).map((p, i) => ({
      lat: p.lat, lon: p.lon, advancedHours: null, forecast: i > 0,
    })),
    past: [],
    issued: w.issuedAt,
    sourceUrl: w.sourceUrl,
  };
}

// Chuyển cảnh báo NCHMF -> đúng shape alert của app (ưu tiên lên đầu tier 1)
function toAlert(w) {
  return {
    kind: w.kind,
    severity: w.severity,
    title: w.title,
    message: w.summary || '',
    source: w.source,
    sourceUrl: w.sourceUrl,
    issuedAt: w.issuedAt,
    regions: w.regions || [],
    official: true,
  };
}

// GET /api/weather?lat=..&lon=..&place=..
export async function getWeather(req, res) {
  const lat = parseFloat(req.query.lat);
  const lon = parseFloat(req.query.lon);
  if (Number.isNaN(lat) || Number.isNaN(lon)) {
    return res.status(400).json({ error: 'Thiếu hoặc sai tham số lat/lon' });
  }

  const key = `wx:${lat.toFixed(3)}:${lon.toFixed(3)}`;
  const cached = getCache(key);
  if (cached) {
    return res.json({ ...cached, cached: true });
  }

  try {
    const raw = await fetchForecast(lat, lon);
    const place = req.query.place
      ? { name: req.query.place }
      : null;
    const result = aggregate(raw, place);

    // Ghép cảnh báo chính thức NCHMF, LỌC THEO VÙNG GPS của người dùng
    const region = resolveRegion(lat, lon);
    const official = peekWarnings()
      .active.filter((w) => isRelevant(region?.code, w))
      .map(toAlert);

    // Thủy văn ĐBSCL (mặn theo trạm gần nhất + ngập theo tỉnh/vùng)
    const hydro = hydroFor(lat, lon, region?.code);
    result.hydro = hydro;

    // Mặn vượt ngưỡng cây trồng (>=4 g/l) -> thêm cảnh báo chính thức
    const sal = hydro?.salinity;
    if (sal && sal.salinity_gl != null && sal.salinity_gl >= 4) {
      official.unshift({
        kind: 'salinity',
        severity: sal.salinity_gl >= 10 ? 'danger' : 'warning',
        title: `Xâm nhập mặn tại ${sal.name || 'trạm gần bạn'}`,
        message: `Độ mặn ${sal.salinity_gl} g/l (${sal.level}) — vượt ngưỡng cây trồng 4 g/l.`,
        source: 'Cục Thủy lợi VN',
        sourceUrl: 'https://thuyloivietnam.gov.vn/dwh',
        official: true,
        regions: region ? [region.code] : [],
      });
    }

    result.alerts = [...official, ...result.alerts];
    result.region = region;

    setCache(key, result);
    res.json({ ...result, cached: false });
  } catch (err) {
    console.error('[getWeather]', err.message);
    res.status(502).json({ error: 'Không lấy được dữ liệu thời tiết', detail: err.message });
  }
}

// GET /api/warnings — danh sách cảnh báo chính thức NCHMF (toàn quốc)
export async function getWarnings(req, res) {
  try {
    const data = await getCachedWarnings();
    res.json(data);
  } catch (err) {
    console.error('[getWarnings]', err.message);
    res.status(502).json({ error: 'Không lấy được cảnh báo NCHMF', detail: err.message });
  }
}

// GET /api/radar — frame radar mưa (RainViewer) cho bản đồ
export async function getRadarFrames(req, res) {
  try {
    const data = await getRadar();
    res.json(data);
  } catch (err) {
    console.error('[getRadar]', err.message);
    res.status(502).json({ error: 'Không lấy được dữ liệu radar', detail: err.message });
  }
}

// GET /api/storm — vị trí + đường đi bão/ATNĐ đang hoạt động (null nếu không có)
export async function getStorm(req, res) {
  try {
    const { active } = await getCachedWarnings();
    const stormWarning = active.find((w) => w.kind === 'storm' && w.storm);
    if (!stormWarning) return res.json({ active: false, storm: null });
    res.json({
      active: true,
      title: stormWarning.title,
      severity: stormWarning.severity,
      issuedAt: stormWarning.issuedAt,
      sourceUrl: stormWarning.sourceUrl,
      ...stormWarning.storm, // center, track, intensity, movement
    });
  } catch (err) {
    console.error('[getStorm]', err.message);
    res.status(502).json({ error: 'Không lấy được dữ liệu bão', detail: err.message });
  }
}

// GET /api/storms — hợp nhất bão JMA (đường đi dự báo nhiều điểm) + NCHMF (vị trí VN)
export async function getStorms(req, res) {
  try {
    const [jma, warnings] = await Promise.all([
      getCachedJmaStorms().catch(() => []),
      getCachedWarnings().catch(() => ({ active: [] })),
    ]);
    const nchmf = warnings.active
      .filter((w) => w.kind === 'storm' && w.storm)
      .map(nchmfToStorm);
    res.json({ storms: [...jma, ...nchmf], fetchedAt: new Date().toISOString() });
  } catch (err) {
    console.error('[getStorms]', err.message);
    res.status(502).json({ error: 'Không lấy được dữ liệu bão', detail: err.message });
  }
}

// GET /api/push-test?key=... — gửi 1 push thử tới topic (chỉ khi FCM_TEST_TOKEN khớp)
export async function pushTest(req, res) {
  const token = process.env.FCM_TEST_TOKEN;
  if (!token) return res.status(404).json({ error: 'Đã tắt (chưa đặt FCM_TEST_TOKEN)' });
  if (req.query.key !== token) return res.status(403).json({ error: 'Sai key' });
  try {
    const id = await sendTest('🔔 Thử FCM', 'Thông báo thử từ máy chủ Thời tiết VN.');
    res.json({ ok: true, messageId: id });
  } catch (err) {
    console.error('[pushTest]', err.message);
    res.status(502).json({ error: err.message });
  }
}

// GET /api/hydro?lat=&lon= — thủy văn ĐBSCL (mặn trạm gần nhất + ngập theo vùng)
export async function getHydro(req, res) {
  const lat = parseFloat(req.query.lat);
  const lon = parseFloat(req.query.lon);
  if (Number.isNaN(lat) || Number.isNaN(lon)) {
    return res.status(400).json({ error: 'Thiếu lat/lon' });
  }
  const region = resolveRegion(lat, lon);
  res.json({ region, hydro: hydroFor(lat, lon, region?.code) });
}

// GET /api/geocode?q=..
export async function searchPlace(req, res) {
  const q = (req.query.q || '').trim();
  if (q.length < 2) {
    return res.status(400).json({ error: 'Từ khóa tìm kiếm quá ngắn' });
  }

  const key = `geo:${q.toLowerCase()}`;
  const cached = getCache(key);
  if (cached) return res.json(cached);

  try {
    const results = await geocode(q);
    setCache(key, results, 24 * 3600); // tên địa danh ít đổi -> cache 1 ngày
    res.json(results);
  } catch (err) {
    console.error('[searchPlace]', err.message);
    res.status(502).json({ error: 'Không tìm được địa danh', detail: err.message });
  }
}
