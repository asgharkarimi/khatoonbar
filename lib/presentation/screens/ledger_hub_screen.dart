import 'package:flutter/material.dart';
import '../../core/data/service_repository.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import 'customer_ledger_screen.dart';
import 'seller_ledger_screen.dart';
import 'logistics_ledger_screen.dart';
import 'driver_ledger_screen.dart';

class LedgerHubScreen extends StatefulWidget {
  final int initialTab;
  const LedgerHubScreen({super.key, this.initialTab = 0});

  @override
  State<LedgerHubScreen> createState() => _LedgerHubScreenState();
}

class _LedgerHubScreenState extends State<LedgerHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServiceRepository _repository = ServiceRepository();
  
  List<Customer> _customers = [];
  List<Seller> _sellers = [];
  List<LogisticsCo> _logisticsCos = [];
  List<Driver> _drivers = [];
  
  Map<String, double> _customerBalances = {};
  Map<String, double> _sellerBalances = {};
  Map<String, double> _logisticsBalances = {};
  Map<String, double> _driverBalances = {};
  
  List<Customer> _filteredCustomers = [];
  List<Seller> _filteredSellers = [];
  List<LogisticsCo> _filteredLogistics = [];
  List<Driver> _filteredDrivers = [];
  
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final customers = await _repository.getCustomers();
    final sellers = await _repository.getSellers();
    final logistics = await _repository.getLogisticsCos();
    final drivers = await _repository.getDrivers();
    
    // Fetch balances
    for (var c in customers) {
      _customerBalances[c.id] = await _repository.getCustomerBalance(c.id);
    }
    for (var s in sellers) {
      _sellerBalances[s.id] = await _repository.getSellerBalance(s.id);
    }
    for (var l in logistics) {
      _logisticsBalances[l.id] = await _repository.getLogisticsBalance(l.id);
    }
    for (var d in drivers) {
      // For drivers, balance is Profit - Paid
      final services = await _repository.getAllServices();
      final payments = await _repository.getPayments();
      final driverServices = services.where((s) => s.driver.id == d.id).toList();
      double totalEarned = driverServices.fold(0.0, (sum, s) => sum + s.netProfit);
      final driverServiceIds = driverServices.map((s) => s.id).toSet();
      final relevantPayments = payments.where((p) => p.type == PaymentType.toDriver && (p.driverId == d.id || (p.serviceId != null && driverServiceIds.contains(p.serviceId))));
      double totalPaid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
      double totalPending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
      _driverBalances[d.id] = totalEarned - totalPaid - totalPending;
    }
    
    setState(() {
      _customers = customers;
      _sellers = sellers;
      _logisticsCos = logistics;
      _drivers = drivers;
      _onSearchChanged(_searchController.text);
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      final q = query.toLowerCase();
      _filteredCustomers = _customers
          .where((c) => c.fullName.toLowerCase().contains(q) || c.village.toLowerCase().contains(q))
          .toList();
      _filteredSellers = _sellers
          .where((s) => s.name.toLowerCase().contains(q) || s.product.toLowerCase().contains(q))
          .toList();
      _filteredLogistics = _logisticsCos
          .where((l) => l.name.toLowerCase().contains(q))
          .toList();
      _filteredDrivers = _drivers
          .where((d) => d.fullName.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر حساب و مالی'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'مشتریان', icon: Icon(Icons.people)),
            Tab(text: 'فروشندگان', icon: Icon(Icons.storefront)),
            Tab(text: 'باربری‌ها', icon: Icon(Icons.business_outlined)),
            Tab(text: 'رانندگان', icon: Icon(Icons.person_pin)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'جستجو...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCustomerList(),
                      _buildSellerList(),
                      _buildLogisticsList(),
                      _buildDriverList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCustomerList() {
    if (_filteredCustomers.isEmpty) {
      return Center(child: Text(_searchController.text.isEmpty ? 'مشتری‌ای ثبت نشده است' : 'موردی یافت نشد'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        final balance = _customerBalances[customer.id] ?? 0;
        return _buildLedgerTile(
          title: customer.fullName,
          subtitle: customer.village.isNotEmpty ? "منطقه: ${customer.village}" : "بدون آدرس",
          icon: Icons.person,
          color: Colors.blue,
          amount: balance,
          amountLabel: "مانده طلب:",
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerLedgerScreen(customer: customer)));
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildSellerList() {
    if (_filteredSellers.isEmpty) {
      return Center(child: Text(_searchController.text.isEmpty ? 'فروشنده‌ای ثبت نشده است' : 'موردی یافت نشد'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSellers.length,
      itemBuilder: (context, index) {
        final seller = _filteredSellers[index];
        final balance = _sellerBalances[seller.id] ?? 0;
        return _buildLedgerTile(
          title: seller.name,
          subtitle: "محصول: ${seller.product}",
          icon: Icons.storefront,
          color: Colors.teal,
          amount: balance,
          amountLabel: "بدهی ما:",
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => SellerLedgerScreen(seller: seller)));
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildLogisticsList() {
    if (_filteredLogistics.isEmpty) {
      return Center(child: Text(_searchController.text.isEmpty ? 'باربری‌ای ثبت نشده است' : 'موردی یافت نشد'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredLogistics.length,
      itemBuilder: (context, index) {
        final logistics = _filteredLogistics[index];
        final balance = _logisticsBalances[logistics.id] ?? 0;
        return _buildLedgerTile(
          title: logistics.name,
          subtitle: "تلفن: ${logistics.phone}",
          icon: Icons.business_outlined,
          color: Colors.orange,
          amount: balance,
          amountLabel: "بدهی بارنامه:",
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => LogisticsLedgerScreen(logisticsCo: logistics)));
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildDriverList() {
    if (_filteredDrivers.isEmpty) {
      return Center(child: Text(_searchController.text.isEmpty ? 'راننده‌ای ثبت نشده است' : 'موردی یافت نشد'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDrivers.length,
      itemBuilder: (context, index) {
        final driver = _filteredDrivers[index];
        final balance = _driverBalances[driver.id] ?? 0;
        return _buildLedgerTile(
          title: driver.fullName,
          subtitle: "تلفن: ${driver.phone}",
          icon: Icons.person_pin,
          color: Colors.teal,
          amount: balance,
          amountLabel: "مانده طلب راننده:",
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => DriverLedgerScreen(driver: driver)));
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildLedgerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double amount,
    required String amountLabel,
    required VoidCallback onTap,
  }) {
    Color amountColor = amount > 0 ? Colors.red.shade800 : (amount < 0 ? Colors.green.shade800 : Colors.blueGrey);
    if (icon == Icons.person || icon == Icons.person_pin) { // For customers & drivers, positive balance is their claim
       amountColor = amount > 0 ? Colors.teal.shade800 : (amount < 0 ? Colors.red.shade800 : Colors.blueGrey);
       if (icon == Icons.person) amountColor = amount > 0 ? Colors.blue.shade800 : amountColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amountLabel, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            Text(
              amount == 0 ? "تسویه" : "${AppFormatters.formatCurrency(amount.abs())} تومان",
              style: TextStyle(fontWeight: FontWeight.bold, color: amountColor, fontSize: 13),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
