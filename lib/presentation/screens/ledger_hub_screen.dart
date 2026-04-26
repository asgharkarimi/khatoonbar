import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../models/models.dart';
import 'customer_ledger_screen.dart';
import 'seller_ledger_screen.dart';

class LedgerHubScreen extends StatefulWidget {
  const LedgerHubScreen({super.key});

  @override
  State<LedgerHubScreen> createState() => _LedgerHubScreenState();
}

class _LedgerHubScreenState extends State<LedgerHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Customer> _customers = [];
  List<Seller> _sellers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final customers = await DatabaseHelper.instance.getAllCustomers();
    final sellers = await DatabaseHelper.instance.getAllSellers();
    setState(() {
      _customers = customers;
      _sellers = sellers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر حساب و مالی'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'مشتریان (بدهکاران)', icon: Icon(Icons.people)),
            Tab(text: 'فروشندگان (بستانکاران)', icon: Icon(Icons.storefront)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCustomerList(),
                _buildSellerList(),
              ],
            ),
    );
  }

  Widget _buildCustomerList() {
    if (_customers.isEmpty) return const Center(child: Text('مشتری‌ای ثبت نشده است'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        final customer = _customers[index];
        return _buildLedgerTile(
          title: customer.fullName,
          subtitle: customer.village.isNotEmpty ? "منطقه: ${customer.village}" : "بدون آدرس",
          icon: Icons.person,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CustomerLedgerScreen(customer: customer)),
          ),
        );
      },
    );
  }

  Widget _buildSellerList() {
    if (_sellers.isEmpty) return const Center(child: Text('فروشنده‌ای ثبت نشده است'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sellers.length,
      itemBuilder: (context, index) {
        final seller = _sellers[index];
        return _buildLedgerTile(
          title: seller.name,
          subtitle: "محصول: ${seller.product}",
          icon: Icons.storefront,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SellerLedgerScreen(seller: seller)),
          ),
        );
      },
    );
  }

  Widget _buildLedgerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }
}
