import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/bmr_calculator.dart';

class FoodLoggingScreen extends StatelessWidget {
  final int targetCalories;
  final int bmr;
  final FitnessGoal goal;

  const FoodLoggingScreen({
    super.key,
    required this.targetCalories,
    required this.bmr,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Logging'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCalorieSummaryCard(),
            const SizedBox(height: 24),
            _buildMealsSection(),
            const SizedBox(height: 24),
            _buildQuickAddSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Food logging feature coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.white,
      ),
    );
  }

  Widget _buildCalorieSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getGoalIcon(),
                  color: _getGoalColor(),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  goal.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _getGoalColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Circular Progress Indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 0,
                    strokeWidth: 12,
                    backgroundColor: AppTheme.mediumGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(_getGoalColor()),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$targetCalories',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _getGoalColor(),
                      ),
                    ),
                    const Text(
                      'kcal remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Calories breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCalorieInfo(
                  label: 'Target',
                  value: targetCalories,
                  icon: Icons.flag_outlined,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.mediumGrey,
                ),
                _buildCalorieInfo(
                  label: 'Consumed',
                  value: 0,
                  icon: Icons.restaurant,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.mediumGrey,
                ),
                _buildCalorieInfo(
                  label: 'Remaining',
                  value: targetCalories,
                  icon: Icons.trending_down,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieInfo({
    required String label,
    required int value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGrey,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMealsSection() {
    final meals = [
      {'name': 'Breakfast', 'icon': Icons.wb_sunny_outlined, 'calories': 0},
      {'name': 'Lunch', 'icon': Icons.wb_cloudy_outlined, 'calories': 0},
      {'name': 'Dinner', 'icon': Icons.nights_stay_outlined, 'calories': 0},
      {'name': 'Snacks', 'icon': Icons.cookie_outlined, 'calories': 0},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text(
                  "Today's Meals",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...meals.map((meal) => _buildMealItem(
                  name: meal['name'] as String,
                  icon: meal['icon'] as IconData,
                  calories: meal['calories'] as int,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem({
    required String name,
    required IconData icon,
    required int calories,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkGrey,
                  ),
                ),
                Text(
                  '$calories kcal',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection() {
    final quickItems = [
      {'name': 'Water', 'icon': Icons.water_drop_outlined},
      {'name': 'Coffee', 'icon': Icons.coffee_outlined},
      {'name': 'Fruit', 'icon': Icons.apple},
      {'name': 'Protein', 'icon': Icons.egg_outlined},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Quick Add',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: quickItems.map((item) {
                return InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGoalIcon() {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return Icons.trending_down;
      case FitnessGoal.maintenance:
        return Icons.balance;
      case FitnessGoal.weightGain:
        return Icons.trending_up;
    }
  }

  Color _getGoalColor() {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return AppTheme.accentOrange;
      case FitnessGoal.maintenance:
        return AppTheme.primaryGreen;
      case FitnessGoal.weightGain:
        return AppTheme.accentBlue;
    }
  }
}
