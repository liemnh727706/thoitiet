import express from 'express';
import cors from 'cors';
import { config } from './config.js';
import weatherRoutes from './routes/weather.routes.js';

const app = express();
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'vn-weather-server', time: new Date().toISOString() });
});

app.use('/api', weatherRoutes);

// 404
app.use((req, res) => {
  res.status(404).json({ error: 'Không tìm thấy endpoint' });
});

app.listen(config.port, () => {
  console.log(`✅ VN Weather server chạy tại http://localhost:${config.port}`);
  console.log(`   GET /health`);
  console.log(`   GET /api/weather?lat=10.76&lon=106.68`);
  console.log(`   GET /api/geocode?q=Ho Chi Minh`);
});
