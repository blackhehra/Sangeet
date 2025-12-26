import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/services/bluetooth_audio_service.dart';

/// Provider for BluetoothAudioService
final bluetoothAudioServiceProvider = Provider<BluetoothAudioService>((ref) {
  return BluetoothAudioService.instance;
});

/// Stream provider for connected audio device
final connectedAudioDeviceProvider = StreamProvider<AudioDevice?>((ref) {
  final service = ref.watch(bluetoothAudioServiceProvider);
  return service.connectedDeviceStream;
});

/// Provider for current connected device (non-stream)
final currentAudioDeviceProvider = Provider<AudioDevice?>((ref) {
  final service = ref.watch(bluetoothAudioServiceProvider);
  return service.currentDevice;
});
