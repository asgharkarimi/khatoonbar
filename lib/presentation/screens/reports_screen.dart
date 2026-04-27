import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../core/database/database_helper.dart'; 
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import 'seller_ledger_screen.dart';
import 'customer_ledger_screen.dart';

enum AccountFilter { all, inDebt, settled }

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
  List<Driver> _drivers = [];
  List<Payment> _allPayments = [];
  bool _isLoading = true;
  AccountFilter _currentFilter = AccountFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final drivers = await DatabaseHelper.instance.getAllDrivers();
      final payments = await DatabaseHelper.instance.getAllPayments();
      setState(() {
        _services = services;
        _sellers = sellers;
        _customers = customers;
        _drivers = drivers;
        _allPayments = payments;
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

    // محاسبات کلی
    double totalCustomerBilling = _services.fold(0.0, (sum, s) => sum + s.totalServicePriceForCustomer);
    double totalCustomerCollected = _allPayments.where((p) => p.type == PaymentType.fromCustomer && p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
    double totalDriversProfit = _services.fold(0.0, (sum, s) => sum + s.netProfit);

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارشات و دفاتر حساب'),
        actions: [
          PopupMenuButton<AccountFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) => setState(() => _currentFilter = filter),
            itemBuilder: (context) => [
              const PopupMenuItem(value: AccountFilter.all, child: Text('همه موارد')),
              const PopupMenuItem(value: AccountFilter.inDebt, child: Text('فقط بدهکاران')),
              const PopupMenuItem(value: AccountFilter.settled, child: Text('فقط تسویه شده')),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'مشتریان', icon: Icon(Icons.group_outlined)),
            Tab(text: 'شرکت‌ها', icon: Icon(Icons.business_outlined)),
            Tab(text: 'رانندگان', icon: Icon(Icons.person_pin_outlined)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterIndicator(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCustomerTab(totalCustomerBilling, totalCustomerCollected),
                _buildSellerTab(),
                _buildDriverTab(totalDriversProfit),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterIndicator() {
    String label = _currentFilter == AccountFilter.inDebt ? "فقط بدهکاران" : (_currentFilter == AccountFilter.settled ? "فقط تسویه شده" : "همه موارد");
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
      color: Colors.grey.shade50, 
      child: Text("وضعیت نمایش: $label", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))
    );
  }

  Widget _buildCustomerTab(double billing, double collected) {
    final filtered = _customers.where((c) {
      final debt = _services.where((s) => s.customer?.id == c.id).fold<double>(0.0, (sum, s) => sum + s.remainingCustomerDebt);
      if (_currentFilter == AccountFilter.inDebt) return debt > 0;
      if (_currentFilter == AccountFilter.settled) return debt <= 0 && _services.any((s) => s.customer?.id == c.id);
      return true;
    }).toList();

    return Column(
      children: [
        _buildMultiSummaryHeader(
          label: 'وضعیت کلی طلب از مشتریان',
          mainAmount: billing - collected,
          mainLabel: 'مانده طلب نهایی (بازار)',
          topAmount: billing,
          topLabel: 'کل مبلغ فاکتور شده',
          bottomAmount: collected,
          bottomLabel: 'کل مبلغ وصول شده',
          color: Colors.blue.shade800,
          bgColor: Colors.blue.shade50,
          icon: Icons.group_outlined,
        ),
        Expanded(
          child: filtered.isEmpty 
            ? _buildEmptyState("مشتری یافت نشد")
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final customer = filtered[index];
                  final debt = _services.where((s) => s.customer?.id == customer.id).fold<double>(0.0, (sum, s) => sum + s.remainingCustomerDebt);
                  return _buildReportItem(
                    title: customer.fullName,
                    amount: debt,
                    label: debt > 0 ? "بدهی مشتری" : "تسویه",
                    color: debt > 0 ? Colors.blue.shade900 : Colors.green.shade700,
                    icon: Icons.person,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerLedgerScreen(customer: customer)));
                      _loadData();
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildSellerTab() {
    final filtered = _sellers.where((s) {
      final debt = _services.where((sel) => sel.seller.id == s.id).fold<double>(0.0, (sum, sel) => sum + sel.remainingDebtToSeller);
      if (_currentFilter == AccountFilter.inDebt) return debt > 0;
      if (_currentFilter == AccountFilter.settled) return debt <= 0 && _services.any((sel) => sel.seller.id == s.id);
      return true;
    }).toList();

    return Expanded(
      child: filtered.isEmpty
        ? _buildEmptyState("شرکتی یافت نشد")
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final seller = filtered[index];
              final sellerServices = _services.where((s) => s.seller.id == seller.id).toList();
              
              double sellerBilling = sellerServices.fold(0.0, (sum, s) => sum + s.totalPurchaseAmount);
              double sellerPaid = _allPayments
                  .where((p) => (p.sellerId == seller.id || sellerServices.any((s) => s.id == p.serviceId)) && p.isCleared && p.type == PaymentType.toSeller)
                  .fold(0.0, (sum, p) => sum + p.amount);
              
              double balance = sellerBilling - sellerPaid;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
                child: ExpansionTile(
                  leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: const Icon(Icons.business, color: Colors.red, size: 20)),
                  title: Text(seller.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    balance > 0 ? "بدهی: ${AppFormatters.formatCurrency(balance)} تومان" : (balance < 0 ? "بستانکار: ${AppFormatters.formatCurrency(balance.abs())} تومان" : "تسویه شده"),
                    style: TextStyle(fontSize: 10, color: balance > 0 ? Colors.red.shade900 : (balance < 0 ? Colors.green.shade700 : Colors.blue.shade700)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow("کل مبلغ فاکتور شده (خرید)", sellerBilling, Colors.black87),
                          _buildDetailRow("کل مبلغ وصول شده (پرداخت)", sellerPaid, Colors.green.shade700),
                          const Divider(),
                          _buildDetailRow(
                            balance >= 0 ? "مانده بدهی نهایی" : "مانده بستانکاری نهایی", 
                            balance.abs(), 
                            balance >= 0 ? Colors.red.shade900 : Colors.green.shade900,
                            isBold: true
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => SellerLedgerScreen(seller: seller)));
                                _loadData();
                              },
                              icon: const Icon(Icons.list_alt, size: 16),
                              label: const Text("مشاهده دفتر حساب و ثبت چک", style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildDriverTab(double totalAmount) {
    final filteredDrivers = _drivers.where((d) {
      if (_currentFilter == AccountFilter.all) return true;
      final driverServices = _services.where((s) => s.driver.id == d.id).toList();
      return driverServices.isNotEmpty;
    }).toList();

    return Column(
      children: [
        _buildSingleSummaryHeader('مجموع درآمد خالص رانندگان', totalAmount, Colors.teal.shade800, Icons.account_balance_wallet, Colors.teal.shade50),
        Expanded(
          child: filteredDrivers.isEmpty
            ? _buildEmptyState("راننده‌ای یافت نشد")
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredDrivers.length,
                itemBuilder: (context, index) {
                  final driver = filteredDrivers[index];
                  final driverServices = _services.where((s) => s.driver.id == driver.id).toList();
                  final totalNetIncome = driverServices.fold(0.0, (sum, s) => sum + s.netProfit);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
                    child: ExpansionTile(
                      leading: CircleAvatar(backgroundColor: Colors.teal.shade50, child: const Icon(Icons.person, color: Colors.teal, size: 20)),
                      title: Text(driver.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text("مجموع درآمد: ${AppFormatters.formatCurrency(totalNetIncome)} تومان", style: TextStyle(fontSize: 10, color: Colors.teal.shade700)),
                      children: driverServices.map((s) => _buildDriverServiceDetail(s)).toList(),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, double amount, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          Text(
            "${AppFormatters.formatCurrency(amount)} تومان",
            style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSummaryHeader({
    required String label,
    required double mainAmount,
    required String mainLabel,
    required double topAmount,
    required String topLabel,
    required double bottomAmount,
    required String bottomLabel,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: _buildHeaderSubItem(topLabel, topAmount, Colors.black87)),
                Container(height: 30, width: 1, color: color.withOpacity(0.2)),
                Expanded(child: _buildHeaderSubItem(bottomLabel, bottomAmount, Colors.green.shade700)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text(mainLabel, style: TextStyle(fontSize: 10, color: color)),
                  const SizedBox(height: 4),
                  Text(
                    "${AppFormatters.formatCurrency(mainAmount)} تومان",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSubItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(AppFormatters.formatCurrency(amount), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildDriverServiceDetail(LoadService s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade50))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${s.loadType.name} (${s.orderCode})", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text(s.date.toPersianDate(), style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
          Text(
            "${AppFormatters.formatCurrency(s.netProfit)} تومان",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSummaryHeader(String label, double amount, Color color, IconData icon, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${AppFormatters.formatCurrency(amount)} تومان",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem({required String title, required double amount, required String label, required Color color, required IconData icon, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(label, style: TextStyle(fontSize: 10, color: color)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              amount == 0 ? "تسویه" : "${AppFormatters.formatCurrency(amount)} تومان",
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
