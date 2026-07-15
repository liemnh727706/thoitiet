// Bảng mã thời tiết WMO (WW code) -> mô tả tiếng Việt + khóa icon.
// icon key khớp với bộ icon dùng ở Flutter app (weather_icons.dart).
// Tham khảo cách phân loại của breezy-weather (open-source).

const MAP = {
  0: { text: 'Trời quang', icon: 'clear' },
  1: { text: 'Ít mây', icon: 'mostly_clear' },
  2: { text: 'Mây rải rác', icon: 'partly_cloudy' },
  3: { text: 'Nhiều mây', icon: 'cloudy' },
  45: { text: 'Sương mù', icon: 'fog' },
  48: { text: 'Sương mù đóng băng', icon: 'fog' },
  51: { text: 'Mưa phùn nhẹ', icon: 'drizzle' },
  53: { text: 'Mưa phùn', icon: 'drizzle' },
  55: { text: 'Mưa phùn dày', icon: 'drizzle' },
  56: { text: 'Mưa phùn băng giá', icon: 'sleet' },
  57: { text: 'Mưa phùn băng giá dày', icon: 'sleet' },
  61: { text: 'Mưa nhỏ', icon: 'rain' },
  63: { text: 'Mưa vừa', icon: 'rain' },
  65: { text: 'Mưa to', icon: 'heavy_rain' },
  66: { text: 'Mưa băng giá nhẹ', icon: 'sleet' },
  67: { text: 'Mưa băng giá', icon: 'sleet' },
  71: { text: 'Tuyết rơi nhẹ', icon: 'snow' },
  73: { text: 'Tuyết rơi', icon: 'snow' },
  75: { text: 'Tuyết rơi dày', icon: 'snow' },
  77: { text: 'Hạt tuyết', icon: 'snow' },
  80: { text: 'Mưa rào nhẹ', icon: 'showers' },
  81: { text: 'Mưa rào', icon: 'showers' },
  82: { text: 'Mưa rào dữ dội', icon: 'heavy_rain' },
  85: { text: 'Mưa tuyết nhẹ', icon: 'snow' },
  86: { text: 'Mưa tuyết dày', icon: 'snow' },
  95: { text: 'Dông', icon: 'thunderstorm' },
  96: { text: 'Dông kèm mưa đá nhẹ', icon: 'thunderstorm' },
  99: { text: 'Dông kèm mưa đá', icon: 'thunderstorm' },
};

export function describeWeather(code) {
  return MAP[code] || { text: 'Không xác định', icon: 'cloudy' };
}

// Hướng gió từ độ (0-360) -> nhãn tiếng Việt (16 hướng)
const DIRS = [
  'Bắc', 'B-ĐB', 'Đông Bắc', 'ĐB-Đ', 'Đông', 'Đ-ĐN', 'Đông Nam', 'ĐN-N',
  'Nam', 'N-TN', 'Tây Nam', 'TN-T', 'Tây', 'T-TB', 'Tây Bắc', 'TB-B',
];

export function windDirection(deg) {
  if (deg == null) return '';
  const idx = Math.round(deg / 22.5) % 16;
  return DIRS[idx];
}

// Đổi tốc độ gió (km/h) -> cấp gió Beaufort (dùng ở VN cho bão/gió mạnh)
export function beaufort(kmh) {
  if (kmh == null) return null;
  const table = [1, 5, 11, 19, 28, 38, 49, 61, 74, 88, 102, 117];
  let level = 12;
  for (let i = 0; i < table.length; i++) {
    if (kmh < table[i]) { level = i; break; }
  }
  return level;
}
