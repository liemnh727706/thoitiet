// Crawler bản tin cảnh báo chính thức của NCHMF (nchmf.gov.vn).
// KHÔNG có API -> parse HTML trang chuyên mục. Mỗi trang giữ bản tin gần nhất
// dạng: <a href="...detail...">TIÊU ĐỀ <span> ( DD/MM/YYYY HH:MM ) </span></a>
import * as cheerio from 'cheerio';
import { classify, parseIssuedAt } from '../utils/nchmfClassify.js';
import { regionsInText } from '../utils/vnRegion.js';
import { parseStorm } from '../utils/stormParse.js';
import { getCache, setCache } from './cache.service.js';

const UA = { 'User-Agent': 'Mozilla/5.0 (compatible; VNWeatherBot/1.0)' };

const CATEGORY_PAGES = {
  storm: 'https://www.nchmf.gov.vn/kttv/vi-VN/1/bao-ap-thap-nhiet-doi-2049-15.html',
  heat: 'https://www.nchmf.gov.vn/kttv/vi-VN/1/nang-nong-2051-15.html',
  cold: 'https://www.nchmf.gov.vn/kttv/vi-VN/1/khong-khi-lanh-2050-15.html',
  flood: 'https://www.nchmf.gov.vn/kttv/vi-VN/1/lu-ngap-lut-16-18.html',
  flashflood: 'https://www.nchmf.gov.vn/kttv/vi-VN/1/lu-quet-17-18.html',
  salinity: 'https://www.nchmf.gov.vn/kttv/vi-VN/1/xam-nhap-man-20-18.html',
};

// Số bản tin (đã khử trùng theo tiêu đề) lấy tối đa mỗi loại:
// lũ có thể nhiều vùng cùng lúc; loại quốc gia/đơn lẻ chỉ lấy bản mới nhất.
const MAX_PER_CATEGORY = {
  storm: 2, heat: 1, cold: 1, flood: 3, flashflood: 1, salinity: 2,
};

async function getHtml(url) {
  const res = await fetch(url, { headers: UA, signal: AbortSignal.timeout(12_000) });
  if (!res.ok) throw new Error(`NCHMF ${res.status} @ ${url}`);
  return res.text();
}

// Lấy nội dung trang chi tiết: tóm tắt (~300 ký tự) + toàn văn (để parse bão).
async function fetchDetail(detailUrl) {
  try {
    const html = await getHtml(detailUrl);
    const $ = cheerio.load(html);
    const paras = [];
    $('p').each((_, el) => {
      const t = $(el).text().replace(/\s+/g, ' ').trim();
      if (t.length > 40) paras.push(t);
    });
    const fullText = paras.join(' ').normalize('NFC');
    const joined = paras.slice(0, 2).join(' ');
    const summary = joined.length > 300 ? joined.slice(0, 297) + '…' : joined;
    return { summary, fullText };
  } catch {
    return { summary: '', fullText: '' };
  }
}

// Parse 1 trang chuyên mục -> danh sách bản tin (khử trùng theo tiêu đề, giữ
// bản mới nhất, giới hạn theo MAX_PER_CATEGORY). Link chi tiết luôn chứa "post".
async function parseCategory(category, url) {
  const html = await getHtml(url);
  const $ = cheerio.load(html);

  const raw = [];
  const seenHref = new Set();
  $('a[href*="post"]').each((_, a) => {
    const rawText = $(a).text().replace(/\s+/g, ' ').trim();
    const href = $(a).attr('href');
    if (!rawText || !href || seenHref.has(href)) return;
    if (/đang cập nhật/i.test(rawText)) return;
    const issuedAtIso = parseIssuedAt(rawText);
    if (!issuedAtIso) return; // chỉ lấy link có ngày giờ = bản tin thật
    seenHref.add(href);
    const title = rawText.replace(/\(.*$/, '').trim();
    if (title) raw.push({ title, href, issuedAtIso });
  });
  if (!raw.length) return [];

  // khử trùng theo tiêu đề, giữ bản mới nhất
  const byTitle = new Map();
  for (const it of raw) {
    const key = it.title.normalize('NFC');
    const ex = byTitle.get(key);
    if (!ex || new Date(it.issuedAtIso) > new Date(ex.issuedAtIso)) byTitle.set(key, it);
  }
  const distinct = [...byTitle.values()]
    .sort((a, b) => new Date(b.issuedAtIso) - new Date(a.issuedAtIso))
    .slice(0, MAX_PER_CATEGORY[category] ?? 2);

  const out = [];
  for (const it of distinct) {
    const detail = await fetchDetail(it.href);
    const { kind, severity } = classify(category, it.title, detail.summary);
    const ageHours = (Date.now() - new Date(it.issuedAtIso).getTime()) / 3_600_000;
    const regions = regionsInText(`${it.title} ${detail.fullText}`);
    const storm = category === 'storm' ? parseStorm(detail.fullText) : null;
    out.push({
      category,
      kind,
      severity,
      title: it.title,
      summary: detail.summary,
      regions,
      storm,
      sourceUrl: it.href,
      issuedAt: it.issuedAtIso,
      ageHours: Math.round(ageHours * 10) / 10,
      source: 'NCHMF - nchmf.gov.vn',
    });
  }
  return out;
}

// Ngưỡng "còn hiệu lực" (giờ) theo loại tin. Có thể override tất cả bằng env
// NCHMF_FRESH_HOURS (hữu ích để tinh chỉnh hoặc demo).
const OVERRIDE = process.env.NCHMF_FRESH_HOURS ? Number(process.env.NCHMF_FRESH_HOURS) : null;
const DEFAULT_FRESH = { storm: 48, heat: 30, cold: 36, flood: 36, flashflood: 36, salinity: 192 };
const FRESH_HOURS = OVERRIDE
  ? Object.fromEntries(Object.keys(DEFAULT_FRESH).map((k) => [k, OVERRIDE]))
  : DEFAULT_FRESH;

// Lấy toàn bộ cảnh báo NCHMF. Trả { all: [...], active: [...] }
export async function fetchNchmfWarnings() {
  const results = await Promise.allSettled(
    Object.entries(CATEGORY_PAGES).map(([cat, url]) => parseCategory(cat, url)),
  );

  const all = [];
  for (const r of results) {
    if (r.status === 'fulfilled' && Array.isArray(r.value)) {
      for (const w of r.value) {
        w.stale = w.ageHours != null && w.ageHours > (FRESH_HOURS[w.category] ?? 36);
        all.push(w);
      }
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
