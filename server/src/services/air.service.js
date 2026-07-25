// Chất lượng không khí từ Open-Meteo Air Quality API (miễn phí, không cần key).
// Trả US AQI (cùng chuẩn AirVisual/IQAir) + PM2.5/PM10... và mức + khuyến cáo.
// (AirVisual/IQAir cần API key riêng + giới hạn lượt; Open-Meteo cho cùng US AQI
//  miễn phí không giới hạn nên dùng làm nguồn chính.)
import { getCache, setCache } from './cache.service.js';

const AQ_API = 'https://air-quality-api.open-meteo.com/v1/air-quality';
const CURRENT = ['us_aqi', 'pm2_5', 'pm10', 'nitrogen_dioxide', 'ozone', 'sulphur_dioxide', 'carbon_monoxide'];

// Phân mức US AQI (chuẩn EPA/AirVisual)
function aqiLevel(aqi) {
  if (aqi == null) return null;
  if (aqi <= 50) return { label: 'Tốt', color: 'good', advice: 'Chất lượng không khí tốt, thoải mái hoạt động ngoài trời.' };
  if (aqi <= 100) return { label: 'Trung bình', color: 'moderate', advice: 'Chấp nhận được; nhóm nhạy cảm nên chú ý.' };
  if (aqi <= 150) return { label: 'Kém (nhạy cảm)', color: 'sensitive', advice: 'Nhóm nhạy cảm (hô hấp, tim mạch, trẻ em, người già) hạn chế ra ngoài lâu.' };
  if (aqi <= 200) return { label: 'Xấu', color: 'unhealthy', advice: 'Mọi người nên giảm hoạt động ngoài trời; đeo khẩu trang lọc bụi mịn.' };
  if (aqi <= 300) return { label: 'Rất xấu', color: 'very_unhealthy', advice: 'Hạn chế ra ngoài; đóng cửa, dùng máy lọc không khí.' };
  return { label: 'Nguy hại', color: 'hazardous', advice: 'Tránh ra ngoài; ảnh hưởng sức khỏe nghiêm trọng.' };
}

export async function fetchAirQuality(lat, lon) {
  const key = `air:${lat.toFixed(2)}:${lon.toFixed(2)}`;
  const cached = getCache(key);
  if (cached) return cached;

  const u = new URL(AQ_API);
  u.searchParams.set('latitude', lat);
  u.searchParams.set('longitude', lon);
  u.searchParams.set('current', CURRENT.join(','));
  u.searchParams.set('timezone', 'auto');

  try {
    const res = await fetch(u, { signal: AbortSignal.timeout(9000) });
    if (!res.ok) return null;
    const j = await res.json();
    const c = j.current || {};
    const aqi = c.us_aqi ?? null;
    const level = aqiLevel(aqi);
    const result = {
      aqi,
      level: level?.label ?? null,
      color: level?.color ?? null,
      advice: level?.advice ?? null,
      pm25: c.pm2_5 ?? null,
      pm10: c.pm10 ?? null,
      no2: c.nitrogen_dioxide ?? null,
      o3: c.ozone ?? null,
      so2: c.sulphur_dioxide ?? null,
      time: c.time ?? null,
      source: 'Open-Meteo Air Quality (US AQI)',
    };
    setCache(key, result, 1800); // 30 phút
    return result;
  } catch {
    return null;
  }
}
