import express from 'express';
import cors from 'cors';
import { config } from './config.js';
import weatherRoutes from './routes/weather.routes.js';
import { startWarningPoll } from './services/nchmf.service.js';
import { startThuyloiPoll } from './services/thuyloi.service.js';
import { onNewWarnings, initPush } from './services/push.service.js';

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
  console.log(`   GET /api/warnings`);
  console.log(`   GET /api/geocode?q=Ho Chi Minh`);

  // Khởi tạo FCM sớm để xác nhận cấu hình ngay khi chạy
  initPush();

  // Poll cảnh báo NCHMF; khi có cảnh báo ACTIVE mới -> đẩy FCM (nếu đã cấu hình)
  startWarningPoll(onNewWarnings);

  // Poll thủy văn ĐBSCL (mặn + ngập) từ Cục Thủy lợi
  startThuyloiPoll();
});
