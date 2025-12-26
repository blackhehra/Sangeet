import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Equalizer preset with frequency band gains
class EqualizerPreset {
  final String name;
  final List<double> gains; // -12 to +12 dB for each band

  const EqualizerPreset({
    required this.name,
    required this.gains,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'gains': gains,
  };

  factory EqualizerPreset.fromJson(Map<String, dynamic> json) {
    return EqualizerPreset(
      name: json['name'] as String,
      gains: (json['gains'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }
}

/// Equalizer service with presets and custom bands
class EqualizerService extends ChangeNotifier {
  static EqualizerService? _instance;
  static EqualizerService get instance => _instance ??= EqualizerService._();
  
  EqualizerService._();

  static const String _presetKey = 'equalizer_preset';
  static const String _customGainsKey = 'equalizer_custom_gains';
  static const String _enabledKey = 'equalizer_enabled';

  SharedPreferences? _prefs;
  
  // 5-band equalizer frequencies (Hz)
  static const List<int> frequencies = [60, 230, 910, 3600, 14000];
  static const List<String> frequencyLabels = ['60', '230', '910', '3.6k', '14k'];
  
  // Built-in presets
  static const List<EqualizerPreset> presets = [
    EqualizerPreset(name: 'Flat', gains: [0, 0, 0, 0, 0]),
    EqualizerPreset(name: 'Bass Boost', gains: [6, 4, 0, 0, 0]),
    EqualizerPreset(name: 'Bass Reducer', gains: [-6, -4, 0, 0, 0]),
    EqualizerPreset(name: 'Treble Boost', gains: [0, 0, 0, 4, 6]),
    EqualizerPreset(name: 'Treble Reducer', gains: [0, 0, 0, -4, -6]),
    EqualizerPreset(name: 'Rock', gains: [5, 3, 0, 3, 5]),
    EqualizerPreset(name: 'Pop', gains: [-1, 2, 4, 2, -1]),
    EqualizerPreset(name: 'Jazz', gains: [3, 0, 2, 3, 4]),
    EqualizerPreset(name: 'Classical', gains: [4, 2, 0, 2, 4]),
    EqualizerPreset(name: 'Hip Hop', gains: [5, 4, 0, 1, 3]),
    EqualizerPreset(name: 'Electronic', gains: [4, 2, 0, 2, 4]),
    EqualizerPreset(name: 'Vocal', gains: [-2, 0, 4, 2, 0]),
  ];

  String _currentPreset = 'Flat';
  List<double> _customGains = [0, 0, 0, 0, 0];
  bool _enabled = true;

  String get currentPreset => _currentPreset;
  List<double> get customGains => List.unmodifiable(_customGains);
  bool get enabled => _enabled;

  /// Get current gains (from preset or custom)
  List<double> get currentGains {
    if (_currentPreset == 'Custom') {
      return _customGains;
    }
    final preset = presets.firstWhere(
      (p) => p.name == _currentPreset,
      orElse: () => presets.first,
    );
    return preset.gains;
  }

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    print('EqualizerService: Initialized with preset: $_currentPreset, enabled: $_enabled');
  }

  void _loadSettings() {
    _currentPreset = _prefs?.getString(_presetKey) ?? 'Flat';
    _enabled = _prefs?.getBool(_enabledKey) ?? true;
    
    final customJson = _prefs?.getString(_customGainsKey);
    if (customJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(customJson);
        _customGains = decoded.map((e) => (e as num).toDouble()).toList();
      } catch (e) {
        _customGains = [0, 0, 0, 0, 0];
      }
    }
  }

  Future<void> _saveSettings() async {
    await _prefs?.setString(_presetKey, _currentPreset);
    await _prefs?.setBool(_enabledKey, _enabled);
    await _prefs?.setString(_customGainsKey, jsonEncode(_customGains));
  }

  /// Set preset by name
  Future<void> setPreset(String presetName) async {
    _currentPreset = presetName;
    await _saveSettings();
    notifyListeners();
    print('EqualizerService: Preset changed to $_currentPreset');
  }

  /// Set custom gain for a specific band
  Future<void> setCustomGain(int bandIndex, double gain) async {
    if (bandIndex < 0 || bandIndex >= _customGains.length) return;
    
    // Clamp gain to -12 to +12 dB
    _customGains[bandIndex] = gain.clamp(-12.0, 12.0);
    _currentPreset = 'Custom';
    await _saveSettings();
    notifyListeners();
  }

  /// Set all custom gains at once
  Future<void> setCustomGains(List<double> gains) async {
    if (gains.length != _customGains.length) return;
    
    _customGains = gains.map((g) => g.clamp(-12.0, 12.0)).toList();
    _currentPreset = 'Custom';
    await _saveSettings();
    notifyListeners();
  }

  /// Toggle equalizer enabled state
  Future<void> toggleEnabled() async {
    _enabled = !_enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Set enabled state
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Reset to flat
  Future<void> reset() async {
    _currentPreset = 'Flat';
    _customGains = [0, 0, 0, 0, 0];
    await _saveSettings();
    notifyListeners();
  }
}
