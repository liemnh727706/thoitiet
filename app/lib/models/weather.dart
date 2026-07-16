// Model khớp với JSON trả về từ backend (/api/weather).

class WeatherResponse {
  final PlaceInfo? place;
  final double latitude;
  final double longitude;
  final String timezone;
  final DateTime updatedAt;
  final List<WeatherAlert> alerts;
  final CurrentWeather current;
  final List<HourlyItem> hourly;
  final List<DailyItem> daily;

  WeatherResponse({
    this.place,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.updatedAt,
    required this.alerts,
    required this.current,
    required this.hourly,
    required this.daily,
  });

  factory WeatherResponse.fromJson(Map<String, dynamic> j) {
    final coords = j['coordinates'] ?? {};
    return WeatherResponse(
      place: j['place'] != null ? PlaceInfo.fromJson(j['place']) : null,
      latitude: (coords['latitude'] ?? 0).toDouble(),
      longitude: (coords['longitude'] ?? 0).toDouble(),
      timezone: j['timezone'] ?? '',
      updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
      alerts: (j['alerts'] as List? ?? [])
          .map((e) => WeatherAlert.fromJson(e))
          .toList(),
      current: CurrentWeather.fromJson(j['current'] ?? {}),
      hourly: (j['hourly'] as List? ?? [])
          .map((e) => HourlyItem.fromJson(e))
          .toList(),
      daily: (j['daily'] as List? ?? [])
          .map((e) => DailyItem.fromJson(e))
          .toList(),
    );
  }
}

class PlaceInfo {
  final String name;
  PlaceInfo({required this.name});
  factory PlaceInfo.fromJson(Map<String, dynamic> j) =>
      PlaceInfo(name: j['name'] ?? '');
}

class WeatherAlert {
  final String kind;      // heat | cold | rain | wind | uv | storm ...
  final String severity;  // danger | warning | watch
  final String title;
  final String message;
  final String source;
  final String? sourceUrl;
  final DateTime? issuedAt;
  final bool official;    // true nếu là bản tin chính thức NCHMF
  final List<String> regions; // mã vùng ảnh hưởng (BAC_BO, ...)

  WeatherAlert({
    required this.kind,
    required this.severity,
    required this.title,
    required this.message,
    required this.source,
    this.sourceUrl,
    this.issuedAt,
    this.official = false,
    this.regions = const [],
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> j) => WeatherAlert(
        kind: j['kind'] ?? '',
        severity: j['severity'] ?? 'watch',
        title: j['title'] ?? '',
        message: j['message'] ?? '',
        source: j['source'] ?? '',
        sourceUrl: j['sourceUrl'],
        issuedAt: j['issuedAt'] != null ? DateTime.tryParse(j['issuedAt']) : null,
        official: j['official'] ?? false,
        regions: (j['regions'] as List? ?? []).map((e) => e.toString()).toList(),
      );

  // Tên vùng tiếng Việt để hiển thị
  static const _regionNames = {
    'BAC_BO': 'Bắc Bộ',
    'BAC_TRUNG_BO': 'Bắc Trung Bộ',
    'TRUNG_TRUNG_BO': 'Trung Trung Bộ',
    'NAM_TRUNG_BO': 'Nam Trung Bộ',
    'TAY_NGUYEN': 'Tây Nguyên',
    'NAM_BO': 'Nam Bộ',
  };
  String get regionsLabel =>
      regions.map((c) => _regionNames[c] ?? c).join(', ');
}

class Wind {
  final int? speed;
  final int? gust;
  final String direction;
  final int? beaufort;
  Wind({this.speed, this.gust, required this.direction, this.beaufort});
  factory Wind.fromJson(Map<String, dynamic> j) => Wind(
        speed: j['speed'],
        gust: j['gust'],
        direction: j['direction'] ?? '',
        beaufort: j['beaufort'],
      );
}

class CurrentWeather {
  final bool isDay;
  final int? temperature;
  final int? apparentTemperature;
  final int? humidity;
  final num? precipitation;
  final int? pressure;
  final int weatherCode;
  final String condition;
  final String icon;
  final Wind wind;

  CurrentWeather({
    required this.isDay,
    this.temperature,
    this.apparentTemperature,
    this.humidity,
    this.precipitation,
    this.pressure,
    required this.weatherCode,
    required this.condition,
    required this.icon,
    required this.wind,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> j) => CurrentWeather(
        isDay: j['isDay'] ?? true,
        temperature: j['temperature'],
        apparentTemperature: j['apparentTemperature'],
        humidity: j['humidity'],
        precipitation: j['precipitation'],
        pressure: j['pressure'],
        weatherCode: j['weatherCode'] ?? 0,
        condition: j['condition'] ?? '',
        icon: j['icon'] ?? 'cloudy',
        wind: Wind.fromJson(j['wind'] ?? {}),
      );
}

class HourlyItem {
  final DateTime time;
  final int? temperature;
  final int? precipitationProbability;
  final String icon;
  final String condition;

  HourlyItem({
    required this.time,
    this.temperature,
    this.precipitationProbability,
    required this.icon,
    required this.condition,
  });

  factory HourlyItem.fromJson(Map<String, dynamic> j) => HourlyItem(
        time: DateTime.tryParse(j['time'] ?? '') ?? DateTime.now(),
        temperature: j['temperature'],
        precipitationProbability: j['precipitationProbability'],
        icon: j['icon'] ?? 'cloudy',
        condition: j['condition'] ?? '',
      );
}

class DailyItem {
  final DateTime date;
  final int? tempMax;
  final int? tempMin;
  final num? precipitationSum;
  final int? precipitationProbability;
  final num? uvIndexMax;
  final String icon;
  final String condition;

  DailyItem({
    required this.date,
    this.tempMax,
    this.tempMin,
    this.precipitationSum,
    this.precipitationProbability,
    this.uvIndexMax,
    required this.icon,
    required this.condition,
  });

  factory DailyItem.fromJson(Map<String, dynamic> j) => DailyItem(
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        tempMax: j['tempMax'],
        tempMin: j['tempMin'],
        precipitationSum: j['precipitationSum'],
        precipitationProbability: j['precipitationProbability'],
        uvIndexMax: j['uvIndexMax'],
        icon: j['icon'] ?? 'cloudy',
        condition: j['condition'] ?? '',
      );
}

class RadarFrame {
  final int time;    // epoch giây
  final String kind; // past | nowcast
  final String url;  // tile template .../{z}/{x}/{y}/...png
  RadarFrame({required this.time, required this.kind, required this.url});
  factory RadarFrame.fromJson(Map<String, dynamic> j) => RadarFrame(
        time: j['time'] ?? 0,
        kind: j['kind'] ?? 'past',
        url: j['url'] ?? '',
      );
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time * 1000);
}

class RadarData {
  final String host;
  final List<RadarFrame> frames;
  final String attribution;
  RadarData({required this.host, required this.frames, required this.attribution});
  factory RadarData.fromJson(Map<String, dynamic> j) => RadarData(
        host: j['host'] ?? '',
        frames: (j['frames'] as List? ?? [])
            .map((e) => RadarFrame.fromJson(e))
            .toList(),
        attribution: j['attribution'] ?? 'RainViewer',
      );
}

class StormPoint {
  final double lat;
  final double lon;
  StormPoint({required this.lat, required this.lon});
  factory StormPoint.fromJson(Map<String, dynamic> j) =>
      StormPoint(lat: (j['lat'] ?? 0).toDouble(), lon: (j['lon'] ?? 0).toDouble());
}

class StormInfo {
  final bool active;
  final String? title;
  final String? severity;
  final String? intensity; // cấp gió, vd "6-7"
  final String? movement;  // hướng, vd "Đông Bắc"
  final StormPoint? center;
  final List<StormPoint> track;
  final String? sourceUrl;

  StormInfo({
    required this.active,
    this.title,
    this.severity,
    this.intensity,
    this.movement,
    this.center,
    this.track = const [],
    this.sourceUrl,
  });

  factory StormInfo.fromJson(Map<String, dynamic> j) => StormInfo(
        active: j['active'] ?? false,
        title: j['title'],
        severity: j['severity'],
        intensity: j['intensity'],
        movement: j['movement'],
        center: j['center'] != null ? StormPoint.fromJson(j['center']) : null,
        track: (j['track'] as List? ?? [])
            .map((e) => StormPoint.fromJson(e))
            .toList(),
        sourceUrl: j['sourceUrl'],
      );
}

class PlaceResult {
  final String name;
  final String admin1;
  final String country;
  final double latitude;
  final double longitude;

  PlaceResult({
    required this.name,
    required this.admin1,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> j) => PlaceResult(
        name: j['name'] ?? '',
        admin1: j['admin1'] ?? '',
        country: j['country'] ?? '',
        latitude: (j['latitude'] ?? 0).toDouble(),
        longitude: (j['longitude'] ?? 0).toDouble(),
      );

  String get label =>
      [name, admin1, country].where((e) => e.isNotEmpty).toSet().join(', ');
}
