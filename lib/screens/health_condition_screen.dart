import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/health_alert_service.dart';

class HealthConditionScreen extends StatefulWidget {
  final Function(List<HealthCondition>) onComplete;
  final VoidCallback? onSkip;

  const HealthConditionScreen({
    super.key,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<HealthConditionScreen> createState() => _HealthConditionScreenState();
}

class _HealthConditionScreenState extends State<HealthConditionScreen> {
  final Set<HealthCondition> _selectedConditions = {};

  void _toggleCondition(HealthCondition condition) {
    setState(() {
      if (condition == HealthCondition.none) {
        _selectedConditions.clear();
        _selectedConditions.add(HealthCondition.none);
      } else {
        _selectedConditions.remove(HealthCondition.none);
        if (_selectedConditions.contains(condition)) {
          _selectedConditions.remove(condition);
        } else {
          _selectedConditions.add(condition);
        }
      }
    });
  }

  void _onContinue() {
    final conditions = _selectedConditions.isEmpty
        ? [HealthCondition.none]
        : _selectedConditions.toList();
    widget.onComplete(conditions);
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildInfoCard(),
                    const SizedBox(height: 14),
                    _buildConditionsGrid(),
                    const SizedBox(height: 14),
                    _buildDisclaimerCard(),
                    const SizedBox(height: 24),
                    _buildButtons(),
                    const SizedBox(height: 32),
                  ],
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
              'Health Profile',
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

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.healthGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.health_and_safety_rounded,
              size: 40, color: AppTheme.healthGreen),
        ),
        const SizedBox(height: 14),
        Text(
          'Health Profile 🩺',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Help us personalize your experience',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softYellow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.warningYellow.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warningYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lightbulb_outline_rounded,
                color: AppTheme.warningYellow, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why we ask',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "We'll provide gentle reminders when logging foods that may need extra mindfulness.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsGrid() {
    final conditions =
        HealthCondition.values.where((c) => c != HealthCondition.none).toList();

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
                child: const Icon(Icons.checklist_rounded,
                    color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select any that apply',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text('You can select multiple conditions',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppTheme.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: conditions.length,
            itemBuilder: (context, index) =>
                _buildConditionTile(conditions[index]),
          ),
          const SizedBox(height: 14),
          Divider(color: AppTheme.softGrey),
          const SizedBox(height: 10),
          _buildNoneOption(),
        ],
      ),
    );
  }

  Widget _buildConditionTile(HealthCondition condition) {
    final isSelected = _selectedConditions.contains(condition);

    return GestureDetector(
      onTap: () => _toggleCondition(condition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? AppTheme.healthGreen.withValues(alpha: 0.1)
              : AppTheme.softGrey,
          border: Border.all(
            color:
                isSelected ? AppTheme.healthGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              condition.icon,
              color: isSelected
                  ? AppTheme.healthGreen
                  : AppTheme.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                condition.label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.healthGreen
                      : AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.healthGreen, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoneOption() {
    final isSelected =
        _selectedConditions.contains(HealthCondition.none);

    return GestureDetector(
      onTap: () => _toggleCondition(HealthCondition.none),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : AppTheme.softGrey,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: isSelected
                  ? AppTheme.primaryGreen
                  : AppTheme.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'None of the above',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    "I don't have any specific health conditions",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isSelected
                          ? AppTheme.primaryGreen.withValues(alpha: 0.7)
                          : AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primaryGreen, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.softYellow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppTheme.warningYellow.withValues(alpha: 0.8),
              size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              HealthAlertService.medicalDisclaimer,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.onSkip != null)
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              'Skip for now',
              style: GoogleFonts.poppins(
                color: AppTheme.textTertiary,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}
