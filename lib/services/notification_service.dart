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
  final int lunchHour;
  final int dinnerHour;

  const NotificationSettings({
    this.dailyReminders = true,
    this.calorieLimitAlerts = true,
    this.healthAlerts = true,
    this.inactivityReminders = true,
    this.breakfastHour = 8,
    this.lunchHour = 13,
    this.dinnerHour = 20,
  });

  Map<String, dynamic> toJson() => {
    'dailyReminders': dailyReminders,
    'calorieLimitAlerts': calorieLimitAlerts,
    'healthAlerts': healthAlerts,
    'inactivityReminders': inactivityReminders,
    'breakfastHour': breakfastHour,
    'lunchHour': lunchHour,
    'dinnerHour': dinnerHour,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationSettings();
    return NotificationSettings(
      dailyReminders: json['dailyReminders'] ?? true,
      calorieLimitAlerts: json['calorieLimitAlerts'] ?? true,
      healthAlerts: json['healthAlerts'] ?? true,
      inactivityReminders: json['inactivityReminders'] ?? true,
      breakfastHour: json['breakfastHour'] ?? 8,
      lunchHour: json['lunchHour'] ?? 13,
      dinnerHour: json['dinnerHour'] ?? 20,
    );
  }

  NotificationSettings copyWith({
    bool? dailyReminders,
    bool? calorieLimitAlerts,
    bool? healthAlerts,
    bool? inactivityReminders,
    int? breakfastHour,
    int? lunchHour,
    int? dinnerHour,
  }) {
    return NotificationSettings(
      dailyReminders: dailyReminders ?? this.dailyReminders,
      calorieLimitAlerts: calorieLimitAlerts ?? this.calorieLimitAlerts,
      healthAlerts: healthAlerts ?? this.healthAlerts,
      inactivityReminders: inactivityReminders ?? this.inactivityReminders,
      breakfastHour: breakfastHour ?? this.breakfastHour,
      lunchHour: lunchHour ?? this.lunchHour,
      dinnerHour: dinnerHour ?? this.dinnerHour,
    );
  }
}

/// Service for managing local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static NotificationSettings _settings = const NotificationSettings();
  static bool _isInitialized = false;

  // Notification IDs
  static const int _breakfastReminderId = 1;
  static const int _lunchReminderId = 2;
  static const int _dinnerReminderId = 3;
  static const int _inactivityReminderId = 4;
  static const int _calorieLimitId = 100;
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
    } catch (e) {
      // Fallback to UTC if timezone detection fails
      debugPrint('Timezone detection failed: $e');
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

    // Load saved settings
    await _loadSettings();
    
    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigation can be handled here if needed
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
        // Parse simple key-value format
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

  /// Schedule all daily meal reminders
  static Future<void> scheduleDailyReminders() async {
    if (!_settings.dailyReminders) return;

    await _scheduleDaily(
      id: _breakfastReminderId,
      hour: _settings.breakfastHour,
      minute: 0,
      title: 'Good morning! 🌅',
      body: "Don't forget to log your breakfast today! Start your day with healthy tracking.",
    );

    await _scheduleDaily(
      id: _lunchReminderId,
      hour: _settings.lunchHour,
      minute: 0,
      title: 'Lunchtime! 🍽️',
      body: "Time to log your lunch. Keep up the great tracking habit!",
    );

    await _scheduleDaily(
      id: _dinnerReminderId,
      hour: _settings.dinnerHour,
      minute: 0,
      title: 'Dinner time! 🌙',
      body: "Remember to log your dinner. You're doing great with your health journey!",
    );

    debugPrint('Daily reminders scheduled: ${_settings.breakfastHour}:00, ${_settings.lunchHour}:00, ${_settings.dinnerHour}:00');
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
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_reminder',
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Get the next instance of a specific time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
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

  /// Show calorie limit alert notification
  static Future<void> showCalorieLimitAlert(int currentCalories, int targetCalories) async {
    if (!_settings.calorieLimitAlerts) return;

    final percentage = ((currentCalories / targetCalories) * 100).round();
    
    await _notifications.show(
      _calorieLimitId,
      'Approaching your calorie target! 📊',
      "You've reached $percentage% of your daily goal ($currentCalories/$targetCalories kcal). Track wisely!",
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

  /// Get notification details configuration
  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'calories_tracker_channel',
        'Calories Tracker',
        channelDescription: 'Notifications for meal reminders and health alerts',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
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
    await _notifications.cancel(_lunchReminderId);
    await _notifications.cancel(_dinnerReminderId);
    await _notifications.cancel(_inactivityReminderId);
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
