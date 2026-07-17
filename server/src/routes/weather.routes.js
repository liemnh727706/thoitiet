import { Router } from 'express';
import {
  getWeather,
  searchPlace,
  getWarnings,
  getRadarFrames,
  getStorm,
  getStorms,
  getHydro,
  pushTest,
} from '../controllers/weather.controller.js';

const router = Router();

router.get('/weather', getWeather);
router.get('/warnings', getWarnings);
router.get('/radar', getRadarFrames);
router.get('/storm', getStorm);
router.get('/storms', getStorms);
router.get('/hydro', getHydro);
router.get('/push-test', pushTest);
router.get('/geocode', searchPlace);

export default router;
