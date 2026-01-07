import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/audio_player_service.dart';

/// Cast Service for Chromecast/AirPlay support
/// Allows casting audio to TV/speakers
/// Note: Requires cast package for actual implementation
class CastService extends ChangeNotifier {
  static final CastService _instance = CastService._internal();
  factory CastService() => _instance;
  CastService._internal();

  bool _isScanning = false;
  bool _isConnected = false;
  CastDevice? _connectedDevice;
  final List<CastDevice> _availableDevices = [];
  
  // Playback state when casting
  bool _isCastPlaying = false;
  Duration _castPosition = Duration.zero;
  Duration _castDuration = Duration.zero;

  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  CastDevice? get connectedDevice => _connectedDevice;
  List<CastDevice> get availableDevices => List.unmodifiable(_availableDevices);
  bool get isCastPlaying => _isCastPlaying;
  Duration get castPosition => _castPosition;
  Duration get castDuration => _castDuration;

  /// Start scanning for cast devices
  Future<void> startScanning() async {
    if (_isScanning) return;
    
    _isScanning = true;
    _availableDevices.clear();
    notifyListeners();
    
    print('CastService: Scanning for devices...');
    
    // In actual implementation, this would use:
    // - cast package for Chromecast
    // - flutter_airplay for AirPlay
    // - DLNA discovery for DLNA devices
    
    // Simulate device discovery
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock devices for UI development
    // In production, these would come from actual discovery
    _availableDevices.addAll([
      // Devices would be discovered here
    ]);
    
    _isScanning = false;
    notifyListeners();
    
    print('CastService: Found ${_availableDevices.length} devices');
  }

  /// Stop scanning
  void stopScanning() {
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a cast device
  Future<bool> connectToDevice(CastDevice device) async {
    print('CastService: Connecting to ${device.name}...');
    
    try {
      // In actual implementation:
      // - For Chromecast: Use cast package to connect
      // - For AirPlay: Use flutter_airplay
      // - For DLNA: Use dlna_dart or similar
      
      await Future.delayed(const Duration(seconds: 1));
      
      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();
      
      print('CastService: Connected to ${device.name}');
      return true;
    } catch (e) {
      print('CastService: Connection failed: $e');
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    if (!_isConnected) return;
    
    print('CastService: Disconnecting from ${_connectedDevice?.name}');
    
    _connectedDevice = null;
    _isConnected = false;
    _isCastPlaying = false;
    _castPosition = Duration.zero;
    _castDuration = Duration.zero;
    notifyListeners();
  }

  /// Cast a track to the connected device
  Future<bool> castTrack(Track track, String streamUrl) async {
    if (!_isConnected || _connectedDevice == null) {
      print('CastService: Not connected to any device');
      return false;
    }
    
    print('CastService: Casting "${track.title}" to ${_connectedDevice!.name}');
    
    try {
      // In actual implementation:
      // - Send media URL to cast device
      // - Set metadata (title, artist, artwork)
      // - Start playback
      
      _castDuration = track.duration;
      _castPosition = Duration.zero;
      _isCastPlaying = true;
      notifyListeners();
      
      // Start position tracking
      _startPositionTracking();
      
      return true;
    } catch (e) {
      print('CastService: Cast failed: $e');
      return false;
    }
  }

  /// Play on cast device
  Future<void> play() async {
    if (!_isConnected) return;
    _isCastPlaying = true;
    notifyListeners();
  }

  /// Pause on cast device
  Future<void> pause() async {
    if (!_isConnected) return;
    _isCastPlaying = false;
    notifyListeners();
  }

  /// Seek on cast device
  Future<void> seek(Duration position) async {
    if (!_isConnected) return;
    _castPosition = position;
    notifyListeners();
  }

  /// Set volume on cast device (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (!_isConnected) return;
    // Send volume command to cast device
    print('CastService: Setting volume to ${(volume * 100).toInt()}%');
  }

  Timer? _positionTimer;
  
  void _startPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isCastPlaying && _castPosition < _castDuration) {
        _castPosition += const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void _stopPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  @override
  void dispose() {
    _stopPositionTracking();
    super.dispose();
  }
}

/// Represents a cast-capable device
class CastDevice {
  final String id;
  final String name;
  final CastDeviceType type;
  final String? modelName;
  final String? ipAddress;

  const CastDevice({
    required this.id,
    required this.name,
    required this.type,
    this.modelName,
    this.ipAddress,
  });
}

enum CastDeviceType {
  chromecast,
  airplay,
  dlna,
  smartTv,
  speaker,
}

extension CastDeviceTypeExtension on CastDeviceType {
  String get displayName {
    switch (this) {
      case CastDeviceType.chromecast:
        return 'Chromecast';
      case CastDeviceType.airplay:
        return 'AirPlay';
      case CastDeviceType.dlna:
        return 'DLNA';
      case CastDeviceType.smartTv:
        return 'Smart TV';
      case CastDeviceType.speaker:
        return 'Speaker';
    }
  }
  
  String get icon {
    switch (this) {
      case CastDeviceType.chromecast:
        return '📺';
      case CastDeviceType.airplay:
        return '📱';
      case CastDeviceType.dlna:
        return '🔊';
      case CastDeviceType.smartTv:
        return '📺';
      case CastDeviceType.speaker:
        return '🔈';
    }
  }
}
