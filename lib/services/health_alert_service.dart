import '../models/food_model.dart';
import 'firestore_service.dart';

/// A health alert containing information about a food-health concern
class HealthAlert {
  final HealthCondition condition;
  final String nutrientConcern;
  final String message;
  final AlertLevel level;
  final String? foodName;
  final double? quantity;
  final bool isExcessQuantity;

  HealthAlert({
    required this.condition,
    required this.nutrientConcern,
    required this.message,
    this.level = AlertLevel.info,
    this.foodName,
    this.quantity,
    this.isExcessQuantity = false,
  });
}

enum AlertLevel { info, caution, warning }

/// Service to generate health awareness alerts based on food properties
class HealthAlertService {
  // Thresholds for nutrient concerns (per serving)
  static const double highSugarThreshold = 15.0; // grams
  static const double highFatThreshold = 20.0; // grams
  static const double highSodiumThreshold = 600.0; // mg
  static const double highCarbsThreshold = 50.0; // grams
  static const double highCaloriesThreshold = 500; // kcal
  
  // Recommended max quantity thresholds
  static const double recommendedMaxQuantity = 1.5; // servings

  // Mapping of conditions to nutrient concerns
  static const Map<HealthCondition, List<String>> conditionConcerns = {
    HealthCondition.diabetes: ['sugar', 'carbs'],
    HealthCondition.bloodPressure: ['sodium'],
    HealthCondition.heartDisease: ['fat', 'sodium'],
    HealthCondition.cholesterol: ['fat'],
    HealthCondition.kidneyIssues: ['sodium', 'protein'],
    HealthCondition.obesity: ['calories', 'fat', 'sugar'],
    HealthCondition.gastricProblems: ['fat', 'spicy'],
    HealthCondition.thyroidIssues: [],
    HealthCondition.anemia: [],
    HealthCondition.pcos: ['sugar', 'carbs'],
    HealthCondition.none: [],
  };

  // Health impact messages for excess quantity
  static Map<HealthCondition, String> getExcessQuantityMessages(String foodName, double quantity) => {
    HealthCondition.diabetes:
        '$foodName at ${quantity.toStringAsFixed(1)} servings contains significantly more carbs and sugar. '
        'This can spike your blood sugar levels. Consider reducing to 1 serving for better glucose control.',
    HealthCondition.bloodPressure:
        'Having ${quantity.toStringAsFixed(1)} servings of $foodName increases sodium intake. '
        'Excess sodium can raise blood pressure. 1 serving is recommended.',
    HealthCondition.heartDisease:
        '${quantity.toStringAsFixed(1)} servings of $foodName means higher fat and sodium intake. '
        'This may strain your cardiovascular system. Consider a smaller portion.',
    HealthCondition.cholesterol:
        'At ${quantity.toStringAsFixed(1)} servings, $foodName provides more fat than recommended. '
        'High fat intake can affect cholesterol levels. Try limiting to 1 serving.',
    HealthCondition.obesity:
        '${quantity.toStringAsFixed(1)} servings of $foodName adds extra calories. '
        'Managing portion sizes is key for weight management. 1 serving is suggested.',
    HealthCondition.kidneyIssues:
        'Higher quantities of $foodName increase your sodium and protein load. '
        'This may put strain on kidneys. Consider reducing the portion.',
    HealthCondition.gastricProblems:
        'Larger portions of $foodName may be harder to digest. '
        'Start with a smaller serving to see how your body responds.',
    HealthCondition.pcos:
        '${quantity.toStringAsFixed(1)} servings of $foodName provides more carbs. '
        'Managing carb intake can help with PCOS symptoms. Try 1 serving.',
    HealthCondition.thyroidIssues:
        'Be mindful of portion sizes as they affect overall nutrition balance.',
    HealthCondition.anemia:
        'Monitor your overall nutrition balance with portion sizes.',
    HealthCondition.none:
        '',
  };

  // Friendly messages for each concern (per serving)
  static const Map<String, Map<HealthCondition, String>> concernMessages = {
    'sugar': {
      HealthCondition.diabetes:
          'This food is higher in sugar which can affect blood glucose levels. Consider enjoying in moderation.',
      HealthCondition.obesity:
          'This is a higher-sugar food. Being mindful of sugar intake can support your wellness goals.',
      HealthCondition.pcos:
          'This food contains more sugar which may affect hormonal balance. Managing sugar intake helps with PCOS.',
    },
    'carbs': {
      HealthCondition.diabetes:
          'This food has more carbohydrates which convert to glucose. Factor this into your daily carb limit.',
      HealthCondition.pcos:
          'This is a higher-carb food. Balancing carbs can help manage insulin resistance with PCOS.',
    },
    'fat': {
      HealthCondition.heartDisease:
          'This food is higher in fat which can affect heart health. Consider smaller portions.',
      HealthCondition.cholesterol:
          'This higher-fat food may impact cholesterol levels. Being mindful of fat helps maintain healthy levels.',
      HealthCondition.obesity:
          'This food is higher in fat and calories. Moderation helps with weight management.',
      HealthCondition.gastricProblems:
          'Higher-fat foods may slow digestion and cause discomfort. Listen to your body.',
    },
    'sodium': {
      HealthCondition.bloodPressure:
          'This food is higher in sodium which can affect blood pressure. Being mindful of salt intake is important.',
      HealthCondition.heartDisease:
          'Higher sodium can impact heart health. Consider this as part of your daily salt limit.',
      HealthCondition.kidneyIssues:
          'Extra sodium puts more load on kidneys. Managing sodium intake supports kidney health.',
    },
    'calories': {
      HealthCondition.obesity:
          'This is a higher-calorie food. Being aware of calorie intake helps with weight goals.',
    },
    'protein': {
      HealthCondition.kidneyIssues:
          'High protein intake requires more kidney work. Your doctor can advise on ideal protein levels.',
    },
  };

  /// Check a food item with quantity against user's health conditions
  static List<HealthAlert> checkFoodWithQuantity(
    FoodItem food,
    double quantity,
    List<HealthCondition> conditions,
  ) {
    final alerts = <HealthAlert>[];

    // Skip if no conditions or only 'none'
    if (conditions.isEmpty ||
        (conditions.length == 1 && conditions.contains(HealthCondition.none))) {
      return alerts;
    }

    // Check for excess quantity first
    if (quantity > recommendedMaxQuantity) {
      for (final condition in conditions) {
        if (condition == HealthCondition.none) continue;
        
        final concerns = conditionConcerns[condition] ?? [];
        if (concerns.isNotEmpty) {
          final excessMessages = getExcessQuantityMessages(food.name, quantity);
          final message = excessMessages[condition] ?? '';
          if (message.isNotEmpty) {
            alerts.add(HealthAlert(
              condition: condition,
              nutrientConcern: 'excess_quantity',
              message: message,
              level: AlertLevel.warning,
              foodName: food.name,
              quantity: quantity,
              isExcessQuantity: true,
            ));
          }
        }
      }
    }

    // Also check for individual nutrient concerns
    for (final condition in conditions) {
      if (condition == HealthCondition.none) continue;

      final concerns = conditionConcerns[condition] ?? [];
      for (final concern in concerns) {
        final alert = _checkConcernWithQuantity(food, quantity, condition, concern);
        if (alert != null) {
          // Avoid duplicate alerts for the same concern
          final hasSimilar = alerts.any(
            (a) => a.nutrientConcern == alert.nutrientConcern && a.condition == alert.condition,
          );
          if (!hasSimilar) {
            alerts.add(alert);
          }
        }
      }
    }

    return alerts;
  }

  /// Legacy method for backward compatibility
  static List<HealthAlert> checkFood(
    FoodItem food,
    List<HealthCondition> conditions,
  ) {
    return checkFoodWithQuantity(food, 1.0, conditions);
  }

  static HealthAlert? _checkConcernWithQuantity(
    FoodItem food,
    double quantity,
    HealthCondition condition,
    String concern,
  ) {
    bool shouldAlert = false;
    final totalCarbs = food.carbs * quantity;
    final totalFat = food.fat * quantity;
    final totalCalories = food.calories * quantity;
    final totalProtein = food.protein * quantity;

    switch (concern) {
      case 'sugar':
        shouldAlert = totalCarbs > highSugarThreshold;
        break;
      case 'carbs':
        shouldAlert = totalCarbs > highCarbsThreshold;
        break;
      case 'fat':
        shouldAlert = totalFat > highFatThreshold;
        break;
      case 'sodium':
        shouldAlert = false; // Enable when sodium data is available
        break;
      case 'calories':
        shouldAlert = totalCalories > highCaloriesThreshold;
        break;
      case 'protein':
        shouldAlert = totalProtein > 40;
        break;
      default:
        shouldAlert = false;
    }

    if (!shouldAlert) return null;

    final conditionMessages = concernMessages[concern];
    final message = conditionMessages?[condition] ??
        'This food is higher in $concern. Consider enjoying in moderation.';

    return HealthAlert(
      condition: condition,
      nutrientConcern: concern,
      message: message,
      foodName: food.name,
      quantity: quantity,
    );
  }

  /// Get a friendly summary of all alerts
  static String getAlertSummary(List<HealthAlert> alerts) {
    if (alerts.isEmpty) return '';

    final concerns = alerts.map((a) => a.nutrientConcern).toSet();
    final concernList = concerns.join(', ');

    return 'This food is higher in $concernList based on your health profile.';
  }

  /// Medical disclaimer text
  static const String medicalDisclaimer =
      'This app does not provide medical advice. These alerts are for general awareness only. '
      'Always consult your healthcare provider for personalized dietary guidance.';

  /// Short disclaimer for inline display
  static const String shortDisclaimer =
      'Not medical advice. Consult your healthcare provider.';
}
