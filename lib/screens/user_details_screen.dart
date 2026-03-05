import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/bmr_calculator.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/firestore_service.dart';
import 'results_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 8;

  // ── Controllers ──────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  // ── Data ─────────────────────────────────────────────────────────────
  FitnessGoal _selectedGoal = FitnessGoal.maintenance;
  Gender _selectedGender = Gender.male;
  DateTime _selectedDOB = DateTime(2000, 1, 1);
  int _selectedHeight = 170; // cm
  bool _heightInCm = true;
  int _selectedWeight = 65; // kg
  bool _weightInKg = true;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  final Set<HealthCondition> _selectedConditions = {};

  // ── Animation ────────────────────────────────────────────────────────
  late AnimationController _contentAnimController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  // ── State ────────────────────────────────────────────────────────────
  BMRResult? _bmrResult;
  bool _isSaving = false;

  // ── Scroll controllers for pickers ───────────────────────────────────
  late FixedExtentScrollController _heightScrollController;
  late FixedExtentScrollController _weightScrollController;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        AuthService.currentUser?.email?.split('@')[0] ?? '';

    _contentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentAnimController, curve: Curves.easeIn),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _contentAnimController, curve: Curves.easeOutCubic),
    );
    _contentAnimController.forward();

    _heightScrollController =
        FixedExtentScrollController(initialItem: _selectedHeight - 100);
    _weightScrollController =
        FixedExtentScrollController(initialItem: _selectedWeight - 20);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    _contentAnimController.dispose();
    _heightScrollController.dispose();
    _weightScrollController.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────────────
  void _nextStep() {
    if (_currentStep == 0 && _nameController.text.trim().isEmpty) {
      _nameController.text = 'User';
    }
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _calculateAndNavigate();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentStep = page);
    FocusScope.of(context).unfocus();
    _contentAnimController.reset();
    _contentAnimController.forward();
  }

  // ── Business Logic (unchanged) ───────────────────────────────────────
  int get _age {
    final now = DateTime.now();
    int age = now.year - _selectedDOB.year;
    if (now.month < _selectedDOB.month ||
        (now.month == _selectedDOB.month && now.day < _selectedDOB.day)) {
      age--;
    }
    return age < 1 ? 1 : age;
  }

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

  Future<void> _calculateAndNavigate() async {
    setState(() => _isSaving = true);

    final heightCm = _heightInCm
        ? _selectedHeight.toDouble()
        : (_selectedHeight * 2.54);
    final weightKg = _weightInKg
        ? _selectedWeight.toDouble()
        : (_selectedWeight * 0.4536);

    _bmrResult = BMRCalculator.calculate(
      weightKg: weightKg,
      heightCm: heightCm,
      age: _age,
      gender: _selectedGender,
      activityLevel: _selectedActivityLevel,
      goal: _selectedGoal,
    );

    final conditions = _selectedConditions.isEmpty
        ? [HealthCondition.none]
        : _selectedConditions.toList();

    await _saveProfileAndContinue(conditions);
  }

  Future<void> _saveProfileAndContinue(
      List<HealthCondition> conditions) async {
    if (_bmrResult == null) return;

    setState(() => _isSaving = true);

    final heightCm = _heightInCm
        ? _selectedHeight.toDouble()
        : (_selectedHeight * 2.54);
    final weightKg = _weightInKg
        ? _selectedWeight.toDouble()
        : (_selectedWeight * 0.4536);

    final name = _nameController.text.trim().isEmpty
        ? (AuthService.currentUser?.email?.split('@')[0] ?? 'User')
        : _nameController.text.trim();

    final firestoreProfile = FirestoreUserProfile(
      name: name,
      age: _age,
      gender: _selectedGender,
      height: heightCm,
      weight: weightKg,
      activityLevel: _selectedActivityLevel,
      fitnessGoal: _selectedGoal,
      targetCalories: _bmrResult!.targetCalories.round(),
      bmr: _bmrResult!.bmr.round(),
      maintenanceCalories: _bmrResult!.maintenanceCalories,
      healthConditions: conditions,
    );

    final success = await FirestoreService.saveUserProfile(firestoreProfile);

    final localProfile = UserProfile(
      name: name,
      age: _age,
      gender: _selectedGender,
      height: heightCm,
      weight: weightKg,
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          result: _bmrResult!,
          gender: _selectedGender,
          age: _age,
          height: _heightInCm
              ? _selectedHeight.toDouble()
              : (_selectedHeight * 2.54),
          weight: _weightInKg
              ? _selectedWeight.toDouble()
              : (_selectedWeight * 0.4536),
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  BUILD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: _currentStep > 0 ? _prevStep : null,
                    child: AnimatedOpacity(
                      opacity: _currentStep > 0 ? 1.0 : 0.3,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.softGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                  // Skip button
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Pages ──────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNameStep(),
                  _buildGoalStep(),
                  _buildGenderStep(),
                  _buildDOBStep(),
                  _buildHeightStep(),
                  _buildWeightStep(),
                  _buildActivityStep(),
                  _buildHealthStep(),
                ],
              ),
            ),

            // ── Bottom: Next / Calculate ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 36),
              child: _buildBottomSection(isLastStep),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom section with next button ──────────────────────────────────
  Widget _buildBottomSection(bool isLastStep) {
    return Column(
      children: [
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalSteps, (i) {
            final isActive = i == _currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryGreen
                    : AppTheme.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        // Button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: isLastStep ? _buildCalculateBtn() : _buildNextArrow(),
        ),
      ],
    );
  }

  Widget _buildNextArrow() {
    return GestureDetector(
      key: const ValueKey('next_arrow'),
      onTap: _nextStep,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          border: Border.all(color: AppTheme.primaryGreen, width: 2.5),
        ),
        child: const Center(
          child: Icon(Icons.arrow_forward_ios_rounded,
              color: AppTheme.primaryGreen, size: 22),
        ),
      ),
    );
  }

  Widget _buildCalculateBtn() {
    return GestureDetector(
      key: const ValueKey('calc_btn'),
      onTap: _isSaving ? null : _nextStep,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(
                'Calculate',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ── Common header builder ────────────────────────────────────────────
  Widget _buildStepHeader({
    required String before,
    required String highlight,
    String after = '',
    required String subtitle,
  }) {
    return FadeTransition(
      opacity: _contentFade,
      child: SlideTransition(
        position: _contentSlide,
        child: Column(
          children: [
            // Step counter
            Text(
              '${_currentStep + 1} / $_totalSteps',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            // Title with highlight
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
                children: [
                  TextSpan(text: before),
                  TextSpan(
                    text: highlight,
                    style: const TextStyle(color: AppTheme.primaryGreen),
                  ),
                  if (after.isNotEmpty) TextSpan(text: after),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  STEP 1 — Name
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildStepHeader(
            before: 'What is your ',
            highlight: 'name',
            after: '?',
            subtitle: 'We will use this data to give you\na better diet type for you',
          ),
          const Spacer(flex: 2),
          FadeTransition(
            opacity: _contentFade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.softGrey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Your name',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textTertiary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  STEP 2 — Goal
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildGoalStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildStepHeader(
            before: 'What is your ',
            highlight: 'goal',
            after: '?',
            subtitle: 'We will use this data to give you\na better diet type for you',
          ),
          const Spacer(flex: 2),
          FadeTransition(
            opacity: _contentFade,
            child: Column(
              children: FitnessGoal.values.map((goal) {
                final isSelected = _selectedGoal == goal;
                return _buildGoalOption(
                  goal: goal,
                  isSelected: isSelected,
                  emoji: _getGoalEmoji(goal),
                  onTap: () => setState(() => _selectedGoal = goal),
                );
              }).toList(),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildGoalOption({
    required FitnessGoal goal,
    required bool isSelected,
    required String emoji,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreenSurface
              : AppTheme.softGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(goal.label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : AppTheme.textPrimary,
                )),
            const Spacer(),
            Text(emoji, style: const TextStyle(fontSize: 28)),
          ],
        ),
      ),
    );
  }

  String _getGoalEmoji(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return '🔥';
      case FitnessGoal.maintenance:
        return '🧘';
      case FitnessGoal.weightGain:
        return '💪';
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  STEP 3 — Gender
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildGenderStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildStepHeader(
            before: 'What is your ',
            highlight: 'gender',
            after: '?',
            subtitle: 'We will use this data to give you\na better diet type for you',
          ),
          const Spacer(flex: 2),
          FadeTransition(
            opacity: _contentFade,
            child: Row(
              children: Gender.values.map((gender) {
                final isSelected = _selectedGender == gender;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = gender),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreenSurface
                            : AppTheme.softGrey,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Avatar illustration
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                      .withValues(alpha: 0.15)
                                  : AppTheme.mediumGrey,
                            ),
                            child: Icon(
                              gender == Gender.male
                                  ? Icons.face_rounded
                                  : Icons.face_3_rounded,
                              size: 40,
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            gender.label,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.primaryGreen
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
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  STEP 4 — Date of Birth
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildDOBStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildStepHeader(
            before: 'Your ',
            highlight: 'date of birth',
            subtitle: 'We will use this data to give you\na better diet type for you',
          ),
          const Spacer(flex: 2),
          FadeTransition(
            opacity: _contentFade,
            child: Column(
              children: [
                // Age display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreenSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_age',
                    style: GoogleFonts.poppins(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'years old',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 24),
                // Date picker button
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDOB,
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppTheme.primaryGreen,
                              onPrimary: Colors.white,
                              surface: AppTheme.white,
                              onSurface: AppTheme.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _selectedDOB = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.softGrey,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppTheme.primaryGreen),
                        const SizedBox(width: 10),
                        Text(
                          '${_monthName(_selectedDOB.month)} / ${_selectedDOB.day} / ${_selectedDOB.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  STEP 5 — Height
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildHeightStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildStepHeader(
            before: 'How ',
            highlight: 'tall',
            after: ' are you?',
            subtitle: 'We will use this data to give you\na better diet type for you',
          ),
          const SizedBox(height: 16),
          // Unit toggle
          FadeTransition(
            opacity: _contentFade,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildUnitToggle('ft', !_heightInCm, () {
                  setState(() => _heightInCm = false);
                }),
                const SizedBox(width: 8),
                _buildUnitToggle('cm', _heightInCm, () {
                  setState(() => _heightInCm = true);
                }),
              ],
            ),
          ),
          const Spacer(flex: 1),
          // Scroll picker
          FadeTransition(
            opacity: _contentFade,
            child: SizedBox(
              height: 200,
              child: _buildScrollPicker(
                controller: _heightScrollController,
                minValue: _heightInCm ? 100 : 36,
                maxValue: _heightInCm ? 250 : 96,
                selectedValue: _selectedHeight,
                unit: _heightInCm ? 'cm' : 'in',
                onChanged: (val) => setState(() => _selectedHeight = val),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  STEP 6 — Weight
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildWeightStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildStepHeader(
            before: 'Your current ',
            highlight: 'weight',
            subtitle: 'We will use this data to give you\na better diet type for you',
          ),
          const SizedBox(height: 16),
          // Unit toggle
          FadeTransition(
            opacity: _contentFade,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildUnitToggle('lbs', !_weightInKg, () {
                  setState(() => _weightInKg = false);
                }),
                const SizedBox(width: 8),
                _buildUnitToggle('kg', _weightInKg, () {
                  setState(() => _weightInKg = true);
                }),
              ],
            ),
          ),
          const Spacer(flex: 1),
          // Scroll picker
          FadeTransition(
            opacity: _contentFade,
            child: SizedBox(
              height: 200,
              child: _buildScrollPicker(
                controller: _weightScrollController,
                minValue: _weightInKg ? 20 : 44,
                maxValue: _weightInKg ? 250 : 550,
                selectedValue: _selectedWeight,
                unit: _weightInKg ? 'kg' : 'lbs',
                onChanged: (val) => setState(() => _selectedWeight = val),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  STEP 7 — Activity Level
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildActivityStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 1),
          _buildStepHeader(
            before: 'Your ',
            highlight: 'activity level',
            subtitle: 'We will use this data to give you\na better diet type for you',
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 5,
            child: FadeTransition(
              opacity: _contentFade,
              child: ListView(
                padding: EdgeInsets.zero,
                children: ActivityLevel.values.map((level) {
                  final isSelected = _selectedActivityLevel == level;
                  return _buildActivityOption(
                    level: level,
                    isSelected: isSelected,
                    emoji: _getActivityEmoji(level),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityOption({
    required ActivityLevel level,
    required bool isSelected,
    required String emoji,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedActivityLevel = level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreenSurface : AppTheme.softGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.textPrimary,
                      )),
                  Text(level.description,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      )),
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

  String _getActivityEmoji(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return '🛋️';
      case ActivityLevel.lightlyActive:
        return '🚶';
      case ActivityLevel.moderatelyActive:
        return '🏃';
      case ActivityLevel.veryActive:
        return '🏋️';
      case ActivityLevel.extraActive:
        return '⚡';
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  SHARED WIDGETS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildUnitToggle(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen : AppTheme.softGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollPicker({
    required FixedExtentScrollController controller,
    required int minValue,
    required int maxValue,
    required int selectedValue,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Selection highlight bar
        Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreenSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
        ),
        // Scroll wheel
        SizedBox(
          height: 200,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 56,
            perspective: 0.003,
            diameterRatio: 1.8,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              onChanged(minValue + index);
              HapticFeedback.selectionClick();
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: maxValue - minValue + 1,
              builder: (context, index) {
                final value = minValue + index;
                final isSelected = value == selectedValue;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.poppins(
                      fontSize: isSelected ? 32 : 18,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.textTertiary,
                    ),
                    child: Text('$value'),
                  ),
                );
              },
            ),
          ),
        ),
        // Unit label on right
        Positioned(
          right: 50,
          child: Text(
            unit,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  STEP 8 — Health Conditions
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildHealthStep() {
    final conditions =
        HealthCondition.values.where((c) => c != HealthCondition.none).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 1),
          _buildStepHeader(
            before: 'Any ',
            highlight: 'health issues',
            after: '?',
            subtitle: 'Select any that apply so we can\npersonalize your experience',
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 5,
            child: FadeTransition(
              opacity: _contentFade,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Condition grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: conditions
                        .map((c) => _buildConditionChip(c))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  // None option
                  _buildNoneOption(),
                  const SizedBox(height: 12),
                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.softGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: AppTheme.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This info helps us provide mindful food suggestions. Not medical advice.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionChip(HealthCondition condition) {
    final isSelected = _selectedConditions.contains(condition);
    return GestureDetector(
      onTap: () => _toggleCondition(condition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreenSurface
              : AppTheme.softGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              condition.icon,
              size: 18,
              color: isSelected
                  ? AppTheme.primaryGreen
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              condition.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryGreen
                    : AppTheme.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primaryGreen, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoneOption() {
    final isSelected = _selectedConditions.contains(HealthCondition.none);
    return GestureDetector(
      onTap: () => _toggleCondition(HealthCondition.none),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : AppTheme.softGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 22,
              color: isSelected
                  ? AppTheme.primaryGreen
                  : AppTheme.textSecondary,
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
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    "I don't have any specific health conditions",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
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
}
