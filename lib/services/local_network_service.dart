import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sangeet/models/track.dart';
import 'package:sangeet/services/audio_player_service.dart';

/// Local Network Streaming Service
/// Allows streaming to other devices on the same WiFi network
/// and controlling playback from multiple devices
class LocalNetworkService extends ChangeNotifier {
  static final LocalNetworkService _instance = LocalNetworkService._internal();
  factory LocalNetworkService() => _instance;
  LocalNetworkService._internal();

  HttpServer? _server;
  final List<ConnectedDevice> _connectedDevices = [];
  bool _isHosting = false;
  String? _hostAddress;
  int _port = 8765;
  
  // Remote control mode
  bool _isRemoteControlled = false;
  String? _controllerAddress;

  bool get isHosting => _isHosting;
  String? get hostAddress => _hostAddress;
  int get port => _port;
  List<ConnectedDevice> get connectedDevices => List.unmodifiable(_connectedDevices);
  bool get isRemoteControlled => _isRemoteControlled;
  String? get controllerAddress => _controllerAddress;

  /// Start hosting - allow other devices to connect
  Future<bool> startHosting(AudioPlayerService audioService) async {
    if (_isHosting) return true;
    
    try {
      // Get local IP address
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      String? localIp;
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168')) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp != null) break;
      }
      
      if (localIp == null) {
        print('LocalNetworkService: Could not find local IP');
        return false;
      }
      
      _hostAddress = localIp;
      
      // Start HTTP server for control commands
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isHosting = true;
      
      print('LocalNetworkService: Hosting at $localIp:$_port');
      notifyListeners();
      
      // Handle incoming requests
      _server!.listen((request) => _handleRequest(request, audioService));
      
      return true;
    } catch (e) {
      print('LocalNetworkService: Error starting host: $e');
      return false;
    }
  }

  /// Stop hosting
  Future<void> stopHosting() async {
    await _server?.close();
    _server = null;
    _isHosting = false;
    _hostAddress = null;
    _connectedDevices.clear();
    notifyListeners();
    print('LocalNetworkService: Stopped hosting');
  }

  /// Connect to a host device
  Future<bool> connectToHost(String hostIp, int port, AudioPlayerService audioService) async {
    try {
      final uri = Uri.parse('http://$hostIp:$port/connect');
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        _isRemoteControlled = true;
        _controllerAddress = hostIp;
        notifyListeners();
        
        // Start listening for state updates
        _startStateSync(hostIp, port, audioService);
        
        print('LocalNetworkService: Connected to host at $hostIp:$port');
        return true;
      }
      return false;
    } catch (e) {
      print('LocalNetworkService: Error connecting to host: $e');
      return false;
    }
  }

  /// Disconnect from host
  void disconnectFromHost() {
    _isRemoteControlled = false;
    _controllerAddress = null;
    notifyListeners();
  }

  /// Send command to host
  Future<void> sendCommand(String command, [Map<String, dynamic>? params]) async {
    if (!_isRemoteControlled || _controllerAddress == null) return;
    
    try {
      final uri = Uri.parse('http://$_controllerAddress:$_port/command');
      final client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'command': command,
        'params': params,
      }));
      await request.close();
    } catch (e) {
      print('LocalNetworkService: Error sending command: $e');
    }
  }

  /// Handle incoming HTTP requests
  void _handleRequest(HttpRequest request, AudioPlayerService audioService) async {
    final path = request.uri.path;
    
    try {
      switch (path) {
        case '/connect':
          _handleConnect(request);
          break;
        case '/disconnect':
          _handleDisconnect(request);
          break;
        case '/command':
          await _handleCommand(request, audioService);
          break;
        case '/state':
          _handleStateRequest(request, audioService);
          break;
        case '/stream':
          await _handleStreamRequest(request, audioService);
          break;
        default:
          request.response.statusCode = HttpStatus.notFound;
          request.response.close();
      }
    } catch (e) {
      print('LocalNetworkService: Error handling request: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.close();
    }
  }

  void _handleConnect(HttpRequest request) {
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    final device = ConnectedDevice(
      address: clientIp,
      connectedAt: DateTime.now(),
    );
    
    if (!_connectedDevices.any((d) => d.address == clientIp)) {
      _connectedDevices.add(device);
      notifyListeners();
    }
    
    request.response.statusCode = HttpStatus.ok;
    request.response.write(jsonEncode({'status': 'connected', 'host': _hostAddress}));
    request.response.close();
    
    print('LocalNetworkService: Device connected from $clientIp');
  }

  void _handleDisconnect(HttpRequest request) {
    final clientIp = request.connectionInfo?.remoteAddress.address;
    _connectedDevices.removeWhere((d) => d.address == clientIp);
    notifyListeners();
    
    request.response.statusCode = HttpStatus.ok;
    request.response.close();
    
    print('LocalNetworkService: Device disconnected from $clientIp');
  }

  Future<void> _handleCommand(HttpRequest request, AudioPlayerService audioService) async {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final command = data['command'] as String;
    final params = data['params'] as Map<String, dynamic>?;
    
    switch (command) {
      case 'play':
        await audioService.resume();
        break;
      case 'pause':
        await audioService.pause();
        break;
      case 'next':
        await audioService.skipToNext();
        break;
      case 'previous':
        await audioService.skipToPrevious();
        break;
      case 'seek':
        final position = params?['position'] as int?;
        if (position != null) {
          await audioService.seek(Duration(milliseconds: position));
        }
        break;
      case 'volume':
        final volume = params?['volume'] as double?;
        if (volume != null) {
          await audioService.setVolume(volume);
        }
        break;
      case 'shuffle':
        audioService.toggleShuffle();
        break;
      case 'repeat':
        audioService.cycleRepeatMode();
        break;
    }
    
    request.response.statusCode = HttpStatus.ok;
    request.response.close();
    
    // Notify all connected devices of state change
    _broadcastState(audioService);
  }

  void _handleStateRequest(HttpRequest request, AudioPlayerService audioService) {
    final track = audioService.currentTrack;
    final state = {
      'isPlaying': audioService.isPlaying,
      'position': audioService.position.inMilliseconds,
      'duration': audioService.duration.inMilliseconds,
      'isShuffled': audioService.isShuffled,
      'repeatMode': audioService.repeatMode.name,
      'currentTrack': track != null ? {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'thumbnailUrl': track.thumbnailUrl,
        'duration': track.duration.inMilliseconds,
      } : null,
    };
    
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(state));
    request.response.close();
  }

  Future<void> _handleStreamRequest(HttpRequest request, AudioPlayerService audioService) async {
    // This would stream the actual audio data
    // For now, return the stream URL
    final track = audioService.currentTrack;
    if (track != null) {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'trackId': track.id,
        'streamUrl': 'http://$_hostAddress:8080/stream/${track.id}',
      }));
    } else {
      request.response.statusCode = HttpStatus.notFound;
    }
    request.response.close();
  }

  void _broadcastState(AudioPlayerService audioService) {
    // In a real implementation, this would use WebSockets
    // to push state updates to all connected devices
  }

  void _startStateSync(String hostIp, int port, AudioPlayerService audioService) {
    // Poll for state updates periodically
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isRemoteControlled) {
        timer.cancel();
        return;
      }
      
      try {
        final uri = Uri.parse('http://$hostIp:$port/state');
        final client = HttpClient();
        final request = await client.getUrl(uri);
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final body = await utf8.decoder.bind(response).join();
          final state = jsonDecode(body) as Map<String, dynamic>;
          // Update local state based on host state
          // This would sync the UI with the host's playback state
        }
      } catch (e) {
        // Host might be unavailable
      }
    });
  }

  /// Scan for available hosts on the network
  Future<List<DiscoveredHost>> scanForHosts() async {
    final hosts = <DiscoveredHost>[];
    
    try {
      // Get local network prefix
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      String? networkPrefix;
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168')) {
            final parts = addr.address.split('.');
            networkPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
            break;
          }
        }
        if (networkPrefix != null) break;
      }
      
      if (networkPrefix == null) return hosts;
      
      // Scan common addresses (this is simplified - real implementation would be more thorough)
      final futures = <Future>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$networkPrefix.$i';
        futures.add(_checkHost(ip, _port).then((isHost) {
          if (isHost) {
            hosts.add(DiscoveredHost(address: ip, port: _port));
          }
        }));
      }
      
      await Future.wait(futures).timeout(const Duration(seconds: 5), onTimeout: () => []);
    } catch (e) {
      print('LocalNetworkService: Error scanning: $e');
    }
    
    return hosts;
  }

  Future<bool> _checkHost(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 200));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class ConnectedDevice {
  final String address;
  final DateTime connectedAt;
  String? name;

  ConnectedDevice({
    required this.address,
    required this.connectedAt,
    this.name,
  });
}

class DiscoveredHost {
  final String address;
  final int port;
  String? name;

  DiscoveredHost({
    required this.address,
    required this.port,
    this.name,
  });
}
