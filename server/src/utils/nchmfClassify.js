// Phân loại loại tin (kind) + mức độ (severity) từ tiêu đề/nội dung bản tin NCHMF.
// severity: 'danger' (đỏ) | 'warning' (cam) | 'watch' (vàng) — khớp app.

// Chuẩn hóa NFC + hoa để so khớp ổn định (trang NCHMF có thể trả Unicode dạng NFD).
function up(s) {
  return (s || '').normalize('NFC').toUpperCase();
}

// Mức độ cho tin BÃO / ÁP THẤP NHIỆT ĐỚI
function stormSeverity(title) {
  const t = up(title);
  if (t.includes('KHẨN CẤP')) return 'danger';
  if (t.includes('BÃO') && t.includes('GẦN BỜ')) return 'danger';
  if (t.includes('BÃO') && (t.includes('TRÊN BIỂN ĐÔNG') || t.includes('KHẨN'))) return 'warning';
  if (t.includes('BÃO')) return 'warning';
  if (t.includes('ÁP THẤP NHIỆT ĐỚI')) return 'warning';
  return 'watch';
}

// Mức độ cho tin NẮNG NÓNG
function heatSeverity(title, body) {
  const t = up(title + ' ' + body);
  if (t.includes('ĐẶC BIỆT GAY GẮT')) return 'danger';
  if (t.includes('GAY GẮT')) return 'warning';
  if (t.includes('NẮNG NÓNG')) return 'watch';
  return 'watch';
}

// Mức độ cho tin KHÔNG KHÍ LẠNH / RÉT
function coldSeverity(title, body) {
  const t = up(title + ' ' + body);
  if (t.includes('RÉT HẠI') || t.includes('BĂNG GIÁ')) return 'danger';
  if (t.includes('RÉT ĐẬM')) return 'warning';
  if (t.includes('GIÓ MÙA ĐÔNG BẮC') || t.includes('RÉT') || t.includes('KHÔNG KHÍ LẠNH')) return 'watch';
  return 'watch';
}

export function classify(category, title, body = '') {
  switch (category) {
    case 'storm':
      return { kind: 'storm', severity: stormSeverity(title) };
    case 'heat':
      return { kind: 'heat', severity: heatSeverity(title, body) };
    case 'cold':
      return { kind: 'cold', severity: coldSeverity(title, body) };
    default:
      return { kind: 'other', severity: 'watch' };
  }
}

// Parse "( DD/MM/YYYY HH:MM )" -> ISO string (giờ VN, +07:00). Trả null nếu không parse được.
export function parseIssuedAt(text) {
  const m = (text || '').match(/(\d{1,2})\/(\d{1,2})\/(\d{4})\s+(\d{1,2}):(\d{2})/);
  if (!m) return null;
  const [, d, mo, y, h, mi] = m;
  const pad = (n) => String(n).padStart(2, '0');
  return `${y}-${pad(mo)}-${pad(d)}T${pad(h)}:${pad(mi)}:00+07:00`;
}
