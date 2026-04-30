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
      'سررسید چک‌ها',
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

        // یادآوری از ۵ روز قبل تا روز سررسید
        if (difference >= 0 && difference <= 5) {
          String title = '';
          String prefix = payment.type == PaymentType.toSeller ? "چک پرداختی به فروشنده" : "چک دریافتی از مشتری";
          
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
}
