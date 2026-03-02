import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/daily_log_service.dart';
import '../services/health_alert_service.dart';
import '../services/notification_service.dart';
import '../utils/bmr_calculator.dart';
import '../widgets/bottom_nav_bar.dart';
import 'food_logging_screen.dart';
import 'weekly_analytics_screen.dart';

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
  NotificationSettings _notificationSettings = NotificationService.settings;

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
    _nameController = TextEditingController(
        text: _profile.name.isNotEmpty ? _profile.name : defaultName);
    _ageController = TextEditingController(text: _profile.age.toString());
    _heightController =
        TextEditingController(text: _profile.height.round().toString());
    _weightController =
        TextEditingController(text: _profile.weight.round().toString());
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

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _isEditing
                        ? _buildEditForm()
                        : _buildPersonalInfoCard(),
                    const SizedBox(height: 12),
                    if (!_isEditing) _buildCalorieInfoCard(),
                    if (!_isEditing) const SizedBox(height: 12),
                    if (!_isEditing) _buildGoalCard(),
                    if (!_isEditing) const SizedBox(height: 12),
                    if (!_isEditing) _buildHealthConditionsCard(),
                    if (!_isEditing) const SizedBox(height: 12),
                    if (!_isEditing) _buildNotificationSettingsCard(),
                    if (!_isEditing) const SizedBox(height: 20),
                    if (!_isEditing) _buildActionsCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: _onNavTap,
        onAddPressed: _navigateToFoodLogging,
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isEditing) {
                setState(() => _isEditing = false);
                _initEditControllers();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.softGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isEditing
                    ? Icons.close_rounded
                    : Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _isEditing ? 'Edit Profile' : 'My Profile',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isEditing)
            GestureDetector(
              onTap: _isSaving ? null : _saveProfile,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20),
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: AppTheme.primaryGreen, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  // ── Profile Avatar Header ──────────────────────────────────────────────
  Widget _buildProfileHeader() {
    final email = AuthService.currentUser?.email ?? 'User';
    final name =
        _profile.name.isNotEmpty ? _profile.name : email.split('@')[0];

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryGreen, width: 3),
          ),
          child: CircleAvatar(
            radius: 42,
            backgroundColor: AppTheme.primaryGreenSurface,
            child: Text(
              name[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          email,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  // ── Personal Info (View Mode) ──────────────────────────────────────────
  Widget _buildPersonalInfoCard() {
    return _buildSection(
      icon: Icons.person_rounded,
      title: 'Personal Information',
      children: [
        _buildInfoRow(Icons.cake_rounded, 'Age', '${_profile.age} years'),
        _buildInfoRow(Icons.person_outline_rounded, 'Gender', _profile.gender.label),
        _buildInfoRow(Icons.height_rounded, 'Height', '${_profile.height.round()} cm'),
        _buildInfoRow(Icons.fitness_center_rounded, 'Weight', '${_profile.weight.round()} kg'),
        _buildInfoRow(Icons.directions_run_rounded, 'Activity', _profile.activityLevel.label),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreenSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit Form ──────────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return _buildSection(
      icon: Icons.edit_rounded,
      title: 'Edit Your Details',
      children: [
        _buildLabeledField('Username', _nameController,
            icon: Icons.person_rounded),
        _buildLabeledField('Age', _ageController,
            icon: Icons.cake_rounded, isNumeric: true),
        _buildLabeledField('Height (cm)', _heightController,
            icon: Icons.height_rounded, isNumeric: true),
        _buildLabeledField('Weight (kg)', _weightController,
            icon: Icons.fitness_center_rounded, isNumeric: true),
        const SizedBox(height: 12),
        Text('Gender',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: Gender.values.map((gender) {
            final isSelected = _editGender == gender;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _editGender = gender),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      gender.label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Activity Level',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<ActivityLevel>(
          value: _editActivityLevel,
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_run_rounded,
                  color: AppTheme.primaryGreen, size: 18),
            ),
          ),
          items: ActivityLevel.values.map((level) {
            return DropdownMenuItem(
                value: level,
                child: Text(level.label,
                    style: GoogleFonts.poppins(fontSize: 13)));
          }).toList(),
          onChanged: (val) =>
              setState(() => _editActivityLevel = val!),
        ),
        const SizedBox(height: 16),
        Text('Fitness Goal',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        ...FitnessGoal.values.map((goal) {
          final isSelected = _editGoal == goal;
          return GestureDetector(
            onTap: () => setState(() => _editGoal = goal),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? _getGoalColor(goal)
                      : AppTheme.softGrey,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? _getGoalColor(goal).withValues(alpha: 0.06)
                    : AppTheme.white,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getGoalColor(goal).withValues(alpha: 0.15)
                          : AppTheme.softGrey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getGoalIcon(goal),
                        color: isSelected
                            ? _getGoalColor(goal)
                            : AppTheme.textSecondary,
                        size: 20),
                  ),
                  const SizedBox(width: 12),
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
    );
  }

  Widget _buildLabeledField(String label, TextEditingController controller,
      {IconData? icon, bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            style: GoogleFonts.poppins(fontSize: 14),
            keyboardType:
                isNumeric ? TextInputType.number : TextInputType.name,
            inputFormatters:
                isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
            textCapitalization: isNumeric
                ? TextCapitalization.none
                : TextCapitalization.words,
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreenSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon,
                          color: AppTheme.primaryGreen, size: 18),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Calorie Info Card ──────────────────────────────────────────────────
  Widget _buildCalorieInfoCard() {
    return _buildSection(
      icon: Icons.local_fire_department_rounded,
      title: 'Calorie Information',
      iconColor: AppTheme.accentOrange,
      children: [
        Row(
          children: [
            Expanded(
                child: _buildCalorieStat(
                    'BMR', '${_profile.bmr}', AppTheme.accentOrange)),
            Container(width: 1, height: 40, color: AppTheme.softGrey),
            Expanded(
                child: _buildCalorieStat(
                    'Maintenance',
                    '${_profile.maintenanceCalories.round()}',
                    AppTheme.primaryGreen)),
            Container(width: 1, height: 40, color: AppTheme.softGrey),
            Expanded(
                child: _buildCalorieStat(
                    'Target',
                    '${_profile.targetCalories}',
                    AppTheme.accentBlue)),
          ],
        ),
      ],
    );
  }

  Widget _buildCalorieStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text('kcal/day',
            style: GoogleFonts.poppins(
                fontSize: 9, color: color.withValues(alpha: 0.7))),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }

  // ── Goal Card ──────────────────────────────────────────────────────────
  Widget _buildGoalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _getGoalColor(_profile.fitnessGoal)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getGoalIcon(_profile.fitnessGoal),
                color: _getGoalColor(_profile.fitnessGoal), size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            _profile.fitnessGoal.label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _getGoalColor(_profile.fitnessGoal),
            ),
          ),
          Text(
            _profile.fitnessGoal.description,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  // ── Health Conditions Card ─────────────────────────────────────────────
  Widget _buildHealthConditionsCard() {
    final conditions = _profile.healthConditions;
    final hasConditions = conditions.isNotEmpty &&
        !(conditions.length == 1 &&
            conditions.contains(HealthCondition.none));

    return _buildSection(
      icon: Icons.health_and_safety_rounded,
      title: 'Health Profile',
      iconColor: AppTheme.healthGreen,
      trailing: GestureDetector(
        onTap: _showEditHealthConditionsDialog,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreenSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Edit',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen)),
        ),
      ),
      children: [
        if (hasConditions)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: conditions
                .where((c) => c != HealthCondition.none)
                .map((c) => _buildConditionChip(c))
                .toList(),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.softGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.primaryGreen, size: 18),
                const SizedBox(width: 8),
                Text('No specific health conditions',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        const SizedBox(height: 10),
        _buildDisclaimerRow(HealthAlertService.shortDisclaimer),
      ],
    );
  }

  Widget _buildConditionChip(HealthCondition condition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.healthGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.healthGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(condition.icon,
              size: 14, color: AppTheme.healthGreen),
          const SizedBox(width: 6),
          Text(
            condition.label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Notification Settings Card ─────────────────────────────────────────
  Widget _buildNotificationSettingsCard() {
    return _buildSection(
      icon: Icons.notifications_active_rounded,
      title: 'Notifications',
      iconColor: AppTheme.accentBlue,
      children: [
        _buildNotificationToggle(
          icon: Icons.wb_sunny_rounded,
          title: 'Meal Reminders',
          subtitle: 'Daily reminders for each meal',
          value: _notificationSettings.dailyReminders,
          onChanged: (v) =>
              _updateNotificationSetting(dailyReminders: v),
        ),
        if (_notificationSettings.dailyReminders) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Tap to change reminder times',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppTheme.textTertiary)),
          ),
          _buildTimePicker(
              icon: Icons.free_breakfast_rounded,
              label: 'Breakfast',
              hour: _notificationSettings.breakfastHour,
              minute: _notificationSettings.breakfastMinute,
              onTimePicked: (t) => _updateNotificationSetting(
                  breakfastHour: t.hour,
                  breakfastMinute: t.minute)),
          const SizedBox(height: 6),
          _buildTimePicker(
              icon: Icons.apple_rounded,
              label: 'Morning Snack',
              hour: _notificationSettings.morningSnackHour,
              minute: _notificationSettings.morningSnackMinute,
              onTimePicked: (t) => _updateNotificationSetting(
                  morningSnackHour: t.hour,
                  morningSnackMinute: t.minute)),
          const SizedBox(height: 6),
          _buildTimePicker(
              icon: Icons.lunch_dining_rounded,
              label: 'Lunch',
              hour: _notificationSettings.lunchHour,
              minute: _notificationSettings.lunchMinute,
              onTimePicked: (t) => _updateNotificationSetting(
                  lunchHour: t.hour,
                  lunchMinute: t.minute)),
          const SizedBox(height: 6),
          _buildTimePicker(
              icon: Icons.icecream_rounded,
              label: 'Evening Snack',
              hour: _notificationSettings.eveningSnackHour,
              minute: _notificationSettings.eveningSnackMinute,
              onTimePicked: (t) => _updateNotificationSetting(
                  eveningSnackHour: t.hour,
                  eveningSnackMinute: t.minute)),
          const SizedBox(height: 6),
          _buildTimePicker(
              icon: Icons.dinner_dining_rounded,
              label: 'Dinner',
              hour: _notificationSettings.dinnerHour,
              minute: _notificationSettings.dinnerMinute,
              onTimePicked: (t) => _updateNotificationSetting(
                  dinnerHour: t.hour,
                  dinnerMinute: t.minute)),
        ],
        Divider(height: 20, color: AppTheme.softGrey),
        _buildNotificationToggle(
          icon: Icons.trending_up_rounded,
          title: 'Calorie Limit Alerts',
          subtitle: 'Alert when approaching daily target',
          value: _notificationSettings.calorieLimitAlerts,
          onChanged: (v) =>
              _updateNotificationSetting(calorieLimitAlerts: v),
        ),
        Divider(height: 20, color: AppTheme.softGrey),
        _buildNotificationToggle(
          icon: Icons.health_and_safety_rounded,
          title: 'Health Awareness',
          subtitle: 'Alerts based on health conditions',
          value: _notificationSettings.healthAlerts,
          onChanged: (v) =>
              _updateNotificationSetting(healthAlerts: v),
        ),
        const SizedBox(height: 8),
        _buildDisclaimerRow(
            'Notifications are for reminders and awareness only, not medical advice.'),
      ],
    );
  }

  Widget _buildTimePicker({
    required IconData icon,
    required String label,
    required int hour,
    required int minute,
    required ValueChanged<TimeOfDay> onTimePicked,
  }) {
    final time = TimeOfDay(hour: hour, minute: minute);
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx)
                  .colorScheme
                  .copyWith(primary: AppTheme.primaryGreen),
            ),
            child: child!,
          ),
        );
        if (picked != null) onTimePicked(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.softGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time.format(context),
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppTheme.primaryGreen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 20,
            color: value ? AppTheme.accentBlue : AppTheme.textTertiary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          value ? AppTheme.textPrimary : AppTheme.textSecondary)),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.textTertiary)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryGreen,
        ),
      ],
    );
  }

  // ── Actions Card ───────────────────────────────────────────────────────
  Widget _buildActionsCard() {
    return GestureDetector(
      onTap: _confirmLogout,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
              color: AppTheme.accentRed.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppTheme.accentRed, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Logout',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentRed)),
                  Text('Sign out of your account',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textTertiary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.accentRed),
          ],
        ),
      ),
    );
  }

  // ── Reusable Section Container ─────────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Color? iconColor,
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
                  color: (iconColor ?? AppTheme.primaryGreen)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: iconColor ?? AppTheme.primaryGreen, size: 20),
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

  Widget _buildDisclaimerRow(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.softGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: AppTheme.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppTheme.textTertiary)),
          ),
        ],
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WeeklyAnalyticsScreen(
              targetCalories: _profile.targetCalories,
              bmr: _profile.bmr,
              goal: _profile.fitnessGoal,
              maintenanceCalories: _profile.maintenanceCalories,
            ),
          ),
        );
        break;
      case 2:
        _showComingSoonDialog('Meal Plan');
        break;
      case 3:
        break;
    }
  }

  void _navigateToFoodLogging() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodLoggingScreen(
          targetCalories: _profile.targetCalories,
          bmr: _profile.bmr,
          goal: _profile.fitnessGoal,
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
            Icon(Icons.construction_rounded, color: AppTheme.accentOrange),
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

  // ── Save Profile ───────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text) ?? _profile.age;
    final height =
        double.tryParse(_heightController.text) ?? _profile.height;
    final weight =
        double.tryParse(_weightController.text) ?? _profile.weight;

    if (name.isEmpty || name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Username must be at least 2 characters',
                style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      );
      return;
    }

    if (age < 1 ||
        age > 120 ||
        height < 50 ||
        height > 300 ||
        weight < 20 ||
        weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter valid values',
                style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = BMRCalculator.calculate(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: _editGender,
      activityLevel: _editActivityLevel,
      goal: _editGoal,
    );

    final updatedProfile = FirestoreUserProfile(
      name: name,
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

    final success =
        await FirestoreService.saveUserProfile(updatedProfile);

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
          content: Text(
              success
                  ? 'Profile updated successfully!'
                  : 'Failed to update profile',
              style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              success ? AppTheme.primaryGreen : AppTheme.accentRed,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );

      if (success) widget.onProfileUpdated?.call();
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppTheme.accentRed),
            const SizedBox(width: 8),
            Text('Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style:
                    GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              FirestoreService.clearCache();
              DailyLogService.clearCache();
              await AuthService.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
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

  void _showEditHealthConditionsDialog() {
    final selectedConditions =
        Set<HealthCondition>.from(_profile.healthConditions);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void toggleCondition(HealthCondition condition) {
            setDialogState(() {
              if (condition == HealthCondition.none) {
                selectedConditions.clear();
                selectedConditions.add(HealthCondition.none);
              } else {
                selectedConditions.remove(HealthCondition.none);
                if (selectedConditions.contains(condition)) {
                  selectedConditions.remove(condition);
                } else {
                  selectedConditions.add(condition);
                }
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.health_and_safety_rounded,
                    color: AppTheme.healthGreen),
                const SizedBox(width: 8),
                Text('Health Conditions',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select any that apply:',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 13)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HealthCondition.values
                          .where((c) => c != HealthCondition.none)
                          .map((condition) {
                        final isSelected =
                            selectedConditions.contains(condition);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(condition.label),
                          labelStyle: GoogleFonts.poppins(
                            color: isSelected
                                ? AppTheme.healthGreen
                                : AppTheme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          selectedColor:
                              AppTheme.healthGreen.withValues(alpha: 0.15),
                          checkmarkColor: AppTheme.healthGreen,
                          onSelected: (_) =>
                              toggleCondition(condition),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),
                    FilterChip(
                      selected: selectedConditions
                          .contains(HealthCondition.none),
                      label: Text('None of the above'),
                      labelStyle: GoogleFonts.poppins(
                        color: selectedConditions
                                .contains(HealthCondition.none)
                            ? AppTheme.primaryGreen
                            : AppTheme.textPrimary,
                        fontWeight: selectedConditions
                                .contains(HealthCondition.none)
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      avatar: Icon(Icons.check_circle_outline,
                          size: 16,
                          color: selectedConditions
                                  .contains(HealthCondition.none)
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary),
                      selectedColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.15),
                      checkmarkColor: AppTheme.primaryGreen,
                      onSelected: (_) =>
                          toggleCondition(HealthCondition.none),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _updateHealthConditions(
                      selectedConditions.toList());
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateHealthConditions(
      List<HealthCondition> conditions) async {
    if (conditions.isEmpty) {
      conditions = [HealthCondition.none];
    }

    final success = await FirestoreService.updateUserProfile({
      'healthConditions':
          conditions.map((c) => c.index).toList(),
    });

    if (mounted) {
      if (success) {
        final updatedProfile =
            await FirestoreService.getUserProfile();
        if (updatedProfile != null && mounted) {
          setState(() => _profile = updatedProfile);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health profile updated',
                style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update health profile',
                style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateNotificationSetting({
    bool? dailyReminders,
    bool? calorieLimitAlerts,
    bool? healthAlerts,
    int? breakfastHour,
    int? breakfastMinute,
    int? morningSnackHour,
    int? morningSnackMinute,
    int? lunchHour,
    int? lunchMinute,
    int? eveningSnackHour,
    int? eveningSnackMinute,
    int? dinnerHour,
    int? dinnerMinute,
  }) async {
    final newSettings = _notificationSettings.copyWith(
      dailyReminders: dailyReminders,
      calorieLimitAlerts: calorieLimitAlerts,
      healthAlerts: healthAlerts,
      breakfastHour: breakfastHour,
      breakfastMinute: breakfastMinute,
      morningSnackHour: morningSnackHour,
      morningSnackMinute: morningSnackMinute,
      lunchHour: lunchHour,
      lunchMinute: lunchMinute,
      eveningSnackHour: eveningSnackHour,
      eveningSnackMinute: eveningSnackMinute,
      dinnerHour: dinnerHour,
      dinnerMinute: dinnerMinute,
    );

    setState(() => _notificationSettings = newSettings);
    await NotificationService.updateSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification settings updated',
              style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
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
}
