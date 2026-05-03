import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'core/utils/notification_service.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/reports_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() async {
  // ۱. شروع سریع رابط کاربری
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // ۲. مقداردهی اولیه Hive
    await Hive.initFlutter();
    
    // ۳. باز کردن باکس‌ها به صورت موازی برای سرعت بیشتر
    await Future.wait([
      Hive.openBox('drivers'),
      Hive.openBox('customers'),
      Hive.openBox('cars'),
      Hive.openBox('sellers'),
      Hive.openBox('load_types'),
      Hive.openBox('load_services'),
      Hive.openBox('payments'),
      Hive.openBox('car_expenses'),
      Hive.openBox('maintenances'),
      Hive.openBox('logistics_cos'), 
      Hive.openBox('settings'),
      Hive.openBox('bank_accounts'),
    ]);

    // ۴. دیتای اولیه
    await DatabaseHelper.instance.seedDefaultData();
    
  } catch (e) {
    debugPrint("خطا در راه‌اندازی دیتابیس: $e");
  }

  // ۵. اجرای اپلیکیشن
  runApp(const KhatoonBarApp());

  // ۶. کارهای پس‌زمینه و اعلان‌ها
  Future.microtask(() async {
    try {
      await NotificationService.init();
      await NotificationService.checkDueChecks();
      await NotificationService.checkMaintenanceReminders();
    } catch (e) {
      debugPrint("خطا در سرویس اعلان: $e");
    }
  });
}

class KhatoonBarApp extends StatelessWidget {
  const KhatoonBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'خاتون بار',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
      ],
      localizationsDelegates: const [
        PersianMaterialLocalizations.delegate,
        PersianCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 1; // تب خانه (وسط)

  final List<Widget> _screens = [
    const ReportsScreen(),
    const HomeScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'گزارشات'),
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'خانه'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'تنظیمات'),
          ],
        ),
      ),
    );
  }
}
