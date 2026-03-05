import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/bmr_calculator.dart';
import '../models/food_model.dart';
import '../services/food_service.dart';
import '../services/daily_log_service.dart';
import '../services/firestore_service.dart';
import '../services/health_alert_service.dart';
import '../services/notification_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'weekly_analytics_screen.dart';
import 'profile_screen.dart';
import 'dart:math' as math;

class FoodLoggingScreen extends StatefulWidget {
  final int targetCalories;
  final int bmr;
  final FitnessGoal goal;
  final String initialMealType;

  const FoodLoggingScreen({
    super.key,
    required this.targetCalories,
    required this.bmr,
    required this.goal,
    this.initialMealType = 'Breakfast',
  });

  @override
  State<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  DailyLogData? _dailyLog;
  List<LoggedFood> _localFoods = [];
  List<HealthCondition> _healthConditions = [];

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  @override
  void initState() {
    super.initState();
    final initialIndex =
        _mealTypes.indexOf(widget.initialMealType).clamp(0, 3);
    _tabController =
        TabController(length: 4, vsync: this, initialIndex: initialIndex);
    _loadData();
  }

  Future<void> _loadData() async {
    await FoodService.loadFoods();
    _dailyLog = await DailyLogService.getTodaysLog();
    final profile = await FirestoreService.getUserProfile();
    _healthConditions =
        profile?.healthConditions ?? [HealthCondition.none];
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

  int get _remainingCalories =>
      widget.targetCalories - _dailySummary.totalCalories;
  double get _progress => widget.targetCalories > 0
      ? _dailySummary.totalCalories / widget.targetCalories
      : 0;

  Future<void> _addLoggedFood(LoggedFood loggedFood) async {
    await DailyLogService.addFoodToMeal(loggedFood.mealType, loggedFood);
    _dailyLog = await DailyLogService.getTodaysLog();
    _rebuildLocalFoods();
    setState(() {});

    await NotificationService.cancelInactivityReminder();
    if (_dailySummary.totalCalories > widget.targetCalories * 0.9) {
      await NotificationService.showCalorieLimitAlert(
        _dailySummary.totalCalories,
        widget.targetCalories,
      );
    }
  }

  Future<void> _removeLoggedFood(LoggedFood food) async {
    final mealFoods =
        _localFoods.where((f) => f.mealType == food.mealType).toList();
    final index = mealFoods.indexOf(food);
    if (index >= 0) {
      await DailyLogService.removeFoodFromMeal(food.mealType, index);
      _dailyLog = await DailyLogService.getTodaysLog();
      _rebuildLocalFoods();
      setState(() {});
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildCalorieSummaryCard(),
            const SizedBox(height: 4),
            _buildTabBar(),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children:
                    _mealTypes.map((meal) => _buildMealTab(meal)).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: _onNavTap,
        onAddPressed: () =>
            _showFoodSelectionSheet(_mealTypes[_tabController.index]),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.softGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              'Food Logging',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: () =>
                _showFoodSelectionSheet(_mealTypes[_tabController.index]),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Calorie Summary Card ───────────────────────────────────────────────
  Widget _buildCalorieSummaryCard() {
    final progressColor =
        _progress > 1.0 ? AppTheme.accentRed : AppTheme.primaryGreen;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          // Mini calorie ring
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _MiniRingPainter(
                progress: _progress.clamp(0.0, 1.0),
                color: progressColor,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_remainingCalories.abs()}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _remainingCalories < 0
                            ? AppTheme.accentRed
                            : progressColor,
                      ),
                    ),
                    Text(
                      _remainingCalories >= 0 ? 'left' : 'over',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Nutrition breakdown
          Expanded(
            child: Column(
              children: [
                _buildNutrientRow(
                    'Calories',
                    '${_dailySummary.totalCalories}',
                    '${widget.targetCalories}',
                    'kcal',
                    progressColor),
                const SizedBox(height: 8),
                _buildNutrientRow(
                    'Protein',
                    _dailySummary.totalProtein.toStringAsFixed(1),
                    '--',
                    'g',
                    AppTheme.accentBlue),
                const SizedBox(height: 8),
                _buildNutrientRow(
                    'Fat',
                    _dailySummary.totalFat.toStringAsFixed(1),
                    '--',
                    'g',
                    AppTheme.accentOrange),
                const SizedBox(height: 8),
                _buildNutrientRow(
                    'Carbs',
                    _dailySummary.totalCarbs.toStringAsFixed(1),
                    '--',
                    'g',
                    AppTheme.accentPurple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(
      String label, String value, String target, String unit, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.bodySmall),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (target != '--')
          Text(
            ' / $target',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textTertiary,
            ),
          ),
        Text(
          ' $unit',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.softGrey,
        borderRadius: BorderRadius.circular(16),
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
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        tabs: _mealTypes.map((meal) {
          final summary = _dailySummary.getMealSummary(meal);
          return Tab(
            height: 42,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(meal, style: const TextStyle(fontSize: 11)),
                if (summary.totalCalories > 0)
                  Text(
                    '${summary.totalCalories}',
                    style: const TextStyle(fontSize: 9),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Meal Tab Content ───────────────────────────────────────────────────
  Widget _buildMealTab(String mealType) {
    final mealSummary = _dailySummary.getMealSummary(mealType);
    final foods = mealSummary.foods;

    if (foods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.softGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getMealIcon(mealType),
                size: 48,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No food logged for $mealType',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showFoodSelectionSheet(mealType),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenSurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        size: 18, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      'Add Food',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: foods.length + 2, // +1 for summary card, +1 for add button
      itemBuilder: (context, index) {
        if (index == 0) return _buildMealSummaryCard(mealSummary);
        if (index == foods.length + 1) return const SizedBox(height: 80);
        return _buildLoggedFoodCard(foods[index - 1]);
      },
    );
  }

  Widget _buildMealSummaryCard(MealSummary summary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreenSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat(
              '${summary.totalCalories}', 'kcal', AppTheme.primaryGreen),
          _buildMiniDivider(),
          _buildMiniStat('${summary.totalProtein.toStringAsFixed(0)}g',
              'Protein', AppTheme.accentBlue),
          _buildMiniDivider(),
          _buildMiniStat('${summary.totalFat.toStringAsFixed(0)}g', 'Fat',
              AppTheme.accentOrange),
          _buildMiniDivider(),
          _buildMiniStat('${summary.totalCarbs.toStringAsFixed(0)}g', 'Carbs',
              AppTheme.accentPurple),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniDivider() {
    return Container(
        width: 1, height: 28, color: AppTheme.primaryGreen.withValues(alpha: 0.2));
  }

  Widget _buildLoggedFoodCard(LoggedFood loggedFood) {
    return Dismissible(
      key: ValueKey(
          '${loggedFood.food.id}_${loggedFood.mealType}_${loggedFood.quantity}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.accentRed),
      ),
      onDismissed: (_) => _removeLoggedFood(loggedFood),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(loggedFood.food.iconData,
                  color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loggedFood.food.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${loggedFood.quantity} × ${loggedFood.food.servingSize}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${loggedFood.totalCalories}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  'kcal',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Food Selection Sheet ───────────────────────────────────────────────
  void _showFoodSelectionSheet(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodSelectionSheet(
        mealType: mealType,
        onFoodSelected: _addLoggedFood,
        healthConditions: _healthConditions,
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────
  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case 1:
        final profile = FirestoreService.cachedProfile;
        if (profile != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WeeklyAnalyticsScreen(
                targetCalories: widget.targetCalories,
                bmr: widget.bmr,
                goal: widget.goal,
                maintenanceCalories: profile.maintenanceCalories,
              ),
            ),
          );
        }
        break;
      case 2:
        _showComingSoonDialog('Meal Plan');
        break;
      case 3:
        final profile2 = FirestoreService.cachedProfile;
        if (profile2 != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                profile: profile2,
                onProfileUpdated: () {},
              ),
            ),
          );
        }
        break;
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.construction_rounded, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            Text('Coming Soon',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          '$feature feature is under development. Stay tuned!',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.poppins(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.wb_sunny_rounded;
      case 'Lunch':
        return Icons.wb_sunny;
      case 'Dinner':
        return Icons.nights_stay_rounded;
      case 'Snacks':
        return Icons.cookie_rounded;
      default:
        return Icons.restaurant;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Food Selection Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════
class FoodSelectionSheet extends StatefulWidget {
  final String mealType;
  final Function(LoggedFood) onFoodSelected;
  final List<HealthCondition> healthConditions;

  const FoodSelectionSheet({
    super.key,
    required this.mealType,
    required this.onFoodSelected,
    this.healthConditions = const [],
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
            .where(
                (f) => f.name.toLowerCase().contains(query.toLowerCase()))
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreenSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getMealIcon(widget.mealType),
                        color: AppTheme.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add to ${widget.mealType}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showCustomFoodDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreenSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 16,
                              color: AppTheme.primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Custom',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.softGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterFoods,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search foods...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textTertiary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _filterFoods('');
                            },
                            icon: const Icon(Icons.clear_rounded,
                                color: AppTheme.textTertiary),
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            // Category chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('All', _selectedCategory == null),
                  ...FoodService.categories.map((category) =>
                      _buildCategoryChip(
                          category, _selectedCategory == category)),
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
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.softGrey,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search_off_rounded,
                                size: 40, color: AppTheme.textTertiary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No foods found',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showCustomFoodDialog,
                            child: Text(
                              'Add custom food',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
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

  Widget _buildCategoryChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectCategory(label == 'All' ? null : label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: AppTheme.mediumGrey),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItem(FoodItem food) {
    return GestureDetector(
      onTap: () => _showQuantityDialog(food),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.softGrey),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(food.iconData, color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          food.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (food.isCustom) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Custom',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    food.servingSize,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildNutrientChip(
                          '${food.calories} kcal', AppTheme.primaryGreen),
                      const SizedBox(width: 4),
                      _buildNutrientChip(
                          'P: ${food.protein}g', AppTheme.accentBlue),
                      const SizedBox(width: 4),
                      _buildNutrientChip(
                          'F: ${food.fat}g', AppTheme.accentOrange),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Quantity Dialog ─────────────────────────────────────────────────────
  void _showQuantityDialog(FoodItem food) {
    double quantity = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(food.iconData,
                    color: AppTheme.primaryGreen, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  food.name,
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Per serving: ${food.servingSize}',
                style: GoogleFonts.poppins(
                    color: AppTheme.textTertiary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Quantity selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQuantityButton(
                    icon: Icons.remove_rounded,
                    onTap: quantity > 0.5
                        ? () =>
                            setDialogState(() => quantity -= 0.5)
                        : null,
                  ),
                  Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.softGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quantity.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  _buildQuantityButton(
                    icon: Icons.add_rounded,
                    onTap: () =>
                        setDialogState(() => quantity += 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Nutrition preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.softGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPreviewStat(
                        'Cal',
                        '${(food.calories * quantity).round()}',
                        AppTheme.primaryGreen),
                    _buildPreviewStat(
                        'Protein',
                        '${(food.protein * quantity).toStringAsFixed(1)}g',
                        AppTheme.accentBlue),
                    _buildPreviewStat(
                        'Fat',
                        '${(food.fat * quantity).toStringAsFixed(1)}g',
                        AppTheme.accentOrange),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final loggedFood = LoggedFood(
                  food: food,
                  quantity: quantity,
                  mealType: widget.mealType,
                );

                final alerts = HealthAlertService.checkFoodWithQuantity(
                  food,
                  quantity,
                  widget.healthConditions,
                );

                Navigator.pop(context);

                if (alerts.isNotEmpty) {
                  _showHealthAlertDialog(loggedFood, alerts);
                } else {
                  _addFoodAndClose(loggedFood);
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Add',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(
      {required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.primaryGreen
              : AppTheme.mediumGrey,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ── Health Alert Dialog ─────────────────────────────────────────────────
  void _showHealthAlertDialog(
      LoggedFood loggedFood, List<HealthAlert> alerts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.softYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: AppTheme.warningYellow,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Health Awareness',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.softYellow.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About ${loggedFood.food.name}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...alerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(alert.condition.icon,
                                  size: 16,
                                  color: AppTheme.warningYellow),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alert.message,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: AppTheme.darkGrey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 14,
                        color:
                            AppTheme.textSecondary.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        HealthAlertService.shortDisclaimer,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _addFoodAndClose(loggedFood);
              if (alerts.isNotEmpty) {
                final firstAlert = alerts.first;
                NotificationService.showHealthAlert(
                  foodName: loggedFood.food.name,
                  concern: firstAlert.nutrientConcern,
                  conditionName: firstAlert.condition.label,
                );
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: Text('Got it, Add Food',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.healthGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _addFoodAndClose(LoggedFood loggedFood) {
    widget.onFoodSelected(loggedFood);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${loggedFood.food.name} to ${widget.mealType}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPreviewStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: color, fontSize: 14)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }

  // ── Custom Food Dialog ─────────────────────────────────────────────────
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_box_rounded,
                  color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 10),
            Text('Add Custom Food',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Food Name *',
                  hintText: 'e.g., Homemade Curry',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: servingSizeController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Serving Size',
                  hintText: 'e.g., 1 cup, 100g',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: caloriesController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Calories *',
                        suffixText: 'kcal',
                        labelStyle: GoogleFonts.poppins(fontSize: 13),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Protein',
                        suffixText: 'g',
                        labelStyle: GoogleFonts.poppins(fontSize: 13),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Fat',
                        suffixText: 'g',
                        labelStyle: GoogleFonts.poppins(fontSize: 13),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Carbs',
                        suffixText: 'g',
                        labelStyle: GoogleFonts.poppins(fontSize: 13),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final calories =
                  int.tryParse(caloriesController.text) ?? 0;

              if (name.isEmpty || calories <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter food name and calories',
                        style: GoogleFonts.poppins()),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }

              final customFood = FoodItem(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                calories: calories,
                protein:
                    double.tryParse(proteinController.text) ?? 0,
                fat: double.tryParse(fatController.text) ?? 0,
                carbs:
                    double.tryParse(carbsController.text) ?? 0,
                servingSize: servingSizeController.text,
                category: 'Custom',
                isCustom: true,
              );

              FoodService.addCustomFood(customFood);
              Navigator.pop(context);
              _filterFoods(_searchController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added $name to food list',
                      style: GoogleFonts.poppins()),
                  backgroundColor: AppTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Add Food',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.wb_sunny_rounded;
      case 'Lunch':
        return Icons.wb_sunny;
      case 'Dinner':
        return Icons.nights_stay_rounded;
      case 'Snacks':
        return Icons.cookie_rounded;
      default:
        return Icons.restaurant;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Mini Ring Painter (used in calorie summary)
// ══════════════════════════════════════════════════════════════════════════
class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _MiniRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;
    const startAngle = -math.pi / 2;

    final bgPaint = Paint()
      ..color = AppTheme.softGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * math.pi * progress;
    if (sweepAngle > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter old) =>
      old.progress != progress || old.color != color;
}
