import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/food_model.dart';

/// Top-level function so it can be used with compute() isolate.
/// Parses the raw JSON string into a list of FoodItem objects off the main thread.
List<FoodItem> _parseFoodsInIsolate(String jsonString) {
  final jsonData = json.decode(jsonString) as Map<String, dynamic>;
  final foodsList = jsonData['foods'] as List<dynamic>? ?? [];
  return foodsList
      .map((j) => FoodItem.fromJson(j as Map<String, dynamic>))
      .toList();
}

class FoodService {
  static List<FoodItem> _foods = [];
  static final List<FoodItem> _customFoods = [];
  static bool _isLoaded = false;

  /// Guard against multiple concurrent load calls.
  static Future<void>? _loadFuture;

  static Future<void> loadFoods() async {
    if (_isLoaded) return;
    // Reuse in-flight future if already loading
    _loadFuture ??= _doLoad();
    return _loadFuture;
  }

  static Future<void> _doLoad() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/foods.json');
      // Parse in a background isolate to avoid main-thread jank
      _foods = await compute(_parseFoodsInIsolate, jsonString);
      _isLoaded = true;
    } catch (e) {
      // If loading fails, use empty list
      _foods = [];
      _isLoaded = true;
    }
  }

  static List<FoodItem> get allFoods => [..._foods, ..._customFoods];

  static List<FoodItem> get predefinedFoods => _foods;

  static List<FoodItem> get customFoods => _customFoods;

  static void addCustomFood(FoodItem food) {
    _customFoods.add(food);
  }

  static void removeCustomFood(String id) {
    _customFoods.removeWhere((f) => f.id == id);
  }

  static List<FoodItem> searchFoods(String query) {
    if (query.isEmpty) return allFoods;
    final lowerQuery = query.toLowerCase();
    return allFoods.where((food) {
      return food.name.toLowerCase().contains(lowerQuery) ||
          food.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  static List<String> get categories {
    final cats = allFoods.map((f) => f.category).toSet().toList();
    cats.sort();
    return cats;
  }

  static List<FoodItem> getFoodsByCategory(String category) {
    return allFoods.where((f) => f.category == category).toList();
  }
}
