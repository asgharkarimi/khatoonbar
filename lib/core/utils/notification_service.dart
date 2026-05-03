import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/models.dart';
import '../data/service_repository.dart';
import 'formatters.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'check_reminders',
      'یادآورهای خاتون بار',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }

  static Future<void> checkDueChecks() async {
    final repository = ServiceRepository();
    final allPayments = await repository.getPayments();
    final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (var payment in allPayments) {
      if (payment.method == PaymentMethod.check && !payment.isCleared && payment.checkDueDate != null) {
        final dueDate = DateTime(payment.checkDueDate!.year, payment.checkDueDate!.month, payment.checkDueDate!.day);
        final difference = dueDate.difference(now).inDays;

        if (difference >= 0 && difference <= 5) {
          String title = '';
          String prefix = payment.type == PaymentType.toSeller ? "چک پرداختی به فروشنده" : "چک دریافتی از مشتری";
          if (payment.type == PaymentType.toLogistics) prefix = "چک پرداختی به باربری";
          
          if (difference == 0) {
            title = 'سررسید $prefix امروز است';
          } else {
            title = '$difference روز تا سررسید $prefix';
          }

          await showNotification(
            payment.id.hashCode,
            title,
            'مبلغ: ${AppFormatters.formatCurrency(payment.amount)} تومان - ${payment.description ?? ""}',
          );
        }
      }
    }
  }

  static Future<void> checkMaintenanceReminders() async {
    final repository = ServiceRepository();
    final maintenances = await repository.getMaintenances();
    final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (var m in maintenances) {
      if (m.nextDate != null) {
        final nextDate = DateTime(m.nextDate!.year, m.nextDate!.month, m.nextDate!.day);
        final difference = nextDate.difference(now).inDays;

        if (difference >= 0 && difference <= 3) {
          String title = difference == 0 ? "زمان سرویس دوره‌ای فرا رسید" : "$difference روز تا موعد سرویس بعدی";
          await showNotification(
            m.id.hashCode + 1,
            title,
            "سرویس: ${m.type} برای خودرو مورد نظر",
          );
        }
      }
    }
  }
}
