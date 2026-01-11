import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'screens/user_details_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/auth/login_screen.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CaloriesTrackerApp());
}

class CaloriesTrackerApp extends StatelessWidget {
  const CaloriesTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calories Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            ),
          );
        }

        // User is logged in - check if they have a profile
        if (snapshot.hasData && snapshot.data != null) {
          return const ProfileChecker();
        }

        // User is not logged in
        FirestoreService.clearCache();
        return const LoginScreen();
      },
    );
  }
}

class ProfileChecker extends StatefulWidget {
  const ProfileChecker({super.key});

  @override
  State<ProfileChecker> createState() => _ProfileCheckerState();
}

class _ProfileCheckerState extends State<ProfileChecker> {
  bool _isLoading = true;
  bool _hasProfile = false;
  FirestoreUserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    try {
      final profile = await FirestoreService.getUserProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _hasProfile = profile != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasProfile = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading your profile...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // User has profile - go to dashboard
    if (_hasProfile && _profile != null) {
      return HomeDashboard(
        targetCalories: _profile!.targetCalories,
        bmr: _profile!.bmr,
        goal: _profile!.fitnessGoal,
        maintenanceCalories: _profile!.maintenanceCalories,
      );
    }

    // No profile - go to user details
    return const UserDetailsScreen();
  }
}
