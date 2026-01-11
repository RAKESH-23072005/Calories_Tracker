import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/daily_log_service.dart';
import '../utils/bmr_calculator.dart';

class ProfileScreen extends StatefulWidget {
  final FirestoreUserProfile profile;
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({
    super.key,
    required this.profile,
    this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late FirestoreUserProfile _profile;
  bool _isEditing = false;
  bool _isSaving = false;

  // Edit controllers
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late Gender _editGender;
  late ActivityLevel _editActivityLevel;
  late FitnessGoal _editGoal;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _initEditControllers();
  }

  void _initEditControllers() {
    final email = AuthService.currentUser?.email ?? 'User';
    final defaultName = email.split('@')[0];
    _nameController = TextEditingController(text: _profile.name.isNotEmpty ? _profile.name : defaultName);
    _ageController = TextEditingController(text: _profile.age.toString());
    _heightController = TextEditingController(text: _profile.height.round().toString());
    _weightController = TextEditingController(text: _profile.weight.round().toString());
    _editGender = _profile.gender;
    _editActivityLevel = _profile.activityLevel;
    _editGoal = _profile.fitnessGoal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
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
            colors: [Color(0xFF4CAF50), Color(0xFF81C784), Color(0xFFF5F5F5)],
            stops: [0.0, 0.25, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _isEditing ? _buildEditForm() : _buildPersonalInfoCard(),
                      const SizedBox(height: 16),
                      if (!_isEditing) _buildCalorieInfoCard(),
                      if (!_isEditing) const SizedBox(height: 16),
                      if (!_isEditing) _buildGoalCard(),
                      if (!_isEditing) const SizedBox(height: 24),
                      if (!_isEditing) _buildActionsCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_isEditing) {
                setState(() => _isEditing = false);
                _initEditControllers();
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(_isEditing ? Icons.close : Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              _isEditing ? 'Edit Profile' : 'My Profile',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isEditing)
            IconButton(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, color: Colors.white),
            )
          else
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final email = AuthService.currentUser?.email ?? 'User';
    final name = _profile.name.isNotEmpty ? _profile.name : email.split('@')[0];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(email, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildEditForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Your Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
            const SizedBox(height: 20),

            // Username
            TextFormField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                hintText: 'Enter your display name',
              ),
            ),
            const SizedBox(height: 16),

            // Age
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake)),
            ),
            const SizedBox(height: 16),


            // Height
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height)),
            ),
            const SizedBox(height: 16),

            // Weight
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.fitness_center)),
            ),
            const SizedBox(height: 20),

            // Gender
            const Text('Gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: Gender.values.map((gender) {
                final isSelected = _editGender == gender;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(gender.label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _editGender = gender),
                      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      labelStyle: TextStyle(color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Activity Level
            const Text('Activity Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ActivityLevel>(
              value: _editActivityLevel,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.directions_run)),
              items: ActivityLevel.values.map((level) {
                return DropdownMenuItem(value: level, child: Text(level.label, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (val) => setState(() => _editActivityLevel = val!),
            ),
            const SizedBox(height: 20),

            // Fitness Goal
            const Text('Fitness Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            ...FitnessGoal.values.map((goal) {
              final isSelected = _editGoal == goal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _editGoal = goal),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? _getGoalColor(goal) : AppTheme.mediumGrey, width: isSelected ? 2 : 1),
                      color: isSelected ? _getGoalColor(goal).withValues(alpha: 0.05) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(_getGoalIcon(goal), color: isSelected ? _getGoalColor(goal) : AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(goal.label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? _getGoalColor(goal) : AppTheme.darkGrey)),
                              Text(goal.description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle, color: _getGoalColor(goal)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
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
                Icon(Icons.person, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.cake, 'Age', '${_profile.age} years'),
            const Divider(height: 24),
            _buildInfoRow(Icons.person_outline, 'Gender', _profile.gender.label),
            const Divider(height: 24),
            _buildInfoRow(Icons.height, 'Height', '${_profile.height.round()} cm'),
            const Divider(height: 24),
            _buildInfoRow(Icons.fitness_center, 'Weight', '${_profile.weight.round()} kg'),
            const Divider(height: 24),
            _buildInfoRow(Icons.directions_run, 'Activity Level', _profile.activityLevel.label),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.darkGrey)),
      ],
    );
  }

  Widget _buildCalorieInfoCard() {
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
                Icon(Icons.local_fire_department, color: AppTheme.accentOrange),
                SizedBox(width: 8),
                Text('Calorie Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildCalorieStat('BMR', '${_profile.bmr}', 'kcal/day', AppTheme.accentOrange)),
                Container(width: 1, height: 50, color: AppTheme.mediumGrey),
                Expanded(child: _buildCalorieStat('Maintenance', '${_profile.maintenanceCalories.round()}', 'kcal/day', AppTheme.primaryGreen)),
                Container(width: 1, height: 50, color: AppTheme.mediumGrey),
                Expanded(child: _buildCalorieStat('Target', '${_profile.targetCalories}', 'kcal/day', AppTheme.accentBlue)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieStat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(unit, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildGoalCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _getGoalColor(_profile.fitnessGoal).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(_getGoalIcon(_profile.fitnessGoal), color: _getGoalColor(_profile.fitnessGoal), size: 32),
            ),
            const SizedBox(height: 12),
            Text(_profile.fitnessGoal.label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getGoalColor(_profile.fitnessGoal))),
            const SizedBox(height: 4),
            Text(_profile.fitnessGoal.description, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.accentRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.logout, color: AppTheme.accentRed),
          ),
          title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: const Text('Sign out of your account', style: TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.accentRed),
          onTap: _confirmLogout,
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text) ?? _profile.age;
    final height = double.tryParse(_heightController.text) ?? _profile.height;
    final weight = double.tryParse(_weightController.text) ?? _profile.weight;

    if (name.isEmpty || name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username must be at least 2 characters'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (age < 1 || age > 120 || height < 50 || height > 300 || weight < 20 || weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid values'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Recalculate BMR
    final result = BMRCalculator.calculate(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: _editGender,
      activityLevel: _editActivityLevel,
      goal: _editGoal,
    );

    final updatedProfile = FirestoreUserProfile(
      name: _nameController.text.trim(),
      age: age,
      gender: _editGender,
      height: height,
      weight: weight,
      activityLevel: _editActivityLevel,
      fitnessGoal: _editGoal,
      targetCalories: result.targetCalories.round(),
      bmr: result.bmr.round(),
      maintenanceCalories: result.maintenanceCalories,
    );

    final success = await FirestoreService.saveUserProfile(updatedProfile);

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) {
          _profile = updatedProfile;
          _isEditing = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated successfully!' : 'Failed to update profile'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppTheme.primaryGreen : AppTheme.accentRed,
        ),
      );

      if (success) {
        widget.onProfileUpdated?.call();
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [Icon(Icons.logout, color: AppTheme.accentRed), SizedBox(width: 8), Text('Logout')],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              FirestoreService.clearCache();
              DailyLogService.clearCache();
              await AuthService.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss: return Icons.trending_down;
      case FitnessGoal.maintenance: return Icons.balance;
      case FitnessGoal.weightGain: return Icons.trending_up;
    }
  }

  Color _getGoalColor(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss: return AppTheme.accentOrange;
      case FitnessGoal.maintenance: return AppTheme.primaryGreen;
      case FitnessGoal.weightGain: return AppTheme.accentBlue;
    }
  }
}
