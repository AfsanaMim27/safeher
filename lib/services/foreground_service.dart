import 'package:flutter/services.dart';

class ForegroundService {
  static const MethodChannel _channel =
  MethodChannel('safeher/foreground');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('startService');
    } catch (e) {
      print('Failed to start foreground service: $e');
    }
  }
}
