import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteQuotesService extends ChangeNotifier {
  static final FavoriteQuotesService _instance = FavoriteQuotesService._internal();

  factory FavoriteQuotesService() => _instance;

  FavoriteQuotesService._internal();

  final List<Map<String, String>> _favorites = [];
  static const String _storageKey = 'favorite_quotes';
  bool _initialized = false;

  List<Map<String, String>> get favorites => List.unmodifiable(_favorites);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey);
    if (stored != null) {
      _favorites.clear();
      _favorites.addAll(stored.map((s) => Map<String, String>.from(jsonDecode(s))));
    }
    _initialized = true;
    notifyListeners(); // 🔄 Notify UI
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _favorites.map((q) => jsonEncode(q)).toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  bool isFavorite(Map<String, String> quote) {
    final id = quote['id'];
    if (id == null) return false;
    return _favorites.any((fav) => fav['id'] == id);
  }

  Future<void> addFavorite(Map<String, String> item) async {
    if (item['id'] == null || isFavorite(item)) return;
    _favorites.add(item);
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> removeFavorite(Map<String, String> item) async {
    _favorites.removeWhere((fav) => fav['id'] == item['id']);
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> toggleFavorite(Map<String, String> item) async {
    if (isFavorite(item)) {
      await removeFavorite(item);
    } else {
      await addFavorite(item);
    }
  }

  Future<void> clearFavorites() async {
    _favorites.clear();
    await _saveFavorites();
    notifyListeners();
  }
}
