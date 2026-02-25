import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'food_logging_screen.dart';
import 'profile_screen.dart';
import '../utils/bmr_calculator.dart';

class WeeklyAnalyticsScreen extends StatefulWidget {
  final int targetCalories;
  final int bmr;
  final FitnessGoal goal;
  final double maintenanceCalories;

  const WeeklyAnalyticsScreen({
    super.key,
    required this.targetCalories,
    required this.bmr,
    required this.goal,
    required this.maintenanceCalories,
  });

  @override
  State<WeeklyAnalyticsScreen> createState() => _WeeklyAnalyticsScreenState();
}

class _WeeklyAnalyticsScreenState extends State<WeeklyAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late Future<WeeklyAnalyticsData> _analyticsFuture;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = AnalyticsService.getAnalytics(
      targetCalories: widget.targetCalories,
      days: _selectedDays,
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  void _switchPeriod(int days) {
    if (days == _selectedDays) return;
    setState(() {
      _selectedDays = days;
      _analyticsFuture = AnalyticsService.getAnalytics(
        targetCalories: widget.targetCalories,
        days: _selectedDays,
      );
      _animController.reset();
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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
              _buildPeriodToggle(),
              Expanded(
                child: FutureBuilder<WeeklyAnalyticsData>(
                  future: _analyticsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState();
                    }

                    final data = snapshot.data;
                    if (data == null || data.isEmpty) {
                      return _buildEmptyState();
                    }

                    return FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildContent(data),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Analytics tab
        onTap: _onNavTap,
        onAddPressed: _navigateToFoodLogging,
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        // Home — go back to dashboard
        Navigator.pop(context);
        break;
      case 1:
        // Already on Analytics — do nothing
        break;
      case 2:
        // Plan — coming soon
        _showComingSoonDialog('Meal Plan');
        break;
      case 3:
        // Settings — navigate to profile
        _navigateToProfile();
        break;
    }
  }

  void _navigateToFoodLogging() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodLoggingScreen(
          targetCalories: widget.targetCalories,
          bmr: widget.bmr,
          goal: widget.goal,
        ),
      ),
    );
  }

  void _navigateToProfile() {
    final profile = FirestoreService.cachedProfile;
    if (profile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            profile: profile,
            onProfileUpdated: () => setState(() {}),
          ),
        ),
      );
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

  // ── App Bar ──────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.analytics_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          const Text(
            'Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            _buildToggleButton('Weekly', 7),
            _buildToggleButton('Monthly', 30),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, int days) {
    final isSelected = _selectedDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchPeriod(days),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.primaryGreen : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ── Main Content ────────────────────────────────────────────────────

  Widget _buildContent(WeeklyAnalyticsData data) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOverviewCards(data),
          const SizedBox(height: 16),
          _buildTargetComparisonCard(data),
          const SizedBox(height: 16),
          _buildMacroAveragesCard(data),
          const SizedBox(height: 16),
          _buildDailyTrendChart(data),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Overview Cards ──────────────────────────────────────────────────

  Widget _buildOverviewCards(WeeklyAnalyticsData data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF7043),
            iconBgColor: const Color(0xFFFBE9E7),
            label: 'Total Calories',
            value: '${data.weeklyTotalCalories}',
            subtitle: '${data.daysLogged} days logged',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            iconColor: AppTheme.primaryGreen,
            iconBgColor: const Color(0xFFE8F5E9),
            label: 'Daily Average',
            value: '${data.averageDailyCalories}',
            subtitle: 'kcal / day',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGrey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Target Comparison ───────────────────────────────────────────────

  Widget _buildTargetComparisonCard(WeeklyAnalyticsData data) {
    final pct = data.calorieTargetPercentage;
    final clampedPct = pct.clamp(0.0, 100.0);
    final isOver = pct > 100;
    final barColor = isOver ? AppTheme.accentRed : AppTheme.primaryGreen;
    final totalTarget = widget.targetCalories * data.daysLogged;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.track_changes_rounded,
                    color: AppTheme.primaryGreen, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Target vs Consumed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: clampedPct / 100,
                minHeight: 14,
                backgroundColor: AppTheme.mediumGrey,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTargetLabel(
                  'Consumed',
                  '${data.weeklyTotalCalories} kcal',
                  AppTheme.accentOrange,
                ),
                _buildTargetLabel(
                  'Target (${data.daysLogged}d)',
                  '$totalTarget kcal',
                  AppTheme.primaryGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetLabel(String label, String value, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey)),
          ],
        ),
      ],
    );
  }

  // ── Macro Averages ──────────────────────────────────────────────────

  Widget _buildMacroAveragesCard(WeeklyAnalyticsData data) {
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
                Icon(Icons.pie_chart_rounded,
                    color: AppTheme.primaryGreen, size: 22),
                SizedBox(width: 8),
                Text(
                  'Average Daily Macros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMacroItem(
                    label: 'Protein',
                    value: data.weeklyAverageProtein,
                    color: AppTheme.accentBlue,
                    icon: Icons.egg_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppTheme.mediumGrey,
                ),
                Expanded(
                  child: _buildMacroItem(
                    label: 'Carbs',
                    value: data.weeklyAverageCarbs,
                    color: Colors.purple,
                    icon: Icons.grain_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppTheme.mediumGrey,
                ),
                Expanded(
                  child: _buildMacroItem(
                    label: 'Fats',
                    value: data.weeklyAverageFats,
                    color: AppTheme.accentOrange,
                    icon: Icons.water_drop_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
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

  // ── Daily Trend Bar Chart ───────────────────────────────────────────

  Widget _buildDailyTrendChart(WeeklyAnalyticsData data) {
    final logs = data.dailyLogs;
    final maxCalories = logs
        .map((l) => l.totalCalories)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final chartMax = (maxCalories * 1.2).clamp(100.0, double.infinity);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_rounded,
                    color: AppTheme.primaryGreen, size: 22),
                SizedBox(width: 8),
                Text(
                  'Daily Calorie Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Target reference line label
            Row(
              children: [
                Container(
                  width: 16,
                  height: 2,
                  color: AppTheme.accentRed.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Target: ${widget.targetCalories} kcal',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _selectedDays <= 7 ? 200 : 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMax > widget.targetCalories.toDouble()
                      ? chartMax
                      : widget.targetCalories * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} kcal',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= logs.length) {
                            return const SizedBox.shrink();
                          }
                          // For monthly view, only show every 5th label to avoid crowding
                          if (_selectedDays > 7 && index % 5 != 0 && index != logs.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _dayLabel(logs[index].date),
                              style: TextStyle(
                                fontSize: _selectedDays > 7 ? 8 : 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMax / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.mediumGrey.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: widget.targetCalories.toDouble(),
                        color: AppTheme.accentRed.withValues(alpha: 0.5),
                        strokeWidth: 2,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
                  barGroups: List.generate(logs.length, (i) {
                    final cal = logs[i].totalCalories.toDouble();
                    final isOver = cal > widget.targetCalories;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                         BarChartRodData(
                          toY: cal,
                          width: logs.length <= 4
                              ? 28
                              : logs.length <= 7
                                  ? 20
                                  : 8,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: isOver
                                ? [
                                    const Color(0xFFFF8A65),
                                    const Color(0xFFE53935),
                                  ]
                                : [
                                    const Color(0xFF81C784),
                                    const Color(0xFF4CAF50),
                                  ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Converts a `YYYY-MM-DD` date string to a label.
  /// Weekly: short day name ("Mon"). Monthly: date ("15/2").
  String _dayLabel(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      if (_selectedDays <= 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (_) {
      return dateStr.length >= 5 ? dateStr.substring(5) : dateStr;
    }
  }

  // ── Empty & Error States ────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Data Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your meals to see\nyour weekly analytics here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Could not load analytics.\nPlease try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
