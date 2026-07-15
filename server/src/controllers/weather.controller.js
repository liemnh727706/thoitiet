import { fetchForecast, geocode } from '../services/openMeteo.service.js';
import { getCache, setCache } from '../services/cache.service.js';
import { aggregate } from '../utils/aggregate.js';

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
    setCache(key, result);
    res.json({ ...result, cached: false });
  } catch (err) {
    console.error('[getWeather]', err.message);
    res.status(502).json({ error: 'Không lấy được dữ liệu thời tiết', detail: err.message });
  }
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
