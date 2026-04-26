import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart'; 
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import 'seller_ledger_screen.dart';
import 'customer_ledger_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LoadService> _services = [];
  List<Seller> _sellers = [];
  List<Customer> _customers = [];
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
    try {
      final services = await DatabaseHelper.instance.getAllServices();
      final sellers = await DatabaseHelper.instance.getAllSellers();
      final customers = await DatabaseHelper.instance.getAllCustomers();
      setState(() {
        _services = services;
        _sellers = sellers;
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت اطلاعات: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    double totalCustomerDebt = 0;
    for (var c in _customers) {
      final customerServices = _services.where((s) => s.customer?.id == c.id).toList();
      totalCustomerDebt += customerServices.fold(0.0, (sum, s) => sum + s.remainingCustomerDebt);
    }

    double totalSellerDebt = 0;
    for (var s in _sellers) {
      final sellerServices = _services.where((sel) => sel.seller.id == s.id).toList();
      totalSellerDebt += sellerServices.fold(0.0, (sum, sel) => sum + sel.remainingDebtToSeller);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارشات مالی و دفاتر حساب'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'بدهی مشتریان', icon: Icon(Icons.group_outlined)),
            Tab(text: 'بدهی به شرکت‌ها', icon: Icon(Icons.business_outlined)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummaryHeader(totalCustomerDebt, totalSellerDebt),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCustomerDebtList(),
                _buildSellerDebtList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(double totalDebt, double totalCredit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildHeaderItem(
                'طلب از مشتریان', 
                totalDebt, 
                Colors.blue.shade800, 
                Icons.arrow_downward, 
                Colors.blue.shade50
              )
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHeaderItem(
                'بدهی به شرکت‌ها', 
                totalCredit, 
                Colors.red.shade800, 
                Icons.arrow_upward, 
                Colors.red.shade50
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderItem(String label, double amount, Color color, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              "${AppFormatters.formatCurrency(amount)} تومان",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDebtList() {
    // لیست مشتریانی که بدهی دارند
    final clientsWithDebt = _customers.where((c) {
      final debt = _services.where((s) => s.customer?.id == c.id)
          .fold(0.0, (sum, s) => sum + s.remainingCustomerDebt);
      return debt > 0;
    }).toList();

    if (clientsWithDebt.isEmpty) return _buildEmptyState("مشتری بدهکاری یافت نشد");

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientsWithDebt.length,
      itemBuilder: (context, index) {
        final customer = clientsWithDebt[index];
        final debt = _services.where((s) => s.customer?.id == customer.id)
            .fold(0.0, (sum, s) => sum + s.remainingCustomerDebt);

        return _buildReportItem(
          title: customer.fullName,
          amount: debt,
          subtitle: "مشاهده صورت‌حساب و ثبت دریافتی",
          color: Colors.blue.shade900,
          icon: Icons.person,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CustomerLedgerScreen(customer: customer)),
            );
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildSellerDebtList() {
    final sellersWithDebt = _sellers.where((s) {
      final debt = _services.where((sel) => sel.seller.id == s.id)
          .fold(0.0, (sum, sel) => sum + sel.remainingDebtToSeller);
      return debt > 0;
    }).toList();

    if (sellersWithDebt.isEmpty) return _buildEmptyState("شرکت بدهکاری یافت نشد");

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sellersWithDebt.length,
      itemBuilder: (context, index) {
        final seller = sellersWithDebt[index];
        final debt = _services.where((sel) => sel.seller.id == seller.id)
            .fold(0.0, (sum, sel) => sum + sel.remainingDebtToSeller);
        
        return _buildReportItem(
          title: seller.name,
          amount: debt,
          subtitle: "مشاهده دفتر حساب و ثبت چک",
          color: Colors.red.shade900,
          icon: Icons.business,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SellerLedgerScreen(seller: seller)),
            );
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade200),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildReportItem({
    required String title,
    required double amount,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${AppFormatters.formatCurrency(amount)} تومان",
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
