import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  LocationResult(this.latitude, this.longitude);
}

class LocationService {
  /// Lấy vị trí hiện tại. Ném Exception với thông báo tiếng Việt nếu lỗi.
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ định vị đang tắt. Vui lòng bật GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Bạn chưa cấp quyền vị trí.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền vị trí bị chặn. Hãy bật lại trong Cài đặt.');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 12),
    );
    return LocationResult(pos.latitude, pos.longitude);
  }
}
