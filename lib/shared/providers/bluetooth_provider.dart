import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/services/bluetooth_audio_service.dart';

/// Provider for BluetoothAudioService
final bluetoothAudioServiceProvider = Provider<BluetoothAudioService>((ref) {
  final service = BluetoothAudioService.instance;
  // Ensure service is initialized
  service.init();
  return service;
});

/// Stream provider for connected audio device
final connectedAudioDeviceProvider = StreamProvider<AudioDevice?>((ref) async* {
  final service = ref.watch(bluetoothAudioServiceProvider);
  
  // Ensure initialized and emit initial value immediately
  await service.init();
  
  // Emit current device immediately to prevent loading
  yield service.currentDevice;
  
  // Then listen to stream for updates
  await for (final device in service.connectedDeviceStream) {
    yield device;
  }
});

/// Provider for current connected device (non-stream)
final currentAudioDeviceProvider = Provider<AudioDevice?>((ref) {
  final service = ref.watch(bluetoothAudioServiceProvider);
  return service.currentDevice;
});
