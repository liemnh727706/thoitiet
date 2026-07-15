import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '4000', 10),
  cacheTtlSeconds: parseInt(process.env.CACHE_TTL_SECONDS || '600', 10),
  redisUrl: process.env.REDIS_URL || '',

  // Endpoint Open-Meteo (miễn phí, không cần API key)
  openMeteo: {
    forecastUrl: 'https://api.open-meteo.com/v1/forecast',
    geocodeUrl: 'https://geocoding-api.open-meteo.com/v1/search',
    airQualityUrl: 'https://air-quality-api.open-meteo.com/v1/air-quality',
  },
};
