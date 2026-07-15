// Chuẩn hóa dữ liệu Open-Meteo về 1 schema thống nhất, chia 3 tầng:
//   tier1: alerts   (cảnh báo khẩn - lên đầu)
//   tier2: current  (thời tiết hiện tại)
//   tier3: hourly + daily (dự báo)
//
// Cảnh báo ở MVP được SINH TỪ NGƯỠNG (nắng nóng, rét, mưa lớn, gió mạnh).
// Bão/ATNĐ/xâm nhập mặn/ngập lụt thật sẽ lấy từ NCHMF/SIWRR ở giai đoạn sau.
import { describeWeather, windDirection, beaufort } from './weatherCodes.js';

// severity: 'danger' (đỏ) | 'warning' (cam) | 'watch' (vàng)
function buildAlerts({ current, daily }) {
  const alerts = [];
  const todayMax = daily.temperature_2m_max?.[0];
  const todayMin = daily.temperature_2m_min?.[0];
  const todayRain = daily.precipitation_sum?.[0];
  const gustMax = daily.wind_gusts_10m_max?.[0];
  const uvMax = daily.uv_index_max?.[0];

  // ---- Nắng nóng (ngưỡng tham khảo của NCHMF) ----
  if (todayMax != null) {
    if (todayMax >= 39) {
      alerts.push(mk('heat', 'danger', 'Nắng nóng đặc biệt gay gắt',
        `Nhiệt độ cao nhất tới ${round(todayMax)}°C. Hạn chế ra ngoài buổi trưa, uống đủ nước.`));
    } else if (todayMax >= 37) {
      alerts.push(mk('heat', 'warning', 'Nắng nóng gay gắt',
        `Nhiệt độ cao nhất khoảng ${round(todayMax)}°C.`));
    } else if (todayMax >= 35) {
      alerts.push(mk('heat', 'watch', 'Nắng nóng',
        `Nhiệt độ cao nhất khoảng ${round(todayMax)}°C.`));
    }
  }

  // ---- Rét / không khí lạnh (bối cảnh miền Bắc) ----
  if (todayMin != null) {
    if (todayMin <= 8) {
      alerts.push(mk('cold', 'danger', 'Rét hại',
        `Nhiệt độ thấp nhất còn ${round(todayMin)}°C. Giữ ấm, đề phòng băng giá vùng núi cao.`));
    } else if (todayMin <= 10) {
      alerts.push(mk('cold', 'warning', 'Rét đậm',
        `Nhiệt độ thấp nhất khoảng ${round(todayMin)}°C.`));
    } else if (todayMin <= 13) {
      alerts.push(mk('cold', 'watch', 'Trời rét',
        `Nhiệt độ thấp nhất khoảng ${round(todayMin)}°C.`));
    }
  }

  // ---- Mưa lớn ----
  if (todayRain != null) {
    if (todayRain >= 100) {
      alerts.push(mk('rain', 'danger', 'Mưa rất to',
        `Lượng mưa dự báo ~${round(todayRain)}mm/ngày. Đề phòng ngập úng, lũ quét.`));
    } else if (todayRain >= 50) {
      alerts.push(mk('rain', 'warning', 'Mưa to',
        `Lượng mưa dự báo ~${round(todayRain)}mm/ngày.`));
    }
  }

  // ---- Gió mạnh / giật ----
  if (gustMax != null && gustMax >= 62) {
    const lvl = beaufort(gustMax);
    alerts.push(mk('wind', gustMax >= 89 ? 'danger' : 'warning', 'Gió mạnh',
      `Gió giật mạnh cấp ${lvl} (~${round(gustMax)} km/h). Chú ý khi di chuyển ngoài trời.`));
  }

  // ---- UV cực cao ----
  if (uvMax != null && uvMax >= 11) {
    alerts.push(mk('uv', 'warning', 'Tia UV cực cao',
      `Chỉ số UV tối đa ${round(uvMax)}. Cần che chắn, chống nắng kỹ.`));
  }

  return alerts;
}

function mk(kind, severity, title, message) {
  return { kind, severity, title, message, source: 'Suy luận từ mô hình (Open-Meteo)' };
}

const round = (n) => (n == null ? null : Math.round(n));

export function aggregate(raw, place) {
  const c = raw.current || {};
  const cu = raw.current_units || {};
  const daily = raw.daily || {};
  const hourly = raw.hourly || {};

  const wx = describeWeather(c.weather_code);

  const current = {
    time: c.time,
    isDay: c.is_day === 1,
    temperature: round(c.temperature_2m),
    apparentTemperature: round(c.apparent_temperature),
    humidity: round(c.relative_humidity_2m),
    precipitation: c.precipitation,
    pressure: round(c.surface_pressure),
    weatherCode: c.weather_code,
    condition: wx.text,
    icon: wx.icon,
    wind: {
      speed: round(c.wind_speed_10m),
      gust: round(c.wind_gusts_10m),
      direction: windDirection(c.wind_direction_10m),
      directionDeg: c.wind_direction_10m,
      beaufort: beaufort(c.wind_speed_10m),
    },
    units: {
      temperature: cu.temperature_2m || '°C',
      wind: cu.wind_speed_10m || 'km/h',
      humidity: '%',
    },
  };

  // Dự báo theo giờ: chỉ lấy từ hiện tại tới 24h tới cho gọn
  const now = new Date(c.time);
  const hourlyList = [];
  const times = hourly.time || [];
  for (let i = 0; i < times.length && hourlyList.length < 24; i++) {
    if (new Date(times[i]) < now) continue;
    const w = describeWeather(hourly.weather_code?.[i]);
    hourlyList.push({
      time: times[i],
      temperature: round(hourly.temperature_2m?.[i]),
      humidity: round(hourly.relative_humidity_2m?.[i]),
      precipitationProbability: hourly.precipitation_probability?.[i],
      precipitation: hourly.precipitation?.[i],
      weatherCode: hourly.weather_code?.[i],
      icon: w.icon,
      condition: w.text,
    });
  }

  // Dự báo 7 ngày
  const dailyList = [];
  const dtimes = daily.time || [];
  for (let i = 0; i < dtimes.length; i++) {
    const w = describeWeather(daily.weather_code?.[i]);
    dailyList.push({
      date: dtimes[i],
      tempMax: round(daily.temperature_2m_max?.[i]),
      tempMin: round(daily.temperature_2m_min?.[i]),
      precipitationSum: daily.precipitation_sum?.[i],
      precipitationProbability: daily.precipitation_probability_max?.[i],
      windMax: round(daily.wind_speed_10m_max?.[i]),
      uvIndexMax: daily.uv_index_max?.[i],
      sunrise: daily.sunrise?.[i],
      sunset: daily.sunset?.[i],
      weatherCode: daily.weather_code?.[i],
      icon: w.icon,
      condition: w.text,
    });
  }

  const alerts = buildAlerts({ current: c, daily });

  return {
    place: place || null,
    coordinates: { latitude: raw.latitude, longitude: raw.longitude },
    timezone: raw.timezone,
    updatedAt: new Date().toISOString(),
    // 3 tầng thông tin
    alerts,        // tier 1
    current,       // tier 2
    hourly: hourlyList,  // tier 3
    daily: dailyList,    // tier 3
  };
}
