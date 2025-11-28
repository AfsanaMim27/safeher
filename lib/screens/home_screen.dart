import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentLocation = "Press SOS to get location";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("SafeHer"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              })
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "Your Location",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              currentLocation,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.all(40),
                  shape: const CircleBorder(),
                ),
                onPressed: () async {
                  Position pos = await _getLocation();
                  setState(() {
                    currentLocation = 
                      "Lat: ${pos.latitude}, Lng: ${pos.longitude}";
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Location Fetched")),
                  );
                },
                child: const Text(
                  "SOS",
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // GPS Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled.");
    }

    // Permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location permission permanently denied.");
    }

    // Get Position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}