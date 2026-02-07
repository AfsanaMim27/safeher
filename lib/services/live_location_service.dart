import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationService {
  Timer? _timer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ask permission ONCE after login
  static Future<void> ensurePermissionGranted() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  /// Start saving location every 30 seconds
  void startTracking({required String sosId}) {
    stopTracking();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _saveLocation(sosId);
    });
  }

  /// Stop tracking
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _saveLocation(String sosId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await _firestore
        .collection('sos_alerts')
        .doc(sosId)
        .collection('locations')
        .add({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': Timestamp.now(),
      'userId': user.uid,
    });
  }
}
