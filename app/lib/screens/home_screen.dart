import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/weather_provider.dart';
import '../theme/weather_gradients.dart';
import '../utils/formatters.dart';
import '../widgets/alert_banner.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/detail_grid.dart';
import '../widgets/hourly_forecast.dart';
import '../widgets/daily_forecast.dart';
import 'search_screen.dart';
import 'radar_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final data = provider.data;
        final isDay = data?.current.isDay ?? true;
        final icon = data?.current.icon ?? 'clear';
        final gradient = WeatherGradients.forCondition(icon, isDay: isDay);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.placeName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                if (data != null)
                  Text(formatUpdated(data.updatedAt),
                      style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Dùng vị trí hiện tại',
              onPressed: () => provider.useCurrentLocation(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.radar),
                tooltip: 'Bản đồ mưa & bão',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RadarScreen(
                      centerLat: data?.latitude,
                      centerLon: data?.longitude,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Tìm địa điểm',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradient,
              ),
            ),
            child: SafeArea(
              child: _buildBody(context, provider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WeatherProvider provider) {
    switch (provider.status) {
      case LoadStatus.loading:
      case LoadStatus.idle:
        if (provider.data == null) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        break;
      case LoadStatus.error:
        if (provider.data == null) {
          return _ErrorView(message: provider.errorMessage, onRetry: provider.load);
        }
        break;
      case LoadStatus.success:
        break;
    }

    final data = provider.data!;
    final today = data.daily.isNotEmpty ? data.daily.first : null;

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // TẦNG 1 - cảnh báo khẩn
          AlertBanner(alerts: data.alerts),
          // TẦNG 2 - thời tiết hiện tại
          const SizedBox(height: 8),
          CurrentWeatherCard(current: data.current),
          const SizedBox(height: 24),
          DetailGrid(current: data.current, today: today),
          const SizedBox(height: 16),
          // TẦNG 3 - dự báo
          HourlyForecast(hourly: data.hourly),
          const SizedBox(height: 16),
          DailyForecast(daily: data.daily),
          const SizedBox(height: 12),
          Center(
            child: Text('Nguồn dữ liệu: Open-Meteo (ECMWF/GFS)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const _ErrorView({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(message ?? 'Đã xảy ra lỗi',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
