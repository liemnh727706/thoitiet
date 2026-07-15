import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/weather.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

enum LoadStatus { idle, loading, success, error }

class WeatherProvider extends ChangeNotifier {
  final ApiService _api;
  final LocationService _location;

  WeatherProvider({ApiService? api, LocationService? location})
      : _api = api ?? ApiService(),
        _location = location ?? LocationService();

  LoadStatus status = LoadStatus.idle;
  String? errorMessage;
  WeatherResponse? data;

  // Địa điểm đang xem
  double _lat = AppConfig.defaultLat;
  double _lon = AppConfig.defaultLon;
  String _placeName = AppConfig.defaultPlace;

  String get placeName => _placeName;

  static const _kLat = 'lat';
  static const _kLon = 'lon';
  static const _kPlace = 'place';

  /// Nạp địa điểm đã lưu (nếu có) rồi tải thời tiết.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_kLat) && prefs.containsKey(_kLon)) {
      _lat = prefs.getDouble(_kLat)!;
      _lon = prefs.getDouble(_kLon)!;
      _placeName = prefs.getString(_kPlace) ?? _placeName;
    }
    await load();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLat, _lat);
    await prefs.setDouble(_kLon, _lon);
    await prefs.setString(_kPlace, _placeName);
  }

  /// Tải thời tiết cho địa điểm hiện tại.
  Future<void> load() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _api.getWeather(lat: _lat, lon: _lon, place: _placeName);
      status = LoadStatus.success;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// Dùng GPS -> lấy vị trí hiện tại rồi tải thời tiết.
  Future<void> useCurrentLocation() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final loc = await _location.getCurrentLocation();
      _lat = loc.latitude;
      _lon = loc.longitude;
      _placeName = 'Vị trí của bạn';
      await _save();
      await load();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      status = LoadStatus.error;
      notifyListeners();
    }
  }

  /// Chọn địa điểm từ kết quả tìm kiếm.
  Future<void> selectPlace(PlaceResult place) async {
    _lat = place.latitude;
    _lon = place.longitude;
    _placeName = place.name;
    await _save();
    await load();
  }
}
