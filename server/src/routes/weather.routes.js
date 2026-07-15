import { Router } from 'express';
import { getWeather, searchPlace } from '../controllers/weather.controller.js';

const router = Router();

router.get('/weather', getWeather);
router.get('/geocode', searchPlace);

export default router;
