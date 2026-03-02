import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/bmr_calculator.dart';
import '../utils/macro_calculator.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/daily_log_service.dart';
import '../services/notification_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'food_logging_screen.dart';
import 'profile_screen.dart';
import 'weekly_analytics_screen.dart';
import 'dart:math' as math;

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

class _HomeDashboardState extends State<HomeDashboard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  DailyLogData? _dailyLog;
  int _currentNavIndex = 0;
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadDailyLog();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
        _animController.forward(from: 0);

        final consumed = log?.totalCalories ?? 0;
        if (consumed > widget.targetCalories * 0.9 &&
            widget.targetCalories > 0) {
          NotificationService.showCalorieLimitAlert(
              consumed, widget.targetCalories);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _consumedCalories => _dailyLog?.totalCalories ?? 0;
  int get _remainingCalories => widget.targetCalories - _consumedCalories;
  double get _progress =>
      widget.targetCalories > 0
          ? _consumedCalories / widget.targetCalories
          : 0;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppTheme.primaryGreen))
            : RefreshIndicator(
                onRefresh: _loadDailyLog,
                color: AppTheme.primaryGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreetingHeader(),
                      const SizedBox(height: 24),
                      _buildCalorieRingCard(),
                      const SizedBox(height: 16),
                      _buildMacroStatsRow(),
                      const SizedBox(height: 24),
                      _buildTodaysMealSection(),
                      const SizedBox(height: 80),
                    ],
                  ),
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

  // ── Greeting Header ──────────────────────────────────────────────────
  Widget _buildGreetingHeader() {
    final email = AuthService.currentUser?.email ?? 'User';
    final emailName = email.split('@')[0];
    final profile = FirestoreService.cachedProfile;
    final name = (profile != null && profile.name.isNotEmpty)
        ? profile.name
        : emailName;
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: _navigateToProfile,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreenSurface,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  width: 2),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$_greeting 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                dateStr,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
        // Settings icon
        GestureDetector(
          onTap: _navigateToProfile,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.softGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_outlined,
                color: AppTheme.textSecondary, size: 22),
          ),
        ),
      ],
    );
  }

  // ── Calorie Ring Card ────────────────────────────────────────────────
  Widget _buildCalorieRingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          // Ring
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, child) {
              return SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _CalorieRingPainter(
                    progress: (_progress * _progressAnim.value).clamp(0.0, 1.0),
                    isOver: _progress > 1.0,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Calories',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        Text(
                          '$_consumedCalories',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'of ${widget.targetCalories} kcal',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Stats row below ring
          Row(
            children: [
              _buildRingStat(
                icon: Icons.flag_outlined,
                label: 'Target',
                value: '${widget.targetCalories}',
                color: AppTheme.primaryGreen,
              ),
              _buildDivider(),
              _buildRingStat(
                icon: Icons.local_fire_department_outlined,
                label: 'Consumed',
                value: '$_consumedCalories',
                color: AppTheme.accentOrange,
              ),
              _buildDivider(),
              _buildRingStat(
                icon: _remainingCalories >= 0
                    ? Icons.remove_circle_outline
                    : Icons.warning_amber_rounded,
                label: _remainingCalories >= 0 ? 'Remaining' : 'Over',
                value: '${_remainingCalories.abs()}',
                color: _remainingCalories >= 0
                    ? AppTheme.accentBlue
                    : AppTheme.accentRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
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
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.mediumGrey,
    );
  }

  // ── Macro Stats Row ──────────────────────────────────────────────────
  Widget _buildMacroStatsRow() {
    final profile = FirestoreService.cachedProfile;
    MacroResult? targetMacros;
    if (profile != null) {
      targetMacros = MacroCalculator.calculate(
        weightKg: profile.weight,
        totalCalories: widget.targetCalories,
        goal: widget.goal,
      );
    }

    final consumedProtein = _dailyLog?.totalProtein ?? 0;
    final consumedFat = _dailyLog?.totalFat ?? 0;
    final consumedCarbs = _dailyLog?.totalCarbs ?? 0;
    final targetProtein = targetMacros?.proteinGrams ?? 0;
    final targetFat = targetMacros?.fatGrams ?? 0;
    final targetCarbs = targetMacros?.carbGrams ?? 0;

    return Row(
      children: [
        _buildMacroCard(
          label: 'Protein',
          consumed: consumedProtein,
          target: targetProtein,
          color: AppTheme.accentBlue,
          icon: Icons.egg_outlined,
        ),
        const SizedBox(width: 10),
        _buildMacroCard(
          label: 'Carbs',
          consumed: consumedCarbs,
          target: targetCarbs,
          color: AppTheme.accentPurple,
          icon: Icons.grain_rounded,
        ),
        const SizedBox(width: 10),
        _buildMacroCard(
          label: 'Fat',
          consumed: consumedFat,
          target: targetFat,
          color: AppTheme.accentOrange,
          icon: Icons.water_drop_outlined,
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required String label,
    required double consumed,
    required double target,
    required Color color,
    required IconData icon,
  }) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${consumed.toStringAsFixed(0)}g',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${target.toStringAsFixed(0)}g target',
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Today's Meal Section ─────────────────────────────────────────────
  Widget _buildTodaysMealSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Today's Meal",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _navigateToFoodLogging,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
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
        const SizedBox(height: 12),
        _buildMealCard(
          name: 'Breakfast',
          icon: Icons.wb_sunny_rounded,
          calories: _dailyLog?.breakfast.totalCalories ?? 0,
          protein: _dailyLog?.breakfast.totalProtein ?? 0,
          carbs: _dailyLog?.breakfast.totalCarbs ?? 0,
          fat: _dailyLog?.breakfast.totalFat ?? 0,
          color: AppTheme.breakfastColor,
          bgColor: const Color(0xFFFFF8F0),
        ),
        const SizedBox(height: 10),
        _buildMealCard(
          name: 'Lunch',
          icon: Icons.wb_sunny,
          calories: _dailyLog?.lunch.totalCalories ?? 0,
          protein: _dailyLog?.lunch.totalProtein ?? 0,
          carbs: _dailyLog?.lunch.totalCarbs ?? 0,
          fat: _dailyLog?.lunch.totalFat ?? 0,
          color: AppTheme.lunchColor,
          bgColor: const Color(0xFFF0F8FF),
        ),
        const SizedBox(height: 10),
        _buildMealCard(
          name: 'Dinner',
          icon: Icons.nights_stay_rounded,
          calories: _dailyLog?.dinner.totalCalories ?? 0,
          protein: _dailyLog?.dinner.totalProtein ?? 0,
          carbs: _dailyLog?.dinner.totalCarbs ?? 0,
          fat: _dailyLog?.dinner.totalFat ?? 0,
          color: AppTheme.dinnerColor,
          bgColor: const Color(0xFFF5F0FF),
        ),
        const SizedBox(height: 10),
        _buildMealCard(
          name: 'Snacks',
          icon: Icons.cookie_rounded,
          calories: _dailyLog?.snacks.totalCalories ?? 0,
          protein: _dailyLog?.snacks.totalProtein ?? 0,
          carbs: _dailyLog?.snacks.totalCarbs ?? 0,
          fat: _dailyLog?.snacks.totalFat ?? 0,
          color: AppTheme.snackColor,
          bgColor: const Color(0xFFFFF5F0),
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required String name,
    required IconData icon,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required Color color,
    required Color bgColor,
  }) {
    final hasData = calories > 0;

    return GestureDetector(
      onTap: () => _navigateToFoodLogging(mealType: name),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // Meal icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            // Meal info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  hasData
                      ? Text(
                          'P: ${protein.toStringAsFixed(0)}g  C: ${carbs.toStringAsFixed(0)}g  F: ${fat.toStringAsFixed(0)}g',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                          ),
                        )
                      : Text(
                          'Tap to add food',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                ],
              ),
            ),
            // Calorie count or add icon
            hasData
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$calories',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: color,
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
                  )
                : Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_rounded, color: color, size: 20),
                  ),
          ],
        ),
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────
  void _navigateToFoodLogging({String mealType = 'Breakfast'}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodLoggingScreen(
          targetCalories: widget.targetCalories,
          bmr: widget.bmr,
          goal: widget.goal,
          initialMealType: mealType,
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
      setState(() => _currentNavIndex = 0);
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        _loadDailyLog();
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeeklyAnalyticsScreen(
              targetCalories: widget.targetCalories,
              bmr: widget.bmr,
              goal: widget.goal,
              maintenanceCalories: widget.maintenanceCalories,
            ),
          ),
        ).then((_) {
          setState(() => _currentNavIndex = 0);
          _loadDailyLog();
        });
        break;
      case 2:
        _showComingSoonDialog('Meal Plan');
        break;
      case 3:
        _navigateToProfile();
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
}

// ── Custom Calorie Ring Painter ──────────────────────────────────────────
class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final bool isOver;

  _CalorieRingPainter({required this.progress, required this.isOver});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 14.0;
    const startAngle = -math.pi / 2;

    // Background track
    final bgPaint = Paint()
      ..color = AppTheme.softGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweepAngle > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: isOver
            ? [const Color(0xFFFF6B6B), const Color(0xFFEE5A5A)]
            : [const Color(0xFF5DD39E), const Color(0xFF2DB573)],
      );

      final arcPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

      // End cap dot
      final endAngle = startAngle + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      final dotPaint = Paint()
        ..color = isOver ? const Color(0xFFEE5A5A) : const Color(0xFF2DB573)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter old) =>
      old.progress != progress || old.isOver != isOver;
}
