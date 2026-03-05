import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
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
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 4),
            _buildPeriodToggle(),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<WeeklyAnalyticsData>(
                future: _analyticsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen),
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: _onNavTap,
        onAddPressed: _navigateToFoodLogging,
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.softGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreenSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics_rounded,
                color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Analytics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Period Toggle ──────────────────────────────────────────────────────
  Widget _buildPeriodToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.softGrey,
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
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Main Content ───────────────────────────────────────────────────────
  Widget _buildContent(WeeklyAnalyticsData data) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOverviewCards(data),
          const SizedBox(height: 12),
          _buildTargetComparisonCard(data),
          const SizedBox(height: 12),
          _buildMacroAveragesCard(data),
          const SizedBox(height: 12),
          _buildDailyTrendChart(data),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Overview Cards ─────────────────────────────────────────────────────
  Widget _buildOverviewCards(WeeklyAnalyticsData data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            color: AppTheme.accentOrange,
            label: 'Total Calories',
            value: '${data.weeklyTotalCalories}',
            subtitle: '${data.daysLogged} days logged',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            color: AppTheme.primaryGreen,
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
    required Color color,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Target Comparison ──────────────────────────────────────────────────
  Widget _buildTargetComparisonCard(WeeklyAnalyticsData data) {
    final pct = data.calorieTargetPercentage;
    final clampedPct = pct.clamp(0.0, 100.0);
    final isOver = pct > 100;
    final barColor = isOver ? AppTheme.accentRed : AppTheme.primaryGreen;
    final totalTarget = widget.targetCalories * data.daysLogged;

    return _buildSection(
      icon: Icons.track_changes_rounded,
      title: 'Target vs Consumed',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: barColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${pct.toStringAsFixed(1)}%',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: barColor,
          ),
        ),
      ),
      children: [
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: clampedPct / 100,
            minHeight: 12,
            backgroundColor: AppTheme.softGrey,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTargetLabel(
                'Consumed', '${data.weeklyTotalCalories} kcal',
                AppTheme.accentOrange),
            _buildTargetLabel(
                'Target (${data.daysLogged}d)', '$totalTarget kcal',
                AppTheme.primaryGreen),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetLabel(String label, String value, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppTheme.textTertiary)),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }

  // ── Macro Averages ─────────────────────────────────────────────────────
  Widget _buildMacroAveragesCard(WeeklyAnalyticsData data) {
    return _buildSection(
      icon: Icons.pie_chart_rounded,
      title: 'Average Daily Macros',
      children: [
        const SizedBox(height: 4),
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
            Container(width: 1, height: 44, color: AppTheme.softGrey),
            Expanded(
              child: _buildMacroItem(
                label: 'Carbs',
                value: data.weeklyAverageCarbs,
                color: AppTheme.accentPurple,
                icon: Icons.grain_rounded,
              ),
            ),
            Container(width: 1, height: 44, color: AppTheme.softGrey),
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
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // ── Daily Trend Bar Chart ──────────────────────────────────────────────
  Widget _buildDailyTrendChart(WeeklyAnalyticsData data) {
    final logs = data.dailyLogs;
    final maxCalories = logs
        .map((l) => l.totalCalories)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final chartMax = (maxCalories * 1.2).clamp(100.0, double.infinity);

    return _buildSection(
      icon: Icons.bar_chart_rounded,
      title: 'Daily Calorie Trend',
      children: [
        Row(
          children: [
            Container(
              width: 14,
              height: 2,
              color: AppTheme.accentRed.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'Target: ${widget.targetCalories} kcal',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                  tooltipRoundedRadius: 10,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()} kcal',
                      GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
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
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          '${value.toInt()}',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: AppTheme.textTertiary,
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
                      if (_selectedDays > 7 &&
                          index % 5 != 0 &&
                          index != logs.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _dayLabel(logs[index].date),
                          style: GoogleFonts.poppins(
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
                  color: AppTheme.softGrey,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: widget.targetCalories.toDouble(),
                    color: AppTheme.accentRed.withValues(alpha: 0.4),
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
                                AppTheme.accentOrange,
                                AppTheme.accentRed,
                              ]
                            : [
                                AppTheme.primaryGreenLight,
                                AppTheme.primaryGreen,
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
    );
  }

  /// Converts a `YYYY-MM-DD` date string to a label.
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

  // ── Reusable Section Container ─────────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ── Empty & Error States ───────────────────────────────────────────────
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
                color: AppTheme.primaryGreenSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 56,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Yet',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your meals to see\nyour analytics here!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textTertiary,
                height: 1.5,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.accentRed),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Could not load analytics.\nPlease try again later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textTertiary),
            ),
          ],
        ),
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
        break;
      case 2:
        _showComingSoonDialog('Meal Plan');
        break;
      case 3:
        final profile = FirestoreService.cachedProfile;
        if (profile != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                profile: profile,
                onProfileUpdated: () {},
              ),
            ),
          );
        }
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

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.construction_rounded,
                color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            Text('Coming Soon',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          '$feature feature is under development!',
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
}
