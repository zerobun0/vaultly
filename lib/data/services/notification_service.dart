import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  static const _budgetChannelId = 'budget_alerts';
  static const _savingsChannelId = 'savings_alerts';

  Future<void> init() async {
    if (_initialised) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _budgetChannelId,
            'Budget Alerts',
            description: 'Alerts when you are approaching or over budget',
            importance: Importance.high,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _savingsChannelId,
            'Savings Milestones',
            description: 'Notifications when savings goals are reached',
            importance: Importance.defaultImportance,
          ),
        );

    _initialised = true;
  }

  Future<void> showBudgetOverspend({
    required String categoryName,
    required double spent,
    required double budget,
  }) async {
    await _plugin.show(
      categoryName.hashCode,
      'Budget Alert: $categoryName',
      'You\'ve spent £${spent.toStringAsFixed(2)} of your £${budget.toStringAsFixed(2)} budget',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _budgetChannelId,
          'Budget Alerts',
          channelDescription: 'Budget overspend alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> showSavingsGoalReached({required String goalName}) async {
    await _plugin.show(
      goalName.hashCode,
      '🎉 Savings Goal Reached!',
      'Congratulations — you\'ve reached your "$goalName" goal!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _savingsChannelId,
          'Savings Milestones',
          channelDescription: 'Savings goal notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
