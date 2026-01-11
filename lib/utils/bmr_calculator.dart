/// Activity level multipliers for TDEE calculation
enum ActivityLevel {
  sedentary(1.2, 'Sedentary', 'Little or no exercise'),
  lightlyActive(1.375, 'Lightly Active', 'Light exercise 1-3 days/week'),
  moderatelyActive(1.55, 'Moderately Active', 'Moderate exercise 3-5 days/week'),
  veryActive(1.725, 'Very Active', 'Hard exercise 6-7 days/week'),
  extraActive(1.9, 'Extra Active', 'Very hard exercise & physical job');

  final double multiplier;
  final String label;
  final String description;

  const ActivityLevel(this.multiplier, this.label, this.description);
}

/// Fitness goals with calorie adjustments
enum FitnessGoal {
  weightLoss(-350, 'Weight Loss', 'Lose ~0.3-0.4 kg per week'),
  maintenance(0, 'Maintenance', 'Maintain current weight'),
  weightGain(350, 'Weight Gain', 'Gain ~0.3-0.4 kg per week');

  final int calorieAdjustment;
  final String label;
  final String description;

  const FitnessGoal(this.calorieAdjustment, this.label, this.description);
}

/// Gender for BMR calculation
enum Gender {
  male('Male'),
  female('Female');

  final String label;

  const Gender(this.label);
}

/// BMR calculation result
class BMRResult {
  final double bmr;
  final double maintenanceCalories;
  final double targetCalories;
  final ActivityLevel activityLevel;
  final FitnessGoal goal;

  const BMRResult({
    required this.bmr,
    required this.maintenanceCalories,
    required this.targetCalories,
    required this.activityLevel,
    required this.goal,
  });
}

/// Calculator for BMR using the Mifflin–St Jeor equation
class BMRCalculator {
  /// Calculate BMR using Mifflin–St Jeor formula
  /// 
  /// Men:   BMR = (10 × weight) + (6.25 × height) - (5 × age) + 5
  /// Women: BMR = (10 × weight) + (6.25 × height) - (5 × age) - 161
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    double bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    
    switch (gender) {
      case Gender.male:
        bmr += 5;
        break;
      case Gender.female:
        bmr -= 161;
        break;
    }
    
    return bmr;
  }

  /// Calculate maintenance calories (TDEE)
  static double calculateMaintenanceCalories({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    return bmr * activityLevel.multiplier;
  }

  /// Calculate target calories based on fitness goal
  static double calculateTargetCalories({
    required double maintenanceCalories,
    required FitnessGoal goal,
  }) {
    return maintenanceCalories + goal.calorieAdjustment;
  }

  /// Complete BMR calculation with all results
  static BMRResult calculate({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
    required ActivityLevel activityLevel,
    required FitnessGoal goal,
  }) {
    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );

    final maintenanceCalories = calculateMaintenanceCalories(
      bmr: bmr,
      activityLevel: activityLevel,
    );

    final targetCalories = calculateTargetCalories(
      maintenanceCalories: maintenanceCalories,
      goal: goal,
    );

    return BMRResult(
      bmr: bmr,
      maintenanceCalories: maintenanceCalories,
      targetCalories: targetCalories,
      activityLevel: activityLevel,
      goal: goal,
    );
  }
}
