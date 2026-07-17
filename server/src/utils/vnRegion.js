// Xác định vùng địa lý Việt Nam từ toạ độ GPS + so khớp vùng trong text bản tin.
// Dùng để lọc cảnh báo NCHMF theo vị trí người dùng.

// Các vùng dự báo NCHMF hay dùng
export const REGIONS = {
  BAC_BO: 'Bắc Bộ',
  BAC_TRUNG_BO: 'Bắc Trung Bộ',
  TRUNG_TRUNG_BO: 'Trung Trung Bộ',
  NAM_TRUNG_BO: 'Nam Trung Bộ',
  TAY_NGUYEN: 'Tây Nguyên',
  NAM_BO: 'Nam Bộ',
};

// Xác định vùng từ lat/lon (xấp xỉ theo vĩ độ; Tây Nguyên tách theo kinh độ).
// VN dài ~8.5–23.5°N. Ngoài khoảng này coi như ngoài VN -> null.
export function resolveRegion(lat, lon) {
  if (lat == null || lat < 8 || lat > 24) return null;
  if (lat >= 20.0) return { code: 'BAC_BO', name: REGIONS.BAC_BO };
  if (lat >= 18.0) return { code: 'BAC_TRUNG_BO', name: REGIONS.BAC_TRUNG_BO };
  if (lat >= 15.5) return { code: 'TRUNG_TRUNG_BO', name: REGIONS.TRUNG_TRUNG_BO };
  if (lat >= 11.5) {
    // Tây Nguyên: nội địa, kinh độ thấp (< ~108.6) và vĩ độ 11.5–15.5
    if (lon != null && lon < 108.6) return { code: 'TAY_NGUYEN', name: REGIONS.TAY_NGUYEN };
    return { code: 'NAM_TRUNG_BO', name: REGIONS.NAM_TRUNG_BO };
  }
  return { code: 'NAM_BO', name: REGIONS.NAM_BO };
}

// Từ khoá khiến 1 cảnh báo được coi là LIÊN QUAN tới người dùng ở vùng đó.
const RELEVANT_KEYWORDS = {
  BAC_BO: ['Bắc Bộ'],
  BAC_TRUNG_BO: ['Bắc Trung Bộ', 'Trung Bộ'],
  TRUNG_TRUNG_BO: ['Trung Trung Bộ', 'Trung Bộ'],
  NAM_TRUNG_BO: ['Nam Trung Bộ', 'Trung Bộ'],
  TAY_NGUYEN: ['Tây Nguyên'],
  NAM_BO: ['Nam Bộ'],
};

const NATIONAL_KEYWORDS = ['cả nước', 'toàn quốc', 'trên phạm vi cả nước'];

// Bảng tỉnh -> vùng (để suy ra vùng khi bản tin chỉ nêu tên tỉnh, vd lũ/mặn).
const PROVINCE_REGION = {
  BAC_BO: ['Hà Nội', 'Hải Phòng', 'Quảng Ninh', 'Lào Cai', 'Yên Bái', 'Điện Biên',
    'Lai Châu', 'Sơn La', 'Hòa Bình', 'Hà Giang', 'Cao Bằng', 'Bắc Kạn', 'Lạng Sơn',
    'Tuyên Quang', 'Thái Nguyên', 'Phú Thọ', 'Bắc Giang', 'Bắc Ninh', 'Vĩnh Phúc',
    'Hưng Yên', 'Hải Dương', 'Thái Bình', 'Hà Nam', 'Nam Định', 'Ninh Bình'],
  BAC_TRUNG_BO: ['Thanh Hóa', 'Nghệ An', 'Hà Tĩnh', 'Quảng Bình', 'Quảng Trị', 'Huế'],
  TRUNG_TRUNG_BO: ['Đà Nẵng', 'Quảng Nam', 'Quảng Ngãi', 'Bình Định'],
  NAM_TRUNG_BO: ['Phú Yên', 'Khánh Hòa', 'Ninh Thuận', 'Bình Thuận'],
  TAY_NGUYEN: ['Kon Tum', 'Gia Lai', 'Đắk Lắk', 'Đắk Nông', 'Lâm Đồng'],
  NAM_BO: ['Hồ Chí Minh', 'Bà Rịa', 'Vũng Tàu', 'Đồng Nai', 'Bình Dương', 'Bình Phước',
    'Tây Ninh', 'Long An', 'Tiền Giang', 'Bến Tre', 'Trà Vinh', 'Vĩnh Long', 'Đồng Tháp',
    'An Giang', 'Kiên Giang', 'Cần Thơ', 'Hậu Giang', 'Sóc Trăng', 'Bạc Liêu', 'Cà Mau'],
};

// Mã vùng của 1 tỉnh (theo tên). Trả null nếu không khớp.
export function provinceRegion(name) {
  const t = (name || '').normalize('NFC');
  for (const [code, provinces] of Object.entries(PROVINCE_REGION)) {
    if (provinces.some((p) => t.includes(p))) return code;
  }
  return null;
}

// Phát hiện các vùng được nhắc trong text (theo tên vùng HOẶC tên tỉnh).
export function regionsInText(text) {
  const t = (text || '').normalize('NFC');
  const found = new Set();
  for (const [code, name] of Object.entries(REGIONS)) {
    if (t.includes(name)) found.add(code);
  }
  for (const [code, provinces] of Object.entries(PROVINCE_REGION)) {
    if (provinces.some((p) => t.includes(p))) found.add(code);
  }
  return [...found];
}

// Cảnh báo có liên quan tới vùng người dùng không?
//  - Bão/ATNĐ: luôn liên quan (ảnh hưởng biển & ven bờ diện rộng).
//  - Có từ khoá "cả nước"/"toàn quốc": liên quan tất cả.
//  - Text nhắc đúng vùng người dùng (hoặc "Trung Bộ" cho các vùng Trung): liên quan.
//  - Không phát hiện được vùng nào trong text: mặc định HIỂN THỊ (không giấu tin chính thức).
export function isRelevant(userRegionCode, warning) {
  if (warning.kind === 'storm') return true;
  // Xâm nhập mặn: chỉ liên quan ĐBSCL (Nam Bộ); chưa biết vị trí -> vẫn hiện.
  if (warning.kind === 'salinity') {
    return !userRegionCode || userRegionCode === 'NAM_BO';
  }
  const text = `${warning.title || ''} ${warning.summary || ''}`.normalize('NFC');
  if (NATIONAL_KEYWORDS.some((k) => text.includes(k))) return true;
  const detected = regionsInText(text);
  if (detected.length === 0) return true; // không rõ vùng -> vẫn hiển thị
  if (!userRegionCode) return true;        // không biết vị trí -> hiển thị hết
  const keywords = RELEVANT_KEYWORDS[userRegionCode] || [];
  return keywords.some((k) => text.includes(k));
}
