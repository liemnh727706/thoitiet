// Crawler bản tin cảnh báo chính thức của NCHMF (nchmf.gov.vn).
// KHÔNG có API -> parse HTML trang chuyên mục. Mỗi trang giữ bản tin gần nhất
// dạng: <a href="...detail...">TIÊU ĐỀ <span> ( DD/MM/YYYY HH:MM ) </span></a>
import * as cheerio from 'cheerio';
import { classify, parseIssuedAt } from '../utils/nchmfClassify.js';
import { getCache, setCache } from './cache.service.js';

const UA = { 'User-Agent': 'Mozilla/5.0 (compatible; VNWeatherBot/1.0)' };

const CATEGORY_PAGES = {
  storm: 'https://www.nchmf.gov.vn/kttv/vi-VN/1/bao-ap-thap-nhiet-doi-2049-15.html',
  heat: 'https://www.nchmf.gov.vn/kttv/vi-VN/1/nang-nong-2051-15.html',
  cold: 'https://www.nchmf.gov.vn/kttv/vi-VN/1/khong-khi-lanh-2050-15.html',
};

async function getHtml(url) {
  const res = await fetch(url, { headers: UA, signal: AbortSignal.timeout(12_000) });
  if (!res.ok) throw new Error(`NCHMF ${res.status} @ ${url}`);
  return res.text();
}

// Lấy tóm tắt từ trang chi tiết bản tin (đoạn <p> dài nhất, ghép lại ~300 ký tự)
async function fetchSummary(detailUrl) {
  try {
    const html = await getHtml(detailUrl);
    const $ = cheerio.load(html);
    const paras = [];
    $('p').each((_, el) => {
      const t = $(el).text().replace(/\s+/g, ' ').trim();
      if (t.length > 40) paras.push(t);
    });
    if (!paras.length) return '';
    // ưu tiên đoạn đầu (thường là mô tả hiện trạng), cắt gọn
    const joined = paras.slice(0, 2).join(' ');
    return joined.length > 300 ? joined.slice(0, 297) + '…' : joined;
  } catch {
    return '';
  }
}

// Parse 1 trang chuyên mục -> bản tin mới nhất (hoặc null nếu "Đang cập nhật")
async function parseCategory(category, url) {
  const html = await getHtml(url);
  const $ = cheerio.load(html);

  // mỗi bản tin nằm trong .grp-list-item ul li; link tiêu đề ở .text-weather-location a
  const items = [];
  $('.grp-list-item ul li').each((_, li) => {
    const a = $(li).find('.text-weather-location a').first();
    const rawText = a.text().replace(/\s+/g, ' ').trim();
    if (!rawText || /đang cập nhật/i.test(rawText)) return;
    const href = a.attr('href');
    const issuedAtIso = parseIssuedAt(rawText);
    // tiêu đề = phần trước dấu "("
    const title = rawText.replace(/\(.*$/, '').trim();
    if (title) items.push({ title, href, issuedAtIso });
  });

  if (!items.length) return null;
  // bản tin đầu tiên là mới nhất
  const latest = items[0];
  const summary = latest.href ? await fetchSummary(latest.href) : '';
  const { kind, severity } = classify(category, latest.title, summary);

  const issuedAt = latest.issuedAtIso;
  const ageHours = issuedAt
    ? (Date.now() - new Date(issuedAt).getTime()) / 3_600_000
    : null;

  return {
    category,
    kind,
    severity,
    title: latest.title,
    summary,
    sourceUrl: latest.href || url,
    issuedAt,
    ageHours: ageHours == null ? null : Math.round(ageHours * 10) / 10,
    source: 'NCHMF - nchmf.gov.vn',
  };
}

// Ngưỡng "còn hiệu lực" (giờ) theo loại tin
const FRESH_HOURS = { storm: 48, heat: 30, cold: 36 };

// Lấy toàn bộ cảnh báo NCHMF. Trả { all: [...], active: [...] }
export async function fetchNchmfWarnings() {
  const results = await Promise.allSettled(
    Object.entries(CATEGORY_PAGES).map(([cat, url]) => parseCategory(cat, url)),
  );

  const all = [];
  for (const r of results) {
    if (r.status === 'fulfilled' && r.value) {
      const w = r.value;
      w.stale =
        w.ageHours != null && w.ageHours > (FRESH_HOURS[w.category] ?? 36);
      all.push(w);
    }
  }
  const active = all.filter((w) => !w.stale);
  return { all, active, fetchedAt: new Date().toISOString() };
}

// -------- Cache + poll nền (tránh crawl mỗi request; NCHMF cập nhật theo giờ) --------
const CACHE_KEY = 'nchmf:warnings';
const CACHE_TTL = 1800; // 30 phút

// Đọc từ cache; nếu chưa có thì crawl và lưu (dùng cho endpoint /api/warnings)
export async function getCachedWarnings() {
  const cached = getCache(CACHE_KEY);
  if (cached) return cached;
  const data = await fetchNchmfWarnings();
  setCache(CACHE_KEY, data, CACHE_TTL);
  return data;
}

// Đọc cache KHÔNG chặn mạng (dùng khi ghép vào /api/weather để giữ tốc độ)
export function peekWarnings() {
  return getCache(CACHE_KEY) || { all: [], active: [], fetchedAt: null };
}

// Poll định kỳ để luôn có sẵn dữ liệu nóng + phục vụ diff cho FCM sau này.
export function startWarningPoll(onNewActive) {
  let prevKeys = new Set();
  const tick = async () => {
    try {
      const data = await fetchNchmfWarnings();
      setCache(CACHE_KEY, data, CACHE_TTL);
      // phát hiện cảnh báo ACTIVE mới (theo title+issuedAt) -> callback (FCM)
      const keys = new Set(data.active.map((w) => `${w.title}|${w.issuedAt}`));
      const fresh = data.active.filter((w) => !prevKeys.has(`${w.title}|${w.issuedAt}`));
      if (prevKeys.size && fresh.length && typeof onNewActive === 'function') {
        onNewActive(fresh);
      }
      prevKeys = keys;
      console.log(`[NCHMF] cập nhật: ${data.all.length} tin, ${data.active.length} còn hiệu lực`);
    } catch (e) {
      console.error('[NCHMF] poll lỗi:', e.message);
    }
  };
  tick(); // chạy ngay khi khởi động
  const timer = setInterval(tick, CACHE_TTL * 1000);
  timer.unref?.();
  return timer;
}
