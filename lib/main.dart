import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

Future<void> requestBLEPermissions() async {
  await FlutterBluePlus.adapterState.first;
}
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BLEHome(),
    );
  }
}

class BLEHome extends StatefulWidget {
  const BLEHome({super.key});

  @override
  State<BLEHome> createState() => _BLEHomeState();
}

class _BLEHomeState extends State<BLEHome> {
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  String lat = "0.0";
  String lon = "0.0";
  final msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      lat = position.latitude.toString();
      lon = position.longitude.toString();
    });
  }

  void startScan() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (r.device.platformName == "ESP32_GPS_NODE") {
          device = r.device;
          connectToDevice();
          FlutterBluePlus.stopScan();
        }
      }
    });
  }

  void connectToDevice() async {
    await device!.connect();

    List<BluetoothService> services = await device!.discoverServices();

    for (var service in services) {
      for (var c in service.characteristics) {
        if (c.properties.write) {
          characteristic = c;
        }
      }
    }

    setState(() {});
  }

  void sendData() async {
    if (characteristic == null) return;

    String message =
        "$lat,$lon|${msgController.text}";

    await characteristic!.write(message.codeUnits);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE GPS Sender")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Latitude: $lat"),
            Text("Longitude: $lon"),
            const SizedBox(height: 20),

            TextField(
              controller: msgController,
              decoration: const InputDecoration(
                labelText: "Message",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: startScan,
              child: const Text("Scan & Connect ESP32"),
            ),

            ElevatedButton(
              onPressed: sendData,
              child: const Text("Send Data"),
            ),
          ],
        ),
      ),
    );
  }
}