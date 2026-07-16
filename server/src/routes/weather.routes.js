import { Router } from 'express';
import { getWeather, searchPlace, getWarnings } from '../controllers/weather.controller.js';

const router = Router();

router.get('/weather', getWeather);
router.get('/warnings', getWarnings);
router.get('/geocode', searchPlace);

export default router;
