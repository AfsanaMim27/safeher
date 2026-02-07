import 'package:geolocator/geolocator.dart';

class PermissionService {
  static Future<void> requestLocationOnce() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }
}
