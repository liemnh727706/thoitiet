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

  WeatherAlert({
    required this.kind,
    required this.severity,
    required this.title,
    required this.message,
    required this.source,
    this.sourceUrl,
    this.issuedAt,
    this.official = false,
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
      );
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
