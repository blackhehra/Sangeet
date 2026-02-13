import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryOptimizationService extends StateNotifier<bool> {
  static const _channel = MethodChannel('com.sangeet.battery/optimization');
  static const _promptShownKey = 'battery_optimization_prompt_shown';

  BatteryOptimizationService() : super(false) {
    checkStatus();
  }

  /// Check if the app is currently exempt from battery optimizations
  Future<bool> checkStatus() async {
    if (!Platform.isAndroid) {
      state = true;
      return true;
    }
    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      state = result ?? false;
      return state;
    } catch (e) {
      print('BatteryOptimizationService: Failed to check status: $e');
      state = false;
      return false;
    }
  }

  /// Request the system dialog to disable battery optimization for this app
  Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      print('BatteryOptimizationService: Failed to request optimization: $e');
    }
  }

  /// Open the battery optimization settings page
  Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      print('BatteryOptimizationService: Failed to open settings: $e');
    }
  }

  /// Check if the first-launch prompt has already been shown
  Future<bool> hasPromptBeenShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_promptShownKey) ?? false;
  }

  /// Mark the first-launch prompt as shown
  Future<void> markPromptAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptShownKey, true);
  }
}

/// Provider for battery optimization service
/// State is `true` if the app is exempt from battery optimizations
final batteryOptimizationProvider =
    StateNotifierProvider<BatteryOptimizationService, bool>((ref) {
  return BatteryOptimizationService();
});
