import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/sos_service.dart';
import '../services/location_permission_service.dart';
import '../services/ble_sos_listener.dart';
import '../controllers/sos_controller.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool sosActive = false;
  String? activeSosId;

  EspConnectionState espState = EspConnectionState.disconnected;
  final BleSosListener _ble = BleSosListener();

  String get espStatusText {
    switch (espState) {
      case EspConnectionState.scanning:
        return "Scanning for ESP32…";
      case EspConnectionState.connecting:
        return "Connecting to ESP32…";
      case EspConnectionState.connected:
        return "ESP32 Connected";
      case EspConnectionState.failed:
        return "ESP32 Not Found / Failed";
      default:
        return "ESP32 Disconnected";
    }
  }

  Color get espStatusColor {
    switch (espState) {
      case EspConnectionState.connected:
        return Colors.green;
      case EspConnectionState.failed:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (!authSnap.hasData) return const LoginScreen();

        final user = authSnap.data!;
        PermissionService.requestLocationOnce();

        return StreamBuilder<AppUser>(
          stream: UserService().getUser(user.uid),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final appUser = userSnap.data!;

            return Scaffold(
              appBar: AppBar(
                title: const Text("SafeHer"),
                backgroundColor: Colors.red,
                actions: [
                  IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()));
                        }
                      })
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome, ${appUser.name}",
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text("Gender: ${appUser.gender}"),
                    Text("Emergency Phone Number: ${appUser.phone}"),
                    const SizedBox(height: 20),
                    Text(
                      "ESP32 Status: $espStatusText",
                      style: TextStyle(
                        color: espStatusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// CONNECT / DISCONNECT ESP
                        ElevatedButton(
                          onPressed: () async {
                            if (espState != EspConnectionState.connected) {
                              await _ble.connect(
                                onSosTrigger: () async {
                                  final sosId =
                                      await SosController.triggerFromESP32(
                                          appUser: appUser);

                                  if (sosId != null && mounted) {
                                    setState(() {
                                      sosActive = true;
                                      activeSosId = sosId;
                                    });
                                  }
                                },
                                onStateChanged: (s) {
                                  if (!mounted) return;
                                  setState(() => espState = s);
                                },
                              );
                            } else {
                              await _ble.disconnect((s) {
                                if (!mounted) return;
                                setState(() => espState = s);
                              });
                            }
                          },
                          child: Text(
                            espState == EspConnectionState.connected
                                ? "DISCONNECT ESP32"
                                : "CONNECT ESP32",
                          ),
                        ),

                        const SizedBox(width: 12),

                        /// NEW BUTTON
                        ElevatedButton(
                          onPressed: () =>
                              _showEmergencyDialog(context, appUser),
                          child: const Text("Change Emergency Number"),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!sosActive)
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 80, vertical: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () async {
                            final sosId = await SosController.triggerFromUI(
                              context: context,
                              appUser: appUser,
                            );
                            if (sosId != null) {
                              setState(() {
                                sosActive = true;
                                activeSosId = sosId;
                              });
                            }
                          },
                          child: const Text(
                            "SOS",
                            style: TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (sosActive)
                      Center(
                        child: ElevatedButton(
                          onPressed: () => _showDeactivateDialog(context),
                          child: const Text("Deactivate SOS"),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Deactivation"),
        content: TextField(
          controller: controller,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await SosService().deactivateSOS(
                sosId: activeSosId!,
                password: controller.text.trim(),
              );

              setState(() {
                sosActive = false;
                activeSosId = null;
              });

              SosController.reset();
              Navigator.pop(context);
            },
            child: const Text("Deactivate"),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context, AppUser appUser) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Emergency Number"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: "Enter phone number",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          /// SAVE BUTTON
          TextButton(
            onPressed: () async {
              final number = controller.text.trim();

              if (number.isEmpty) return;

              await SosService().saveEmergencyNumber(appUser, number);

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Emergency number saved")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
