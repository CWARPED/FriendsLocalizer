import 'package:shared_preferences/shared_preferences.dart';
import 'store.dart';

/// Store de production basé sur shared_preferences.
class PrefsStore implements Store {
  final SharedPreferences _prefs;
  PrefsStore(this._prefs);

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}
