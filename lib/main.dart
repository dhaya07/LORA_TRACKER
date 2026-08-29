import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const LoraTrackerApp());
}

// ============================================================
// APP
// ============================================================

class LoraTrackerApp extends StatelessWidget {
  const LoraTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoRa Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1769E0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF172033),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F4F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF1769E0),
              width: 1.2,
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.88,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _openMainPage();
  }

  Future<void> _openMainPage() async {
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DevicePage(),
        transitionDuration: const Duration(milliseconds: 550),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF06172B),
              Color(0xFF0A2A4A),
              Color(0xFF03111F),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -80,
              child: _SplashGlow(
                size: 270,
                opacity: 0.10,
              ),
            ),
            Positioned(
              top: 115,
              left: -105,
              child: _SplashGlow(
                size: 220,
                opacity: 0.07,
              ),
            ),
            const Positioned(
              top: 92,
              left: 38,
              child: _SplashDot(size: 3),
            ),
            const Positioned(
              top: 150,
              right: 48,
              child: _SplashDot(size: 2),
            ),
            const Positioned(
              top: 235,
              left: 72,
              child: _SplashDot(size: 2),
            ),
            const Positioned(
              top: 305,
              right: 32,
              child: _SplashDot(size: 3),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0C365A),
                        border: Border.all(
                          color: const Color(0xFF3EBBFF).withOpacity(0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF19B9FF).withOpacity(0.20),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                const Color(0xFF29B6F6).withOpacity(0.24),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on_rounded,
                            size: 54,
                            color: Colors.white,
                          ),
                          const Positioned(
                            top: 14,
                            child: Icon(
                              Icons.wifi_tethering_rounded,
                              size: 30,
                              color: Color(0xFF35C4FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                      children: [
                        TextSpan(
                          text: 'LoRa ',
                          style: TextStyle(
                            color: Color(0xFF27C2FF),
                          ),
                        ),
                        TextSpan(
                          text: 'Tracker',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Track. Connect. Explore.',
                    style: TextStyle(
                      color: Color(0xFFB8D8EA),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(flex: 1),
                  SizedBox(
                    height: 175,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SplashLandscapePainter(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Column(
                    children: [
                      const SizedBox(
                        width: 170,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20),
                          ),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: Color(0xFF21415B),
                            valueColor:
                            AlwaysStoppedAnimation<Color>(
                              Color(0xFF27C2FF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Establishing connection...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'LONG RANGE • LOW POWER • CONNECTED',
                      style: TextStyle(
                        color: Color(0xFF6E9AB3),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashGlow extends StatelessWidget {
  final double size;
  final double opacity;

  const _SplashGlow({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF2FBFFF).withOpacity(opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

class _SplashDot extends StatelessWidget {
  final double size;

  const _SplashDot({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF55CFFF),
      ),
    );
  }
}

class _SplashLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.78;

    final farMountain = Paint()
      ..color = const Color(0xFF143B59)
      ..style = PaintingStyle.fill;

    final farPath = Path()
      ..moveTo(0, groundY)
      ..lineTo(size.width * 0.18, size.height * 0.38)
      ..lineTo(size.width * 0.30, size.height * 0.60)
      ..lineTo(size.width * 0.46, size.height * 0.28)
      ..lineTo(size.width * 0.62, size.height * 0.60)
      ..lineTo(size.width * 0.78, size.height * 0.40)
      ..lineTo(size.width, size.height * 0.67)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(farPath, farMountain);

    final frontMountain = Paint()
      ..color = const Color(0xFF09263E)
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(0, groundY + 10)
      ..lineTo(size.width * 0.23, size.height * 0.57)
      ..lineTo(size.width * 0.38, size.height * 0.75)
      ..lineTo(size.width * 0.55, size.height * 0.47)
      ..lineTo(size.width * 0.70, size.height * 0.72)
      ..lineTo(size.width * 0.84, size.height * 0.54)
      ..lineTo(size.width, size.height * 0.75)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(frontPath, frontMountain);

    final towerPaint = Paint()
      ..color = const Color(0xFF6D9AB3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final towerX = size.width * 0.50;
    final towerTop = size.height * 0.13;
    final towerBottom = size.height * 0.82;

    canvas.drawLine(
      Offset(towerX, towerTop),
      Offset(towerX - 25, towerBottom),
      towerPaint,
    );

    canvas.drawLine(
      Offset(towerX, towerTop),
      Offset(towerX + 25, towerBottom),
      towerPaint,
    );

    for (var i = 0; i < 5; i++) {
      final y = towerTop + 18 + (i * 15.0);
      final halfWidth = 5 + (i * 4.0);

      canvas.drawLine(
        Offset(towerX - halfWidth, y),
        Offset(towerX + halfWidth, y),
        towerPaint,
      );
    }

    final antennaPaint = Paint()
      ..color = const Color(0xFF35C4FF)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(towerX, towerTop),
      Offset(towerX, towerTop - 17),
      antennaPaint,
    );

    final signalPaint = Paint()
      ..color = const Color(0xFF35C4FF).withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final signalCenter = Offset(
      towerX,
      towerTop - 10,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: signalCenter,
        radius: 17,
      ),
      -2.35,
      1.55,
      false,
      signalPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: signalCenter,
        radius: 27,
      ),
      -2.35,
      1.55,
      false,
      signalPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: signalCenter,
        radius: 37,
      ),
      -2.35,
      1.55,
      false,
      signalPaint,
    );

    final markerCenter = Offset(
      size.width * 0.78,
      size.height * 0.64,
    );

    final markerPaint = Paint()
      ..color = const Color(0xFF27C2FF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      markerCenter,
      7,
      markerPaint,
    );

    final markerRingPaint = Paint()
      ..color = const Color(0xFF27C2FF).withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      markerCenter,
      14,
      markerRingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// LOCATION PACKET MODEL
// ============================================================

class LocationPacket {
  final String deviceId;
  final double latitude;
  final double longitude;
  final String timestamp;
  final int battery;

  const LocationPacket({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.battery,
  });

  // ==========================================================
  // PACKET FORMAT
  //
  // LOC,DeviceID,Latitude,Longitude,Timestamp,Battery
  //
  // Example:
  //
  // LOC,DEV001,28.5985,77.3618,12:35:42,87
  // ==========================================================

  static LocationPacket? parse(String data) {
    try {
      final parts = data.trim().split(',');

      if (parts.length != 6) {
        debugPrint(
          'LOCATION PACKET REJECTED: wrong field count',
        );
        return null;
      }

      if (parts[0].trim().toUpperCase() != 'LOC') {
        return null;
      }

      final deviceId = parts[1].trim();

      if (deviceId.isEmpty) {
        debugPrint(
          'LOCATION PACKET REJECTED: empty device ID',
        );
        return null;
      }

      final latitude = double.tryParse(
        parts[2].trim(),
      );

      final longitude = double.tryParse(
        parts[3].trim(),
      );

      final timestamp = parts[4].trim();

      final battery = int.tryParse(
        parts[5].trim(),
      );

      if (latitude == null ||
          longitude == null ||
          battery == null) {
        debugPrint(
          'LOCATION PACKET REJECTED: invalid data',
        );
        return null;
      }

      if (latitude < -90 || latitude > 90) {
        debugPrint(
          'LOCATION PACKET REJECTED: invalid latitude',
        );
        return null;
      }

      if (longitude < -180 || longitude > 180) {
        debugPrint(
          'LOCATION PACKET REJECTED: invalid longitude',
        );
        return null;
      }

      if (battery < 0 || battery > 100) {
        debugPrint(
          'LOCATION PACKET REJECTED: invalid battery',
        );
        return null;
      }

      return LocationPacket(
        deviceId: deviceId,
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp,
        battery: battery,
      );
    } catch (e) {
      debugPrint(
        'LOCATION PACKET PARSE ERROR: $e',
      );

      return null;
    }
  }
}

// ============================================================
// MESSAGE MODEL
// ============================================================

class ChatMessage {
  final String text;
  final bool fromMe;
  final DateTime time;

  const ChatMessage({
    required this.text,
    required this.fromMe,
    required this.time,
  });
}

// ============================================================
// OFFLINE MBTILES MAP
// ============================================================

class OfflineMapManager {
  static const String assetPath =
      'assets/maps/noida.mbtiles';

  static const String localFileName =
      'noida.mbtiles';

  static Future<MbTilesTileProvider> load() async {
    final directory =
    await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/$localFileName',
    );

    if (!await file.exists()) {
      debugPrint(
        'OFFLINE MAP: Copying MBTiles to device...',
      );

      final byteData =
      await rootBundle.load(assetPath);

      final bytes =
      byteData.buffer.asUint8List();

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      debugPrint(
        'OFFLINE MAP: Copy completed',
      );
    } else {
      debugPrint(
        'OFFLINE MAP: Existing MBTiles found',
      );
    }

    debugPrint(
      'OFFLINE MAP PATH: ${file.path}',
    );

    final provider =
    MbTilesTileProvider.fromPath(
      path: file.path,
    );

    debugPrint(
      'OFFLINE MAP: Provider initialized',
    );

    return provider;
  }
}

// ============================================================
// DEVICE PAGE
// ============================================================

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final List<ScanResult> scanResults = [];

  // ==========================================================
  // RECEIVED LOCATION DATABASE
  //
  // One entry per Device ID.
  //
  // Example:
  //
  // DEV001 -> latest DEV001 location
  // DEV002 -> latest DEV002 location
  //
  // If DEV001 sends another packet, its existing marker moves.
  // ==========================================================

  final Map<String, LocationPacket> receivedLocations = {};

  MbTilesTileProvider? offlineTileProvider;

  bool mapLoading = true;
  String? mapError;

  BluetoothDevice? connectedDevice;

  BluetoothCharacteristic? rxCharacteristic;
  BluetoothCharacteristic? txCharacteristic;

  StreamSubscription<List<ScanResult>>? scanSubscription;

  StreamSubscription<BluetoothConnectionState>?
  connectionSubscription;

  StreamSubscription<List<int>>?
  notificationSubscription;

  String status = 'Disconnected';

  bool isScanning = false;
  bool isConnecting = false;

  // ==========================================================
  // UUIDs
  // ==========================================================

  final Guid serviceUuid = Guid(
    '6E400001-B5A3-F393-E0A9-E50E24DCCA9E',
  );

  final Guid rxUuid = Guid(
    '6E400002-B5A3-F393-E0A9-E50E24DCCA9E',
  );

  final Guid txUuid = Guid(
    '6E400003-B5A3-F393-E0A9-E50E24DCCA9E',
  );

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    scanSubscription =
        FlutterBluePlus.scanResults.listen(
              (results) {
            if (!mounted) return;

            setState(() {
              scanResults.clear();
              scanResults.addAll(results);
            });
          },
        );

    _initializeOfflineMap();
  }

  // ==========================================================
  // INITIALIZE OFFLINE MAP
  // ==========================================================

  Future<void> _initializeOfflineMap() async {
    try {
      debugPrint(
        'OFFLINE MAP: Initializing...',
      );

      final provider =
      await OfflineMapManager.load();

      if (!mounted) {
        provider.dispose();
        return;
      }

      setState(() {
        offlineTileProvider = provider;
        mapLoading = false;
        mapError = null;
      });

      debugPrint(
        'OFFLINE MAP: READY',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'OFFLINE MAP ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        mapLoading = false;
        mapError = e.toString();
      });
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    scanSubscription?.cancel();
    connectionSubscription?.cancel();
    notificationSubscription?.cancel();

    offlineTileProvider?.dispose();

    super.dispose();
  }

  // ==========================================================
  // SCAN
  // ==========================================================

  Future<void> startScan() async {
    if (isScanning) return;

    setState(() {
      scanResults.clear();
      isScanning = true;
      status = 'Scanning for devices...';
    });

    try {
      final bluetoothState =
      await FlutterBluePlus.adapterState.first;

      if (bluetoothState != BluetoothAdapterState.on) {
        if (!mounted) return;

        setState(() {
          status = 'Bluetooth is OFF';
          isScanning = false;
        });

        return;
      }

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
      );

      if (!mounted) return;

      setState(() {
        isScanning = false;

        status = scanResults.isEmpty
            ? 'No devices found'
            : '${scanResults.length} device(s) found';
      });
    } catch (e) {
      debugPrint(
        'SCAN ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isScanning = false;
        status = 'Scan failed';
      });
    }
  }

  // ==========================================================
  // CONNECT
  // ==========================================================

  Future<void> connectToDevice(
      BluetoothDevice device) async {
    if (isConnecting) return;

    if (connectedDevice != null) {
      if (connectedDevice!.remoteId ==
          device.remoteId) {
        return;
      }

      await disconnectDevice();
    }

    setState(() {
      isConnecting = true;
      status = 'Connecting...';
    });

    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        license: License.free,
      );

      connectedDevice = device;

      debugPrint(
        'CONNECTED: ${device.platformName}',
      );

      // --------------------------------------------------------
      // Connection state listener
      // --------------------------------------------------------

      await connectionSubscription?.cancel();

      connectionSubscription =
          device.connectionState.listen(
                (state) {
              debugPrint(
                'Connection state: $state',
              );

              if (!mounted) return;

              if (state ==
                  BluetoothConnectionState.connected) {
                setState(() {
                  status = 'Connected';
                });
              } else {
                setState(() {
                  status = 'Disconnected';
                  connectedDevice = null;
                  rxCharacteristic = null;
                  txCharacteristic = null;
                });
              }
            },
          );

      // --------------------------------------------------------
      // Discover BLE services
      // --------------------------------------------------------

      await discoverServices(device);

      if (rxCharacteristic == null ||
          txCharacteristic == null) {
        throw Exception(
          'Required BLE characteristics not found',
        );
      }

      if (!mounted) return;

      setState(() {
        isConnecting = false;
        status = 'Connected';
      });

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // NO CHAT NAVIGATION HERE.
      //
      // User must press CHAT manually.
      // --------------------------------------------------------

    } catch (e, stackTrace) {
      debugPrint(
        'CONNECTION ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      await cleanupBle();

      try {
        await device.disconnect();
      } catch (_) {
        // Device may already be disconnected.
      }

      if (!mounted) return;

      setState(() {
        isConnecting = false;
        connectedDevice = null;
        status = 'Connection failed';
      });
    }
  }

  // ==========================================================
  // DISCOVER SERVICES
  // ==========================================================

  Future<void> discoverServices(
      BluetoothDevice device) async {
    debugPrint(
      '========== SERVICE DISCOVERY ==========',
    );

    final services =
    await device.discoverServices();

    BluetoothCharacteristic? foundRx;
    BluetoothCharacteristic? foundTx;

    for (final service in services) {
      debugPrint(
        'SERVICE: ${service.uuid}',
      );

      if (service.uuid != serviceUuid) {
        continue;
      }

      for (final characteristic
      in service.characteristics) {
        debugPrint(
          'CHARACTERISTIC: ${characteristic.uuid}',
        );

        // ------------------------------------------------------
        // PHONE -> ESP32
        // ------------------------------------------------------

        if (characteristic.uuid == rxUuid) {
          foundRx = characteristic;

          debugPrint(
            'RX CHARACTERISTIC FOUND',
          );
        }

        // ------------------------------------------------------
        // ESP32 -> PHONE
        // ------------------------------------------------------

        if (characteristic.uuid == txUuid) {
          foundTx = characteristic;

          debugPrint(
            'TX CHARACTERISTIC FOUND',
          );
        }
      }
    }

    if (foundRx == null) {
      throw Exception(
        'RX characteristic not found',
      );
    }

    if (foundTx == null) {
      throw Exception(
        'TX characteristic not found',
      );
    }

    rxCharacteristic = foundRx;
    txCharacteristic = foundTx;

    // ========================================================
    // LISTENER CREATED BEFORE NOTIFICATIONS ENABLED
    // ========================================================

    await notificationSubscription?.cancel();

    notificationSubscription =
        txCharacteristic!.onValueReceived.listen(
          handleIncomingBleData,
          onError: (error) {
            debugPrint(
              'BLE NOTIFICATION ERROR: $error',
            );
          },
          cancelOnError: false,
        );

    // --------------------------------------------------------
    // Enable notifications
    // --------------------------------------------------------

    await txCharacteristic!.setNotifyValue(true);

    debugPrint(
      'TX NOTIFICATIONS ENABLED',
    );

    debugPrint(
      '========== SERVICE DISCOVERY END ==========',
    );
  }

  // ==========================================================
  // BLE RECEIVE
  // ==========================================================

  void handleIncomingBleData(
      List<int> value) {
    if (value.isEmpty) return;

    final message = utf8.decode(
      value,
      allowMalformed: true,
    ).trim();

    if (message.isEmpty) return;

    debugPrint(
      '================================',
    );

    debugPrint(
      'BLE DATA RECEIVED',
    );

    debugPrint(
      'DATA: $message',
    );

    debugPrint(
      '================================',
    );

    // ========================================================
    // LOCATION PACKET
    //
    // LOC,DeviceID,Latitude,Longitude,Timestamp,Battery
    // ========================================================

    final packet =
    LocationPacket.parse(message);

    if (packet != null) {
      debugPrint(
        'LOCATION PACKET DETECTED',
      );

      debugPrint(
        'Device ID : ${packet.deviceId}',
      );

      debugPrint(
        'Latitude  : ${packet.latitude}',
      );

      debugPrint(
        'Longitude : ${packet.longitude}',
      );

      debugPrint(
        'Timestamp : ${packet.timestamp}',
      );

      debugPrint(
        'Battery   : ${packet.battery}%',
      );

      if (!mounted) return;

      setState(() {
        receivedLocations[packet.deviceId] =
            packet;
      });

      return;
    }

    // --------------------------------------------------------
    // Normal text packet.
    //
    // Do not put it into the map.
    // ChatPage handles normal messages when open.
    // --------------------------------------------------------

    debugPrint(
      'NORMAL BLE MESSAGE',
    );
  }

  // ==========================================================
  // CLEAN BLE
  // ==========================================================

  Future<void> cleanupBle() async {
    await notificationSubscription?.cancel();

    notificationSubscription = null;

    await connectionSubscription?.cancel();

    connectionSubscription = null;

    rxCharacteristic = null;
    txCharacteristic = null;
  }

  // ==========================================================
  // DISCONNECT
  // ==========================================================

  Future<void> disconnectDevice() async {
    debugPrint(
      'Disconnecting device...',
    );

    final device = connectedDevice;

    await cleanupBle();

    if (device != null) {
      try {
        await device.disconnect();
      } catch (e) {
        debugPrint(
          'Disconnect error: $e',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      connectedDevice = null;
      status = 'Disconnected';
      isConnecting = false;
    });
  }

  // ==========================================================
  // DEVICE NAME
  // ==========================================================

  String getDeviceName(
      BluetoothDevice device) {
    final name = device.platformName;

    if (name.isNotEmpty) {
      return name;
    }

    return 'ESP32 Device';
  }

  // ==========================================================
  // OFFLINE MAP
  // ==========================================================

  Widget _buildOfflineMap() {
    // --------------------------------------------------------
    // Loading
    // --------------------------------------------------------

    if (mapLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading offline map...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF697487),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // --------------------------------------------------------
    // Error
    // --------------------------------------------------------

    if (offlineTileProvider == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 40,
                color: Color(0xFF9AA3B2),
              ),
              const SizedBox(height: 10),
              const Text(
                'Offline map unavailable',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF303A4D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mapError ?? 'Unknown map error',
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8A94A4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --------------------------------------------------------
    // MARKERS
    // --------------------------------------------------------

    final List<Marker> markers = [];

    // ========================================================
    // PHONE / TEST LOCATION
    // ========================================================

    markers.add(
      Marker(
        point: const LatLng(
          28.5970,
          77.3595,
        ),
        width: 70,
        height: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1769E0),
                borderRadius:
                BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black26,
                  ),
                ],
              ),
              child: const Text(
                'PHONE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF1769E0),
              size: 38,
            ),
          ],
        ),
      ),
    );

    // ========================================================
    // RECEIVED DEVICES
    // ========================================================

    for (final packet
    in receivedLocations.values) {
      markers.add(
        Marker(
          point: LatLng(
            packet.latitude,
            packet.longitude,
          ),
          width: 95,
          height: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints:
                const BoxConstraints(
                  maxWidth: 90,
                ),
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius:
                  BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 4,
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: Text(
                  packet.deviceId,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFD64545),
                size: 38,
              ),
            ],
          ),
        ),
      );
    }

    // ========================================================
    // MAP
    // ========================================================

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(
          28.5970,
          77.3595,
        ),
        initialZoom: 13,
        minZoom: 10,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          tileProvider: offlineTileProvider!,
          tileSize: 256,
        ),
        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LoRa Tracker',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Scan',
            onPressed:
            isScanning ? null : startScan,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ====================================================
          // STATUS
          // ====================================================

          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE7EBF0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                      connectedDevice != null
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        Color(0xFF303A4D),
                      ),
                    ),
                  ),
                  if (isScanning)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ====================================================
          // MAP
          // ====================================================

          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              10,
            ),
            child: SizedBox(
              height: 280,
              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(14),
                child: Container(
                  color:
                  const Color(0xFFE9EDF2),
                  child:
                  _buildOfflineMap(),
                ),
              ),
            ),
          ),

          // ====================================================
          // DEVICES TITLE
          // ====================================================

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              children: [
                const Text(
                  'Nearby Devices',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF202A3A),
                  ),
                ),
                const Spacer(),
                Text(
                  '${scanResults.length} found',
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF7B8493),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ====================================================
          // DEVICE LIST
          // ====================================================

          Expanded(
            child: scanResults.isEmpty
                ? Center(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bluetooth_disabled,
                    size: 34,
                    color:
                    Color(0xFF9AA3B2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No devices found',
                    style:
                    TextStyle(
                      fontSize: 14,
                      color:
                      Color(0xFF727C8D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed:
                    isScanning
                        ? null
                        : startScan,
                    child:
                    const Text('SCAN'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16,
              ),
              itemCount:
              scanResults.length,
              itemBuilder:
                  (context, index) {
                final result =
                scanResults[index];

                final device =
                    result.device;

                final isConnected =
                    connectedDevice != null &&
                        connectedDevice!
                            .remoteId ==
                            device.remoteId;

                return Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: _DeviceCard(
                    name:
                    getDeviceName(
                      device,
                    ),
                    id: device.remoteId
                        .toString(),
                    rssi: result.rssi,
                    connected:
                    isConnected,
                    connecting:
                    isConnecting,

                    // ----------------------------
                    // CONNECT
                    // ----------------------------

                    onConnect: () {
                      connectToDevice(
                        device,
                      );
                    },

                    // ----------------------------
                    // DISCONNECT
                    // ----------------------------

                    onDisconnect:
                    disconnectDevice,

                    // ----------------------------
                    // CHAT
                    // ----------------------------

                    onChat:
                    isConnected &&
                        rxCharacteristic !=
                            null
                        ? () {
                      Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder:
                              (_) =>
                              ChatPage(
                                device:
                                device,
                                rxCharacteristic:
                                rxCharacteristic!,
                                onDisconnect:
                                disconnectDevice,
                              ),
                        ),
                      );
                    }
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DEVICE CARD
// ============================================================

class _DeviceCard extends StatelessWidget {
  final String name;
  final String id;
  final int rssi;

  final bool connected;
  final bool connecting;

  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback? onChat;

  const _DeviceCard({
    required this.name,
    required this.id,
    required this.rssi,
    required this.connected,
    required this.connecting,
    required this.onConnect,
    required this.onDisconnect,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: connected
              ? const Color(0xFF1769E0)
              .withOpacity(0.35)
              : const Color(0xFFE5E9EF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
              const Color(0xFFEFF4FC),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.developer_board_outlined,
              size: 22,
              color:
              Color(0xFF1769E0),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF202A3A),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  id,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 10,
                    color:
                    Color(0xFF8A94A4),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'RSSI $rssi dBm',
                  style:
                  const TextStyle(
                    fontSize: 10,
                    color:
                    Color(0xFF727C8D),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ==================================================
          // CONNECTED
          // ==================================================

          if (connected)
            Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                // --------------------------------------------
                // CHAT
                // --------------------------------------------

                SizedBox(
                  height: 34,
                  child:
                  OutlinedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(
                      Icons
                          .chat_bubble_outline_rounded,
                      size: 15,
                    ),
                    label: const Text(
                      'CHAT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    style:
                    OutlinedButton
                        .styleFrom(
                      foregroundColor:
                      const Color(
                        0xFF1769E0,
                      ),
                      side:
                      const BorderSide(
                        color:
                        Color(
                          0xFF1769E0,
                        ),
                      ),
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 9,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          8,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // --------------------------------------------
                // DISCONNECT
                // --------------------------------------------

                SizedBox(
                  height: 34,
                  child:
                  ElevatedButton(
                    onPressed:
                    onDisconnect,
                    style:
                    ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      const Color(
                        0xFFFCECEC,
                      ),
                      foregroundColor:
                      const Color(
                        0xFFD64545,
                      ),
                      elevation: 0,
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 9,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          8,
                        ),
                      ),
                    ),
                    child:
                    const Text(
                      'DISCONNECT',
                      style:
                      TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )

          // ==================================================
          // NOT CONNECTED
          // ==================================================

          else
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed:
                connecting
                    ? null
                    : onConnect,
                style:
                ElevatedButton
                    .styleFrom(
                  elevation: 0,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 13,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                  ),
                ),
                child: Text(
                  connecting
                      ? '...'
                      : 'CONNECT',
                  style:
                  const TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAT PAGE
// ============================================================

class ChatPage extends StatefulWidget {
  final BluetoothDevice device;

  final BluetoothCharacteristic
  rxCharacteristic;

  final Future<void> Function()
  onDisconnect;

  const ChatPage({
    super.key,
    required this.device,
    required this.rxCharacteristic,
    required this.onDisconnect,
  });

  @override
  State<ChatPage> createState() =>
      _ChatPageState();
}

class _ChatPageState
    extends State<ChatPage> {
  final TextEditingController
  messageController =
  TextEditingController();

  final ScrollController
  chatScrollController =
  ScrollController();

  final List<ChatMessage> messages = [];

  BluetoothCharacteristic?
  txCharacteristic;

  StreamSubscription<List<int>>?
  notificationSubscription;

  bool isConnected = true;
  bool isSending = false;

  final Guid txUuid = Guid(
    '6E400003-B5A3-F393-E0A9-E50E24DCCA9E',
  );

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    setupNotifications();
  }

  // ==========================================================
  // SETUP NOTIFICATIONS
  // ==========================================================

  Future<void> setupNotifications() async {
    try {
      debugPrint(
        'CHAT: discovering services...',
      );

      final services =
      await widget.device
          .discoverServices();

      for (final service
      in services) {
        for (final characteristic
        in service
            .characteristics) {
          if (characteristic.uuid ==
              txUuid) {
            txCharacteristic =
                characteristic;

            break;
          }
        }
      }

      if (txCharacteristic == null) {
        debugPrint(
          'CHAT: TX characteristic not found',
        );

        return;
      }

      await notificationSubscription
          ?.cancel();

      notificationSubscription =
          txCharacteristic!
              .onValueReceived
              .listen(
            handleIncomingBleData,
            onError: (error) {
              debugPrint(
                'Notification error: $error',
              );
            },
            cancelOnError: false,
          );

      debugPrint(
        'CHAT: notification listener created',
      );

      await txCharacteristic!
          .setNotifyValue(true);

      debugPrint(
        'CHAT: notifications ENABLED',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'CHAT notification setup error: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );
    }
  }

  // ==========================================================
  // BLE RECEIVE
  // ==========================================================

  void handleIncomingBleData(
      List<int> value) {
    if (value.isEmpty) return;

    final message = utf8.decode(
      value,
      allowMalformed: true,
    ).trim();

    if (message.isEmpty) return;

    debugPrint(
      '================================',
    );

    debugPrint(
      'CHAT BLE DATA RECEIVED',
    );

    debugPrint(
      'DATA: $message',
    );

    debugPrint(
      '================================',
    );

    // --------------------------------------------------------
    // Ignore location packets here.
    //
    // DevicePage handles location packets.
    // --------------------------------------------------------

    final locationPacket =
    LocationPacket.parse(
      message,
    );

    if (locationPacket != null) {
      debugPrint(
        'CHAT: Location packet ignored here.',
      );

      return;
    }

    // --------------------------------------------------------
    // Normal chat message
    // --------------------------------------------------------

    if (!mounted) return;

    setState(() {
      messages.add(
        ChatMessage(
          text: message,
          fromMe: false,
          time: DateTime.now(),
        ),
      );
    });

    scrollChatToBottom();
  }

  // ==========================================================
  // SEND MESSAGE
  // ==========================================================

  Future<void> sendChatMessage(
      String message) async {
    message = message.trim();

    if (message.isEmpty) return;

    if (!isConnected) return;

    if (isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      await widget.rxCharacteristic
          .write(
        utf8.encode(message),
        withoutResponse: false,
      );

      debugPrint(
        '================================',
      );

      debugPrint(
        'MESSAGE SENT TO ESP32',
      );

      debugPrint(message);

      debugPrint(
        '================================',
      );

      if (!mounted) return;

      setState(() {
        messages.add(
          ChatMessage(
            text: message,
            fromMe: true,
            time: DateTime.now(),
          ),
        );

        messageController.clear();

        isSending = false;
      });

      scrollChatToBottom();
    } catch (e) {
      debugPrint(
        'SEND ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isSending = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to send message',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // DISCONNECT
  // ==========================================================

  Future<void>
  disconnectFromChat() async {
    await notificationSubscription
        ?.cancel();

    notificationSubscription = null;

    try {
      await widget.device.disconnect();
    } catch (e) {
      debugPrint(
        'Disconnect error: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      isConnected = false;
    });

    Navigator.of(context).pop();
  }

  // ==========================================================
  // SCROLL
  // ==========================================================

  void scrollChatToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) {
        if (!chatScrollController
            .hasClients) {
          return;
        }

        chatScrollController
            .animateTo(
          chatScrollController
              .position
              .maxScrollExtent,
          duration:
          const Duration(
            milliseconds: 220,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ==========================================================
  // TIME
  // ==========================================================

  String formatTime(
      DateTime time) {
    final hour = time.hour
        .toString()
        .padLeft(2, '0');

    final minute = time.minute
        .toString()
        .padLeft(2, '0');

    return '$hour:$minute';
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    notificationSubscription
        ?.cancel();

    messageController.dispose();

    chatScrollController
        .dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            Navigator.of(context)
                .pop();
          },
        ),

        titleSpacing: 0,

        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                const Color(
                  0xFFEFF4FC,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  10,
                ),
              ),
              child: const Icon(
                Icons.developer_board,
                size: 19,
                color:
                Color(
                  0xFF1769E0,
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    widget.device
                        .platformName
                        .isNotEmpty
                        ? widget.device
                        .platformName
                        : 'ESP32 Device',
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration:
                        const BoxDecoration(
                          shape:
                          BoxShape
                              .circle,
                          color:
                          Colors.green,
                        ),
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      const Text(
                        'Connected',
                        style:
                        TextStyle(
                          fontSize: 10,
                          color:
                          Color(
                            0xFF6D7787,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ====================================================
          // CHAT INFO
          // ====================================================

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 16,
              vertical: 9,
            ),
            decoration:
            const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom:
                BorderSide(
                  color:
                  Color(
                    0xFFE8ECF1,
                  ),
                ),
              ),
            ),
            child: Text(
              widget.device
                  .remoteId
                  .toString(),
              style:
              const TextStyle(
                fontSize: 10,
                color:
                Color(
                  0xFF8993A2,
                ),
              ),
            ),
          ),

          // ====================================================
          // MESSAGES
          // ====================================================

          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Column(
                mainAxisSize:
                MainAxisSize
                    .min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFEFF4FC,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                    ),
                    child:
                    const Icon(
                      Icons
                          .chat_bubble_outline,
                      size: 28,
                      color:
                      Color(
                        0xFF1769E0,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'No messages yet',
                    style:
                    TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight
                          .w600,
                      color:
                      Color(
                        0xFF697487,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  const Text(
                    'Send a message to the ESP32',
                    style:
                    TextStyle(
                      fontSize: 11,
                      color:
                      Color(
                        0xFF9AA3B1,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller:
              chatScrollController,
              padding:
              const EdgeInsets
                  .fromLTRB(
                12,
                14,
                12,
                12,
              ),
              itemCount:
              messages.length,
              itemBuilder:
                  (context, index) {
                final message =
                messages[index];

                return _ChatBubble(
                  message:
                  message,
                  time:
                  formatTime(
                    message.time,
                  ),
                );
              },
            ),
          ),

          // ====================================================
          // INPUT
          // ====================================================

          SafeArea(
            child: Container(
              padding:
              const EdgeInsets
                  .fromLTRB(
                10,
                8,
                10,
                8,
              ),
              decoration:
              const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color:
                    Color(
                      0xFFE8ECF1,
                    ),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .end,
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      messageController,
                      enabled:
                      isConnected &&
                          !isSending,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction:
                      TextInputAction
                          .newline,
                      decoration:
                      const InputDecoration(
                        hintText:
                        'Type a message...',
                        hintStyle:
                        TextStyle(
                          fontSize: 13,
                          color:
                          Color(
                            0xFF9AA3B1,
                          ),
                        ),
                        contentPadding:
                        EdgeInsets
                            .symmetric(
                          horizontal: 15,
                          vertical: 11,
                        ),
                      ),
                      onSubmitted:
                          (value) {
                        sendChatMessage(
                          value,
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  SizedBox(
                    width: 45,
                    height: 45,
                    child:
                    FilledButton(
                      onPressed:
                      isConnected &&
                          !isSending
                          ? () {
                        sendChatMessage(
                          messageController
                              .text,
                        );
                      }
                          : null,
                      style:
                      FilledButton
                          .styleFrom(
                        padding:
                        EdgeInsets.zero,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            13,
                          ),
                        ),
                      ),
                      child: isSending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color:
                          Colors
                              .white,
                        ),
                      )
                          : const Icon(
                        Icons
                            .send_rounded,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAT BUBBLE
// ============================================================

class _ChatBubble
    extends StatelessWidget {
  final ChatMessage message;
  final String time;

  const _ChatBubble({
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      message.fromMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
        BoxConstraints(
          maxWidth:
          MediaQuery.of(context)
              .size
              .width *
              0.76,
        ),
        margin:
        const EdgeInsets.only(
          bottom: 8,
        ),
        padding:
        const EdgeInsets.fromLTRB(
          12,
          9,
          10,
          7,
        ),
        decoration:
        BoxDecoration(
          color: message.fromMe
              ? const Color(
            0xFF1769E0,
          )
              : Colors.white,
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          border: message.fromMe
              ? null
              : Border.all(
            color:
            const Color(
              0xFFE3E8EF,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .end,
          children: [
            Align(
              alignment:
              Alignment.centerLeft,
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: message.fromMe
                      ? Colors.white
                      : const Color(
                    0xFF273142,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              time,
              style: TextStyle(
                fontSize: 9,
                color: message.fromMe
                    ? Colors.white70
                    : const Color(
                  0xFF929BA9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}