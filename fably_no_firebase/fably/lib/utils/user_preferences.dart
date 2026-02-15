import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String genderKey = 'user_gender';

  static Future<bool> hasSelectedGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(genderKey) != null;
  }

  static Future<void> saveGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(genderKey, gender);
  }
}
