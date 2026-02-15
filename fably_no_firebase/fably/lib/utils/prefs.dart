import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class Prefs{

  Future<void> setPrefs(name, value) async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(name, value);
  }

  Future<String?> getPrefs(name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userInfoString = prefs.getString(name);
    return userInfoString;
  }

  Future<void> clearPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();

    print(prefs.getKeys());
  }
}