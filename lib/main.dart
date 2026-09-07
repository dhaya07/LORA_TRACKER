
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart'
as vt;
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:path_provider/path_provider.dart';

import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

// ============================================================
// LANGUAGE
// ============================================================

final ValueNotifier<bool> languageNotifier = ValueNotifier<bool>(false);

String tr(String english, String tamil) {
  return languageNotifier.value ? tamil : english;
}

String trStatus(String status) {
  final foundMatch = RegExp(r'^(\d+) device\(s\) found$').firstMatch(status);
  if (foundMatch != null) {
    final count = foundMatch.group(1)!;
    return languageNotifier.value
        ? '$count சாதனங்கள் கிடைத்தன'
        : '$count device(s) found';
  }

  switch (status) {
    case 'Disconnected':
      return tr('Disconnected', 'துண்டிக்கப்பட்டது');
    case 'Checking Bluetooth...':
      return tr('Checking Bluetooth...', 'ப்ளூடூத்தை சரிபார்க்கிறது...');
    case 'Bluetooth is OFF':
      return tr('Bluetooth is OFF', 'ப்ளூடூத் அணைக்கப்பட்டுள்ளது');
    case 'Turn ON Location to scan Bluetooth':
      return tr('Turn ON Location to scan Bluetooth', 'ப்ளூடூத் சாதனங்களைத் தேட இருப்பிடத்தை இயக்கவும்');
    case 'Location permission required':
      return tr('Location permission required', 'இருப்பிட அனுமதி தேவை');
    case 'Scanning for devices...':
      return tr('Scanning for devices...', 'சாதனங்களைத் தேடுகிறது...');
    case 'No devices found':
      return tr('No devices found', 'சாதனங்கள் எதுவும் கிடைக்கவில்லை');
    case 'Scan failed':
      return tr('Scan failed', 'தேடல் தோல்வியடைந்தது');
    case 'Connecting...':
      return tr('Connecting...', 'இணைக்கிறது...');
    case 'Connected':
      return tr('Connected', 'இணைக்கப்பட்டுள்ளது');
    case 'Connection failed':
      return tr('Connection failed', 'இணைப்பு தோல்வியடைந்தது');
    default:
      return status;
  }
}

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
                  Text(tr('Track. Connect. Explore.', 'கண்காணி. இணை. ஆராய்.'),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF27C2FF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('Establishing connection...', 'இணைப்பை நிறுவுகிறது...'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      tr('LONG RANGE • LOW POWER • CONNECTED', 'நீண்ட தூரம் • குறைந்த மின்சாரம் • இணைக்கப்பட்டது'),
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
// OFFLINE VECTOR MAP STYLE
// ============================================================
// This is a local MapLibre-style theme.
// The tile provider is the local Sathyamangalam PMTiles archive.
// No internet connection is required.

final Map<String, Object?> _offlineMapStyle = {
  'version': 8,
  'sources': {
    'protomaps': {
      'type': 'vector',
    },
  },
  'layers': [
    {
      'id': 'background',
      'type': 'background',
      'paint': {
        'background-color': '#F5F7FA',
      },
    },
    {
      'id': 'landcover',
      'type': 'fill',
      'source': 'protomaps',
      'source-layer': 'landcover',
      'paint': {
        'fill-color': '#E8F0E4',
        'fill-opacity': 0.72,
      },
    },
    {
      'id': 'landuse',
      'type': 'fill',
      'source': 'protomaps',
      'source-layer': 'landuse',
      'paint': {
        'fill-color': '#EAF0E7',
        'fill-opacity': 0.72,
      },
    },
    {
      'id': 'park',
      'type': 'fill',
      'source': 'protomaps',
      'source-layer': 'park',
      'paint': {
        'fill-color': '#DDECD8',
        'fill-opacity': 0.9,
      },
    },
    {
      'id': 'water',
      'type': 'fill',
      'source': 'protomaps',
      'source-layer': 'water',
      'paint': {
        'fill-color': '#CFE8F7',
      },
    },
    {
      'id': 'waterway',
      'type': 'line',
      'source': 'protomaps',
      'source-layer': 'waterway',
      'paint': {
        'line-color': '#9ED0EA',
        'line-width': 1.4,
      },
    },
    {
      'id': 'building',
      'type': 'fill',
      'source': 'protomaps',
      'source-layer': 'building',
      'paint': {
        'fill-color': '#E3E6EA',
        'fill-opacity': 0.9,
      },
    },
    {
      'id': 'transportation-casing',
      'type': 'line',
      'source': 'protomaps',
      'source-layer': 'transportation',
      'paint': {
        'line-color': '#C9CED6',
        'line-width': 4.2,
      },
    },
    {
      'id': 'transportation',
      'type': 'line',
      'source': 'protomaps',
      'source-layer': 'transportation',
      'paint': {
        'line-color': '#FFFFFF',
        'line-width': 2.2,
      },
    },
    {
      'id': 'transportation-name',
      'type': 'symbol',
      'source': 'protomaps',
      'source-layer': 'transportation_name',
      'layout': {
        'text-field': '{name}',
        'text-size': 10,
        'text-allow-overlap': false,
      },
      'paint': {
        'text-color': '#555B66',
        'text-halo-color': '#FFFFFF',
        'text-halo-width': 1.2,
      },
    },
    {
      'id': 'water-name',
      'type': 'symbol',
      'source': 'protomaps',
      'source-layer': 'water_name',
      'layout': {
        'text-field': '{name}',
        'text-size': 10,
      },
      'paint': {
        'text-color': '#4E8FB0',
        'text-halo-color': '#FFFFFF',
        'text-halo-width': 1,
      },
    },
    {
      'id': 'place-labels',
      'type': 'symbol',
      'source': 'protomaps',
      'source-layer': 'place',
      'layout': {
        'text-field': '{name}',
        'text-size': 12,
        'text-allow-overlap': false,
      },
      'paint': {
        'text-color': '#3F4652',
        'text-halo-color': '#FFFFFF',
        'text-halo-width': 1.5,
      },
    },
    {
      'id': 'poi-labels',
      'type': 'symbol',
      'source': 'protomaps',
      'source-layer': 'poi',
      'layout': {
        'text-field': '{name}',
        'text-size': 9,
        'text-allow-overlap': false,
      },
      'paint': {
        'text-color': '#5B6470',
        'text-halo-color': '#FFFFFF',
        'text-halo-width': 1,
      },
    },
    {
      'id': 'aerodrome-label',
      'type': 'symbol',
      'source': 'protomaps',
      'source-layer': 'aerodrome_label',
      'layout': {
        'text-field': '{name}',
        'text-size': 10,
      },
      'paint': {
        'text-color': '#596273',
        'text-halo-color': '#FFFFFF',
        'text-halo-width': 1,
      },
    },
  ],
};

// ============================================================
// OFFLINE PMTILES MAP MANAGER
// ============================================================

class OfflineMapManager {
  static const String assetPath =
      'assets/maps/Sathya.pmtiles';

  static const String localFileName =
      'Sathya.pmtiles';

  HttpServer? _server;
  File? _file;

  Future<String> start() async {
    final directory =
    await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/$localFileName',
    );

    // The map asset is versioned so an existing installation does not
    // accidentally keep an older PMTiles file after an APK update.
    const assetVersion = 'sathya_v2';
    final versionFile = File(
      '${directory.path}/sathya_map_version.txt',
    );

    final installedVersion =
    await versionFile.exists()
        ? (await versionFile.readAsString()).trim()
        : '';

    if (!await file.exists() || installedVersion != assetVersion) {
      debugPrint(
        'PMTILES: Installing $localFileName ($assetVersion)...',
      );

      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      final tempFile = File('${file.path}.tmp');
      await tempFile.writeAsBytes(bytes, flush: true);

      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(file.path);
      await versionFile.writeAsString(assetVersion, flush: true);

      debugPrint('PMTILES: Map installation completed');
    } else {
      debugPrint(
        'PMTILES: Existing $localFileName ($installedVersion) found',
      );
    }

    _file = file;

    debugPrint('PMTILES PATH: ${file.path}');
    debugPrint(
      'PMTILES SIZE: ${await file.length()} bytes',
    );

    // flutter_map_vector_tiles 2.8.1 opens PMTiles through an HTTP
    // tile source. Android cannot use an absolute filesystem path as
    // an HTTP URI, so expose the local PMTiles file through a tiny
    // loopback HTTP server. The server supports HTTP Range requests,
    // which PMTiles uses to read only the required portions of the file.
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );

    _server!.listen(_handleRequest);

    final port = _server!.port;
    final url = 'http://127.0.0.1:$port/$localFileName';

    debugPrint('PMTILES LOCAL SERVER: $url');

    return url;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    final file = _file;

    if (file == null ||
        request.uri.pathSegments.isEmpty ||
        request.uri.pathSegments.last != localFileName) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    try {
      final length = await file.length();

      response.headers.set(
        'Accept-Ranges',
        'bytes',
      );
      response.headers.set(
        'Content-Type',
        'application/octet-stream',
      );

      if (request.method == 'HEAD') {
        response.statusCode = HttpStatus.ok;
        response.headers.contentLength = length;
        await response.close();
        return;
      }

      final rangeHeader = request.headers.value('range');

      if (rangeHeader == null ||
          !rangeHeader.startsWith('bytes=')) {
        response.statusCode = HttpStatus.ok;
        response.headers.contentLength = length;
        await response.addStream(file.openRead());
        await response.close();
        return;
      }

      final range = rangeHeader.substring('bytes='.length).split('-');
      final start = int.tryParse(range.first);

      if (start == null || start < 0 || start >= length) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(
          'Content-Range',
          'bytes */$length',
        );
        await response.close();
        return;
      }

      int end;

      if (range.length > 1 && range[1].isNotEmpty) {
        end = int.tryParse(range[1]) ?? (length - 1);
      } else {
        end = length - 1;
      }

      if (end >= length) {
        end = length - 1;
      }

      if (end < start) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(
          'Content-Range',
          'bytes */$length',
        );
        await response.close();
        return;
      }

      final contentLength = end - start + 1;

      response.statusCode = HttpStatus.partialContent;
      response.headers.contentLength = contentLength;
      response.headers.set(
        'Content-Range',
        'bytes $start-$end/$length',
      );

      await response.addStream(
        file.openRead(start, end + 1),
      );
      await response.close();
    } catch (e) {
      debugPrint('PMTILES SERVER ERROR: $e');
      try {
        await response.close();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await _server?.close(force: true);
    _server = null;
    _file = null;
  }
}


// ============================================================
// DATA MODELS
// ============================================================

enum ChatScope { privateChat, commonChat }

enum ChatMessageType { text, voice }

class NodeInfo {
  final String id;
  final double latitude;
  final double longitude;
  final int battery;
  final DateTime lastSeen;
  int? rssi;

  NodeInfo({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.battery,
    required this.lastSeen,
    this.rssi,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String? recipientId;
  final String text;
  final bool fromMe;
  final DateTime time;
  final ChatMessageType type;
  final String? audioPath;

  const ChatMessage({
    required this.id,
    required this.senderId,
    this.recipientId,
    required this.text,
    required this.fromMe,
    required this.time,
    this.type = ChatMessageType.text,
    this.audioPath,
  });

  bool get isVoice => type == ChatMessageType.voice;
}

// ------------------------------------------------------------
// ChatNotifier
// ------------------------------------------------------------
// A tiny observable message list. Each open conversation (common
// chat or a specific private chat) has one of these. Incoming BLE
// data mutates the notifier directly, and whichever chat page is
// currently on screen is listening to it -- so the message shows up
// immediately, instead of waiting for the underlying DevicePage
// (which is buried under the pushed chat route and does not get
// rebuilt just because it called setState) to eventually redraw.
// ------------------------------------------------------------
class ChatNotifier extends ChangeNotifier {
  final List<ChatMessage> messages = [];

  void add(ChatMessage message) {
    messages.add(message);
    notifyListeners();
  }
}

class AppNotification {
  final String id;
  final String senderId;
  final String preview;
  final DateTime time;
  final bool isPrivate;
  bool read;

  AppNotification({
    required this.id,
    required this.senderId,
    required this.preview,
    required this.time,
    required this.isPrivate,
    this.read = false,
  });
}

// Existing location packet format is intentionally retained.
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

  static LocationPacket? parse(String data) {
    try {
      final parts = data.trim().split(',');
      if (parts.length != 6) return null;
      if (parts[0].trim().toUpperCase() != 'LOC') return null;

      final id = parts[1].trim();
      final lat = double.tryParse(parts[2].trim());
      final lon = double.tryParse(parts[3].trim());
      final timestamp = parts[4].trim();
      final battery = int.tryParse(parts[5].trim());

      if (id.isEmpty || lat == null || lon == null || battery == null) {
        return null;
      }
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
      if (battery < 0 || battery > 100) return null;

      return LocationPacket(
        deviceId: id,
        latitude: lat,
        longitude: lon,
        timestamp: timestamp,
        battery: battery,
      );
    } catch (_) {
      return null;
    }
  }
}

// ============================================================
// VOICE PACKET PROTOCOL
// ============================================================
// Kept compatible with the user's existing phone-side voice framing.
// ESP32 can later be updated to add routing metadata around this frame.

class VoicePacket {
  static const List<int> magic = [0x56, 0x4F, 0x49, 0x43]; // VOIC
  static const int version = 1;
  static const int headerSize = 16;
  static const int crcSize = 2;
  static const int maxPayload = 80;

  final int messageId;
  final int chunkIndex;
  final int totalChunks;
  final int flags;
  final List<int> payload;

  const VoicePacket({
    required this.messageId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.flags,
    required this.payload,
  });

  List<int> encode() {
    final bytes = <int>[];
    bytes.addAll(magic);
    bytes.add(version);
    _writeUint32(bytes, messageId);
    _writeUint16(bytes, chunkIndex);
    _writeUint16(bytes, totalChunks);
    bytes.add(flags & 0xFF);
    _writeUint16(bytes, payload.length);
    bytes.addAll(payload);
    _writeUint16(bytes, crc16(bytes));
    return bytes;
  }

  static VoicePacket? decode(List<int> bytes) {
    try {
      if (bytes.length < headerSize + crcSize) return null;
      for (var i = 0; i < magic.length; i++) {
        if (bytes[i] != magic[i]) return null;
      }
      if (bytes[4] != version) return null;

      final messageId = _readUint32(bytes, 5);
      final chunkIndex = _readUint16(bytes, 9);
      final totalChunks = _readUint16(bytes, 11);
      final flags = bytes[13];
      final payloadLength = _readUint16(bytes, 14);

      final expectedLength = headerSize + payloadLength + crcSize;
      if (bytes.length != expectedLength) return null;
      if (totalChunks == 0 || chunkIndex >= totalChunks) return null;

      final payloadEnd = headerSize + payloadLength;
      final receivedCrc = _readUint16(bytes, payloadEnd);
      final calculatedCrc = crc16(bytes.sublist(0, payloadEnd));
      if (receivedCrc != calculatedCrc) return null;

      return VoicePacket(
        messageId: messageId,
        chunkIndex: chunkIndex,
        totalChunks: totalChunks,
        flags: flags,
        payload: List<int>.from(bytes.sublist(headerSize, payloadEnd)),
      );
    } catch (_) {
      return null;
    }
  }

  static void _writeUint16(List<int> out, int value) {
    out.add((value >> 8) & 0xFF);
    out.add(value & 0xFF);
  }

  static void _writeUint32(List<int> out, int value) {
    out.add((value >> 24) & 0xFF);
    out.add((value >> 16) & 0xFF);
    out.add((value >> 8) & 0xFF);
    out.add(value & 0xFF);
  }

  static int _readUint16(List<int> data, int offset) =>
      (data[offset] << 8) | data[offset + 1];

  static int _readUint32(List<int> data, int offset) =>
      (data[offset] << 24) |
      (data[offset + 1] << 16) |
      (data[offset + 2] << 8) |
      data[offset + 3];

  static int crc16(List<int> data) {
    var crc = 0xFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }
}

class _IncomingVoiceMessage {
  final int totalChunks;
  final Map<int, List<int>> chunks = {};

  _IncomingVoiceMessage(this.totalChunks);

  bool get complete => chunks.length == totalChunks;

  List<int> assemble() {
    final output = <int>[];
    for (var i = 0; i < totalChunks; i++) {
      final chunk = chunks[i];
      if (chunk == null) throw StateError('Missing voice chunk $i');
      output.addAll(chunk);
    }
    return output;
  }
}

// ============================================================
// COMMUNICATION ROUTING
// ============================================================
// This is the app-side routing layer.
// IMPORTANT: until the ESP32 firmware is updated, the ESP32 will
// still receive the current raw UART/BLE payload. The envelopes below
// are therefore used by the new app architecture and are ready for
// the later ESP32 routing implementation.

class RoutingPacket {
  static String privateText({
    required String from,
    required String to,
    required String text,
  }) {
    return 'MSG,PRIVATE,$from,$to,${base64Encode(utf8.encode(text))}';
  }

  static String commonText({
    required String from,
    required String text,
  }) {
    return 'MSG,COMMON,$from,ALL,${base64Encode(utf8.encode(text))}';
  }

  static ParsedRoutingPacket? parse(String data) {
    try {
      final p = data.trim().split(',');
      if (p.length < 5 || p[0].toUpperCase() != 'MSG') return null;

      final scope = p[1].toUpperCase() == 'PRIVATE'
          ? ChatScope.privateChat
          : p[1].toUpperCase() == 'COMMON'
          ? ChatScope.commonChat
          : null;

      if (scope == null) return null;

      final from = p[2].trim();
      final to = p[3].trim();
      final encoded = p.sublist(4).join(',');
      final decoded = utf8.decode(base64Decode(encoded), allowMalformed: true);

      return ParsedRoutingPacket(
        scope: scope,
        from: from,
        to: to,
        text: decoded,
      );
    } catch (_) {
      return null;
    }
  }
}

class ParsedRoutingPacket {
  final ChatScope scope;
  final String from;
  final String to;
  final String text;

  const ParsedRoutingPacket({
    required this.scope,
    required this.from,
    required this.to,
    required this.text,
  });
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
  final Map<String, NodeInfo> nodes = {};

  bool get isTamil => languageNotifier.value;

  String get languageButtonText => isTamil ? 'English' : 'தமிழ்';

  void _toggleLanguage() {
    languageNotifier.value = !languageNotifier.value;
    setState(() {});
  }

  // Conversations are now observable notifiers instead of plain lists,
  // so whichever chat page is currently open updates itself the instant
  // a message arrives -- it no longer depends on DevicePage rebuilding.
  final Map<String, ChatNotifier> privateChats = {};
  final ChatNotifier commonChat = ChatNotifier();

  final List<AppNotification> notifications = [];

  final MapController _mapController = MapController();
  StreamSubscription<Position>? positionSubscription;
  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;
  StreamSubscription<List<int>>? notificationSubscription;

  LatLng? currentLocation;
  bool _mapReady = false;
  bool _hasCenteredOnLocation = false;

  vt.PmTilesVectorTileProvider? pmtilesProvider;
  final OfflineMapManager _offlineMapManager = OfflineMapManager();
  vt.Theme? mapTheme;
  bool mapLoading = true;
  String? mapError;

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? rxCharacteristic;
  BluetoothCharacteristic? txCharacteristic;

  String status = 'Disconnected';
  bool isScanning = false;
  bool isConnecting = false;
  bool showBlePanel = true;

  final Guid serviceUuid =
  Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  final Guid rxUuid =
  Guid('6E400002-B5A3-F393-E0A9-E50E24DCCA9E');
  final Guid txUuid =
  Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E');

  Timer? locationTimer;
  final Battery battery = Battery();
  bool locationSending = false;
  String mobileDeviceId = 'PHONE';
  bool locationPermissionReady = false;

  // Voice messaging.
  final AudioRecorder _voiceRecorder = AudioRecorder();

  // BLE voice framing buffer.
  // One BLE notification may contain a partial frame, one complete frame,
  // or several VoicePackets.
  final List<int> _voiceRxBuffer = <int>[];
  Timer? _voiceRxBufferTimer;

  final Map<int, _IncomingVoiceMessage> _incomingVoiceMessages = {};
  final Map<int, Timer> _incomingVoiceTimeouts = {};

  // Voice recording UI state.
  bool _isVoiceRecording = false;

  int get unreadNotifications =>
      notifications.where((n) => !n.read).length;

  @override
  void initState() {
    super.initState();

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      final unique = <String, ScanResult>{};
      for (final result in results) {
        unique[result.device.remoteId.toString()] = result;
      }
      setState(() {
        scanResults
          ..clear()
          ..addAll(unique.values);
      });
    });

    _initializeOfflineMap();
    _initializeMobileDeviceId();
    _initializeLiveLocation();
  }

  Future<void> _initializeMobileDeviceId() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/lora_tracker_device_id.txt');

      if (await file.exists()) {
        final existingId = (await file.readAsString()).trim();
        if (existingId.isNotEmpty && mounted) {
          setState(() => mobileDeviceId = existingId);
          return;
        }
      }

      final random = Random.secure();
      final id = 'PHONE_'
          '${random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase()}'
          '${random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase()}';

      await file.writeAsString(id, flush: true);
      if (mounted) setState(() => mobileDeviceId = id);
    } catch (e) {
      debugPrint('MOBILE DEVICE ID ERROR: $e');
    }
  }

  Future<void> _initializeOfflineMap() async {
    try {
      final pmtilesUrl = await _offlineMapManager.start();
      if (!mounted) {
        await _offlineMapManager.dispose();
        return;
      }

      final provider =
      await vt.PmTilesVectorTileProvider.open(pmtilesUrl);
      final theme = vt.ThemeReader(
        logger: const vt.Logger.console(),
      ).read(_offlineMapStyle);

      if (!mounted) return;
      setState(() {
        pmtilesProvider = provider;
        mapTheme = theme;
        mapLoading = false;
        mapError = null;
      });
    } catch (e, stackTrace) {
      debugPrint('PMTILES ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      setState(() {
        mapLoading = false;
        mapError = e.toString();
      });
    }
  }

  Future<void> _initializeLiveLocation() async {
    try {
      final ready = await _prepareLocationPermission();
      if (!ready) return;

      locationPermissionReady = true;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _updateCurrentMapLocation(position, centerMap: true);

      await positionSubscription?.cancel();
      positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        _updateCurrentMapLocation,
        onError: (e) => debugPrint('MAP LOCATION STREAM ERROR: $e'),
      );
    } catch (e) {
      debugPrint('MAP LOCATION ERROR: $e');
    }
  }

  void _updateCurrentMapLocation(
      Position position, {
        bool centerMap = false,
      }) {
    if (!mounted) return;
    final location = LatLng(position.latitude, position.longitude);

    setState(() => currentLocation = location);

    if ((_mapReady && !_hasCenteredOnLocation) || centerMap) {
      if (_mapReady) {
        _mapController.move(location, 14);
        _hasCenteredOnLocation = true;
      }
    }
  }

  Future<bool> _prepareLocationPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (_) {
      return false;
    }
  }

  Future<void> startScan() async {
    if (isScanning) return;

    setState(() {
      scanResults.clear();
      isScanning = true;
      status = 'Checking Bluetooth...';
    });

    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        if (mounted) {
          setState(() {
            isScanning = false;
            status = 'Bluetooth is OFF';
          });
        }
        return;
      }

      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationEnabled && mounted) {
        setState(() {
          isScanning = false;
          status = 'Turn ON Location to scan Bluetooth';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('Please turn ON Location in phone Settings, then scan again.', 'தொலைபேசி அமைப்புகளில் இருப்பிடத்தை இயக்கி, மீண்டும் தேடவும்.'),
            ),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            isScanning = false;
            status = 'Location permission required';
          });
        }
        return;
      }

      if (mounted) setState(() => status = 'Scanning for devices...');

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        androidUsesFineLocation: true,
      );

      if (!mounted) return;
      setState(() {
        isScanning = false;
        status = scanResults.isEmpty
            ? 'No devices found'
            : '${scanResults.length} device(s) found';
      });
    } catch (e, stackTrace) {
      debugPrint('SCAN ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      setState(() {
        isScanning = false;
        status = 'Scan failed';
      });
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (isConnecting) return;

    if (connectedDevice != null &&
        connectedDevice!.remoteId != device.remoteId) {
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
      await connectionSubscription?.cancel();
      connectionSubscription = device.connectionState.listen((state) {
        if (!mounted) return;

        if (state == BluetoothConnectionState.connected) {
          setState(() {
            status = 'Connected';
            showBlePanel = false;
          });
        } else {
          _stopLocationSharing();
          setState(() {
            status = 'Disconnected';
            connectedDevice = null;
            rxCharacteristic = null;
            txCharacteristic = null;
            showBlePanel = true;
          });
        }
      });

      await discoverServices(device);

      if (rxCharacteristic == null || txCharacteristic == null) {
        throw Exception('Required BLE characteristics not found');
      }

      if (!mounted) return;
      setState(() {
        isConnecting = false;
        status = 'Connected';
        showBlePanel = false;
      });

      await _startLocationSharing();
    } catch (e, stackTrace) {
      debugPrint('CONNECTION ERROR: $e');
      debugPrint(stackTrace.toString());

      await cleanupBle();
      try {
        await device.disconnect();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        isConnecting = false;
        connectedDevice = null;
        status = 'Connection failed';
        showBlePanel = true;
      });
    }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    BluetoothCharacteristic? foundRx;
    BluetoothCharacteristic? foundTx;

    for (final service in services) {
      if (service.uuid != serviceUuid) continue;

      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == rxUuid) foundRx = characteristic;
        if (characteristic.uuid == txUuid) foundTx = characteristic;
      }
    }

    if (foundRx == null) throw Exception('RX characteristic not found');
    if (foundTx == null) throw Exception('TX characteristic not found');

    rxCharacteristic = foundRx;
    txCharacteristic = foundTx;

    await notificationSubscription?.cancel();
    notificationSubscription = txCharacteristic!.onValueReceived.listen(
      handleIncomingBleData,
      onError: (e) => debugPrint('BLE NOTIFICATION ERROR: $e'),
      cancelOnError: false,
    );

    await txCharacteristic!.setNotifyValue(true);
  }

  void handleIncomingBleData(List<int> value) {
    if (value.isEmpty) return;

    // IMPORTANT:
    // Never call VoicePacket.decode(value) directly. One BLE notification
    // may contain a partial frame, one complete frame, or several frames.
    _voiceRxBuffer.addAll(value);
    _processIncomingBleBuffer();
  }

  int _findMagic(List<int> data, int start) {
    if (data.length < VoicePacket.magic.length) return -1;

    for (var i = start; i <= data.length - VoicePacket.magic.length; i++) {
      var match = true;
      for (var j = 0; j < VoicePacket.magic.length; j++) {
        if (data[i + j] != VoicePacket.magic[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  int _magicSuffixLength(List<int> data) {
    final maxKeep = min(VoicePacket.magic.length - 1, data.length);

    for (var len = maxKeep; len > 0; len--) {
      var match = true;
      final start = data.length - len;

      for (var i = 0; i < len; i++) {
        if (data[start + i] != VoicePacket.magic[i]) {
          match = false;
          break;
        }
      }

      if (match) return len;
    }

    return 0;
  }

  void _processIncomingBleBuffer() {
    while (_voiceRxBuffer.isNotEmpty) {
      final magicIndex = _findMagic(_voiceRxBuffer, 0);

      // No complete VOIC marker yet. Process ordinary text, while keeping
      // a possible partial VOIC marker at the end.
      if (magicIndex < 0) {
        final keep = _magicSuffixLength(_voiceRxBuffer);
        final textLength = _voiceRxBuffer.length - keep;

        if (textLength > 0) {
          final textBytes = _voiceRxBuffer.sublist(0, textLength);
          _voiceRxBuffer.removeRange(0, textLength);
          _processIncomingTextBytes(textBytes);
          continue;
        }

        _armVoiceRxBufferTimeout();
        return;
      }

      // Bytes before VOIC are normal text/protocol data.
      if (magicIndex > 0) {
        final prefix = _voiceRxBuffer.sublist(0, magicIndex);
        _voiceRxBuffer.removeRange(0, magicIndex);
        _processIncomingTextBytes(prefix);
        continue;
      }

      // We are exactly at VOIC. Wait for the complete fixed header.
      if (_voiceRxBuffer.length < VoicePacket.headerSize) {
        _armVoiceRxBufferTimeout();
        return;
      }

      if (_voiceRxBuffer[4] != VoicePacket.version) {
        debugPrint('VOICE RX: invalid version; resynchronizing');
        _voiceRxBuffer.removeAt(0);
        continue;
      }

      final payloadLength =
      (_voiceRxBuffer[14] << 8) | _voiceRxBuffer[15];

      if (payloadLength > VoicePacket.maxPayload) {
        debugPrint(
          'VOICE RX: invalid payload length $payloadLength; resynchronizing',
        );
        _voiceRxBuffer.removeAt(0);
        continue;
      }

      final expectedLength =
          VoicePacket.headerSize + payloadLength + VoicePacket.crcSize;

      // Header says more bytes are needed. Keep buffering.
      if (_voiceRxBuffer.length < expectedLength) {
        _armVoiceRxBufferTimeout();
        return;
      }

      final frame = List<int>.from(
        _voiceRxBuffer.sublist(0, expectedLength),
      );
      _voiceRxBuffer.removeRange(0, expectedLength);

      final voicePacket = VoicePacket.decode(frame);

      if (voicePacket != null) {
        _cancelVoiceRxBufferTimeout();
        _handleIncomingVoicePacket(voicePacket);
      } else {
        // A failed binary voice frame must NEVER fall through to text.
        debugPrint('VOICE RX: invalid frame/CRC; resynchronizing');
        continue;
      }
    }

    _cancelVoiceRxBufferTimeout();
  }

  void _processIncomingTextBytes(List<int> bytes) {
    if (bytes.isEmpty) return;

    final message = utf8.decode(bytes, allowMalformed: true).trim();
    if (message.isEmpty) return;

    final locationPacket = LocationPacket.parse(message);
    if (locationPacket != null) {
      final node = NodeInfo(
        id: locationPacket.deviceId,
        latitude: locationPacket.latitude,
        longitude: locationPacket.longitude,
        battery: locationPacket.battery,
        lastSeen: DateTime.now(),
      );

      if (mounted) {
        setState(() => nodes[locationPacket.deviceId] = node);
      }
      return;
    }

    final routed = RoutingPacket.parse(message);
    if (routed != null) {
      _handleRoutedMessage(routed);
      return;
    }

    // Only genuine text reaches the raw-text fallback.
    _handleRawIncomingMessage(message);
  }

  void _armVoiceRxBufferTimeout() {
    _voiceRxBufferTimer?.cancel();
    _voiceRxBufferTimer = Timer(const Duration(seconds: 10), () {
      if (_voiceRxBuffer.isNotEmpty) {
        debugPrint(
          'VOICE RX: incomplete frame timed out; clearing '
              '${_voiceRxBuffer.length} buffered bytes',
        );
        _voiceRxBuffer.clear();
      }
    });
  }

  void _cancelVoiceRxBufferTimeout() {
    _voiceRxBufferTimer?.cancel();
    _voiceRxBufferTimer = null;
  }

  void _handleRoutedMessage(ParsedRoutingPacket packet) {
    if (packet.scope == ChatScope.privateChat &&
        packet.to != mobileDeviceId &&
        packet.to != 'ALL') {
      return;
    }

    final msg = ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      senderId: packet.from,
      recipientId:
      packet.scope == ChatScope.privateChat ? mobileDeviceId : null,
      text: packet.text,
      fromMe: false,
      time: DateTime.now(),
    );

    if (packet.scope == ChatScope.privateChat) {
      privateChats.putIfAbsent(packet.from, () => ChatNotifier()).add(msg);
      _addNotification(
        senderId: packet.from,
        preview: packet.text,
        isPrivate: true,
      );
    } else {
      commonChat.add(msg);
    }

    // Still needed here: this drives the notifications badge and the
    // node list, both of which DevicePage itself renders.
    if (mounted) setState(() {});
  }

  void _handleRawIncomingMessage(String message) {
    final msg = ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      senderId: 'ESP32',
      text: message,
      fromMe: false,
      time: DateTime.now(),
    );

    commonChat.add(msg);
    _addNotification(
      senderId: 'ESP32',
      preview: message,
      isPrivate: false,
    );

    if (mounted) setState(() {});
  }

  void _addNotification({
    required String senderId,
    required String preview,
    required bool isPrivate,
  }) {
    notifications.insert(
      0,
      AppNotification(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        senderId: senderId,
        preview: preview,
        time: DateTime.now(),
        isPrivate: isPrivate,
      ),
    );
    if (notifications.length > 100) {
      notifications.removeLast();
    }
  }

  Future<void> _startLocationSharing() async {
    if (rxCharacteristic == null) return;

    final ready = await _prepareLocationPermission();
    if (!ready) return;

    locationPermissionReady = true;
    locationTimer?.cancel();

    await _sendCurrentLocation();

    locationTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _sendCurrentLocation(),
    );
  }

  void _stopLocationSharing() {
    locationTimer?.cancel();
    locationTimer = null;
    locationSending = false;
  }

  Future<void> _sendCurrentLocation() async {
    if (locationSending ||
        connectedDevice == null ||
        rxCharacteristic == null) {
      return;
    }

    if (!locationPermissionReady) {
      final ready = await _prepareLocationPermission();
      if (!ready) return;
      locationPermissionReady = true;
    }

    locationSending = true;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final batteryLevel = await battery.batteryLevel;
      final now = DateTime.now();
      final timestamp =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';

      final packet =
          'LOC,$mobileDeviceId,'
          '${position.latitude.toStringAsFixed(6)},'
          '${position.longitude.toStringAsFixed(6)},'
          '$timestamp,$batteryLevel';

      await rxCharacteristic!.write(
        utf8.encode(packet),
        withoutResponse: false,
      );
    } catch (e) {
      debugPrint('LOCATION SEND ERROR: $e');
    } finally {
      locationSending = false;
    }
  }

  Future<void> sendPrivateText(String nodeId, String text) async {
    text = text.trim();
    if (text.isEmpty || rxCharacteristic == null) return;

    final packet = RoutingPacket.privateText(
      from: mobileDeviceId,
      to: nodeId,
      text: text,
    );

    try {
      await rxCharacteristic!.write(
        utf8.encode(packet),
        withoutResponse: false,
      );

      final message = ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        senderId: mobileDeviceId,
        recipientId: nodeId,
        text: text,
        fromMe: true,
        time: DateTime.now(),
      );

      privateChats.putIfAbsent(nodeId, () => ChatNotifier()).add(message);
    } catch (e) {
      _showSnack(tr('Failed to send private message', 'தனிப்பட்ட செய்தியை அனுப்ப முடியவில்லை'));
      debugPrint('PRIVATE SEND ERROR: $e');
    }
  }

  Future<void> sendCommonText(String text) async {
    text = text.trim();
    if (text.isEmpty || rxCharacteristic == null) return;

    final packet = RoutingPacket.commonText(
      from: mobileDeviceId,
      text: text,
    );

    try {
      await rxCharacteristic!.write(
        utf8.encode(packet),
        withoutResponse: false,
      );

      commonChat.add(
        ChatMessage(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          senderId: mobileDeviceId,
          text: text,
          fromMe: true,
          time: DateTime.now(),
        ),
      );
    } catch (e) {
      _showSnack(tr('Failed to send common message', 'பொது செய்தியை அனுப்ப முடியவில்லை'));
      debugPrint('COMMON SEND ERROR: $e');
    }
  }

  // ----------------------------------------------------------
  // Voice messaging (Common Chat only for now).
  //
  // VoicePacket has no sender/recipient field, so there is currently
  // no way to route an incoming voice clip to a specific private
  // conversation. Until the ESP32 firmware adds that metadata, voice
  // messages -- sent and received -- live in Common Chat, matching
  // the existing fallback behavior used for unrouted raw text.
  // ----------------------------------------------------------

  Future<void> _startVoiceRecording({String? privateTarget}) async {
    if (_isVoiceRecording) return;

    try {
      final hasPermission = await _voiceRecorder.hasPermission();
      if (!hasPermission) {
        _showSnack(tr('Microphone permission is required to record voice messages', 'குரல் செய்திகளைப் பதிவு செய்ய மைக்ரோஃபோன் அனுமதி தேவை'));
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/voice_out_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _voiceRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 32000,
          sampleRate: 16000,
        ),
        path: path,
      );

      _isVoiceRecording = true;
    } catch (e) {
      debugPrint('VOICE RECORD START ERROR: $e');
      _showSnack(tr('Could not start recording', 'பதிவைத் தொடங்க முடியவில்லை'));
    }
  }

  Future<void> _stopVoiceRecordingAndSend({String? privateTarget}) async {
    if (!_isVoiceRecording) return;

    _isVoiceRecording = false;

    try {
      final path = await _voiceRecorder.stop();
      if (path == null) return;

      final file = File(path);
      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      if (connectedDevice == null || rxCharacteristic == null) {
        _showSnack(tr('Not connected to a LoRa node', 'LoRa முனையுடன் இணைக்கப்படவில்லை'));
        return;
      }

      await _sendVoiceBytes(
        bytes,
        localAudioPath: path,
        privateTarget: privateTarget,
      );
    } catch (e) {
      debugPrint('VOICE RECORD STOP ERROR: $e');
      _showSnack(tr('Failed to send voice message', 'குரல் செய்தியை அனுப்ப முடியவில்லை'));
    }
  }

  Future<void> _sendVoiceBytes(
      List<int> bytes, {
        required String localAudioPath,
        String? privateTarget,
      }) async {
    // 32-bit message id, derived from the clock -- good enough to avoid
    // collisions between consecutive voice messages from this phone.
    final messageId = DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF;
    final totalChunks =
    (bytes.length / VoicePacket.maxPayload).ceil().clamp(1, 0xFFFF);

    try {
      for (var i = 0; i < totalChunks; i++) {
        final start = i * VoicePacket.maxPayload;
        final end = min(start + VoicePacket.maxPayload, bytes.length);

        final packet = VoicePacket(
          messageId: messageId,
          chunkIndex: i,
          totalChunks: totalChunks,
          flags: 0,
          payload: bytes.sublist(start, end),
        );

        await rxCharacteristic!.write(
          packet.encode(),
          withoutResponse: false,
        );

        // Small pacing delay so the ESP32's BLE stack isn't flooded --
        // tune/remove once the firmware side is confirmed to keep up.
        await Future.delayed(const Duration(milliseconds: 5));
      }

      final localMessage = ChatMessage(
        id: '$messageId',
        senderId: mobileDeviceId,
        recipientId: privateTarget,
        text: '',
        fromMe: true,
        time: DateTime.now(),
        type: ChatMessageType.voice,
        audioPath: localAudioPath,
      );

      if (privateTarget != null) {
        privateChats
            .putIfAbsent(privateTarget, () => ChatNotifier())
            .add(localMessage);
      } else {
        commonChat.add(localMessage);
      }
    } catch (e) {
      debugPrint('VOICE SEND ERROR: $e');
      _showSnack(tr('Failed to send voice message', 'குரல் செய்தியை அனுப்ப முடியவில்லை'));
    }
  }

  Future<void> _handleIncomingVoicePacket(VoicePacket packet) async {
    final existing = _incomingVoiceMessages[packet.messageId];

    // Do not allow an inconsistent packet to change the declared message size.
    if (existing != null && existing.totalChunks != packet.totalChunks) {
      debugPrint(
        'VOICE ASSEMBLY: totalChunks changed for message '
            '${packet.messageId}; resetting',
      );
      _incomingVoiceTimeouts.remove(packet.messageId)?.cancel();
      _incomingVoiceMessages.remove(packet.messageId);
    }

    final incoming = _incomingVoiceMessages.putIfAbsent(
      packet.messageId,
          () => _IncomingVoiceMessage(packet.totalChunks),
    );

    incoming.chunks[packet.chunkIndex] = List<int>.from(packet.payload);

    // Reset the timeout whenever a valid chunk arrives.
    _incomingVoiceTimeouts.remove(packet.messageId)?.cancel();
    _incomingVoiceTimeouts[packet.messageId] = Timer(
      const Duration(seconds: 15),
          () {
        final removed = _incomingVoiceMessages.remove(packet.messageId);
        _incomingVoiceTimeouts.remove(packet.messageId)?.cancel();

        if (removed != null) {
          debugPrint(
            'VOICE ASSEMBLY TIMEOUT: message ${packet.messageId}, '
                '${removed.chunks.length}/${removed.totalChunks} chunks received',
          );
        }
      },
    );

    if (!incoming.complete) return;

    _incomingVoiceTimeouts.remove(packet.messageId)?.cancel();
    _incomingVoiceMessages.remove(packet.messageId);

    try {
      final bytes = incoming.assemble();

      if (bytes.isEmpty) {
        debugPrint('VOICE ASSEMBLE: empty audio for ${packet.messageId}');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/voice_in_${packet.messageId}.m4a';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      commonChat.add(
        ChatMessage(
          id: '${packet.messageId}',
          senderId: 'ESP32',
          text: '',
          fromMe: false,
          time: DateTime.now(),
          type: ChatMessageType.voice,
          audioPath: path,
        ),
      );

      _addNotification(
        senderId: 'ESP32',
        preview: tr('Voice message', 'குரல் செய்தி'),
        isPrivate: false,
      );

      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      debugPrint('VOICE ASSEMBLE ERROR: $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> cleanupBle() async {
    await notificationSubscription?.cancel();
    notificationSubscription = null;
    await connectionSubscription?.cancel();
    connectionSubscription = null;

    _cancelVoiceRxBufferTimeout();
    _voiceRxBuffer.clear();

    for (final timer in _incomingVoiceTimeouts.values) {
      timer.cancel();
    }
    _incomingVoiceTimeouts.clear();
    _incomingVoiceMessages.clear();

    rxCharacteristic = null;
    txCharacteristic = null;
  }

  Future<void> disconnectDevice() async {
    _stopLocationSharing();
    final device = connectedDevice;

    await cleanupBle();

    if (device != null) {
      try {
        await device.disconnect();
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      connectedDevice = null;
      status = 'Disconnected';
      isConnecting = false;
      showBlePanel = true;
    });
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String getDeviceName(BluetoothDevice device) {
    final name = device.platformName;
    return name.isNotEmpty ? name : tr('ESP32 Device', 'ESP32 சாதனம்');
  }

  void _centerOnCurrentLocation() {
    final location = currentLocation;
    if (location == null) {
      _initializeLiveLocation();
      return;
    }
    _mapController.move(location, 14);
    _hasCenteredOnLocation = true;
  }

  void _showNodePopup(NodeInfo node) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final rssi = node.rssi;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.router_rounded,
                        color: Color(0xFF1769E0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.id,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tr('Battery ${node.battery}%', 'மின்கலம் ${node.battery}%'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF727C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.signal_cellular_alt_rounded,
                        label: tr('RSSI', 'சிக்னல்'),
                        value: rssi == null ? tr('N/A', 'கிடைக்கவில்லை') : '$rssi dBm',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.location_on_outlined,
                        label: tr('Position', 'இருப்பிடம்'),
                        value:
                        '${node.latitude.toStringAsFixed(5)}, '
                            '${node.longitude.toStringAsFixed(5)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: connectedDevice == null
                        ? null
                        : () {
                      Navigator.pop(context);
                      _openPrivateChat(node);
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(tr('CHAT', 'அரட்டை')),
                  ),
                ),
                if (connectedDevice == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      tr('Connect the ESP32 over BLE before starting a chat.', 'அரட்டையைத் தொடங்குவதற்கு முன் ESP32-ஐ BLE மூலம் இணைக்கவும்.'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A94A4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPrivateChat(NodeInfo node) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivateChatPage(
          node: node,
          mobileDeviceId: mobileDeviceId,
          chat: privateChats.putIfAbsent(node.id, () => ChatNotifier()),
          sendText: (text) => sendPrivateText(node.id, text),
          onVoiceHoldStart: () =>
              _startVoiceRecording(privateTarget: node.id),
          onVoiceHoldEnd: () =>
              _stopVoiceRecordingAndSend(privateTarget: node.id),
          connected: connectedDevice != null && rxCharacteristic != null,
        ),
      ),
    );
  }

  void _openCommonChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommonChatPage(
          mobileDeviceId: mobileDeviceId,
          chat: commonChat,
          sendText: sendCommonText,
          onVoiceHoldStart: _startVoiceRecording,
          onVoiceHoldEnd: _stopVoiceRecordingAndSend,
          connected: connectedDevice != null && rxCharacteristic != null,
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationPage(
          notifications: notifications,
          onOpen: (notification) {
            notification.read = true;
            final node = nodes[notification.senderId];
            if (node != null) {
              Navigator.pop(context);
              _openPrivateChat(node);
            } else {
              Navigator.pop(context);
              _showSnack(tr('Sender ${notification.senderId} is not currently on the map.', 'அனுப்புநர் ${notification.senderId} தற்போது வரைபடத்தில் இல்லை.'));
            }
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildOfflineMap() {
    if (mapLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 12),
            Text(
              tr('Loading Sathya offline map...', 'Sathya ஆஃப்லைன் வரைபடத்தை ஏற்றுகிறது...'),
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

    if (pmtilesProvider == null || mapTheme == null) {
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
              Text(tr('Sathya offline map unavailable', 'Sathya ஆஃப்லைன் வரைபடம் கிடைக்கவில்லை'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF303A4D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mapError ?? tr('Unknown PMTiles error', 'தெரியாத PMTiles பிழை'),
                textAlign: TextAlign.center,
                maxLines: 5,
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

    final markers = <Marker>[];

    if (currentLocation != null) {
      markers.add(
        Marker(
          point: currentLocation!,
          width: 84,
          height: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1769E0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tr('YOU', 'நீங்கள்'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF1769E0),
                size: 38,
              ),
            ],
          ),
        ),
      );
    }

    for (final node in nodes.values) {
      markers.add(
        Marker(
          point: LatLng(node.latitude, node.longitude),
          width: 110,
          height: 76,
          child: GestureDetector(
            onTap: () => _showNodePopup(node),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    node.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
        ),
      );
    }

    final mapCenter = currentLocation ?? const LatLng(11.337, 77.115);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: 14,
            minZoom: 8,
            maxZoom: 16,
            onMapReady: () {
              _mapReady = true;
              final location = currentLocation;
              if (location != null && !_hasCenteredOnLocation) {
                _mapController.move(location, 14);
                _hasCenteredOnLocation = true;
              }
            },
          ),
          children: [
            vt.VectorTileLayer(
              theme: mapTheme!,
              tileProviders: vt.TileProviders({
                'protomaps': pmtilesProvider!,
              }),
              showLabels: true,
              logger: const vt.Logger.console(),
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: Colors.white,
            elevation: 3,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: _centerOnCurrentLocation,
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFF1769E0),
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlePanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE6EBF1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tr('Connect LoRa Node', 'LoRa முனையை இணைக்கவும்'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF202A3A),
                    ),
                  ),
                ),
                Text(
                  '${scanResults.length} ${tr('found', 'கிடைத்தது')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7B8493),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: tr('Scan', 'தேடுக'),
                  onPressed: isScanning ? null : startScan,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connectedDevice != null
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trStatus(status),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4C5666),
                    ),
                  ),
                ),
                if (isScanning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 190,
            child: scanResults.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bluetooth_searching_rounded,
                    size: 30,
                    color: Color(0xFF9AA3B2),
                  ),
                  const SizedBox(height: 7),
                  Text(tr('Scan and choose your ESP32 LoRa node', 'உங்கள் ESP32 LoRa முனையைத் தேடி தேர்ந்தெடுக்கவும்'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF727C8D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: isScanning ? null : startScan,
                    child: Text(tr('SCAN', 'தேடுக')),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                final device = result.device;
                final isConnected =
                    connectedDevice?.remoteId == device.remoteId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: Color(0xFFE4E9EF),
                      ),
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFF4FC),
                      child: Icon(
                        Icons.developer_board_outlined,
                        color: Color(0xFF1769E0),
                      ),
                    ),
                    title: Text(
                      getDeviceName(device),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${device.remoteId} • ${result.rssi} dBm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: isConnected
                        ? const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    )
                        : SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: isConnecting
                            ? null
                            : () => connectToDevice(device),
                        child: Text(
                          isConnecting ? '...' : tr('CONNECT', 'இணைக்கவும்'),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE6EBF1)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openNotifications,
                icon: Badge(
                  isLabelVisible: unreadNotifications > 0,
                  label: Text('$unreadNotifications'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
                label: Text(tr('Notifications', 'அறிவிப்புகள்')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _openCommonChat,
                icon: const Icon(Icons.forum_outlined),
                label: Text(tr('Common Chat', 'பொது அரட்டை')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = connectedDevice != null;

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
          TextButton(
            onPressed: _toggleLanguage,
            child: Text(
              languageButtonText,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1769E0),
              ),
            ),
          ),
          if (connected)
            IconButton(
              tooltip: 'BLE',
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.bluetooth_connected_rounded,
                              color: Colors.green,
                            ),
                            title: Text(
                              getDeviceName(connectedDevice!),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              connectedDevice!.remoteId.toString(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                disconnectDevice();
                              },
                              icon: const Icon(Icons.bluetooth_disabled),
                              label: Text(tr('Disconnect', 'துண்டிக்கவும்')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.bluetooth_connected_rounded),
            ),
          IconButton(
            tooltip: tr('Notifications', 'அறிவிப்புகள்'),
            onPressed: _openNotifications,
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildOfflineMap(),
          ),
          if (!connected && showBlePanel)
            _buildBlePanel()
          else
            _buildBottomActions(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    positionSubscription?.cancel();
    scanSubscription?.cancel();
    connectionSubscription?.cancel();
    notificationSubscription?.cancel();
    _cancelVoiceRxBufferTimeout();
    for (final timer in _incomingVoiceTimeouts.values) {
      timer.cancel();
    }
    _incomingVoiceTimeouts.clear();
    _incomingVoiceMessages.clear();
    _offlineMapManager.dispose();
    _voiceRecorder.dispose();
    super.dispose();
  }
}

// ============================================================
// INFO TILE
// ============================================================

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1769E0)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8993A2),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRIVATE CHAT
// ============================================================

class PrivateChatPage extends StatefulWidget {
  final NodeInfo node;
  final String mobileDeviceId;
  final ChatNotifier chat;
  final Future<void> Function(String) sendText;
  final Future<void> Function() onVoiceHoldStart;
  final Future<void> Function() onVoiceHoldEnd;
  final bool connected;

  const PrivateChatPage({
    super.key,
    required this.node,
    required this.mobileDeviceId,
    required this.chat,
    required this.sendText,
    required this.onVoiceHoldStart,
    required this.onVoiceHoldEnd,
    required this.connected,
  });

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.chat.addListener(_onChatUpdated);
  }

  void _onChatUpdated() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty || !widget.connected) return;
    await widget.sendText(text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.chat.messages;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.router_rounded, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.node.id,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                widget.node.rssi == null
                    ? tr('RSSI N/A', 'சிக்னல் கிடைக்கவில்லை')
                    : '${widget.node.rssi} dBm',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 9,
            ),
            color: const Color(0xFFF5F7FA),
            child: Text(
              tr('Private chat • ${widget.node.id}', 'தனிப்பட்ட அரட்டை • ${widget.node.id}'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6D7787),
              ),
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Text(
                tr('No private messages yet', 'தனிப்பட்ட செய்திகள் எதுவும் இல்லை'),
                style: TextStyle(color: Color(0xFF8A94A4)),
              ),
            )
                : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final m = messages[index];
                return _MessageBubble(message: m);
              },
            ),
          ),
          _Composer(
            controller: controller,
            enabled: widget.connected,
            onSend: _send,
            onVoiceHoldStart: widget.onVoiceHoldStart,
            onVoiceHoldEnd: widget.onVoiceHoldEnd,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.chat.removeListener(_onChatUpdated);
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }
}

// ============================================================
// COMMON CHAT
// ============================================================

class CommonChatPage extends StatefulWidget {
  final String mobileDeviceId;
  final ChatNotifier chat;
  final Future<void> Function(String) sendText;
  final Future<void> Function() onVoiceHoldStart;
  final Future<void> Function() onVoiceHoldEnd;
  final bool connected;

  const CommonChatPage({
    super.key,
    required this.mobileDeviceId,
    required this.chat,
    required this.sendText,
    required this.onVoiceHoldStart,
    required this.onVoiceHoldEnd,
    required this.connected,
  });

  @override
  State<CommonChatPage> createState() => _CommonChatPageState();
}

class _CommonChatPageState extends State<CommonChatPage> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.chat.addListener(_onChatUpdated);
  }

  void _onChatUpdated() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty || !widget.connected) return;
    await widget.sendText(text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.chat.messages;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Common Chat', 'பொது அரட்டை')),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.public_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            color: const Color(0xFFF5F7FA),
            child: Text(tr('Messages from all LoRa nodes', 'அனைத்து LoRa முனைகளிலிருந்தும் செய்திகள்'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6D7787),
              ),
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Text(
                tr('No common messages yet', 'பொது செய்திகள் எதுவும் இல்லை'),
                style: TextStyle(color: Color(0xFF8A94A4)),
              ),
            )
                : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final m = messages[index];
                return Column(
                  crossAxisAlignment: m.fromMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!m.fromMe)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          bottom: 3,
                        ),
                        child: Text(
                          m.senderId,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF697487),
                          ),
                        ),
                      ),
                    _MessageBubble(message: m),
                  ],
                );
              },
            ),
          ),
          _Composer(
            controller: controller,
            enabled: widget.connected,
            onSend: _send,
            onVoiceHoldStart: widget.onVoiceHoldStart,
            onVoiceHoldEnd: widget.onVoiceHoldEnd,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.chat.removeListener(_onChatUpdated);
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }
}

// ============================================================
// NOTIFICATIONS
// ============================================================

class NotificationPage extends StatelessWidget {
  final List<AppNotification> notifications;
  final void Function(AppNotification) onOpen;

  const NotificationPage({
    super.key,
    required this.notifications,
    required this.onOpen,
  });

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Notifications', 'அறிவிப்புகள்')),
      ),
      body: notifications.isEmpty
          ? Center(
        child: Text(
          tr('No notifications', 'அறிவிப்புகள் எதுவும் இல்லை'),
          style: TextStyle(color: Color(0xFF8A94A4)),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final n = notifications[index];
          return ListTile(
            onTap: () => onOpen(n),
            tileColor: n.read
                ? Colors.white
                : const Color(0xFFEFF4FC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0xFFE4E9EF),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE7F0FF),
              child: Icon(
                n.isPrivate
                    ? Icons.chat_bubble_rounded
                    : Icons.forum_rounded,
                color: const Color(0xFF1769E0),
              ),
            ),
            title: Text(
              n.isPrivate
                  ? tr('Private message from ${n.senderId}', 'தனிப்பட்ட செய்தி • ${n.senderId}')
                  : tr('Common message from ${n.senderId}', 'பொது செய்தி • ${n.senderId}'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              n.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _time(n.time),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8A94A4),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// MESSAGE BUBBLE
// ============================================================

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  StreamSubscription<void>? _completeSubscription;

  @override
  void initState() {
    super.initState();
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _togglePlayback() async {
    final path = widget.message.audioPath;
    if (path == null) return;

    try {
      if (_isPlaying) {
        await _player.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        await _player.play(DeviceFileSource(path));
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint('VOICE PLAYBACK ERROR: $e');
    }
  }

  @override
  void dispose() {
    _completeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    return Align(
      alignment:
      message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
        decoration: BoxDecoration(
          color: message.fromMe
              ? const Color(0xFF1769E0)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: message.fromMe
              ? null
              : Border.all(color: const Color(0xFFE3E8EF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.isVoice)
              GestureDetector(
                onTap: _togglePlayback,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 26,
                      color: message.fromMe
                          ? Colors.white
                          : const Color(0xFF1769E0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('Voice message', 'குரல் செய்தி'),
                      style: TextStyle(
                        fontSize: 14,
                        color: message.fromMe
                            ? Colors.white
                            : const Color(0xFF273142),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: message.fromMe
                      ? Colors.white
                      : const Color(0xFF273142),
                ),
              ),
            const SizedBox(height: 3),
            Text(
              '${message.time.hour.toString().padLeft(2, '0')}:'
                  '${message.time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 9,
                color: message.fromMe
                    ? Colors.white70
                    : const Color(0xFF929BA9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COMPOSER
// ============================================================

class _Composer extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final Future<void> Function() onSend;

  // Tap-to-see-info mode (used by Private Chat until voice routing exists).
  final VoidCallback? onVoiceTap;

  // Press-and-hold-to-record mode.
  final Future<void> Function()? onVoiceHoldStart;
  final Future<void> Function()? onVoiceHoldEnd;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
    this.onVoiceTap,
    this.onVoiceHoldStart,
    this.onVoiceHoldEnd,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _recording = false;
  bool _sendingVoice = false;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  bool get _hasHoldRecording => widget.onVoiceHoldStart != null;

  void _handleLongPressStart(LongPressStartDetails _) {
    if (!widget.enabled || _recording || _sendingVoice) return;

    setState(() {
      _recording = true;
      _recordingDuration = Duration.zero;
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!mounted || !_recording) return;
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      },
    );

    widget.onVoiceHoldStart?.call();
  }

  Future<void> _handleLongPressEnd(LongPressEndDetails _) async {
    if (!_recording) return;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    setState(() {
      _recording = false;
      _sendingVoice = true;
    });

    try {
      await widget.onVoiceHoldEnd?.call();
    } finally {
      if (mounted) {
        setState(() {
          _sendingVoice = false;
          _recordingDuration = Duration.zero;
        });
      }
    }
  }

  void _handleLongPressCancel() {
    if (!_recording) return;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    setState(() {
      _recording = false;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE8ECF1)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _recording || _sendingVoice
                  ? Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _sendingVoice
                      ? const Color(0xFFF1F4F8)
                      : const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _sendingVoice
                        ? const Color(0xFFD7DEE8)
                        : const Color(0xFFFFB8B8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _sendingVoice
                          ? Icons.cloud_upload_rounded
                          : Icons.mic_rounded,
                      size: 19,
                      color: _sendingVoice
                          ? const Color(0xFF1769E0)
                          : const Color(0xFFD64545),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _sendingVoice
                            ? tr('Sharing voice message...', 'குரல் செய்தியைப் பகிர்கிறது...')
                            : tr('Recording voice • ${_formatDuration(_recordingDuration)}', 'குரலைப் பதிவு செய்கிறது • ${_formatDuration(_recordingDuration)}'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _sendingVoice
                              ? const Color(0xFF4C5666)
                              : const Color(0xFFD64545),
                        ),
                      ),
                    ),
                    if (_recording)
                      Text(tr('Release to send', 'அனுப்ப விடுங்கள்'),
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8A94A4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (_sendingVoice)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              )
                  : TextField(
                controller: widget.controller,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: _recording
                      ? tr('Recording... release to send', 'பதிவு செய்கிறது... அனுப்ப விடுங்கள்')
                      : tr('Type a message...', 'செய்தியை உள்ளிடவும்...'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                ),
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
            const SizedBox(width: 7),
            GestureDetector(
              onLongPressStart: (_hasHoldRecording && widget.enabled)
                  ? _handleLongPressStart
                  : null,
              onLongPressEnd: (_hasHoldRecording && widget.enabled)
                  ? _handleLongPressEnd
                  : null,
              onLongPressCancel: (_hasHoldRecording && widget.enabled)
                  ? _handleLongPressCancel
                  : null,
              onTap: (!_hasHoldRecording && widget.enabled)
                  ? widget.onVoiceTap
                  : null,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _recording
                      ? const Color(0xFFFFE7E7)
                      : Colors.transparent,
                  border: Border.all(
                    color: _recording
                        ? const Color(0xFFD64545)
                        : const Color(0xFFD7DEE8),
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _recording
                      ? Icons.stop_circle_rounded
                      : Icons.mic_none_rounded,
                  size: 21,
                  color: _recording
                      ? const Color(0xFFD64545)
                      : (widget.enabled
                      ? const Color(0xFF273142)
                      : const Color(0xFFB6BEC9)),
                ),
              ),
            ),
            const SizedBox(width: 7),
            SizedBox(
              width: 45,
              height: 45,
              child: FilledButton(
                onPressed: widget.enabled ? widget.onSend : null,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
