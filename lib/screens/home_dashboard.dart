import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../utils/bmr_calculator.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/daily_log_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'food_logging_screen.dart';
import 'profile_screen.dart';

class HomeDashboard extends StatefulWidget {
  final int targetCalories;
  final int bmr;
  final FitnessGoal goal;
  final double maintenanceCalories;

  const HomeDashboard({
    super.key,
    required this.targetCalories,
    required this.bmr,
    required this.goal,
    required this.maintenanceCalories,
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  bool _isLoading = true;
  DailyLogData? _dailyLog;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyLog();
  }

  Future<void> _loadDailyLog() async {
    setState(() => _isLoading = true);
    try {
      final log = await DailyLogService.getTodaysLog();
      if (mounted) {
        setState(() {
          _dailyLog = log;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _consumedCalories => _dailyLog?.totalCalories ?? 0;
  int get _remainingCalories => widget.targetCalories - _consumedCalories;
  double get _progress => widget.targetCalories > 0 
      ? _consumedCalories / widget.targetCalories 
      : 0;

  @override
  Widget build(BuildContext context) {
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
            stops: [0.0, 0.2, 0.35],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : RefreshIndicator(
                        onRefresh: _loadDailyLog,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCalorieOverviewCard(),
                              const SizedBox(height: 16),
                              _buildMacronutrientsCard(),
                              const SizedBox(height: 16),
                              _buildMealBreakdownCard(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        onAddPressed: _navigateToFoodLogging,
      ),
    );
  }

  Widget _buildAppBar() {
    final email = AuthService.currentUser?.email ?? 'User';
    final emailName = email.split('@')[0];
    // Use Firestore profile name if available, otherwise fall back to email
    final profile = FirestoreService.cachedProfile;
    final name = (profile != null && profile.name.isNotEmpty) ? profile.name : emailName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateToProfile,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 22,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Notification or settings icon (optional placeholder)
          IconButton(
            onPressed: _navigateToProfile,
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieOverviewCard() {
    final progressColor = _progress > 1.0 ? AppTheme.accentRed : AppTheme.primaryGreen;

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: _progress.clamp(0.0, 1.0),
                          strokeWidth: 12,
                          backgroundColor: AppTheme.mediumGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_remainingCalories.abs()}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _remainingCalories < 0 ? AppTheme.accentRed : progressColor,
                            ),
                          ),
                          Text(
                            _remainingCalories >= 0 ? 'kcal left' : 'kcal over',
                            style: TextStyle(
                              fontSize: 11,
                              color: _remainingCalories < 0 ? AppTheme.accentRed : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalorieStat('Target', '${widget.targetCalories}', Icons.flag_outlined, AppTheme.primaryGreen),
                      const SizedBox(height: 12),
                      _buildCalorieStat('Consumed', '$_consumedCalories', Icons.restaurant, AppTheme.accentOrange),
                      const SizedBox(height: 12),
                      _buildCalorieStat('BMR', '${widget.bmr}', Icons.local_fire_department, AppTheme.accentBlue),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _getGoalColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getGoalIcon(), color: _getGoalColor(), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    widget.goal.label,
                    style: TextStyle(color: _getGoalColor(), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              Text('$value kcal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacronutrientsCard() {
    final protein = _dailyLog?.totalProtein ?? 0;
    final fat = _dailyLog?.totalFat ?? 0;
    final carbs = _dailyLog?.totalCarbs ?? 0;
    final total = protein + fat + carbs;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: AppTheme.primaryGreen, size: 22),
                SizedBox(width: 8),
                Text('Macronutrients', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: total > 0
                      ? PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 25,
                            sections: [
                              PieChartSectionData(value: protein, color: AppTheme.accentBlue, title: '', radius: 22),
                              PieChartSectionData(value: fat, color: AppTheme.accentOrange, title: '', radius: 22),
                              PieChartSectionData(value: carbs, color: Colors.purple, title: '', radius: 22),
                            ],
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.softGrey),
                          child: const Center(child: Text('No data', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
                        ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildMacroRow('Protein', protein, 'g', AppTheme.accentBlue),
                      const SizedBox(height: 10),
                      _buildMacroRow('Fat', fat, 'g', AppTheme.accentOrange),
                      const SizedBox(height: 10),
                      _buildMacroRow('Carbs', carbs, 'g', Colors.purple),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String label, double value, String unit, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Text('${value.toStringAsFixed(1)}$unit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMealBreakdownCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.restaurant_menu, color: AppTheme.primaryGreen, size: 22),
              SizedBox(width: 8),
              Text('Meal Breakdown', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildMealCard(
              name: 'Breakfast',
              icon: Icons.wb_sunny_rounded,
              calories: _dailyLog?.breakfast.totalCalories ?? 0,
              color: const Color(0xFFFFB74D),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
              ),
            ),
            _buildMealCard(
              name: 'Lunch',
              icon: Icons.wb_sunny,
              calories: _dailyLog?.lunch.totalCalories ?? 0,
              color: const Color(0xFF4FC3F7),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
              ),
            ),
            _buildMealCard(
              name: 'Dinner',
              icon: Icons.nights_stay_rounded,
              calories: _dailyLog?.dinner.totalCalories ?? 0,
              color: const Color(0xFF7E57C2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
              ),
            ),
            _buildMealCard(
              name: 'Snacks',
              icon: Icons.cookie_rounded,
              calories: _dailyLog?.snacks.totalCalories ?? 0,
              color: const Color(0xFFFF8A65),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBE9E7), Color(0xFFFFCCBC)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required String name,
    required IconData icon,
    required int calories,
    required Color color,
    required Gradient gradient,
  }) {
    final percentage = widget.targetCalories > 0 
        ? (calories / widget.targetCalories * 100).clamp(0.0, 100.0) 
        : 0.0;
    final progress = percentage / 100;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToFoodLogging(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            strokeCap: StrokeCap.round,
                          ),
                          Text(
                            '${percentage.toInt()}%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$calories',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToFoodLogging() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodLoggingScreen(
          targetCalories: widget.targetCalories,
          bmr: widget.bmr,
          goal: widget.goal,
        ),
      ),
    );
    _loadDailyLog();
  }

  void _navigateToProfile() async {
    final profile = FirestoreService.cachedProfile;
    if (profile != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            profile: profile,
            onProfileUpdated: () => setState(() {}),
          ),
        ),
      );
      // Refresh UI to show updated name
      setState(() {});
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    
    switch (index) {
      case 0:
        // Home - already on home, just refresh
        _loadDailyLog();
        break;
      case 1:
        // Analytics - show coming soon
        _showComingSoonDialog('Analytics');
        break;
      case 2:
        // Plan - show coming soon
        _showComingSoonDialog('Meal Plan');
        break;
      case 3:
        // Setting - navigate to profile
        _navigateToProfile();
        break;
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.construction, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            const Text('Coming Soon'),
          ],
        ),
        content: Text(
          '$feature feature is under development. Stay tuned for updates!',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon() {
    switch (widget.goal) {
      case FitnessGoal.weightLoss: return Icons.trending_down;
      case FitnessGoal.maintenance: return Icons.balance;
      case FitnessGoal.weightGain: return Icons.trending_up;
    }
  }

  Color _getGoalColor() {
    switch (widget.goal) {
      case FitnessGoal.weightLoss: return AppTheme.accentOrange;
      case FitnessGoal.maintenance: return AppTheme.primaryGreen;
      case FitnessGoal.weightGain: return AppTheme.accentBlue;
    }
  }
}
