// lib/providers/favorite_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class FavoriteProvider extends ChangeNotifier {
  Set<int> _favoriteIds = {};
  List<TempatModel> _favoriteItems = [];

  Set<int> get favoriteIds => _favoriteIds;
  List<TempatModel> get favoriteItems => _favoriteItems;
  int get count => _favoriteIds.length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorites') ?? [];
    _favoriteIds = ids.map((e) => int.parse(e)).toSet();
    notifyListeners();
  }

  bool isFavorite(int id) => _favoriteIds.contains(id);

  Future<void> toggle(TempatModel tempat) async {
    if (_favoriteIds.contains(tempat.id)) {
      _favoriteIds.remove(tempat.id);
      _favoriteItems.removeWhere((t) => t.id == tempat.id);
    } else {
      _favoriteIds.add(tempat.id);
      _favoriteItems.insert(0, tempat);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteIds.map((e) => e.toString()).toList());
    notifyListeners();
  }

  void syncItems(List<TempatModel> allTempat) {
    _favoriteItems = allTempat.where((t) => _favoriteIds.contains(t.id)).toList();
    notifyListeners();
  }
}