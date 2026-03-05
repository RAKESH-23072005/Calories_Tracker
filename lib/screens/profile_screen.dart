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

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _initEditControllers();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
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
    _animController.dispose();
    super.dispose();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  BUILD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            if (_isEditing) ...[
                              _buildEditForm(),
                            ] else ...[
                              _buildCalorieStatsCard(),
                              const SizedBox(height: 14),
                              _buildPersonalInfoCard(),
                              const SizedBox(height: 14),
                              _buildGoalCard(),
                              const SizedBox(height: 14),
                              _buildHealthConditionsCard(),
                              const SizedBox(height: 14),
                              _buildNotificationSettingsCard(),
                              const SizedBox(height: 20),
                              _buildLogoutButton(),
                            ],
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: _onNavTap,
        onAddPressed: _navigateToFoodLogging,
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  APP BAR
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _buildAppBarButton(
            onTap: () {
              if (_isEditing) {
                setState(() => _isEditing = false);
                _initEditControllers();
              } else {
                Navigator.pop(context);
              }
            },
            icon: _isEditing
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
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
          _isEditing
              ? _buildAppBarButton(
                  onTap: _isSaving ? null : _saveProfile,
                  icon: Icons.check_rounded,
                  isAccent: true,
                  isLoading: _isSaving,
                )
              : _buildAppBarButton(
                  onTap: () => setState(() => _isEditing = true),
                  icon: Icons.edit_rounded,
                  isAccent: true,
                ),
        ],
      ),
    );
  }

  Widget _buildAppBarButton({
    VoidCallback? onTap,
    required IconData icon,
    bool isAccent = false,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isAccent ? AppTheme.primaryGreenSurface : AppTheme.softGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primaryGreen))
            : Icon(icon,
                size: 18,
                color: isAccent
                    ? AppTheme.primaryGreen
                    : AppTheme.textPrimary),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  PROFILE HEADER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildProfileHeader() {
    final email = AuthService.currentUser?.email ?? 'User';
    final name =
        _profile.name.isNotEmpty ? _profile.name : email.split('@')[0];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B7A4A), Color(0xFF2DB573)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6), width: 2.5),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          // Goal badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getGoalIcon(_profile.fitnessGoal),
                    size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  _profile.fitnessGoal.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  CALORIE STATS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildCalorieStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          _buildStatColumn('BMR', '${_profile.bmr}', AppTheme.accentOrange,
              Icons.local_fire_department_rounded),
          _statDivider(),
          _buildStatColumn(
              'Maintenance',
              '${_profile.maintenanceCalories.round()}',
              AppTheme.primaryGreen,
              Icons.speed_rounded),
          _statDivider(),
          _buildStatColumn('Target', '${_profile.targetCalories}',
              AppTheme.accentBlue, Icons.flag_rounded),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w700, color: color)),
          Text('kcal',
              style: GoogleFonts.poppins(
                  fontSize: 9, color: color.withValues(alpha: 0.7))),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppTheme.textTertiary)),
        ],
      ),
    );
  }

  Widget _statDivider() =>
      Container(width: 1, height: 48, color: AppTheme.softGrey);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  PERSONAL INFO (View)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildPersonalInfoCard() {
    return _buildCard(
      icon: Icons.person_rounded,
      title: 'Personal Info',
      children: [
        _infoRow(Icons.cake_rounded, 'Age', '${_profile.age} years'),
        _infoRow(Icons.person_outline_rounded, 'Gender',
            _profile.gender.label),
        _infoRow(Icons.height_rounded, 'Height',
            '${_profile.height.round()} cm'),
        _infoRow(Icons.fitness_center_rounded, 'Weight',
            '${_profile.weight.round()} kg'),
        _infoRow(Icons.directions_run_rounded, 'Activity',
            _profile.activityLevel.label),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreenSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  EDIT FORM
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildEditForm() {
    return _buildCard(
      icon: Icons.edit_rounded,
      title: 'Edit Your Details',
      children: [
        _editField('Username', _nameController, Icons.person_rounded),
        _editField('Age', _ageController, Icons.cake_rounded,
            isNumeric: true),
        _editField('Height (cm)', _heightController, Icons.height_rounded,
            isNumeric: true),
        _editField('Weight (kg)', _weightController,
            Icons.fitness_center_rounded,
            isNumeric: true),
        const SizedBox(height: 10),
        _label('Gender'),
        const SizedBox(height: 6),
        Row(
          children: Gender.values.map((g) {
            final sel = _editGender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _editGender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        sel ? AppTheme.primaryGreen : AppTheme.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(g.label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? Colors.white
                              : AppTheme.textSecondary,
                        )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _label('Activity Level'),
        const SizedBox(height: 6),
        DropdownButtonFormField<ActivityLevel>(
          value: _editActivityLevel,
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: ActivityLevel.values
              .map((l) => DropdownMenuItem(
                  value: l,
                  child: Text(l.label,
                      style: GoogleFonts.poppins(fontSize: 13))))
              .toList(),
          onChanged: (v) =>
              setState(() => _editActivityLevel = v!),
        ),
        const SizedBox(height: 14),
        _label('Fitness Goal'),
        const SizedBox(height: 6),
        ...FitnessGoal.values.map((goal) {
          final sel = _editGoal == goal;
          final color = _getGoalColor(goal);
          return GestureDetector(
            onTap: () => setState(() => _editGoal = goal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: sel
                    ? color.withValues(alpha: 0.08)
                    : AppTheme.softGrey,
                border: Border.all(
                  color: sel ? color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(_getGoalIcon(goal),
                      color: sel ? color : AppTheme.textSecondary,
                      size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.label,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: sel ? color : AppTheme.textPrimary)),
                        Text(goal.description,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.textTertiary)),
                      ],
                    ),
                  ),
                  if (sel)
                    Icon(Icons.check_circle_rounded,
                        color: color, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _editField(
      String label, TextEditingController ctrl, IconData icon,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 4),
          TextFormField(
            controller: ctrl,
            style: GoogleFonts.poppins(fontSize: 14),
            keyboardType:
                isNumeric ? TextInputType.number : TextInputType.name,
            inputFormatters:
                isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
            textCapitalization: isNumeric
                ? TextCapitalization.none
                : TextCapitalization.words,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon:
                  Icon(icon, color: AppTheme.primaryGreen, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.textSecondary));

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  GOAL CARD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildGoalCard() {
    final color = _getGoalColor(_profile.fitnessGoal);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_getGoalIcon(_profile.fitnessGoal),
                color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Goal',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textTertiary)),
                Text(_profile.fitnessGoal.label,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(_profile.fitnessGoal.description,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textTertiary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  HEALTH CONDITIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildHealthConditionsCard() {
    final conds = _profile.healthConditions;
    final hasConditions = conds.isNotEmpty &&
        !(conds.length == 1 && conds.contains(HealthCondition.none));

    return _buildCard(
      icon: Icons.health_and_safety_rounded,
      title: 'Health Profile',
      iconColor: AppTheme.healthGreen,
      trailing: GestureDetector(
        onTap: _showEditHealthDialog,
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
            children: conds
                .where((c) => c != HealthCondition.none)
                .map((c) => _healthChip(c))
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
        Container(
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
                child: Text(HealthAlertService.shortDisclaimer,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppTheme.textTertiary)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _healthChip(HealthCondition c) {
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
          Icon(c.icon, size: 14, color: AppTheme.healthGreen),
          const SizedBox(width: 6),
          Text(c.label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildNotificationSettingsCard() {
    return _buildCard(
      icon: Icons.notifications_active_rounded,
      title: 'Notifications',
      iconColor: AppTheme.accentBlue,
      children: [
        _toggleRow(
          Icons.wb_sunny_rounded,
          'Meal Reminders',
          'Daily reminders for each meal',
          _notificationSettings.dailyReminders,
          (v) => _updateNotification(dailyReminders: v),
        ),
        if (_notificationSettings.dailyReminders) ...[
          const SizedBox(height: 8),
          _timeTile(Icons.free_breakfast_rounded, 'Breakfast',
              _notificationSettings.breakfastHour,
              _notificationSettings.breakfastMinute,
              (t) => _updateNotification(
                  breakfastHour: t.hour, breakfastMinute: t.minute)),
          _timeTile(Icons.apple_rounded, 'Morning Snack',
              _notificationSettings.morningSnackHour,
              _notificationSettings.morningSnackMinute,
              (t) => _updateNotification(
                  morningSnackHour: t.hour,
                  morningSnackMinute: t.minute)),
          _timeTile(Icons.lunch_dining_rounded, 'Lunch',
              _notificationSettings.lunchHour,
              _notificationSettings.lunchMinute,
              (t) => _updateNotification(
                  lunchHour: t.hour, lunchMinute: t.minute)),
          _timeTile(Icons.icecream_rounded, 'Evening Snack',
              _notificationSettings.eveningSnackHour,
              _notificationSettings.eveningSnackMinute,
              (t) => _updateNotification(
                  eveningSnackHour: t.hour,
                  eveningSnackMinute: t.minute)),
          _timeTile(Icons.dinner_dining_rounded, 'Dinner',
              _notificationSettings.dinnerHour,
              _notificationSettings.dinnerMinute,
              (t) => _updateNotification(
                  dinnerHour: t.hour, dinnerMinute: t.minute)),
        ],
        Divider(height: 20, color: AppTheme.softGrey),
        _toggleRow(
          Icons.trending_up_rounded,
          'Calorie Limit Alerts',
          'Alert when approaching daily target',
          _notificationSettings.calorieLimitAlerts,
          (v) => _updateNotification(calorieLimitAlerts: v),
        ),
        Divider(height: 20, color: AppTheme.softGrey),
        _toggleRow(
          Icons.health_and_safety_rounded,
          'Health Awareness',
          'Alerts based on health conditions',
          _notificationSettings.healthAlerts,
          (v) => _updateNotification(healthAlerts: v),
        ),
      ],
    );
  }

  Widget _toggleRow(IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color:
                  value ? AppTheme.accentBlue : AppTheme.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: value
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textTertiary)),
              ],
            ),
          ),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryGreen),
        ],
      ),
    );
  }

  Widget _timeTile(IconData icon, String label, int hour, int minute,
      ValueChanged<TimeOfDay> onPicked) {
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
        if (picked != null) onPicked(picked);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(time.format(context),
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen)),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  LOGOUT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildLogoutButton() {
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  REUSABLE CARD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildCard({
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
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  NAVIGATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        _showDialog(
          'Coming Soon',
          'Meal Plan feature is under development!',
          Icons.construction_rounded,
          AppTheme.accentOrange,
        );
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  SAVE PROFILE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text) ?? _profile.age;
    final height =
        double.tryParse(_heightController.text) ?? _profile.height;
    final weight =
        double.tryParse(_weightController.text) ?? _profile.weight;

    if (name.isEmpty || name.length < 2) {
      _snack('Username must be at least 2 characters', false);
      return;
    }
    if (age < 1 || age > 120 || height < 50 || height > 300 ||
        weight < 20 || weight > 500) {
      _snack('Please enter valid values', false);
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

    final updated = FirestoreUserProfile(
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

    final ok = await FirestoreService.saveUserProfile(updated);

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (ok) {
          _profile = updated;
          _isEditing = false;
        }
      });
      _snack(ok ? 'Profile updated!' : 'Failed to update', ok);
      if (ok) widget.onProfileUpdated?.call();
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  DIALOGS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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

  void _showEditHealthDialog() {
    final sel = Set<HealthCondition>.from(_profile.healthConditions);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void toggle(HealthCondition c) {
            setDialogState(() {
              if (c == HealthCondition.none) {
                sel.clear();
                sel.add(HealthCondition.none);
              } else {
                sel.remove(HealthCondition.none);
                sel.contains(c) ? sel.remove(c) : sel.add(c);
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
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HealthCondition.values
                          .where((c) => c != HealthCondition.none)
                          .map((c) {
                        final on = sel.contains(c);
                        return FilterChip(
                          selected: on,
                          label: Text(c.label),
                          labelStyle: GoogleFonts.poppins(
                            color: on
                                ? AppTheme.healthGreen
                                : AppTheme.textPrimary,
                            fontWeight: on
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          selectedColor: AppTheme.healthGreen
                              .withValues(alpha: 0.15),
                          checkmarkColor: AppTheme.healthGreen,
                          onSelected: (_) => toggle(c),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),
                    FilterChip(
                      selected: sel.contains(HealthCondition.none),
                      label: const Text('None of the above'),
                      labelStyle: GoogleFonts.poppins(fontSize: 12),
                      selectedColor: AppTheme.primaryGreen
                          .withValues(alpha: 0.15),
                      checkmarkColor: AppTheme.primaryGreen,
                      onSelected: (_) => toggle(HealthCondition.none),
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
                  await _updateHealth(sel.toList());
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

  void _showDialog(
      String title, String msg, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(msg,
            style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK',
                style: GoogleFonts.poppins(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  DATA OPERATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _updateHealth(List<HealthCondition> conditions) async {
    if (conditions.isEmpty) conditions = [HealthCondition.none];
    final ok = await FirestoreService.updateUserProfile({
      'healthConditions': conditions.map((c) => c.index).toList(),
    });
    if (mounted) {
      if (ok) {
        final p = await FirestoreService.getUserProfile();
        if (p != null && mounted) setState(() => _profile = p);
        _snack('Health profile updated', true);
      } else {
        _snack('Failed to update', false);
      }
    }
  }

  Future<void> _updateNotification({
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
    final s = _notificationSettings.copyWith(
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
    setState(() => _notificationSettings = s);
    await NotificationService.updateSettings(s);
    if (mounted) _snack('Settings updated', true);
  }

  void _snack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppTheme.primaryGreen : AppTheme.accentRed,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  IconData _getGoalIcon(FitnessGoal goal) => switch (goal) {
        FitnessGoal.weightLoss => Icons.trending_down_rounded,
        FitnessGoal.maintenance => Icons.balance_rounded,
        FitnessGoal.weightGain => Icons.trending_up_rounded,
      };

  Color _getGoalColor(FitnessGoal goal) => switch (goal) {
        FitnessGoal.weightLoss => AppTheme.accentOrange,
        FitnessGoal.maintenance => AppTheme.primaryGreen,
        FitnessGoal.weightGain => AppTheme.accentBlue,
      };
}
