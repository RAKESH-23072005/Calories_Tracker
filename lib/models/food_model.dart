import 'package:flutter/material.dart';

class FoodItem {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final String category;
  final String servingSize;
  final String icon;
  final bool isCustom;

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    this.carbs = 0,
    this.category = 'Other',
    this.servingSize = '1 serving',
    this.icon = 'food',
    this.isCustom = false,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      calories: (json['calories'] ?? 0).toInt(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      category: json['category'] ?? 'Other',
      servingSize: json['servingSize'] ?? '1 serving',
      icon: json['icon'] ?? 'food',
      isCustom: json['isCustom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'category': category,
    'servingSize': servingSize,
    'icon': icon,
    'isCustom': isCustom,
  };

  IconData get iconData {
    switch (icon) {
      case 'egg':
        return Icons.egg_outlined;
      case 'drumstick':
        return Icons.set_meal;
      case 'rice':
        return Icons.rice_bowl;
      case 'fruit':
        return Icons.apple;
      case 'dairy':
        return Icons.local_cafe;
      case 'grain':
        return Icons.breakfast_dining;
      case 'bread':
        return Icons.bakery_dining;
      case 'fish':
        return Icons.set_meal;
      case 'vegetable':
        return Icons.eco;
      case 'nut':
        return Icons.grass;
      case 'legume':
        return Icons.spa;
      case 'coffee':
        return Icons.coffee;
      case 'tea':
        return Icons.emoji_food_beverage;
      case 'juice':
        return Icons.local_bar;
      case 'shake':
        return Icons.blender;
      default:
        return Icons.restaurant;
    }
  }
}

class LoggedFood {
  final FoodItem food;
  final double quantity;
  final String mealType;
  final DateTime timestamp;

  LoggedFood({
    required this.food,
    required this.quantity,
    required this.mealType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  int get totalCalories => (food.calories * quantity).round();
  double get totalProtein => food.protein * quantity;
  double get totalFat => food.fat * quantity;
  double get totalCarbs => food.carbs * quantity;
}

class MealSummary {
  final String mealType;
  final List<LoggedFood> foods;

  MealSummary({
    required this.mealType,
    required this.foods,
  });

  int get totalCalories => foods.fold(0, (sum, f) => sum + f.totalCalories);
  double get totalProtein => foods.fold(0.0, (sum, f) => sum + f.totalProtein);
  double get totalFat => foods.fold(0.0, (sum, f) => sum + f.totalFat);
  double get totalCarbs => foods.fold(0.0, (sum, f) => sum + f.totalCarbs);
}

class DailySummary {
  final List<LoggedFood> allFoods;

  DailySummary({required this.allFoods});

  int get totalCalories => allFoods.fold(0, (sum, f) => sum + f.totalCalories);
  double get totalProtein => allFoods.fold(0.0, (sum, f) => sum + f.totalProtein);
  double get totalFat => allFoods.fold(0.0, (sum, f) => sum + f.totalFat);
  double get totalCarbs => allFoods.fold(0.0, (sum, f) => sum + f.totalCarbs);

  MealSummary getMealSummary(String mealType) {
    return MealSummary(
      mealType: mealType,
      foods: allFoods.where((f) => f.mealType == mealType).toList(),
    );
  }
}
