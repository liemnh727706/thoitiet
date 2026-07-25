// Reverse-geocode GPS -> đơn vị hành chính MỚI (34 tỉnh 2025) qua GeoServer WFS
// (point-in-polygon phía server, payload nhỏ). Nguồn: Cục Thủy lợi, lớp
// diaphantinh_2025 (trường tentinh = tên tỉnh mới). LƯU Ý: WFS 2.0 EPSG:4326
// dùng thứ tự trục lat/lon -> POINT(lat lon).
import { getCache, setCache } from './cache.service.js';

const WFS = process.env.THUYLOI_WFS_URL || 'https://gs.vbeta.net/geoserver/dubaonguonnuoc/wfs';
const CACHE_TTL = 86400; // 1 ngày (ranh giới hành chính gần như tĩnh)

export async function reverseProvince(lat, lon) {
  const key = `admin:${lat.toFixed(3)}:${lon.toFixed(3)}`;
  const cached = getCache(key);
  if (cached !== null && cached !== undefined) return cached;

  const cql = `INTERSECTS(geom, POINT(${lat} ${lon}))`; // lat lon (WFS2 axis order)
  const url = `${WFS}?service=WFS&version=2.0.0&request=GetFeature` +
    `&typeNames=dubaonguonnuoc:diaphantinh_2025&outputFormat=application/json` +
    `&propertyName=tentinh&CQL_FILTER=${encodeURIComponent(cql)}&count=1`;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(9000) });
    if (!res.ok) return null;
    const j = await res.json();
    const name = j.features?.[0]?.properties?.tentinh || null;
    const result = name ? { province: name } : null;
    setCache(key, result, CACHE_TTL);
    return result;
  } catch {
    return null;
  }
}
