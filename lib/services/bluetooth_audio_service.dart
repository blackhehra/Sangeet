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

    // Listen to Bluetooth adapter state changes
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _checkConnectedDevices();
      } else {
        _currentDevice = null;
        _connectedDeviceController.add(null);
      }
    });

    // Initial check
    await _checkConnectedDevices();
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
      // Check if Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _currentDevice = null;
        _connectedDeviceController.add(null);
        return;
      }

      // Get connected devices
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
    _adapterStateSubscription?.cancel();
    _connectedDeviceController.close();
  }
}
