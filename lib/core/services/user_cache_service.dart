import 'package:shared_preferences/shared_preferences.dart';

class UserCacheService {
  Future<void> saveUserInfo(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getUserInfo(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
