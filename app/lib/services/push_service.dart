import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Xử lý push khi app chạy nền / bị tắt (phải là hàm top-level).
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  // Hệ thống tự hiển thị notification; ở đây chỉ log.
  debugPrint('[FCM bg] ${message.notification?.title}');
}

class PushService {
  // Khởi tạo Firebase + đăng ký nhận cảnh báo. Bọc try/catch để nếu chưa
  // cấu hình (thiếu google-services.json) thì app vẫn chạy bình thường.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_bgHandler);

      final fm = FirebaseMessaging.instance;
      await fm.requestPermission(); // Android 13+ và iOS xin quyền thông báo
      await fm.subscribeToTopic('weather-warnings'); // nhận cảnh báo NCHMF

      // Foreground: log tiêu đề (có thể nâng cấp hiển thị banner trong app)
      FirebaseMessaging.onMessage.listen((m) {
        debugPrint('[FCM] ${m.notification?.title}');
      });
      debugPrint('[FCM] Đã bật, subscribe topic weather-warnings');
    } catch (e) {
      // Chưa cấu hình Firebase -> bỏ qua, không làm app crash.
      debugPrint('[FCM] Chưa bật (thiếu cấu hình Firebase): $e');
    }
  }
}
