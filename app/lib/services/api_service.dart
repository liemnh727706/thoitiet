import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/weather.dart';

class ApiService {
  final http.Client _client;
  ApiService([http.Client? client]) : _client = client ?? http.Client();

  Future<WeatherResponse> getWeather({
    required double lat,
    required double lon,
    String? place,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBase}/api/weather').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        if (place != null) 'place': place,
      },
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Lỗi máy chủ (${res.statusCode})');
    }
    return WeatherResponse.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<RadarData> getRadar() async {
    final uri = Uri.parse('${AppConfig.apiBase}/api/radar');
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Không lấy được radar (${res.statusCode})');
    }
    return RadarData.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<StormInfo> getStorm() async {
    final uri = Uri.parse('${AppConfig.apiBase}/api/storm');
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Không lấy được dữ liệu bão (${res.statusCode})');
    }
    return StormInfo.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<List<PlaceResult>> searchPlace(String query) async {
    final uri = Uri.parse('${AppConfig.apiBase}/api/geocode')
        .replace(queryParameters: {'q': query});
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Không tìm được địa danh (${res.statusCode})');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return list.map((e) => PlaceResult.fromJson(e)).toList();
  }
}
