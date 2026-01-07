import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Model for connected audio device
class AudioDevice {
  final String name;
  final String id;
  final AudioDeviceType type;
  final bool isConnected;

  const AudioDevice({
    required this.name,
    required this.id,
    required this.type,
    this.isConnected = true,
  });

  @override
  String toString() => 'AudioDevice(name: $name, type: $type)';
}

enum AudioDeviceType {
  bluetooth,
  wired,
  speaker,
  unknown,
}

/// Service for detecting connected Bluetooth audio devices
class BluetoothAudioService {
  static final BluetoothAudioService _instance = BluetoothAudioService._internal();
  factory BluetoothAudioService() => _instance;
  BluetoothAudioService._internal();

  static BluetoothAudioService get instance => _instance;

  final _connectedDeviceController = StreamController<AudioDevice?>.broadcast();
  Stream<AudioDevice?> get connectedDeviceStream => _connectedDeviceController.stream;
  
  AudioDevice? _currentDevice;
  AudioDevice? get currentDevice => _currentDevice;
  
  StreamSubscription? _adapterStateSubscription;
  bool _isInitialized = false;

  /// Initialize the service and start listening for Bluetooth changes
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Emit initial null value to prevent loading state
    _connectedDeviceController.add(null);

    try {
      // Check if we have Bluetooth permissions first
      final hasPermission = await hasBluetoothPermission();
      if (!hasPermission) {
        print('BluetoothAudioService: No Bluetooth permission, service will be inactive');
        return;
      }

      // Listen to Bluetooth adapter state changes
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        if (state == BluetoothAdapterState.on) {
          _checkConnectedDevices();
        } else {
          _currentDevice = null;
          _connectedDeviceController.add(null);
        }
      });

      // Initial check - this will update the stream with actual device if found
      await _checkConnectedDevices();
      
      // Set up periodic refresh to catch device connections/disconnections
      _startPeriodicRefresh();
    } catch (e) {
      print('BluetoothAudioService: Failed to initialize due to missing permissions: $e');
      // Service remains inactive but doesn't crash the app
    }
  }
  
  Timer? _refreshTimer;
  
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkConnectedDevices();
    });
  }

  /// Check if Bluetooth permission is granted
  Future<bool> hasBluetoothPermission() async {
    final bluetoothConnect = await Permission.bluetoothConnect.status;
    final bluetoothScan = await Permission.bluetoothScan.status;
    return bluetoothConnect.isGranted && bluetoothScan.isGranted;
  }

  /// Request Bluetooth permissions
  Future<bool> requestBluetoothPermission() async {
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetooth,
    ].request();

    return statuses[Permission.bluetoothConnect]?.isGranted == true &&
           statuses[Permission.bluetoothScan]?.isGranted == true;
  }

  /// Check for connected Bluetooth audio devices
  Future<void> _checkConnectedDevices() async {
    try {
      // First try to get system-level connected audio devices via platform channel
      final device = await _getSystemAudioDevice();
      if (device != null) {
        _currentDevice = device;
        _connectedDeviceController.add(_currentDevice);
        return;
      }

      // Check if we still have permissions before proceeding
      final hasPermission = await hasBluetoothPermission();
      if (!hasPermission) {
        print('BluetoothAudioService: No permission for device check');
        _currentDevice = null;
        _connectedDeviceController.add(null);
        return;
      }

      // Fallback: Check if Bluetooth is on and scan for connected devices
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _currentDevice = null;
        _connectedDeviceController.add(null);
        return;
      }

      // Get connected devices through flutter_blue_plus
      final connectedDevices = FlutterBluePlus.connectedDevices;
      
      if (connectedDevices.isNotEmpty) {
        // Find audio devices (headphones, speakers, etc.)
        for (final device in connectedDevices) {
          // Check if it's likely an audio device by name patterns
          final name = device.platformName.toLowerCase();
          if (_isLikelyAudioDevice(name)) {
            _currentDevice = AudioDevice(
              name: device.platformName,
              id: device.remoteId.str,
              type: AudioDeviceType.bluetooth,
            );
            _connectedDeviceController.add(_currentDevice);
            print('BluetoothAudioService: Found connected audio device: ${device.platformName}');
            return;
          }
        }
        
        // If no obvious audio device, use the first connected device
        if (connectedDevices.isNotEmpty) {
          final device = connectedDevices.first;
          _currentDevice = AudioDevice(
            name: device.platformName,
            id: device.remoteId.str,
            type: AudioDeviceType.bluetooth,
          );
          _connectedDeviceController.add(_currentDevice);
          print('BluetoothAudioService: Using connected device: ${device.platformName}');
          return;
        }
      }

      // No connected devices
      _currentDevice = null;
      _connectedDeviceController.add(null);
    } catch (e) {
      print('BluetoothAudioService: Error checking devices: $e');
      _currentDevice = null;
      _connectedDeviceController.add(null);
    }
  }

  /// Get system-level connected audio device via platform channel
  Future<AudioDevice?> _getSystemAudioDevice() async {
    try {
      print('BluetoothAudioService: Calling platform channel...');
      const platform = MethodChannel('com.sangeet.audio/bluetooth');
      final result = await platform.invokeMethod('getConnectedAudioDevice')
          .timeout(const Duration(seconds: 2));
      
      print('BluetoothAudioService: Platform channel result: $result');
      
      if (result != null && result is Map) {
        final name = result['name'] as String?;
        final type = result['type'] as String?;
        
        print('BluetoothAudioService: Device name=$name, type=$type');
        
        if (name != null && type == 'bluetooth') {
          print('BluetoothAudioService: Found device via platform channel: $name');
          return AudioDevice(
            name: name,
            id: result['id'] as String? ?? 'system',
            type: AudioDeviceType.bluetooth,
          );
        }
      } else {
        print('BluetoothAudioService: Platform channel returned null or invalid data');
      }
    } catch (e) {
      // Platform channel not implemented or error - fallback to flutter_blue_plus
      print('BluetoothAudioService: Platform channel error: $e');
    }
    return null;
  }

  /// Check if device name suggests it's an audio device
  bool _isLikelyAudioDevice(String name) {
    final audioKeywords = [
      'airpods', 'buds', 'earbuds', 'headphone', 'headset',
      'speaker', 'soundbar', 'audio', 'jbl', 'bose', 'sony',
      'beats', 'samsung', 'galaxy buds', 'pixel buds', 'jabra',
      'sennheiser', 'anker', 'soundcore', 'marshall', 'harman',
      'bang', 'olufsen', 'skullcandy', 'audio-technica',
    ];
    
    for (final keyword in audioKeywords) {
      if (name.contains(keyword)) return true;
    }
    return false;
  }

  /// Open Bluetooth settings
  Future<void> openBluetoothSettings() async {
    try {
      await FlutterBluePlus.turnOn();
    } on PlatformException catch (e) {
      print('BluetoothAudioService: Cannot turn on Bluetooth: $e');
      // On some devices, we need to open settings manually
      await openAppSettings();
    }
  }

  /// Refresh connected devices
  Future<void> refresh() async {
    await _checkConnectedDevices();
  }

  /// Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
    _adapterStateSubscription?.cancel();
    _connectedDeviceController.close();
  }
}
