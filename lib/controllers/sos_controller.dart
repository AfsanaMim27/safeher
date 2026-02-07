import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/sos_service.dart';

class SosController {
  static bool sosActive = false;

  /// UI TRIGGER
  static Future<String?> triggerFromUI({
    required BuildContext context,
    required AppUser appUser,
  }) async {
    if (sosActive) return null;

    try {
      final sosId = await SosService().activateSOS(
        user: appUser,
      );

      sosActive = true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 SOS ACTIVATED'),
          backgroundColor: Colors.red,
        ),
      );

      return sosId;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return null;
    }
  }

  /// ESP32 / BLE TRIGGER
  static Future<String?> triggerFromESP32({
    required AppUser appUser,
  }) async {
    if (sosActive) return null;

    final sosId = await SosService().activateSOS(
      user: appUser,
    );

    sosActive = true;
    return sosId;
  }

  /// RESET AFTER DEACTIVATION
  static void reset() {
    sosActive = false;
  }
}
