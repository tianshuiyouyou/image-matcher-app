import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/image_data.dart';

class DBHelper {
  static const String STORAGE_KEY = 'image_library';

  static Future<void> saveLibrary(List<ImageData> library) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = library.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(STORAGE_KEY, jsonList);
  }

  static Future<List<ImageData>> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList(STORAGE_KEY);
    if (jsonList == null) return [];
    return jsonList.map((str) => ImageData.fromJson(jsonDecode(str))).toList();
  }

  static Future<void> clearLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(STORAGE_KEY);
  }
}
