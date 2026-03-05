import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification settings for the user
class NotificationSettings {
  final bool dailyReminders;
  final bool calorieLimitAlerts;
  final bool healthAlerts;
  final bool inactivityReminders;
  final int breakfastHour;
  final int breakfastMinute;
  final int morningSnackHour;
  final int morningSnackMinute;
  final int lunchHour;
  final int lunchMinute;
  final int eveningSnackHour;
  final int eveningSnackMinute;
  final int dinnerHour;
  final int dinnerMinute;

  const NotificationSettings({
    this.dailyReminders = true,
    this.calorieLimitAlerts = true,
    this.healthAlerts = true,
    this.inactivityReminders = true,
    this.breakfastHour = 8,
    this.breakfastMinute = 0,
    this.morningSnackHour = 10,
    this.morningSnackMinute = 30,
    this.lunchHour = 13,
    this.lunchMinute = 0,
    this.eveningSnackHour = 17,
    this.eveningSnackMinute = 0,
    this.dinnerHour = 20,
    this.dinnerMinute = 0,
  });

  Map<String, dynamic> toJson() => {
    'dailyReminders': dailyReminders,
    'calorieLimitAlerts': calorieLimitAlerts,
    'healthAlerts': healthAlerts,
    'inactivityReminders': inactivityReminders,
    'breakfastHour': breakfastHour,
    'breakfastMinute': breakfastMinute,
    'morningSnackHour': morningSnackHour,
    'morningSnackMinute': morningSnackMinute,
    'lunchHour': lunchHour,
    'lunchMinute': lunchMinute,
    'eveningSnackHour': eveningSnackHour,
    'eveningSnackMinute': eveningSnackMinute,
    'dinnerHour': dinnerHour,
    'dinnerMinute': dinnerMinute,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationSettings();
    return NotificationSettings(
      dailyReminders: json['dailyReminders'] ?? true,
      calorieLimitAlerts: json['calorieLimitAlerts'] ?? true,
      healthAlerts: json['healthAlerts'] ?? true,
      inactivityReminders: json['inactivityReminders'] ?? true,
      breakfastHour: json['breakfastHour'] ?? 8,
      breakfastMinute: json['breakfastMinute'] ?? 0,
      morningSnackHour: json['morningSnackHour'] ?? 10,
      morningSnackMinute: json['morningSnackMinute'] ?? 30,
      lunchHour: json['lunchHour'] ?? 13,
      lunchMinute: json['lunchMinute'] ?? 0,
      eveningSnackHour: json['eveningSnackHour'] ?? 17,
      eveningSnackMinute: json['eveningSnackMinute'] ?? 0,
      dinnerHour: json['dinnerHour'] ?? 20,
      dinnerMinute: json['dinnerMinute'] ?? 0,
    );
  }

  NotificationSettings copyWith({
    bool? dailyReminders,
    bool? calorieLimitAlerts,
    bool? healthAlerts,
    bool? inactivityReminders,
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
  }) {
    return NotificationSettings(
      dailyReminders: dailyReminders ?? this.dailyReminders,
      calorieLimitAlerts: calorieLimitAlerts ?? this.calorieLimitAlerts,
      healthAlerts: healthAlerts ?? this.healthAlerts,
      inactivityReminders: inactivityReminders ?? this.inactivityReminders,
      breakfastHour: breakfastHour ?? this.breakfastHour,
      breakfastMinute: breakfastMinute ?? this.breakfastMinute,
      morningSnackHour: morningSnackHour ?? this.morningSnackHour,
      morningSnackMinute: morningSnackMinute ?? this.morningSnackMinute,
      lunchHour: lunchHour ?? this.lunchHour,
      lunchMinute: lunchMinute ?? this.lunchMinute,
      eveningSnackHour: eveningSnackHour ?? this.eveningSnackHour,
      eveningSnackMinute: eveningSnackMinute ?? this.eveningSnackMinute,
      dinnerHour: dinnerHour ?? this.dinnerHour,
      dinnerMinute: dinnerMinute ?? this.dinnerMinute,
    );
  }
}

/// Service for managing local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static NotificationSettings _settings = const NotificationSettings();
  static bool _isInitialized = false;

  // Channel config — HIGH importance for heads-up display
  static const String _channelId = 'meal_reminder_channel';
  static const String _channelName = 'Meal Reminders';
  static const String _channelDescription =
      'Daily meal and snack reminder notifications';

  // Notification IDs
  static const int _breakfastReminderId = 1;
  static const int _morningSnackReminderId = 2;
  static const int _lunchReminderId = 3;
  static const int _eveningSnackReminderId = 4;
  static const int _dinnerReminderId = 5;
  static const int _inactivityReminderId = 6;
  static const int _calorieDeficitId = 100;
  static const int _calorieLimitId = 101;
  static const int _healthAlertId = 200;

  // Preference keys
  static const String _prefsKey = 'notification_settings';

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize timezone
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('Timezone detection failed, using UTC: $e');
    }

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the Android notification channel with HIGH importance
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
        // Request permissions on Android 13+
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    }

    // Load saved settings
    await _loadSettings();
    
    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (especially for Android 13+)
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// Load notification settings from preferences
  static Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_prefsKey);
      if (settingsJson != null) {
        final Map<String, dynamic> json = {};
        for (final entry in settingsJson.split(',')) {
          final parts = entry.split(':');
          if (parts.length == 2) {
            final key = parts[0].trim();
            final value = parts[1].trim();
            if (value == 'true' || value == 'false') {
              json[key] = value == 'true';
            } else {
              json[key] = int.tryParse(value) ?? value;
            }
          }
        }
        _settings = NotificationSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  /// Save notification settings to preferences
  static Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _settings.toJson();
      final settingsString = json.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      await prefs.setString(_prefsKey, settingsString);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  /// Get current notification settings
  static NotificationSettings get settings => _settings;

  /// Update notification settings
  static Future<void> updateSettings(NotificationSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    
    // Reschedule reminders with new settings
    await cancelAllReminders();
    if (_settings.dailyReminders) {
      await scheduleDailyReminders();
    }
  }

  /// Schedule all 5 daily meal reminders.
  /// Always cancels and reschedules to survive OEM battery optimisations.
  static Future<void> scheduleDailyReminders() async {
    if (!_settings.dailyReminders) return;

    // Cancel all existing meal reminders first — OPPO / Realme / OnePlus
    // can silently kill scheduled alarms, so we must reschedule every launch.
    await cancelAllReminders();

    // Breakfast
    await _scheduleDaily(
      id: _breakfastReminderId,
      hour: _settings.breakfastHour,
      minute: _settings.breakfastMinute,
      title: 'Breakfast Time 🍳',
      body: 'Start your day healthy. Log your breakfast now!',
    );

    // Morning Snack
    await _scheduleDaily(
      id: _morningSnackReminderId,
      hour: _settings.morningSnackHour,
      minute: _settings.morningSnackMinute,
      title: 'Snack Time 🍎',
      body: 'Have a healthy snack and log it now!',
    );

    // Lunch
    await _scheduleDaily(
      id: _lunchReminderId,
      hour: _settings.lunchHour,
      minute: _settings.lunchMinute,
      title: 'Lunch Reminder 🥗',
      body: "Don't forget to log your lunch intake.",
    );

    // Evening Snack
    await _scheduleDaily(
      id: _eveningSnackReminderId,
      hour: _settings.eveningSnackHour,
      minute: _settings.eveningSnackMinute,
      title: 'Evening Snack 🍌',
      body: 'Time for a light snack. Stay on track!',
    );

    // Dinner
    await _scheduleDaily(
      id: _dinnerReminderId,
      hour: _settings.dinnerHour,
      minute: _settings.dinnerMinute,
      title: 'Dinner Time 🍽',
      body: 'Track your dinner and stay on target!',
    );

    // Log what was scheduled for debugging
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('✅ Scheduled ${pending.length} notifications:');
    for (final n in pending) {
      debugPrint('   ID ${n.id}: ${n.title}');
    }

    debugPrint('Daily reminders scheduled (5 meals)');
  }

  /// Schedule a daily recurring notification
  static Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      final scheduledTime = _nextInstanceOfTime(hour, minute);
      debugPrint('Scheduling notification ID $id at $scheduledTime');
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_reminder',
      );
    } catch (e) {
      debugPrint('Error scheduling notification $id: $e');
    }
  }

  /// Get the next instance of a specific time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Schedule inactivity reminder (if no meals logged by 2 PM)
  static Future<void> scheduleInactivityReminder() async {
    if (!_settings.inactivityReminders) return;

    await _scheduleDaily(
      id: _inactivityReminderId,
      hour: 14,
      minute: 0,
      title: 'Stay consistent! 📝',
      body: "No meals logged yet today. Take a moment to track what you've eaten.",
    );
  }

  /// Cancel inactivity reminder (when user logs a meal)
  static Future<void> cancelInactivityReminder() async {
    await _notifications.cancel(_inactivityReminderId);
  }

  /// Schedule a 9 PM calorie deficit reminder if consumed < target
  static Future<void> scheduleCalorieDeficitReminder({
    required int consumedCalories,
    required int targetCalories,
  }) async {
    // Cancel any existing deficit reminder first
    await _notifications.cancel(_calorieDeficitId);

    // Only schedule if there's a deficit
    if (consumedCalories >= targetCalories) return;

    final deficit = targetCalories - consumedCalories;

    try {
      await _notifications.zonedSchedule(
        _calorieDeficitId,
        'Calorie Check 📊',
        "You're $deficit kcal short of your goal. Log your meals!",
        _nextInstanceOfTime(21, 0), // 9:00 PM
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'calorie_deficit',
      );
    } catch (e) {
      debugPrint('Error scheduling calorie deficit reminder: $e');
    }
  }

  /// Show calorie limit alert notification
  static Future<void> showCalorieLimitAlert(
      int currentCalories, int targetCalories) async {
    if (!_settings.calorieLimitAlerts) return;

    final percentage = ((currentCalories / targetCalories) * 100).round();
    final exceeded = currentCalories > targetCalories;

    await _notifications.show(
      _calorieLimitId,
      exceeded
          ? 'Calorie limit exceeded! ⚠️'
          : 'Approaching your calorie target! 📊',
      exceeded
          ? "You've consumed $currentCalories/$targetCalories kcal ($percentage%). Consider lighter meals for the rest of the day."
          : "You've reached $percentage% of your daily goal ($currentCalories/$targetCalories kcal). Track wisely!",
      _notificationDetails(),
      payload: 'calorie_limit',
    );
  }

  /// Show health awareness notification
  static Future<void> showHealthAlert({
    required String foodName,
    required String concern,
    required String conditionName,
  }) async {
    if (!_settings.healthAlerts) return;

    await _notifications.show(
      _healthAlertId + DateTime.now().millisecond,
      'Health Awareness 💚',
      '$foodName is higher in $concern. Consider moderation for $conditionName management. (Not medical advice)',
      _notificationDetails(),
      payload: 'health_alert',
    );
  }

  /// Notification details — uses HIGH importance channel
  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Cancel all scheduled reminders
  static Future<void> cancelAllReminders() async {
    await _notifications.cancel(_breakfastReminderId);
    await _notifications.cancel(_morningSnackReminderId);
    await _notifications.cancel(_lunchReminderId);
    await _notifications.cancel(_eveningSnackReminderId);
    await _notifications.cancel(_dinnerReminderId);
    await _notifications.cancel(_inactivityReminderId);
    await _notifications.cancel(_calorieDeficitId);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Check if notifications are enabled
  static bool get areNotificationsEnabled => _settings.dailyReminders;

  /// Medical disclaimer for health notifications
  static const String healthDisclaimer = 
      'These notifications are for awareness only and do not constitute medical advice. '
      'Please consult your healthcare provider for personalized dietary guidance.';

}

