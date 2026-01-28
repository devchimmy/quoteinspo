import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:quote_application/wallpaper%20model/wallpaper_model.dart';

class WallpaperService {
  static Future<List<WallpaperModel>> loadWallpapers() async {
    final data = await rootBundle.loadString(
      'assets/json/wallpaper_backgrounds.json',
    );

    final List decoded = json.decode(data);

    return decoded
        .map((e) => WallpaperModel.fromJson(e))
        .toList();
  }
}
