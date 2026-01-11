import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/bmr_calculator.dart';
import '../models/food_model.dart';
import '../services/food_service.dart';
import '../services/daily_log_service.dart';

class FoodLoggingScreen extends StatefulWidget {
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
  State<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  DailyLogData? _dailyLog;
  List<LoggedFood> _localFoods = [];

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await FoodService.loadFoods();
    _dailyLog = await DailyLogService.getTodaysLog();
    _rebuildLocalFoods();
    setState(() => _isLoading = false);
  }

  void _rebuildLocalFoods() {
    _localFoods = [];
    if (_dailyLog == null) return;
    
    for (final foodData in _dailyLog!.breakfast.foods) {
      _localFoods.add(_loggedFoodFromData(foodData, 'Breakfast'));
    }
    for (final foodData in _dailyLog!.lunch.foods) {
      _localFoods.add(_loggedFoodFromData(foodData, 'Lunch'));
    }
    for (final foodData in _dailyLog!.dinner.foods) {
      _localFoods.add(_loggedFoodFromData(foodData, 'Dinner'));
    }
    for (final foodData in _dailyLog!.snacks.foods) {
      _localFoods.add(_loggedFoodFromData(foodData, 'Snacks'));
    }
  }

  LoggedFood _loggedFoodFromData(LoggedFoodData data, String mealType) {
    return LoggedFood(
      food: FoodItem(
        id: data.foodId,
        name: data.foodName,
        calories: (data.calories / data.quantity).round(),
        protein: data.protein / data.quantity,
        fat: data.fat / data.quantity,
        carbs: data.carbs / data.quantity,
        category: '',
        servingSize: data.servingSize,
        icon: '',
      ),
      quantity: data.quantity,
      mealType: mealType,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DailySummary get _dailySummary => DailySummary(allFoods: _localFoods);
  List<LoggedFood> get _loggedFoods => _localFoods;

  int get _remainingCalories => widget.targetCalories - _dailySummary.totalCalories;
  double get _progress => widget.targetCalories > 0 ? _dailySummary.totalCalories / widget.targetCalories : 0;

  Future<void> _addLoggedFood(LoggedFood loggedFood) async {
    await DailyLogService.addFoodToMeal(loggedFood.mealType, loggedFood);
    _dailyLog = await DailyLogService.getTodaysLog();
    _rebuildLocalFoods();
    setState(() {});
  }

  Future<void> _removeLoggedFood(LoggedFood food) async {
    final mealFoods = _localFoods.where((f) => f.mealType == food.mealType).toList();
    final index = mealFoods.indexOf(food);
    if (index >= 0) {
      await DailyLogService.removeFoodFromMeal(food.mealType, index);
      _dailyLog = await DailyLogService.getTodaysLog();
      _rebuildLocalFoods();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF81C784),
              Color(0xFFF5F5F5),
            ],
            stops: [0.0, 0.15, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildDailySummaryCard(),
              _buildTabBar(),
              Expanded(
                child: Container(
                  color: AppTheme.softGrey,
                  child: TabBarView(
                    controller: _tabController,
                    children: _mealTypes.map((meal) => _buildMealTab(meal)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFoodSelectionSheet(_mealTypes[_tabController.index]),
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Food Logging',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard() {
    final progressColor = _progress > 1.0 ? AppTheme.accentRed : AppTheme.primaryGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  // Calories Circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: _progress.clamp(0.0, 1.0),
                          strokeWidth: 10,
                          backgroundColor: AppTheme.mediumGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_remainingCalories.abs()}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _remainingCalories < 0 ? AppTheme.accentRed : progressColor,
                            ),
                          ),
                          Text(
                            _remainingCalories >= 0 ? 'left' : 'over',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Nutrition breakdown
                  Expanded(
                    child: Column(
                      children: [
                        _buildNutrientRow('Calories', '${_dailySummary.totalCalories}', '${widget.targetCalories}', 'kcal', progressColor),
                        const SizedBox(height: 12),
                        _buildNutrientRow('Protein', _dailySummary.totalProtein.toStringAsFixed(1), '--', 'g', AppTheme.accentBlue),
                        const SizedBox(height: 12),
                        _buildNutrientRow('Fat', _dailySummary.totalFat.toStringAsFixed(1), '--', 'g', AppTheme.accentOrange),
                        const SizedBox(height: 12),
                        _buildNutrientRow('Carbs', _dailySummary.totalCarbs.toStringAsFixed(1), '--', 'g', Colors.purple),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, String target, String unit, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (target != '--') ...[
          Text(
            ' / $target',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
        Text(
          ' $unit',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        indicator: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: _mealTypes.map((meal) {
          final summary = _dailySummary.getMealSummary(meal);
          return Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(meal),
                if (summary.totalCalories > 0)
                  Text(
                    '${summary.totalCalories} kcal',
                    style: const TextStyle(fontSize: 10),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealTab(String mealType) {
    final mealSummary = _dailySummary.getMealSummary(mealType);
    final foods = mealSummary.foods;

    if (foods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getMealIcon(mealType),
              size: 64,
              color: AppTheme.mediumGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No food logged for $mealType',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showFoodSelectionSheet(mealType),
              icon: const Icon(Icons.add),
              label: const Text('Add Food'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal summary card
          _buildMealSummaryCard(mealSummary),
          const SizedBox(height: 16),
          // Logged foods
          ...foods.map((loggedFood) => _buildLoggedFoodCard(loggedFood)),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildMealSummaryCard(MealSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMiniStat('Calories', '${summary.totalCalories}', 'kcal', AppTheme.primaryGreen),
            _buildMiniStat('Protein', summary.totalProtein.toStringAsFixed(1), 'g', AppTheme.accentBlue),
            _buildMiniStat('Fat', summary.totalFat.toStringAsFixed(1), 'g', AppTheme.accentOrange),
            _buildMiniStat('Carbs', summary.totalCarbs.toStringAsFixed(1), 'g', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.7),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedFoodCard(LoggedFood loggedFood) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            loggedFood.food.iconData,
            color: AppTheme.primaryGreen,
          ),
        ),
        title: Text(
          loggedFood.food.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${loggedFood.quantity} × ${loggedFood.food.servingSize}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${loggedFood.totalCalories} kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  'P: ${loggedFood.totalProtein.toStringAsFixed(1)}g',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
            IconButton(
              onPressed: () => _removeLoggedFood(loggedFood),
              icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodSelectionSheet(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodSelectionSheet(
        mealType: mealType,
        onFoodSelected: _addLoggedFood,
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.wb_sunny_outlined;
      case 'Lunch':
        return Icons.wb_cloudy_outlined;
      case 'Dinner':
        return Icons.nights_stay_outlined;
      case 'Snacks':
        return Icons.cookie_outlined;
      default:
        return Icons.restaurant;
    }
  }
}

// Food Selection Bottom Sheet
class FoodSelectionSheet extends StatefulWidget {
  final String mealType;
  final Function(LoggedFood) onFoodSelected;

  const FoodSelectionSheet({
    super.key,
    required this.mealType,
    required this.onFoodSelected,
  });

  @override
  State<FoodSelectionSheet> createState() => _FoodSelectionSheetState();
}

class _FoodSelectionSheetState extends State<FoodSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _filteredFoods = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _filteredFoods = FoodService.allFoods;
  }

  void _filterFoods(String query) {
    setState(() {
      if (query.isEmpty && _selectedCategory == null) {
        _filteredFoods = FoodService.allFoods;
      } else if (_selectedCategory != null) {
        _filteredFoods = FoodService.getFoodsByCategory(_selectedCategory!)
            .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _filteredFoods = FoodService.searchFoods(query);
      }
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _filterFoods(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.mediumGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(_getMealIcon(widget.mealType), color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Add to ${widget.mealType}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showCustomFoodDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Custom'),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filterFoods,
                decoration: InputDecoration(
                  hintText: 'Search foods...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _filterFoods('');
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
              ),
            ),
            // Category chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) => _selectCategory(null),
                      selectedColor: AppTheme.primaryGreen,
                      labelStyle: TextStyle(
                        color: _selectedCategory == null ? Colors.white : AppTheme.darkGrey,
                      ),
                    ),
                  ),
                  ...FoodService.categories.map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) => _selectCategory(category),
                      selectedColor: AppTheme.primaryGreen,
                      labelStyle: TextStyle(
                        color: _selectedCategory == category ? Colors.white : AppTheme.darkGrey,
                      ),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Food list
            Expanded(
              child: _filteredFoods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: AppTheme.mediumGrey),
                          const SizedBox(height: 8),
                          const Text('No foods found'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _showCustomFoodDialog,
                            child: const Text('Add custom food'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredFoods.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final food = _filteredFoods[index];
                        return _buildFoodItem(food);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(FoodItem food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showQuantityDialog(food),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(food.iconData, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (food.isCustom) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Custom',
                              style: TextStyle(fontSize: 10, color: AppTheme.accentOrange),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      food.servingSize,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildNutrientChip('${food.calories} kcal', AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        _buildNutrientChip('P: ${food.protein}g', AppTheme.accentBlue),
                        const SizedBox(width: 6),
                        _buildNutrientChip('F: ${food.fat}g', AppTheme.accentOrange),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showQuantityDialog(FoodItem food) {
    double quantity = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(food.iconData, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Expanded(child: Text(food.name, style: const TextStyle(fontSize: 18))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Per serving: ${food.servingSize}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              // Quantity selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: quantity > 0.5
                        ? () => setDialogState(() => quantity -= 0.5)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTheme.primaryGreen,
                  ),
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.softGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      quantity.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setDialogState(() => quantity += 0.5),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.primaryGreen,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Nutrition preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.softGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPreviewStat('Cal', '${(food.calories * quantity).round()}', AppTheme.primaryGreen),
                    _buildPreviewStat('Protein', '${(food.protein * quantity).toStringAsFixed(1)}g', AppTheme.accentBlue),
                    _buildPreviewStat('Fat', '${(food.fat * quantity).toStringAsFixed(1)}g', AppTheme.accentOrange),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onFoodSelected(LoggedFood(
                  food: food,
                  quantity: quantity,
                  mealType: widget.mealType,
                ));
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${food.name} to ${widget.mealType}'),
                    backgroundColor: AppTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  void _showCustomFoodDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final fatController = TextEditingController();
    final carbsController = TextEditingController();
    final servingSizeController = TextEditingController(text: '1 serving');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_box, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Add Custom Food'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Food Name *',
                  hintText: 'e.g., Homemade Curry',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: servingSizeController,
                decoration: const InputDecoration(
                  labelText: 'Serving Size',
                  hintText: 'e.g., 1 cup, 100g',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calories *',
                        suffixText: 'kcal',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fatController,
                      decoration: const InputDecoration(
                        labelText: 'Fat',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carbs',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final calories = int.tryParse(caloriesController.text) ?? 0;

              if (name.isEmpty || calories <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter food name and calories'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final customFood = FoodItem(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                calories: calories,
                protein: double.tryParse(proteinController.text) ?? 0,
                fat: double.tryParse(fatController.text) ?? 0,
                carbs: double.tryParse(carbsController.text) ?? 0,
                servingSize: servingSizeController.text,
                category: 'Custom',
                isCustom: true,
              );

              FoodService.addCustomFood(customFood);
              Navigator.pop(context);
              _filterFoods(_searchController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added $name to food list'),
                  backgroundColor: AppTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Add Food'),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.wb_sunny_outlined;
      case 'Lunch':
        return Icons.wb_cloudy_outlined;
      case 'Dinner':
        return Icons.nights_stay_outlined;
      case 'Snacks':
        return Icons.cookie_outlined;
      default:
        return Icons.restaurant;
    }
  }
}
