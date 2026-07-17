import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'state/weather_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  await PushService.init(); // bật FCM nếu đã cấu hình Firebase (an toàn nếu chưa)
  runApp(const VnWeatherApp());
}

class VnWeatherApp extends StatelessWidget {
  const VnWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeatherProvider()..init(),
      child: MaterialApp(
        title: 'Thời tiết Việt Nam',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const RootView(),
      ),
    );
  }
}

// Bọc màn hình chính để lắng nghe push foreground -> hiện banner + refresh cảnh báo.
class RootView extends StatefulWidget {
  const RootView({super.key});
  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  @override
  void initState() {
    super.initState();
    PushService.foreground.addListener(_onPush);
  }

  @override
  void dispose() {
    PushService.foreground.removeListener(_onPush);
    super.dispose();
  }

  void _onPush() {
    final alert = PushService.foreground.value;
    if (alert == null || !mounted) return;

    // Tải lại thời tiết để cảnh báo mới xuất hiện trong danh sách (tier 1)
    context.read<WeatherProvider>().load();

    // Hiện banner khẩn ngay trên đầu màn hình
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: const Color(0xFFD32F2F),
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        content: Text(
          alert.body.isEmpty ? alert.title : '${alert.title}\n${alert.body}',
          style: const TextStyle(color: Colors.white, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('ĐÓNG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
