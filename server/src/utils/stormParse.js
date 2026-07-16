// Trích vị trí tâm bão/ATNĐ + đường đi dự báo + cấp gió từ nội dung bản tin NCHMF.
// Bản tin liệt kê toạ độ dạng: "X,Y độ Vĩ Bắc; Z,W độ Kinh Đông" (dấu phẩy = thập phân).

const num = (s) => parseFloat(String(s).replace(',', '.'));

export function parseStorm(text) {
  if (!text) return null;
  const t = text.normalize('NFC');

  // tất cả toạ độ (vị trí hiện tại + các mốc dự báo nếu có)
  const coordRe = /(\d{1,2}[,.]?\d?)\s*độ\s*Vĩ\s*Bắc\s*;?\s*(\d{2,3}[,.]?\d?)\s*độ\s*Kinh\s*Đông/gi;
  const points = [];
  for (const m of t.matchAll(coordRe)) {
    const lat = num(m[1]);
    const lon = num(m[2]);
    if (lat >= 0 && lat <= 35 && lon >= 90 && lon <= 135) {
      points.push({ lat, lon });
    }
  }
  if (!points.length) return null;

  // cấp gió mạnh nhất vùng gần tâm (lấy cụm "cấp N-M" đầu tiên)
  const gio = t.match(/mạnh\s*(?:nhất|dần)?[^]{0,40}?cấp\s*(\d{1,2}(?:\s*-\s*\d{1,2})?)/i)
    || t.match(/cấp\s*(\d{1,2}(?:\s*-\s*\d{1,2})?)/i);
  const intensity = gio ? gio[1].replace(/\s/g, '') : null;

  // hướng di chuyển (dừng ở "với"/"mỗi"/dấu câu để không lấy dư)
  const huong = t.match(/di chuyển\s*(?:chủ yếu\s*)?theo hướng\s*([\p{L} ]+?)(?:\s+với|\s+mỗi|[,.;])/iu);
  const movement = huong ? huong[1].trim() : null;

  return {
    center: points[0],                 // vị trí hiện tại
    track: points,                      // hiện tại + dự báo (nếu bản tin có)
    intensity,                          // ví dụ "6-7" (cấp gió)
    movement,                           // ví dụ "Đông Bắc"
  };
}
