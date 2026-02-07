import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:safeher/models/user_model.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveEmergencyNumber(AppUser user, String number) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not logged in';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({
      'phone': number,
    }, SetOptions(merge: true));
  }

  /// ACTIVATE SOS
  Future<String> activateSOS({
    required AppUser user,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not logged in';

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final doc = await _firestore.collection('sos_alerts').add({
      'userId': currentUser.uid,
      'userName': user.name,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await sendSMS(
        message:
            "Help Me. My location: https://www.google.com/maps?q=${position.latitude},${position.longitude}",
        recipients: [user.phone],
        sendDirect: true, // Send without opening SMS app
      );
    } catch (e) {
      throw 'Failed to send SMS: $e';
    }

    return doc.id;
  }

  /// DEACTIVATE SOS (PASSWORD REQUIRED)
  Future<void> deactivateSOS({
    required String sosId,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not logged in';

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    try {
      await user.reauthenticateWithCredential(credential);
    } catch (_) {
      throw 'Wrong password';
    }

    await _firestore.collection('sos_alerts').doc(sosId).update({
      'status': 'resolved',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }
}
