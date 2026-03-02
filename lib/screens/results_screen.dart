import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/bmr_calculator.dart';
import 'home_dashboard.dart';

class ResultsScreen extends StatefulWidget {
  final BMRResult result;
  final Gender gender;
  final int age;
  final double height;
  final double weight;

  const ResultsScreen({
    super.key,
    required this.result,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeDashboard(
          targetCalories: widget.result.targetCalories.round(),
          bmr: widget.result.bmr.round(),
          goal: widget.result.goal,
          maintenanceCalories: widget.result.maintenanceCalories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        _buildHeaderSection(),
                        const SizedBox(height: 24),
                        _buildUserSummary(),
                        const SizedBox(height: 24),
                        _buildMainResultCard(),
                        const SizedBox(height: 14),
                        _buildDetailCards(),
                        const SizedBox(height: 28),
                        _buildContinueButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          Expanded(
            child: Text(
              'Your Results',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreenSurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_events_rounded,
              size: 44, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 14),
        Text(
          'Calculation Complete! 🎉',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Here's your personalized calorie plan",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildUserSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreenSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryChip(Icons.person_rounded, widget.gender.label),
          _buildDivider(),
          _buildSummaryChip(Icons.cake_rounded, '${widget.age} yrs'),
          _buildDivider(),
          _buildSummaryChip(
              Icons.height_rounded, '${widget.height.round()} cm'),
          _buildDivider(),
          _buildSummaryChip(Icons.fitness_center_rounded,
              '${widget.weight.round()} kg'),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryGreen),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: AppTheme.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 1,
      height: 14,
      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
    );
  }

  Widget _buildMainResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _getGoalColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getGoalIcon(),
                    color: _getGoalColor(), size: 18),
                const SizedBox(width: 6),
                Text(
                  widget.result.goal.label,
                  style: GoogleFonts.poppins(
                    color: _getGoalColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Daily Calorie Target',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.result.targetCalories.round()}',
                style: GoogleFonts.poppins(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: _getGoalColor(),
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  'kcal',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.result.goal.description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Minimum',
            value: '${widget.result.bmr.round()}',
            unit: 'kcal/day',
            color: AppTheme.accentOrange,
            description: 'At rest',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.directions_run_rounded,
            label: 'Maintenance',
            value: '${widget.result.maintenanceCalories.round()}',
            unit: 'kcal/day',
            color: AppTheme.primaryGreen,
            description: widget.result.activityLevel.label,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(unit,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.7))),
          const SizedBox(height: 2),
          Text(description,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppTheme.textTertiary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _navigateToDashboard,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              'Go to Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getGoalIcon() {
    switch (widget.result.goal) {
      case FitnessGoal.weightLoss:
        return Icons.trending_down_rounded;
      case FitnessGoal.maintenance:
        return Icons.balance_rounded;
      case FitnessGoal.weightGain:
        return Icons.trending_up_rounded;
    }
  }

  Color _getGoalColor() {
    switch (widget.result.goal) {
      case FitnessGoal.weightLoss:
        return AppTheme.accentOrange;
      case FitnessGoal.maintenance:
        return AppTheme.primaryGreen;
      case FitnessGoal.weightGain:
        return AppTheme.accentBlue;
    }
  }
}
