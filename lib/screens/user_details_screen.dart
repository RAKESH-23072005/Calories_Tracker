import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Store BMR result for use after health condition selection
  BMRResult? _bmrResult;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

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

      // Navigate to health condition selection screen
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

  Future<void> _saveProfileAndContinue(List<HealthCondition> conditions) async {
    if (_bmrResult == null) return;

    setState(() => _isSaving = true);

    // Save user profile to Firestore with health conditions
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

    // Also save locally for quick access
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
        const SnackBar(
          content: Text('Profile saved locally. Cloud sync failed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Pop back to user details, then replace with results
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
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number';
    }
    if (age < 1 || age > 120) {
      return 'Age must be between 1 and 120';
    }
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your height';
    }
    final height = double.tryParse(value);
    if (height == null) {
      return 'Please enter a valid number';
    }
    if (height < 50 || height > 300) {
      return 'Height must be between 50 and 300 cm';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your weight';
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid number';
    }
    if (weight < 20 || weight > 500) {
      return 'Weight must be between 20 and 500 kg';
    }
    return null;
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
              Color(0xFF4CAF50), // Primary green
              Color(0xFF81C784), // Light green
              Color(0xFFF5F5F5), // Soft grey
            ],
            stops: [0.0, 0.25, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Logout button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8),
                  child: IconButton(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                  ),
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
                          const SizedBox(height: 16),
                          _buildActivityCard(),
                          const SizedBox(height: 16),
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
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.accentOrange),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.fitness_center,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Calorie Calculator',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your details to calculate\nyour daily calorie needs',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Gender Selection
            const Text(
              'Gender',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Gender>(
                segments: Gender.values.map((gender) {
                  return ButtonSegment(
                    value: gender,
                    label: Text(gender.label),
                    icon: Icon(
                      gender == Gender.male ? Icons.male : Icons.female,
                    ),
                  );
                }).toList(),
                selected: {_selectedGender},
                onSelectionChanged: (selected) {
                  setState(() {
                    _selectedGender = selected.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            // Age Input
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: 'Enter your age',
                suffixText: 'years',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateAge,
            ),
            const SizedBox(height: 16),
            // Height Input
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height',
                hintText: 'Enter your height',
                suffixText: 'cm',
                prefixIcon: Icon(Icons.height),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: _validateHeight,
            ),
            const SizedBox(height: 16),
            // Weight Input
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight',
                hintText: 'Enter your weight',
                suffixText: 'kg',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: _validateWeight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.directions_run, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Activity Level',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ActivityLevel>(
              value: _selectedActivityLevel,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.speed),
              ),
              items: ActivityLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        level.label,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        level.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedActivityLevel = value;
                  });
                }
              },
              selectedItemBuilder: (context) {
                return ActivityLevel.values.map((level) {
                  return Text(level.label);
                }).toList();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag_outlined, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Fitness Goal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: FitnessGoal.values.map((goal) {
                final isSelected = _selectedGoal == goal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedGoal = goal;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getGoalColor(goal).withValues(alpha: 0.1)
                            : AppTheme.softGrey,
                        borderRadius: BorderRadius.circular(12),
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
                                  ? _getGoalColor(goal).withValues(alpha: 0.2)
                                  : AppTheme.mediumGrey,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getGoalIcon(goal),
                              color: isSelected
                                  ? _getGoalColor(goal)
                                  : AppTheme.textSecondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? _getGoalColor(goal)
                                        : AppTheme.darkGrey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  goal.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: _getGoalColor(goal),
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
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
        return Icons.trending_down;
      case FitnessGoal.maintenance:
        return Icons.balance;
      case FitnessGoal.weightGain:
        return Icons.trending_up;
    }
  }

  Widget _buildCalculateButton() {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : _calculateAndNavigate,
      icon: _isSaving 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.calculate),
      label: Text(_isSaving ? 'Calculating...' : 'Calculate My Calories'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 4,
      ),
    );
  }
}
