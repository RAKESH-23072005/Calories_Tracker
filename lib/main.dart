import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/user_details_screen.dart';

void main() {
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
      home: const UserDetailsScreen(),
    );
  }
}
