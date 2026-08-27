import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

      home: const DevicePage(),
    );
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
// DEVICE PAGE
// ============================================================

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final List<ScanResult> scanResults = [];

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
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    connectionSubscription?.cancel();
    notificationSubscription?.cancel();

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
      debugPrint('SCAN ERROR: $e');

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
      BluetoothDevice device,
      ) async {
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
      // IMPORTANT:
      // Create connection listener after successful connection.
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
      // Discover characteristics
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
      // Open chat page
      // --------------------------------------------------------

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            device: device,
            rxCharacteristic: rxCharacteristic!,
            onDisconnect: disconnectDevice,
          ),
        ),
      );

      // When returning from ChatPage
      if (mounted &&
          connectedDevice != null) {
        setState(() {
          status = 'Connected';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('CONNECTION ERROR: $e');
      debugPrint(stackTrace.toString());

      await cleanupBle();

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
      BluetoothDevice device,
      ) async {
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
    // CRITICAL FIX
    //
    // LISTENER IS CREATED BEFORE NOTIFICATIONS ARE ENABLED.
    // ========================================================

    await notificationSubscription?.cancel();

    notificationSubscription =
        txCharacteristic!.onValueReceived.listen(
              (value) {
            // ----------------------------------------------------
            // DO NOT TOUCH THE TEXT FIELD HERE.
            // DO NOT REQUIRE KEYBOARD FOCUS.
            // ----------------------------------------------------

            final message = utf8.decode(
              value,
              allowMalformed: true,
            );

            debugPrint(
              '================================',
            );

            debugPrint(
              'BLE NOTIFICATION RECEIVED',
            );

            debugPrint(
              'DATA: $message',
            );

            debugPrint(
              '================================',
            );

            // The ChatPage owns the actual message display.
            //
            // This listener remains active while connected.
          },
          onError: (error) {
            debugPrint(
              'BLE NOTIFICATION ERROR: $error',
            );
          },
        );

    // --------------------------------------------------------
    // NOW enable notifications.
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
      BluetoothDevice device,
      ) {
    final name = device.platformName;

    if (name.isNotEmpty) {
      return name;
    }

    return 'ESP32 Device';
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
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF303A4D),
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
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              14,
            ),
            child: Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF5),
                borderRadius:
                BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFDDE3EB),
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 44,
                      color: Color(0xFF8994A5),
                    ),
                  ),

                  Positioned(
                    left: 20,
                    top: 20,
                    child: _mapMarker(
                      connected: connectedDevice !=
                          null,
                    ),
                  ),

                  Positioned(
                    right: 55,
                    bottom: 35,
                    child: _mapMarker(
                      connected: false,
                    ),
                  ),

                  Positioned(
                    left: 120,
                    bottom: 50,
                    child: _mapMarker(
                      connected: false,
                    ),
                  ),

                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Junction Map',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ====================================================
          // DEVICES TITLE
          // ====================================================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              children: [
                const Text(
                  'Nearby Devices',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202A3A),
                  ),
                ),

                const Spacer(),

                Text(
                  '${scanResults.length} found',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7B8493),
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
                    color: Color(0xFF9AA3B2),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'No devices found',
                    style: TextStyle(
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
                    getDeviceName(device),
                    id: device.remoteId
                        .toString(),
                    rssi: result.rssi,
                    connected:
                    isConnected,
                    connecting:
                    isConnecting,
                    onConnect: () {
                      connectToDevice(
                        device,
                      );
                    },
                    onDisconnect:
                    disconnectDevice,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapMarker({
    required bool connected,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: connected
            ? const Color(0xFF1769E0)
            : Colors.white,
        border: Border.all(
          color: connected
              ? const Color(0xFF1769E0)
              : const Color(0xFFB8C1CE),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            color: Colors.black12,
          ),
        ],
      ),
      child: Icon(
        Icons.location_on,
        size: 17,
        color: connected
            ? Colors.white
            : const Color(0xFF687487),
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

  const _DeviceCard({
    required this.name,
    required this.id,
    required this.rssi,
    required this.connected,
    required this.connecting,
    required this.onConnect,
    required this.onDisconnect,
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
              color: const Color(0xFFEFF4FC),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.developer_board_outlined,
              size: 22,
              color: Color(0xFF1769E0),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202A3A),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  id,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A94A4),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'RSSI $rssi dBm',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF727C8D),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          if (connected)
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: onDisconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFFFCECEC),
                  foregroundColor:
                  const Color(0xFFD64545),
                  elevation: 0,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'DISCONNECT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed:
                connecting ? null : onConnect,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 13,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  connecting
                      ? '...'
                      : 'CONNECT',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

  final BluetoothCharacteristic rxCharacteristic;

  final Future<void> Function()
  onDisconnect;

  const ChatPage({
    super.key,
    required this.device,
    required this.rxCharacteristic,
    required this.onDisconnect,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController
  messageController =
  TextEditingController();

  final ScrollController
  chatScrollController =
  ScrollController();

  final List<ChatMessage> messages = [];

  BluetoothCharacteristic? txCharacteristic;

  StreamSubscription<List<int>>?
  notificationSubscription;

  bool isConnected = true;
  bool isSending = false;

  // ==========================================================
  // UUID
  // ==========================================================

  final Guid txUuid = Guid(
    '6E400003-B5A3-F393-E0A9-E50E24DCCA9E',
  );

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
      await widget.device.discoverServices();

      for (final service in services) {
        for (final characteristic
        in service.characteristics) {
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

      // ======================================================
      // CRITICAL ORDER
      //
      // 1. Cancel old listener
      // 2. Create listener
      // 3. Enable notification
      //
      // NOT the other way around.
      // ======================================================

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
      List<int> value,
      ) {
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
      'MESSAGE FROM ESP32',
    );

    debugPrint(message);

    debugPrint(
      '================================',
    );

    if (!mounted) return;

    // ========================================================
    // UI UPDATE HAPPENS DIRECTLY HERE.
    //
    // It does NOT depend on:
    // - TextField
    // - keyboard
    // - cursor
    // - messageController
    // ========================================================

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
      String message,
      ) async {
    message = message.trim();

    if (message.isEmpty) return;

    if (!isConnected) {
      return;
    }

    if (isSending) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      await widget.rxCharacteristic.write(
        utf8.encode(message),
        withoutResponse: false,
      );

      debugPrint('================================');
      debugPrint('MESSAGE SENT TO ESP32');
      debugPrint(message);
      debugPrint('================================');

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
      debugPrint('SEND ERROR: $e');

      if (!mounted) return;

      setState(() {
        isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
        ),
      );
    }
  }

  // ==========================================================
  // DISCONNECT
  // ==========================================================

  Future<void> disconnectFromChat() async {
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
        .addPostFrameCallback((_) {
      if (!chatScrollController
          .hasClients) {
        return;
      }

      chatScrollController.animateTo(
        chatScrollController
            .position
            .maxScrollExtent,
        duration:
        const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  // ==========================================================
  // TIME
  // ==========================================================

  String formatTime(DateTime time) {
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
    notificationSubscription?.cancel();

    messageController.dispose();

    chatScrollController.dispose();

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
            Navigator.of(context).pop();
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
                const Color(0xFFEFF4FC),
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.developer_board,
                size: 19,
                color:
                Color(0xFF1769E0),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
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
                    TextOverflow.ellipsis,
                    style: const TextStyle(
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
                          BoxShape.circle,
                          color:
                          Colors.green,
                        ),
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      const Text(
                        'Connected',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                          Color(0xFF6D7787),
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
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 9,
            ),
            decoration:
            const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE8ECF1),
                ),
              ),
            ),
            child: Text(
              widget.device.remoteId
                  .toString(),
              style: const TextStyle(
                fontSize: 10,
                color:
                Color(0xFF8993A2),
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
                MainAxisSize.min,
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
                    child: const Icon(
                      Icons.chat_bubble_outline,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w600,
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
                    style: TextStyle(
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
                  message: message,
                  time: formatTime(
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
              const EdgeInsets.fromLTRB(
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
                    color: Color(0xFFE8ECF1),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.end,
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
                      TextInputAction.newline,
                      decoration:
                      const InputDecoration(
                        hintText:
                        'Type a message...',
                        hintStyle: TextStyle(
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
                      onSubmitted: (value) {
                        sendChatMessage(
                          value,
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 7),

                  SizedBox(
                    width: 45,
                    height: 45,
                    child: FilledButton(
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
                      FilledButton.styleFrom(
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
                          strokeWidth: 2,
                          color:
                          Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.send_rounded,
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

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String time;

  const _ChatBubble({
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
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
        decoration: BoxDecoration(
          color: message.fromMe
              ? const Color(0xFF1769E0)
              : Colors.white,
          borderRadius:
          BorderRadius.circular(14),
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
          CrossAxisAlignment.end,
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

            const SizedBox(height: 3),

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