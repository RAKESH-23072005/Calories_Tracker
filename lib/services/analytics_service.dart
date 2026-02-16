import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'daily_log_service.dart';

/// Holds computed weekly (or custom-period) analytics data.
class WeeklyAnalyticsData {
  final List<DailyLogData> dailyLogs;
  final int weeklyTotalCalories;
  final int averageDailyCalories;
  final double weeklyAverageProtein;
  final double weeklyAverageCarbs;
  final double weeklyAverageFats;
  final double calorieTargetPercentage; // % of target achieved

  WeeklyAnalyticsData({
    required this.dailyLogs,
    required this.weeklyTotalCalories,
    required this.averageDailyCalories,
    required this.weeklyAverageProtein,
    required this.weeklyAverageCarbs,
    required this.weeklyAverageFats,
    required this.calorieTargetPercentage,
  });

  factory WeeklyAnalyticsData.empty() => WeeklyAnalyticsData(
        dailyLogs: [],
        weeklyTotalCalories: 0,
        averageDailyCalories: 0,
        weeklyAverageProtein: 0,
        weeklyAverageCarbs: 0,
        weeklyAverageFats: 0,
        calorieTargetPercentage: 0,
      );

  bool get isEmpty => dailyLogs.isEmpty;
  int get daysLogged => dailyLogs.length;
}

/// Service that fetches daily logs from Firestore and computes analytics.
///
/// Designed to be extensible — pass [days] to support weekly (7),
/// monthly (30), or any custom period.
class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> get _dailyLogsCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('dailyLogs');
  }

  /// Formats a [DateTime] as `YYYY-MM-DD` to match Firestore document IDs.
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Fetches daily logs for the last [days] days and computes analytics.
  ///
  /// [targetCalories] is the user's daily target, used to calculate
  /// the overall target-comparison percentage.
  static Future<WeeklyAnalyticsData> getAnalytics({
    int days = 7,
    required int targetCalories,
  }) async {
    if (_userId == null) return WeeklyAnalyticsData.empty();

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1));
      final startDateStr = _formatDate(startDate);

      final snapshot = await _dailyLogsCollection
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .orderBy('date')
          .limit(days)
          .get();

      final logs = snapshot.docs
          .map((doc) => DailyLogData.fromFirestore(doc.data()))
          .toList();

      return _computeAnalytics(
        logs: logs,
        targetCalories: targetCalories,
        days: days,
      );
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      return WeeklyAnalyticsData.empty();
    }
  }

  /// Pure calculation — no Firestore calls. Easy to unit-test.
  static WeeklyAnalyticsData _computeAnalytics({
    required List<DailyLogData> logs,
    required int targetCalories,
    required int days,
  }) {
    if (logs.isEmpty) return WeeklyAnalyticsData.empty();

    final totalCalories =
        logs.fold<int>(0, (s, log) => s + log.totalCalories);
    final totalProtein =
        logs.fold<double>(0, (s, log) => s + log.totalProtein);
    final totalCarbs =
        logs.fold<double>(0, (s, log) => s + log.totalCarbs);
    final totalFats =
        logs.fold<double>(0, (s, log) => s + log.totalFat);

    final daysLogged = logs.length;
    final avgCalories = (totalCalories / daysLogged).round();
    final avgProtein = totalProtein / daysLogged;
    final avgCarbs = totalCarbs / daysLogged;
    final avgFats = totalFats / daysLogged;

    // Target comparison: consumed / (target × days with data) × 100
    final totalTarget = targetCalories * daysLogged;
    final targetPercentage =
        totalTarget > 0 ? (totalCalories / totalTarget) * 100 : 0.0;

    return WeeklyAnalyticsData(
      dailyLogs: logs,
      weeklyTotalCalories: totalCalories,
      averageDailyCalories: avgCalories,
      weeklyAverageProtein: avgProtein,
      weeklyAverageCarbs: avgCarbs,
      weeklyAverageFats: avgFats,
      calorieTargetPercentage: targetPercentage,
    );
  }
}
