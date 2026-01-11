import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/bmr_calculator.dart';

class UserProfile {
  final String name;
  final int age;
  final Gender gender;
  final double height;
  final double weight;
  final ActivityLevel activityLevel;
  final FitnessGoal fitnessGoal;
  final int targetCalories;
  final int bmr;
  final double maintenanceCalories;

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.fitnessGoal,
    required this.targetCalories,
    required this.bmr,
    required this.maintenanceCalories,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender.index,
    'height': height,
    'weight': weight,
    'activityLevel': activityLevel.index,
    'fitnessGoal': fitnessGoal.index,
    'targetCalories': targetCalories,
    'bmr': bmr,
    'maintenanceCalories': maintenanceCalories,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      age: json['age'] ?? 25,
      gender: Gender.values[json['gender'] ?? 0],
      height: (json['height'] ?? 170).toDouble(),
      weight: (json['weight'] ?? 70).toDouble(),
      activityLevel: ActivityLevel.values[json['activityLevel'] ?? 0],
      fitnessGoal: FitnessGoal.values[json['fitnessGoal'] ?? 1],
      targetCalories: json['targetCalories'] ?? 2000,
      bmr: json['bmr'] ?? 1500,
      maintenanceCalories: (json['maintenanceCalories'] ?? 2000).toDouble(),
    );
  }
}

class UserProfileService {
  static const String _profileKey = 'user_profile';
  static UserProfile? _cachedProfile;

  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(profile.toJson());
    await prefs.setString(_profileKey, jsonString);
    _cachedProfile = profile;
  }

  static Future<UserProfile?> getProfile() async {
    if (_cachedProfile != null) return _cachedProfile;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_profileKey);
    
    if (jsonString == null) return null;
    
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      _cachedProfile = UserProfile.fromJson(jsonMap);
      return _cachedProfile;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> hasProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_profileKey);
  }

  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    _cachedProfile = null;
  }

  static void updateCachedProfile(UserProfile profile) {
    _cachedProfile = profile;
  }

  static UserProfile? get cachedProfile => _cachedProfile;
}
