import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_model.dart';

class FoodLogService {
  static const String _logKey = 'food_log';
  static const String _dateKey = 'food_log_date';
  static List<LoggedFood> _loggedFoods = [];

  static List<LoggedFood> get loggedFoods => _loggedFoods;

  static Future<void> loadTodaysLog() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_dateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Clear log if it's a new day
    if (savedDate != today) {
      await clearLog();
      await prefs.setString(_dateKey, today);
      return;
    }

    final jsonString = prefs.getString(_logKey);
    if (jsonString == null) {
      _loggedFoods = [];
      return;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      _loggedFoods = jsonList.map((item) {
        final foodJson = item['food'] as Map<String, dynamic>;
        return LoggedFood(
          food: FoodItem.fromJson(foodJson),
          quantity: (item['quantity'] as num).toDouble(),
          mealType: item['mealType'] as String,
        );
      }).toList();
    } catch (e) {
      _loggedFoods = [];
    }
  }

  static Future<void> saveLog() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final jsonList = _loggedFoods.map((loggedFood) => {
      'food': loggedFood.food.toJson(),
      'quantity': loggedFood.quantity,
      'mealType': loggedFood.mealType,
    }).toList();

    await prefs.setString(_logKey, json.encode(jsonList));
    await prefs.setString(_dateKey, today);
  }

  static Future<void> addFood(LoggedFood food) async {
    _loggedFoods.add(food);
    await saveLog();
  }

  static Future<void> removeFood(LoggedFood food) async {
    _loggedFoods.remove(food);
    await saveLog();
  }

  static Future<void> clearLog() async {
    _loggedFoods = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logKey);
  }

  static DailySummary getDailySummary() {
    return DailySummary(allFoods: _loggedFoods);
  }
}
