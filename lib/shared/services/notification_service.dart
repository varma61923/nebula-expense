import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/storage/storage_service.dart';
import '../../shared/models/transaction_model.dart';

/// Comprehensive offline notification service
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final StorageService _storage = StorageService();
  
  static bool _isInitialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Linux initialization
      const LinuxInitializationSettings linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        linux: linuxSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Request notification permissions
  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    
    return true; // Assume granted for other platforms
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Schedule a reminder notification
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders',
            'Expense Reminders',
            channelDescription: 'Reminders for expense tracking',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'reminder',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      // Save reminder to storage
      await _saveReminderToStorage(id, title, body, scheduledDate, payload);
    } catch (e) {
      debugPrint('Failed to schedule reminder: $e');
    }
  }

  /// Schedule recurring transaction reminder
  static Future<void> scheduleRecurringReminder({
    required String transactionId,
    required String title,
    required DateTime nextDate,
    required RecurrencePattern pattern,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final reminderId = transactionId.hashCode;
      
      await scheduleReminder(
        id: reminderId,
        title: 'Recurring Transaction Due',
        body: title,
        scheduledDate: nextDate,
        payload: 'recurring_transaction:$transactionId',
      );

      // Schedule next occurrence if pattern continues
      if (pattern.shouldContinue(nextDate, 1)) {
        final nextOccurrence = pattern.getNextOccurrence(nextDate);
        await scheduleRecurringReminder(
          transactionId: transactionId,
          title: title,
          nextDate: nextOccurrence,
          pattern: pattern,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule recurring reminder: $e');
    }
  }

  /// Schedule budget limit warning
  static Future<void> scheduleBudgetWarning({
    required String walletId,
    required String category,
    required double currentSpent,
    required double budgetLimit,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final percentage = (currentSpent / budgetLimit) * 100;
      final reminderId = '${walletId}_${category}_budget'.hashCode;
      
      String title;
      String body;
      
      if (percentage >= 100) {
        title = 'Budget Exceeded!';
        body = 'You have exceeded your $category budget by ${(percentage - 100).toStringAsFixed(1)}%';
      } else if (percentage >= 90) {
        title = 'Budget Warning';
        body = 'You have used ${percentage.toStringAsFixed(1)}% of your $category budget';
      } else if (percentage >= 75) {
        title = 'Budget Alert';
        body = 'You have used ${percentage.toStringAsFixed(1)}% of your $category budget';
      } else {
        return; // No warning needed
      }

      await _notifications.show(
        reminderId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_warnings',
            'Budget Warnings',
            channelDescription: 'Warnings when approaching budget limits',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'budget_warning',
          ),
        ),
        payload: 'budget_warning:$walletId:$category',
      );
    } catch (e) {
      debugPrint('Failed to schedule budget warning: $e');
    }
  }

  /// Schedule bill payment reminder
  static Future<void> scheduleBillReminder({
    required String billId,
    required String billName,
    required DateTime dueDate,
    required double amount,
    String? currency,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final reminderId = billId.hashCode;
      final formattedAmount = currency != null ? '$currency $amount' : amount.toString();
      
      // Schedule 3 days before due date
      final reminderDate = dueDate.subtract(const Duration(days: 3));
      
      if (reminderDate.isAfter(DateTime.now())) {
        await scheduleReminder(
          id: reminderId,
          title: 'Bill Payment Due',
          body: '$billName - $formattedAmount due in 3 days',
          scheduledDate: reminderDate,
          payload: 'bill_reminder:$billId',
        );
      }

      // Schedule on due date
      await scheduleReminder(
        id: reminderId + 1,
        title: 'Bill Payment Due Today',
        body: '$billName - $formattedAmount is due today',
        scheduledDate: dueDate,
        payload: 'bill_due:$billId',
      );
    } catch (e) {
      debugPrint('Failed to schedule bill reminder: $e');
    }
  }

  /// Schedule expense tracking reminder
  static Future<void> scheduleExpenseTrackingReminder() async {
    if (!_isInitialized) await initialize();

    try {
      final now = DateTime.now();
      final reminderTime = DateTime(now.year, now.month, now.day, 20, 0); // 8 PM
      
      // If it's already past 8 PM, schedule for tomorrow
      final scheduledDate = reminderTime.isBefore(now) 
          ? reminderTime.add(const Duration(days: 1))
          : reminderTime;

      await scheduleReminder(
        id: 'daily_expense_reminder'.hashCode,
        title: 'Track Your Expenses',
        body: 'Don\'t forget to log your expenses for today',
        scheduledDate: scheduledDate,
        payload: 'daily_expense_reminder',
      );
    } catch (e) {
      debugPrint('Failed to schedule expense tracking reminder: $e');
    }
  }

  /// Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      Importance importance;
      Priority androidPriority;
      
      switch (priority) {
        case NotificationPriority.low:
          importance = Importance.low;
          androidPriority = Priority.low;
          break;
        case NotificationPriority.normal:
          importance = Importance.defaultImportance;
          androidPriority = Priority.defaultPriority;
          break;
        case NotificationPriority.high:
          importance = Importance.high;
          androidPriority = Priority.high;
          break;
        case NotificationPriority.urgent:
          importance = Importance.max;
          androidPriority = Priority.max;
          break;
      }

      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'general',
            'General Notifications',
            channelDescription: 'General app notifications',
            importance: importance,
            priority: androidPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            categoryIdentifier: 'general',
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Cancel a scheduled notification
  static Future<void> cancelNotification(int id) async {
    if (!_isInitialized) await initialize();

    try {
      await _notifications.cancel(id);
      await _removeReminderFromStorage(id);
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();

    try {
      await _notifications.cancelAll();
      await _clearAllRemindersFromStorage();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();

    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Failed to get pending notifications: $e');
      return [];
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await initialize();

    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        return await androidImplementation?.areNotificationsEnabled() ?? false;
      } else if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
            _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
        final settings = await iosImplementation?.getNotificationSettings();
        return settings?.authorizationStatus == AuthorizationStatus.authorized;
      }
      
      return true; // Assume enabled for other platforms
    } catch (e) {
      debugPrint('Failed to check notification status: $e');
      return false;
    }
  }

  /// Save reminder to storage for persistence
  static Future<void> _saveReminderToStorage(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
    String? payload,
  ) async {
    try {
      final reminders = _storage.getSetting<List<Map<String, dynamic>>>('scheduled_reminders') ?? [];
      
      reminders.add({
        'id': id,
        'title': title,
        'body': body,
        'scheduledDate': scheduledDate.toIso8601String(),
        'payload': payload,
      });
      
      await _storage.saveSetting('scheduled_reminders', reminders);
    } catch (e) {
      debugPrint('Failed to save reminder to storage: $e');
    }
  }

  /// Remove reminder from storage
  static Future<void> _removeReminderFromStorage(int id) async {
    try {
      final reminders = _storage.getSetting<List<Map<String, dynamic>>>('scheduled_reminders') ?? [];
      reminders.removeWhere((reminder) => reminder['id'] == id);
      await _storage.saveSetting('scheduled_reminders', reminders);
    } catch (e) {
      debugPrint('Failed to remove reminder from storage: $e');
    }
  }

  /// Clear all reminders from storage
  static Future<void> _clearAllRemindersFromStorage() async {
    try {
      await _storage.deleteSetting('scheduled_reminders');
    } catch (e) {
      debugPrint('Failed to clear reminders from storage: $e');
    }
  }

  /// Restore scheduled reminders after app restart
  static Future<void> restoreScheduledReminders() async {
    if (!_isInitialized) await initialize();

    try {
      final reminders = _storage.getSetting<List<Map<String, dynamic>>>('scheduled_reminders') ?? [];
      final now = DateTime.now();
      
      for (final reminder in reminders) {
        final scheduledDate = DateTime.parse(reminder['scheduledDate']);
        
        // Only reschedule future reminders
        if (scheduledDate.isAfter(now)) {
          await scheduleReminder(
            id: reminder['id'],
            title: reminder['title'],
            body: reminder['body'],
            scheduledDate: scheduledDate,
            payload: reminder['payload'],
          );
        }
      }
      
      // Clean up past reminders
      final futureReminders = reminders.where((reminder) {
        final scheduledDate = DateTime.parse(reminder['scheduledDate']);
        return scheduledDate.isAfter(now);
      }).toList();
      
      await _storage.saveSetting('scheduled_reminders', futureReminders);
    } catch (e) {
      debugPrint('Failed to restore scheduled reminders: $e');
    }
  }
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Notification types
enum NotificationType {
  reminder,
  budgetWarning,
  billDue,
  recurringTransaction,
  expenseTracking,
  general,
}
