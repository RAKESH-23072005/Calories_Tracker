import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_model.dart';

class MealLog {
  final List<LoggedFoodData> foods;
  final int totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;

  MealLog({
    required this.foods,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
  });

  factory MealLog.empty() => MealLog(
    foods: [],
    totalCalories: 0,
    totalProtein: 0,
    totalFat: 0,
    totalCarbs: 0,
  );

  Map<String, dynamic> toFirestore() => {
    'foods': foods.map((f) => f.toFirestore()).toList(),
    'totalCalories': totalCalories,
    'totalProtein': totalProtein,
    'totalFat': totalFat,
    'totalCarbs': totalCarbs,
  };

  factory MealLog.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return MealLog.empty();
    
    final foodsList = (data['foods'] as List<dynamic>?)
        ?.map((f) => LoggedFoodData.fromFirestore(f as Map<String, dynamic>))
        .toList() ?? [];
    
    return MealLog(
      foods: foodsList,
      totalCalories: data['totalCalories'] ?? 0,
      totalProtein: (data['totalProtein'] ?? 0).toDouble(),
      totalFat: (data['totalFat'] ?? 0).toDouble(),
      totalCarbs: (data['totalCarbs'] ?? 0).toDouble(),
    );
  }
}

class LoggedFoodData {
  final String foodId;
  final String foodName;
  final double quantity;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final String servingSize;

  LoggedFoodData({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.servingSize,
  });

  Map<String, dynamic> toFirestore() => {
    'foodId': foodId,
    'foodName': foodName,
    'quantity': quantity,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'servingSize': servingSize,
  };

  factory LoggedFoodData.fromFirestore(Map<String, dynamic> data) {
    return LoggedFoodData(
      foodId: data['foodId'] ?? '',
      foodName: data['foodName'] ?? '',
      quantity: (data['quantity'] ?? 1).toDouble(),
      calories: data['calories'] ?? 0,
      protein: (data['protein'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      servingSize: data['servingSize'] ?? '',
    );
  }

  factory LoggedFoodData.fromLoggedFood(LoggedFood loggedFood) {
    return LoggedFoodData(
      foodId: loggedFood.food.id,
      foodName: loggedFood.food.name,
      quantity: loggedFood.quantity,
      calories: loggedFood.totalCalories,
      protein: loggedFood.totalProtein,
      fat: loggedFood.totalFat,
      carbs: loggedFood.totalCarbs,
      servingSize: loggedFood.food.servingSize,
    );
  }
}

class DailyLogData {
  final String date;
  final MealLog breakfast;
  final MealLog lunch;
  final MealLog dinner;
  final MealLog snacks;
  final int totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final DateTime updatedAt;

  DailyLogData({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory DailyLogData.empty(String date) => DailyLogData(
    date: date,
    breakfast: MealLog.empty(),
    lunch: MealLog.empty(),
    dinner: MealLog.empty(),
    snacks: MealLog.empty(),
    totalCalories: 0,
    totalProtein: 0,
    totalFat: 0,
    totalCarbs: 0,
  );

  Map<String, dynamic> toFirestore() => {
    'date': date,
    'breakfast': breakfast.toFirestore(),
    'lunch': lunch.toFirestore(),
    'dinner': dinner.toFirestore(),
    'snacks': snacks.toFirestore(),
    'totalCalories': totalCalories,
    'totalProtein': totalProtein,
    'totalFat': totalFat,
    'totalCarbs': totalCarbs,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory DailyLogData.fromFirestore(Map<String, dynamic> data) {
    return DailyLogData(
      date: data['date'] ?? '',
      breakfast: MealLog.fromFirestore(data['breakfast'] as Map<String, dynamic>?),
      lunch: MealLog.fromFirestore(data['lunch'] as Map<String, dynamic>?),
      dinner: MealLog.fromFirestore(data['dinner'] as Map<String, dynamic>?),
      snacks: MealLog.fromFirestore(data['snacks'] as Map<String, dynamic>?),
      totalCalories: data['totalCalories'] ?? 0,
      totalProtein: (data['totalProtein'] ?? 0).toDouble(),
      totalFat: (data['totalFat'] ?? 0).toDouble(),
      totalCarbs: (data['totalCarbs'] ?? 0).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MealLog getMealLog(String mealType) {
    switch (mealType) {
      case 'Breakfast': return breakfast;
      case 'Lunch': return lunch;
      case 'Dinner': return dinner;
      case 'Snacks': return snacks;
      default: return MealLog.empty();
    }
  }
}

class DailyLogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static DailyLogData? _cachedLog;
  static String? _cachedDate;

  static String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  static String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static CollectionReference<Map<String, dynamic>> get _dailyLogsCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('dailyLogs');
  }

  // Get today's log
  static Future<DailyLogData> getTodaysLog() async {
    final today = _todayDate;
    
    // Return cached if same date
    if (_cachedLog != null && _cachedDate == today) {
      return _cachedLog!;
    }

    try {
      final doc = await _dailyLogsCollection.doc(today).get();
      if (doc.exists && doc.data() != null) {
        _cachedLog = DailyLogData.fromFirestore(doc.data()!);
        _cachedDate = today;
        return _cachedLog!;
      }
    } catch (e) {
      print('Error getting daily log: $e');
    }

    // Return empty log if not exists
    _cachedLog = DailyLogData.empty(today);
    _cachedDate = today;
    return _cachedLog!;
  }

  // Save or update daily log
  static Future<bool> saveDailyLog(DailyLogData log) async {
    if (_userId == null) return false;

    try {
      await _dailyLogsCollection.doc(log.date).set(log.toFirestore());
      _cachedLog = log;
      _cachedDate = log.date;
      return true;
    } catch (e) {
      print('Error saving daily log: $e');
      return false;
    }
  }

  // Add food to a meal
  static Future<bool> addFoodToMeal(String mealType, LoggedFood food) async {
    try {
      final log = await getTodaysLog();
      final foods = _getFoodsForMeal(log, mealType);
      foods.add(LoggedFoodData.fromLoggedFood(food));
      
      final updatedLog = _updateLogWithMeal(log, mealType, foods);
      return await saveDailyLog(updatedLog);
    } catch (e) {
      print('Error adding food: $e');
      return false;
    }
  }

  // Remove food from a meal
  static Future<bool> removeFoodFromMeal(String mealType, int index) async {
    try {
      final log = await getTodaysLog();
      final foods = _getFoodsForMeal(log, mealType);
      if (index >= 0 && index < foods.length) {
        foods.removeAt(index);
      }
      
      final updatedLog = _updateLogWithMeal(log, mealType, foods);
      return await saveDailyLog(updatedLog);
    } catch (e) {
      print('Error removing food: $e');
      return false;
    }
  }

  static List<LoggedFoodData> _getFoodsForMeal(DailyLogData log, String mealType) {
    switch (mealType) {
      case 'Breakfast': return List.from(log.breakfast.foods);
      case 'Lunch': return List.from(log.lunch.foods);
      case 'Dinner': return List.from(log.dinner.foods);
      case 'Snacks': return List.from(log.snacks.foods);
      default: return [];
    }
  }

  static DailyLogData _updateLogWithMeal(DailyLogData log, String mealType, List<LoggedFoodData> foods) {
    final mealLog = MealLog(
      foods: foods,
      totalCalories: foods.fold(0, (sum, f) => sum + f.calories),
      totalProtein: foods.fold(0.0, (sum, f) => sum + f.protein),
      totalFat: foods.fold(0.0, (sum, f) => sum + f.fat),
      totalCarbs: foods.fold(0.0, (sum, f) => sum + f.carbs),
    );

    MealLog breakfast = log.breakfast;
    MealLog lunch = log.lunch;
    MealLog dinner = log.dinner;
    MealLog snacks = log.snacks;

    switch (mealType) {
      case 'Breakfast': breakfast = mealLog; break;
      case 'Lunch': lunch = mealLog; break;
      case 'Dinner': dinner = mealLog; break;
      case 'Snacks': snacks = mealLog; break;
    }

    final totalCalories = breakfast.totalCalories + lunch.totalCalories + 
                         dinner.totalCalories + snacks.totalCalories;
    final totalProtein = breakfast.totalProtein + lunch.totalProtein + 
                        dinner.totalProtein + snacks.totalProtein;
    final totalFat = breakfast.totalFat + lunch.totalFat + 
                    dinner.totalFat + snacks.totalFat;
    final totalCarbs = breakfast.totalCarbs + lunch.totalCarbs + 
                      dinner.totalCarbs + snacks.totalCarbs;

    return DailyLogData(
      date: log.date,
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      snacks: snacks,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalFat: totalFat,
      totalCarbs: totalCarbs,
    );
  }

  // Clear cache (call on logout or date change)
  static void clearCache() {
    _cachedLog = null;
    _cachedDate = null;
  }

  // Get cached log
  static DailyLogData? get cachedLog => _cachedLog;
}
