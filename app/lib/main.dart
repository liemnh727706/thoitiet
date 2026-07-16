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
        home: const HomeScreen(),
      ),
    );
  }
}
