import 'package:flutter/material.dart';
import 'settings/manage_drivers_screen.dart';
import 'settings/manage_cars_screen.dart';
import 'settings/manage_sellers_screen.dart';
import 'settings/manage_load_types_screen.dart';
import 'settings/manage_customers_screen.dart';
import 'settings/manage_car_expenses_screen.dart';
import 'maintenance_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات پایه')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/khatoon_logo.png',
                  height: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'خاتون بار',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'نسخه 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildSettingItem(
            context,
            'سرویس‌های دوره‌ای (نت)',
            'تعویض روغن، گریس‌کاری و یادآوری',
            Icons.build_circle,
            const MaintenanceScreen(),
            highlightColor: Colors.orange,
          ),
          const Divider(height: 32),
          _buildSettingItem(
            context,
            'مدیریت رانندگان',
            'افزودن و ویرایش لیست رانندگان',
            Icons.person_add,
            const ManageDriversScreen(),
          ),
          _buildSettingItem(
            context,
            'مدیریت مشتریان',
            'لیست گیرندگان بار (مشتریان)',
            Icons.people_outline,
            const ManageCustomersScreen(),
          ),
          _buildSettingItem(
            context,
            'هزینه‌های متفرقه ماشین',
            'تعمیرات، لاستیک، بیمه و غیره',
            Icons.settings_suggest_outlined,
            const ManageCarExpensesScreen(),
          ),
          _buildSettingItem(
            context,
            'مدیریت ماشین‌ها',
            'تعریف خودروهای جدید و پلاک‌ها',
            Icons.local_shipping,
            const ManageCarsScreen(),
          ),
          _buildSettingItem(
            context,
            'مدیریت فروشندگان',
            'لیست شرکت‌ها و ماسه‌شویی‌ها',
            Icons.storefront,
            const ManageSellersScreen(),
          ),
          _buildSettingItem(
            context,
            'مدیریت انواع بار',
            'آجر، ماسه، سیمان و موارد دلخواه',
            Icons.category,
            const ManageLoadTypesScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget? targetScreen, {
    bool isSwitch = false,
    Color highlightColor = Colors.green,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: highlightColor.withOpacity(0.1),
          child: Icon(icon, color: highlightColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: isSwitch
            ? Switch(value: true, onChanged: (v) {})
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: targetScreen != null
            ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen))
            : null,
      ),
    );
  }
}
