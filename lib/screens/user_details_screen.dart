import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/bmr_calculator.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/firestore_service.dart';
import 'health_condition_screen.dart';
import 'results_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  Gender _selectedGender = Gender.male;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  FitnessGoal _selectedGoal = FitnessGoal.maintenance;
  BMRResult? _bmrResult;
  bool _isSaving = false;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndNavigate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      _bmrResult = BMRCalculator.calculate(
        weightKg: double.parse(_weightController.text),
        heightCm: double.parse(_heightController.text),
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        activityLevel: _selectedActivityLevel,
        goal: _selectedGoal,
      );

      setState(() => _isSaving = false);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HealthConditionScreen(
            onComplete: (conditions) => _saveProfileAndContinue(conditions),
            onSkip: () => _saveProfileAndContinue([HealthCondition.none]),
          ),
        ),
      );
    }
  }

  Future<void> _saveProfileAndContinue(
      List<HealthCondition> conditions) async {
    if (_bmrResult == null) return;

    setState(() => _isSaving = true);

    final firestoreProfile = FirestoreUserProfile(
      name: AuthService.currentUser?.email?.split('@')[0] ?? 'User',
      age: int.parse(_ageController.text),
      gender: _selectedGender,
      height: double.parse(_heightController.text),
      weight: double.parse(_weightController.text),
      activityLevel: _selectedActivityLevel,
      fitnessGoal: _selectedGoal,
      targetCalories: _bmrResult!.targetCalories.round(),
      bmr: _bmrResult!.bmr.round(),
      maintenanceCalories: _bmrResult!.maintenanceCalories,
      healthConditions: conditions,
    );

    final success = await FirestoreService.saveUserProfile(firestoreProfile);

    final localProfile = UserProfile(
      name: AuthService.currentUser?.email?.split('@')[0] ?? 'User',
      age: int.parse(_ageController.text),
      gender: _selectedGender,
      height: double.parse(_heightController.text),
      weight: double.parse(_weightController.text),
      activityLevel: _selectedActivityLevel,
      fitnessGoal: _selectedGoal,
      targetCalories: _bmrResult!.targetCalories.round(),
      bmr: _bmrResult!.bmr.round(),
      maintenanceCalories: _bmrResult!.maintenanceCalories,
    );
    await UserProfileService.saveProfile(localProfile);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile saved locally. Cloud sync failed.',
              style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          result: _bmrResult!,
          gender: _selectedGender,
          age: int.parse(_ageController.text),
          height: double.parse(_heightController.text),
          weight: double.parse(_weightController.text),
        ),
      ),
    );
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your age';
    final age = int.tryParse(value);
    if (age == null) return 'Please enter a valid number';
    if (age < 1 || age > 120) return 'Age must be between 1 and 120';
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your height';
    final h = double.tryParse(value);
    if (h == null) return 'Please enter a valid number';
    if (h < 50 || h > 300) return 'Height must be between 50 and 300 cm';
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your weight';
    final w = double.tryParse(value);
    if (w == null) return 'Please enter a valid number';
    if (w < 20 || w > 500) return 'Weight must be between 20 and 500 kg';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    'Setup Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.softGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          size: 18, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderSection(),
                        const SizedBox(height: 24),
                        _buildPersonalInfoCard(),
                        const SizedBox(height: 12),
                        _buildActivityCard(),
                        const SizedBox(height: 12),
                        _buildGoalCard(),
                        const SizedBox(height: 24),
                        _buildCalculateButton(),
                        const SizedBox(height: 32),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            Text('Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreenSurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.fitness_center_rounded,
              size: 40, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 16),
        Text(
          'Calorie Calculator',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your details to calculate\nyour daily calorie needs',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textTertiary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
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
          _buildSectionHeader(Icons.person_rounded, 'Personal Information'),
          const SizedBox(height: 18),

          // Gender selection
          Text('Gender',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: Gender.values.map((gender) {
              final isSelected = _selectedGender == gender;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = gender),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.softGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          gender == Gender.male ? Icons.male : Icons.female,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          gender.label,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Age
          _buildFieldLabel('Age'),
          TextFormField(
            controller: _ageController,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter your age',
              suffixText: 'years',
              prefixIcon: _buildFieldIcon(Icons.cake_rounded),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateAge,
          ),
          const SizedBox(height: 14),

          // Height
          _buildFieldLabel('Height'),
          TextFormField(
            controller: _heightController,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter your height',
              suffixText: 'cm',
              prefixIcon: _buildFieldIcon(Icons.height_rounded),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: _validateHeight,
          ),
          const SizedBox(height: 14),

          // Weight
          _buildFieldLabel('Weight'),
          TextFormField(
            controller: _weightController,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter your weight',
              suffixText: 'kg',
              prefixIcon: _buildFieldIcon(Icons.monitor_weight_outlined),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: _validateWeight,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
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
          _buildSectionHeader(
              Icons.directions_run_rounded, 'Activity Level'),
          const SizedBox(height: 14),
          DropdownButtonFormField<ActivityLevel>(
            value: _selectedActivityLevel,
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              prefixIcon: _buildFieldIcon(Icons.speed_rounded),
            ),
            items: ActivityLevel.values.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(level.label,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                    Text(level.description,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppTheme.textTertiary)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedActivityLevel = v);
            },
            selectedItemBuilder: (context) {
              return ActivityLevel.values
                  .map((l) => Text(l.label,
                      style: GoogleFonts.poppins(fontSize: 13)))
                  .toList();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
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
          _buildSectionHeader(Icons.flag_rounded, 'Fitness Goal'),
          const SizedBox(height: 14),
          ...FitnessGoal.values.map((goal) {
            final isSelected = _selectedGoal == goal;
            return GestureDetector(
              onTap: () => setState(() => _selectedGoal = goal),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getGoalColor(goal).withValues(alpha: 0.06)
                      : AppTheme.softGrey,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? _getGoalColor(goal)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getGoalColor(goal)
                                .withValues(alpha: 0.15)
                            : AppTheme.mediumGrey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getGoalIcon(goal),
                        color: isSelected
                            ? _getGoalColor(goal)
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.label,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? _getGoalColor(goal)
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            goal.description,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: _getGoalColor(goal), size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _calculateAndNavigate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          disabledBackgroundColor:
              AppTheme.primaryGreen.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Calculate My Calories',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
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
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary)),
    );
  }

  Widget _buildFieldIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreenSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppTheme.primaryGreen, size: 18),
    );
  }

  Color _getGoalColor(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return AppTheme.accentOrange;
      case FitnessGoal.maintenance:
        return AppTheme.primaryGreen;
      case FitnessGoal.weightGain:
        return AppTheme.accentBlue;
    }
  }

  IconData _getGoalIcon(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return Icons.trending_down_rounded;
      case FitnessGoal.maintenance:
        return Icons.balance_rounded;
      case FitnessGoal.weightGain:
        return Icons.trending_up_rounded;
    }
  }
}
