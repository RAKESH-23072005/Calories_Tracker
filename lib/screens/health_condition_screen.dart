import 'package:flutter/material.dart';
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
        // Selecting 'None' clears all other selections
        _selectedConditions.clear();
        _selectedConditions.add(HealthCondition.none);
      } else {
        // Remove 'None' if selecting a specific condition
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
            stops: [0.0, 0.2, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  color: AppTheme.softGrey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        _buildConditionsGrid(),
                        const SizedBox(height: 16),
                        _buildDisclaimerCard(),
                        const SizedBox(height: 24),
                        _buildButtons(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Health Profile',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us personalize your experience',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.softYellow.withValues(alpha: 0.5),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningYellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: AppTheme.warningYellow,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why we ask',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'We\'ll provide gentle reminders when logging foods that may need extra mindfulness based on your selections.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsGrid() {
    // Separate 'None' from other conditions
    final conditions = HealthCondition.values.where((c) => c != HealthCondition.none).toList();

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
                Icon(Icons.checklist, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Select any that apply',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'You can select multiple conditions',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            // Conditions grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: conditions.length,
              itemBuilder: (context, index) {
                final condition = conditions[index];
                return _buildConditionTile(condition);
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // 'None' option
            _buildNoneOption(),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionTile(HealthCondition condition) {
    final isSelected = _selectedConditions.contains(condition);

    return InkWell(
      onTap: () => _toggleCondition(condition),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppTheme.healthGreen.withValues(alpha: 0.15)
              : AppTheme.softGrey,
          border: Border.all(
            color: isSelected ? AppTheme.healthGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              condition.icon,
              color: isSelected ? AppTheme.healthGreen : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                condition.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppTheme.healthGreen : AppTheme.darkGrey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.healthGreen,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoneOption() {
    final isSelected = _selectedConditions.contains(HealthCondition.none);

    return InkWell(
      onTap: () => _toggleCondition(HealthCondition.none),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
              : AppTheme.softGrey,
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'None of the above',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'I don\'t have any specific health conditions',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppTheme.primaryGreen.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Card(
      elevation: 1,
      color: AppTheme.softYellow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.warningYellow.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                HealthAlertService.medicalDisclaimer,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkGrey.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _onContinue,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 3,
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.onSkip != null)
          TextButton(
            onPressed: widget.onSkip,
            child: const Text(
              'Skip for now',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}
