import 'package:flutter/material.dart';
import 'settings/manage_drivers_screen.dart';
import 'settings/manage_cars_screen.dart';
import 'settings/manage_sellers_screen.dart';
import 'settings/manage_load_types_screen.dart';
import 'settings/manage_customers_screen.dart';
import 'settings/manage_car_expenses_screen.dart';
import 'settings/manage_logistics_cos_screen.dart';
import 'settings/manage_bank_accounts_screen.dart';
import 'maintenance_screen.dart';
import 'transaction_history_screen.dart';
import '../../core/utils/backup_service.dart';

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
                  'نسخه 1.1.0',
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
            'دفتر کل (ریز تراکنش‌ها)',
            'مشاهده تمامی واریزها، برداشت‌ها و هزینه‌ها',
            Icons.receipt_long,
            const TransactionHistoryScreen(),
            highlightColor: Colors.deepPurple,
          ),
          const Divider(height: 32),
          _buildSettingItem(
            context,
            'مدیریت حساب‌های بانکی من',
            'ثبت کارت‌ها و شماره حساب‌های شخصی',
            Icons.account_balance_wallet,
            const ManageBankAccountsScreen(),
            highlightColor: Colors.blueAccent,
          ),
          _buildSettingItem(
            context,
            'سرویس‌های دوره‌ای (نت)',
            'تعویض روغن، گریس‌کاری و یادآوری',
            Icons.build_circle,
            const MaintenanceScreen(),
            highlightColor: Colors.orange,
          ),
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
            'مدیریت باربری‌ها',
            'افزودن و ویرایش لیست باربری‌ها',
            Icons.business,
            const ManageLogisticsCosScreen(),
            highlightColor: Colors.blue,
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
          const Divider(height: 32),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.indigoAccent, child: Icon(Icons.backup, color: Colors.white)),
            title: const Text('پشتیبان‌گیری از داده‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('ارسال فایل پشتیبان به تلگرام، ایتا یا حافظه', style: TextStyle(fontSize: 12)),
            onTap: () => BackupService.createBackup(),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.restore, color: Colors.white)),
            title: const Text('بازیابی اطلاعات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('انتخاب فایل JSON برای بازگردانی داده‌ها', style: TextStyle(fontSize: 12)),
            onTap: () async {
              bool success = await BackupService.restoreBackup();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اطلاعات با موفقیت بازیابی شد. لطفا برنامه را مجددا باز کنید.'), backgroundColor: Colors.green));
              }
            },
          ),
          const SizedBox(height: 40),
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: targetScreen != null
            ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen))
            : null,
      ),
    );
  }
}
