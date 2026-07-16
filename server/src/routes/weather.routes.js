import { Router } from 'express';
import {
  getWeather,
  searchPlace,
  getWarnings,
  getRadarFrames,
  getStorm,
} from '../controllers/weather.controller.js';

const router = Router();

router.get('/weather', getWeather);
router.get('/warnings', getWarnings);
router.get('/radar', getRadarFrames);
router.get('/storm', getStorm);
router.get('/geocode', searchPlace);

export default router;
