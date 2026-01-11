import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/bmr_calculator.dart';

class FirestoreUserProfile {
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
  final DateTime createdAt;
  final DateTime updatedAt;

  FirestoreUserProfile({
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
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
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
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory FirestoreUserProfile.fromFirestore(Map<String, dynamic> data) {
    return FirestoreUserProfile(
      name: data['name'] ?? '',
      age: data['age'] ?? 25,
      gender: Gender.values[data['gender'] ?? 0],
      height: (data['height'] ?? 170).toDouble(),
      weight: (data['weight'] ?? 70).toDouble(),
      activityLevel: ActivityLevel.values[data['activityLevel'] ?? 0],
      fitnessGoal: FitnessGoal.values[data['fitnessGoal'] ?? 1],
      targetCalories: data['targetCalories'] ?? 2000,
      bmr: data['bmr'] ?? 1500,
      maintenanceCalories: (data['maintenanceCalories'] ?? 2000).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static FirestoreUserProfile? _cachedProfile;

  static String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // User Profiles Collection Reference
  static CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Save or update user profile
  static Future<bool> saveUserProfile(FirestoreUserProfile profile) async {
    if (_userId == null) return false;

    try {
      await _usersCollection.doc(_userId).set(
        profile.toFirestore(),
        SetOptions(merge: true),
      );
      _cachedProfile = profile;
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  // Get user profile
  static Future<FirestoreUserProfile?> getUserProfile() async {
    if (_userId == null) return null;

    // Return cached profile if available
    if (_cachedProfile != null) return _cachedProfile;

    try {
      final doc = await _usersCollection.doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        _cachedProfile = FirestoreUserProfile.fromFirestore(doc.data()!);
        return _cachedProfile;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Check if user has profile
  static Future<bool> hasUserProfile() async {
    if (_userId == null) return false;

    try {
      final doc = await _usersCollection.doc(_userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Update specific fields
  static Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    if (_userId == null) return false;

    try {
      updates['updatedAt'] = Timestamp.now();
      await _usersCollection.doc(_userId).update(updates);
      _cachedProfile = null; // Clear cache to force refresh
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Delete user profile
  static Future<bool> deleteUserProfile() async {
    if (_userId == null) return false;

    try {
      await _usersCollection.doc(_userId).delete();
      _cachedProfile = null;
      return true;
    } catch (e) {
      print('Error deleting user profile: $e');
      return false;
    }
  }

  // Clear cached profile (call on logout)
  static void clearCache() {
    _cachedProfile = null;
  }

  // Get cached profile without async
  static FirestoreUserProfile? get cachedProfile => _cachedProfile;
}
