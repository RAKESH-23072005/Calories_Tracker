import 'bmr_calculator.dart';

/// Result class for macro calculations
class MacroResult {
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final double proteinCalories;
  final double carbCalories;
  final double fatCalories;
  final double proteinPercentage;
  final double carbPercentage;
  final double fatPercentage;
  final int totalCalories;

  const MacroResult({
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    required this.proteinCalories,
    required this.carbCalories,
    required this.fatCalories,
    required this.proteinPercentage,
    required this.carbPercentage,
    required this.fatPercentage,
    required this.totalCalories,
  });
}

/// Calculator for daily macronutrient targets
/// 
/// Protein calculation based on body weight:
/// - Weight Loss: 1.6g per kg
/// - Maintenance: 1.8g per kg
/// - Muscle Gain: 2.2g per kg
/// 
/// Fat: 25% of total daily calories (÷9 for grams)
/// Carbs: Remaining calories after protein and fat (÷4 for grams)
class MacroCalculator {
  /// Protein multipliers based on fitness goal (grams per kg body weight)
  static double getProteinMultiplier(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 1.6;
      case FitnessGoal.maintenance:
        return 1.8;
      case FitnessGoal.weightGain:
        return 2.2;
    }
  }

  /// Calculate daily macronutrient targets
  /// 
  /// [weightKg] - User's body weight in kilograms
  /// [totalCalories] - Target daily calories
  /// [goal] - Fitness goal (weight loss, maintenance, or muscle gain)
  static MacroResult calculate({
    required double weightKg,
    required int totalCalories,
    required FitnessGoal goal,
  }) {
    // 1. Calculate protein based on body weight
    final proteinMultiplier = getProteinMultiplier(goal);
    final proteinGrams = weightKg * proteinMultiplier;
    final proteinCalories = proteinGrams * 4; // 4 calories per gram of protein

    // 2. Calculate fat as 25% of total calories
    final fatCalories = totalCalories * 0.25;
    final fatGrams = fatCalories / 9; // 9 calories per gram of fat

    // 3. Calculate carbs from remaining calories
    final remainingCalories = totalCalories - (proteinCalories + fatCalories);
    final double carbCalories = remainingCalories > 0 ? remainingCalories.toDouble() : 0.0;
    final carbGrams = carbCalories / 4; // 4 calories per gram of carbs

    // 4. Calculate percentages
    final totalMacroCalories = proteinCalories + fatCalories + carbCalories;
    final proteinPercentage = totalMacroCalories > 0 
        ? (proteinCalories / totalMacroCalories) * 100 
        : 0.0;
    final fatPercentage = totalMacroCalories > 0 
        ? (fatCalories / totalMacroCalories) * 100 
        : 0.0;
    final carbPercentage = totalMacroCalories > 0 
        ? (carbCalories / totalMacroCalories) * 100 
        : 0.0;

    return MacroResult(
      proteinGrams: proteinGrams,
      carbGrams: carbGrams,
      fatGrams: fatGrams,
      proteinCalories: proteinCalories,
      carbCalories: carbCalories,
      fatCalories: fatCalories,
      proteinPercentage: proteinPercentage,
      carbPercentage: carbPercentage,
      fatPercentage: fatPercentage,
      totalCalories: totalCalories,
    );
  }
}
