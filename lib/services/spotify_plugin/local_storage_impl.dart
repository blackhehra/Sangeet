import 'package:hetu_spotube_plugin/hetu_spotube_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-based implementation of Localstorage for the Hetu plugin
class SharedPreferencesLocalStorage implements Localstorage {
  final SharedPreferences _prefs;
  final String pluginSlug;

  SharedPreferencesLocalStorage(this._prefs, this.pluginSlug);

  String _prefix(String key) {
    return 'sangeet_plugin.$pluginSlug.$key';
  }

  @override
  Future<void> clear() {
    return _prefs.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(_prefix(key));
  }

  @override
  Future<bool?> getBool(String key) async {
    return _prefs.getBool(_prefix(key));
  }

  @override
  Future<double?> getDouble(String key) async {
    return _prefs.getDouble(_prefix(key));
  }

  @override
  Future<int?> getInt(String key) async {
    return _prefs.getInt(_prefix(key));
  }

  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(_prefix(key));
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    return _prefs.getStringList(_prefix(key));
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(_prefix(key));
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(_prefix(key), value);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(_prefix(key), value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(_prefix(key), value);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(_prefix(key), value);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(_prefix(key), value);
  }
}
