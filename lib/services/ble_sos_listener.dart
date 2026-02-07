import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum EspConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  failed,
}

class BleSosListener {
  static const String deviceName = "SAFEHER_SOS";
  static const String serviceUUID = "12345678-1234-1234-1234-1234567890ab";
  static const String characteristicUUID =
      "abcd1234-5678-1234-5678-abcdef123456";

  BluetoothDevice? _device;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  EspConnectionState state = EspConnectionState.disconnected;
  bool _manualDisconnect = false;

  /// 🔵 CONNECT WITH TIMEOUT + STATUS
  Future<void> connect({
    required Function onSosTrigger,
    required Function(EspConnectionState) onStateChanged,
  }) async {
    _manualDisconnect = false;
    state = EspConnectionState.scanning;
    onStateChanged(state);

    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first;

    bool deviceFound = false;

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen(
          (results) async {
        for (final r in results) {
          if (r.device.platformName == deviceName) {
            deviceFound = true;
            await FlutterBluePlus.stopScan();

            state = EspConnectionState.connecting;
            onStateChanged(state);

            _device = r.device;

            try {
              await _device!.connect(autoConnect: false, timeout: const Duration(seconds: 10));
            } catch (_) {
              state = EspConnectionState.failed;
              onStateChanged(state);
              return;
            }

            _listenConnectionState(
              onSosTrigger: onSosTrigger,
              onStateChanged: onStateChanged,
            );

            await _listenToCharacteristic(onSosTrigger);

            state = EspConnectionState.connected;
            onStateChanged(state);
            return;
          }
        }
      },
    );

    await FlutterBluePlus.startScan();

    /// ⏱️ SCAN TIMEOUT
    Future.delayed(const Duration(seconds: 12), () async {
      if (!deviceFound && state == EspConnectionState.scanning) {
        await FlutterBluePlus.stopScan();
        state = EspConnectionState.failed;
        onStateChanged(state);
      }
    });
  }

  /// 🔔 CHARACTERISTIC LISTENER
  Future<void> _listenToCharacteristic(Function onSosTrigger) async {
    final services = await _device!.discoverServices();

    for (final s in services) {
      if (s.uuid.toString() == serviceUUID) {
        for (final c in s.characteristics) {
          if (c.uuid.toString() == characteristicUUID) {
            await c.setNotifyValue(true);
            _notifySub = c.lastValueStream.listen((value) {
              final msg = String.fromCharCodes(value);
              if (msg == "SOS_TRIGGER") {
                onSosTrigger();
              }
            });
          }
        }
      }
    }
  }

  /// 🔁 AUTO-RECONNECT
  void _listenConnectionState({
    required Function onSosTrigger,
    required Function(EspConnectionState) onStateChanged,
  }) {
    _connSub?.cancel();
    _connSub = _device!.connectionState.listen((s) async {
      if (s == BluetoothConnectionState.disconnected &&
          !_manualDisconnect) {
        state = EspConnectionState.scanning;
        onStateChanged(state);

        await Future.delayed(const Duration(seconds: 3));
        await connect(
          onSosTrigger: onSosTrigger,
          onStateChanged: onStateChanged,
        );
      }
    });
  }

  /// 🔴 MANUAL DISCONNECT
  Future<void> disconnect(Function(EspConnectionState) onStateChanged) async {
    _manualDisconnect = true;

    await _scanSub?.cancel();
    await _notifySub?.cancel();
    await _connSub?.cancel();
    await _device?.disconnect();

    state = EspConnectionState.disconnected;
    onStateChanged(state);
  }
}
