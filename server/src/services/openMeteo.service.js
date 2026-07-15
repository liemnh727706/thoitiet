// Gọi Open-Meteo (forecast + geocoding). Node 20+ có sẵn global fetch.
import { config } from '../config.js';

const CURRENT = [
  'temperature_2m',
  'relative_humidity_2m',
  'apparent_temperature',
  'is_day',
  'precipitation',
  'weather_code',
  'wind_speed_10m',
  'wind_direction_10m',
  'wind_gusts_10m',
  'surface_pressure',
];

const HOURLY = [
  'temperature_2m',
  'relative_humidity_2m',
  'precipitation_probability',
  'precipitation',
  'weather_code',
  'wind_speed_10m',
];

const DAILY = [
  'weather_code',
  'temperature_2m_max',
  'temperature_2m_min',
  'apparent_temperature_max',
  'precipitation_sum',
  'precipitation_probability_max',
  'wind_speed_10m_max',
  'wind_gusts_10m_max',
  'wind_direction_10m_dominant',
  'uv_index_max',
  'sunrise',
  'sunset',
];

export async function fetchForecast(lat, lon) {
  const url = new URL(config.openMeteo.forecastUrl);
  url.searchParams.set('latitude', lat);
  url.searchParams.set('longitude', lon);
  url.searchParams.set('current', CURRENT.join(','));
  url.searchParams.set('hourly', HOURLY.join(','));
  url.searchParams.set('daily', DAILY.join(','));
  url.searchParams.set('timezone', 'auto');
  url.searchParams.set('forecast_days', '7');
  url.searchParams.set('wind_speed_unit', 'kmh');

  const res = await fetch(url, { signal: AbortSignal.timeout(10_000) });
  if (!res.ok) {
    throw new Error(`Open-Meteo forecast lỗi: ${res.status}`);
  }
  return res.json();
}

export async function geocode(name, count = 8) {
  const url = new URL(config.openMeteo.geocodeUrl);
  url.searchParams.set('name', name);
  url.searchParams.set('count', String(count));
  url.searchParams.set('language', 'vi');
  url.searchParams.set('format', 'json');

  const res = await fetch(url, { signal: AbortSignal.timeout(10_000) });
  if (!res.ok) {
    throw new Error(`Open-Meteo geocoding lỗi: ${res.status}`);
  }
  const data = await res.json();
  return (data.results || []).map((r) => ({
    id: r.id,
    name: r.name,
    admin1: r.admin1 || '',
    country: r.country || '',
    countryCode: r.country_code || '',
    latitude: r.latitude,
    longitude: r.longitude,
  }));
}
