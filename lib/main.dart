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
import 'presentation/screens/ledger_hub_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // مقداردهی اولیه سرویس اعلان‌ها
  await NotificationService.init();
  
  await Hive.initFlutter();
  
  await Hive.openBox('drivers');
  await Hive.openBox('customers');
  await Hive.openBox('cars');
  await Hive.openBox('sellers');
  await Hive.openBox('load_types');
  await Hive.openBox('load_services');
  await Hive.openBox('payments');
  await Hive.openBox('car_expenses');
  await Hive.openBox('maintenances');
  await Hive.openBox('logistics_cos'); 
  await Hive.openBox('settings');

  await DatabaseHelper.instance.seedDefaultData();

  // بررسی چک‌های سررسید امروز هنگام ورود به برنامه
  NotificationService.checkDueChecks();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              "خطایی رخ داده است:\n${details.exception}",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  };

  runApp(const KhatoonBarApp());
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
        // ترتیب اینجا خیلی حیاتیه! فارسی‌ها باید اول باشن تا میلادی گوگل اولویت پیدا نکنه
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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LedgerHubScreen(),
    const ReportsScreen(),
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'خانه'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'حساب‌ها'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'گزارشات'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'تنظیمات'),
          ],
        ),
      ),
    );
  }
}
