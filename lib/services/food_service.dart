import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/food_model.dart';

class FoodService {
  static List<FoodItem> _foods = [];
  static List<FoodItem> _customFoods = [];
  static bool _isLoaded = false;

  static Future<void> loadFoods() async {
    if (_isLoaded) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/foods.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> foodsList = jsonData['foods'] ?? [];
      
      _foods = foodsList.map((json) => FoodItem.fromJson(json)).toList();
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
