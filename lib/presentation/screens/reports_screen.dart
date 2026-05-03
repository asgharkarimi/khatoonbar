import 'dart:io';
import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../core/database/database_helper.dart'; 
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_service.dart';
import '../../models/models.dart';
import 'seller_ledger_screen.dart';
import 'customer_ledger_screen.dart';
import 'logistics_ledger_screen.dart';
import 'driver_ledger_screen.dart';

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
  List<Car> _cars = [];
  List<LogisticsCo> _logisticsCos = [];
  List<Payment> _allPayments = [];
  List<Maintenance> _maintenances = [];
  List<CarExpense> _carExpenses = [];
  
  bool _isLoading = true;
  AccountFilter _currentFilter = AccountFilter.all;
  
  Jalali _selectedDate = Jalali.now();
  Jalali _viewMonth = Jalali.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
      final cars = await DatabaseHelper.instance.getAllCars();
      final logistics = await DatabaseHelper.instance.getAllLogisticsCos();
      final payments = await DatabaseHelper.instance.getAllPayments();
      final maintenance = await DatabaseHelper.instance.getAllMaintenances();
      final carExpenses = await DatabaseHelper.instance.getAllCarExpenses();
      
      setState(() {
        _services = services;
        _sellers = sellers;
        _customers = customers;
        _drivers = drivers;
        _cars = cars;
        _logisticsCos = logistics;
        _allPayments = payments;
        _maintenances = maintenance;
        _carExpenses = carExpenses;
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

  void _exportToPdf() async {
    String title = "";
    List<String> headers = [];
    List<List<String>> data = [];

    if (_tabController.index == 0) {
      title = "گزارش وضعیت حساب مشتریان";
      headers = ["ردیف", "نام مشتری", "مانده بدهی نهایی"];
      int i = 1;
      for (var c in _customers) {
        final customerServices = _services.where((s) => s.customer?.id == c.id).toList();
        final debt = customerServices.fold<double>(0.0, (sum, s) => sum + s.finalBalanceCustomerDebt);
        if (_currentFilter == AccountFilter.inDebt && debt <= 0) continue;
        if (_currentFilter == AccountFilter.settled && (debt > 0 || customerServices.isEmpty)) continue;
        data.add([(i++).toString().toPersianDigit(), c.fullName, AppFormatters.formatCurrency(debt)]);
      }
    } else if (_tabController.index == 1) {
      title = "گزارش وضعیت حساب با فروشندگان";
      headers = ["ردیف", "نام فروشنده", "مانده بدهی ما"];
      int i = 1;
      for (var s in _sellers) {
        final sellerServices = _services.where((sel) => sel.seller.id == s.id).toList();
        double billing = sellerServices.fold(0.0, (sum, ser) => sum + ser.totalPurchaseAmount);
        final relevantPayments = _allPayments.where((p) => p.type == PaymentType.toSeller && (p.sellerId == s.id || (p.serviceId != null && sellerServices.any((ser) => ser.id == p.serviceId))));
        double paid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
        double pending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
        double balance = billing - paid - pending;
        if (_currentFilter == AccountFilter.inDebt && balance <= 0) continue;
        if (_currentFilter == AccountFilter.settled && balance != 0) continue;
        data.add([(i++).toString().toPersianDigit(), s.name, AppFormatters.formatCurrency(balance)]);
      }
    } else if (_tabController.index == 2) {
      title = "گزارش طلب رانندگان";
      headers = ["ردیف", "نام راننده", "مانده طلب"];
      int i = 1;
      for (var d in _drivers) {
        final driverServices = _services.where((s) => s.driver.id == d.id).toList();
        double earned = driverServices.fold(0.0, (sum, s) => sum + s.netProfit);
        final relevantPayments = _allPayments.where((p) => p.type == PaymentType.toDriver && (p.driverId == d.id || (p.serviceId != null && driverServices.any((s) => s.id == p.serviceId))));
        double paid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
        double pending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
        double balance = earned - paid - pending;
        data.add([(i++).toString().toPersianDigit(), d.fullName, AppFormatters.formatCurrency(balance)]);
      }
    } else if (_tabController.index == 3) {
      title = "لیست چک‌های تاریخ ${_selectedDate.formatFullDate()}";
      headers = ["ردیف", "طرف حساب", "مبلغ", "نوع", "وضعیت"];
      final dayChecks = _allPayments.where((p) => p.method == PaymentMethod.check && p.checkDueDate != null && Jalali.fromDateTime(p.checkDueDate!) == _selectedDate).toList();
      int i = 1;
      for (var c in dayChecks) {
        data.add([(i++).toString().toPersianDigit(), _getTargetName(c), AppFormatters.formatCurrency(c.amount), _getPaymentTypeLabel(c.type), c.isCleared ? "وصول شده" : "در انتظار"]);
      }
    }

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("دیتایی برای گزارش‌گیری در این فیلتر وجود ندارد")));
      return;
    }

    bool success = await PdfService.generateAndPrintGeneralReport(title, headers, data);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("خطا در تولید فایل PDF.")));
    }
  }

  String _getPaymentTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.fromCustomer: return "دریافتی";
      case PaymentType.toSeller: return "پرداخت فروشنده";
      case PaymentType.toLogistics: return "پرداخت باربری";
      case PaymentType.toDriver: return "پرداخت راننده";
    }
  }

  String _getTargetName(Payment p) {
    if (p.type == PaymentType.fromCustomer) {
      final c = _customers.firstWhere((c) => c.id == p.customerId, orElse: () => Customer(id: '', firstName: 'نامشخص', lastName: '', phone: ''));
      return c.fullName;
    } else if (p.type == PaymentType.toSeller) {
      final s = _sellers.firstWhere((s) => s.id == p.sellerId, orElse: () => Seller(id: '', name: 'نامشخص', product: ''));
      return s.name;
    } else if (p.type == PaymentType.toLogistics) {
      final l = _logisticsCos.firstWhere((l) => l.id == p.logisticsId, orElse: () => LogisticsCo(id: '', name: 'نامشخص', phone: ''));
      return l.name;
    } else {
      final d = _drivers.firstWhere((d) => d.id == p.driverId, orElse: () => Driver(id: '', firstName: 'نامشخص', lastName: '', phone: ''));
      return d.fullName;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارشات و دفاتر حساب'),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: _exportToPdf, tooltip: 'خروجی گزارش PDF'),
          if (_tabController.index < 2)
            PopupMenuButton<AccountFilter>(
              icon: const Icon(Icons.filter_list),
              onSelected: (filter) => setState(() => _currentFilter = filter),
              itemBuilder: (context) => [
                const PopupMenuItem(value: AccountFilter.all, child: Text('همه موارد')),
                const PopupMenuItem(value: AccountFilter.inDebt, child: Text('فقط بدهکاران')),
                const PopupMenuItem(value: AccountFilter.settled, child: Text('فقط تسویه شده')),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'مشتریان', icon: Icon(Icons.group_outlined)),
            Tab(text: 'فروشندگان', icon: Icon(Icons.storefront_outlined)),
            Tab(text: 'رانندگان', icon: Icon(Icons.person_pin_outlined)),
            Tab(text: 'چک‌ها', icon: Icon(Icons.event_note_outlined)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index < 2) _buildFilterIndicator(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCustomerTab(),
                _buildSellerTab(),
                _buildDriverTab(),
                _buildChecksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterIndicator() {
    String label = _currentFilter == AccountFilter.inDebt ? "فقط بدهکاران" : (_currentFilter == AccountFilter.settled ? "فقط تسویه شده" : "همه موارد");
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.grey.shade50, child: Text("وضعیت نمایش: $label", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)));
  }

  Widget _buildCustomerTab() {
    final filtered = _customers.where((c) {
      final customerServices = _services.where((s) => s.customer?.id == c.id).toList();
      final debt = customerServices.fold<double>(0.0, (sum, s) => sum + s.finalBalanceCustomerDebt);
      if (_currentFilter == AccountFilter.inDebt) return debt > 0;
      if (_currentFilter == AccountFilter.settled) return debt <= 0 && customerServices.isNotEmpty;
      return true;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final customer = filtered[index];
        final customerServices = _services.where((s) => s.customer?.id == customer.id).toList();
        final debt = customerServices.fold<double>(0.0, (sum, s) => sum + s.finalBalanceCustomerDebt);
        return _buildReportItem(title: customer.fullName, amount: debt, label: debt > 0 ? "مانده بدهی نهایی" : "تسویه", color: debt > 0 ? Colors.blue.shade900 : Colors.green.shade700, icon: Icons.person, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerLedgerScreen(customer: customer))); _loadData(); });
      },
    );
  }

  Widget _buildSellerTab() {
    final filtered = _sellers.where((s) {
      final sellerServices = _services.where((sel) => sel.seller.id == s.id).toList();
      double billing = sellerServices.fold(0.0, (sum, ser) => sum + ser.totalPurchaseAmount);
      final relevantPayments = _allPayments.where((p) => p.type == PaymentType.toSeller && (p.sellerId == s.id || (p.serviceId != null && sellerServices.any((ser) => ser.id == p.serviceId))));
      double paid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
      double pending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
      double balance = billing - paid - pending;
      if (_currentFilter == AccountFilter.inDebt) return balance > 0;
      if (_currentFilter == AccountFilter.settled) return balance <= 0 && sellerServices.isNotEmpty;
      return true;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final seller = filtered[index];
        final sellerServices = _services.where((s) => s.seller.id == seller.id).toList();
        double billing = sellerServices.fold(0.0, (sum, s) => sum + s.totalPurchaseAmount);
        final relevantPayments = _allPayments.where((p) => p.type == PaymentType.toSeller && (p.sellerId == seller.id || (p.serviceId != null && sellerServices.any((s) => s.id == p.serviceId))));
        double paid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
        double pending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
        double balance = billing - paid - pending;

        return _buildReportItem(title: seller.name, amount: balance, label: balance > 0 ? "بدهی ما به فروشنده" : "تسویه", color: balance > 0 ? Colors.red.shade900 : Colors.green.shade700, icon: Icons.storefront, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => SellerLedgerScreen(seller: seller))); _loadData(); });
      },
    );
  }

  Widget _buildDriverTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _drivers.length,
      itemBuilder: (context, index) {
        final driver = _drivers[index];
        final driverServices = _services.where((s) => s.driver.id == driver.id).toList();
        final totalNetIncome = driverServices.fold(0.0, (sum, s) => sum + s.netProfit);
        
        final relevantPayments = _allPayments.where((p) => p.type == PaymentType.toDriver && (p.driverId == driver.id || (p.serviceId != null && driverServices.any((s) => s.id == p.serviceId))));
        double paid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
        double pending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
        double balance = totalNetIncome - paid - pending;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(backgroundColor: Colors.teal.shade50, child: const Icon(Icons.person, color: Colors.teal, size: 20)),
            title: Text(driver.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text("مانده طلب راننده: ${AppFormatters.formatCurrency(balance)} تومان", style: TextStyle(fontSize: 10, color: balance >= 0 ? Colors.teal.shade700 : Colors.red.shade700)),
            children: [
              ...driverServices.map((s) => ListTile(
                title: Text("${s.loadType.name} (${s.orderCode.toPersianDigit()})", style: const TextStyle(fontSize: 11)),
                trailing: Text(AppFormatters.formatCurrency(s.netProfit), style: const TextStyle(fontSize: 11, color: Colors.green)),
              )),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => DriverLedgerScreen(driver: driver)));
                    _loadData();
                  },
                  child: const Text("مشاهده دفتر حساب راننده", style: TextStyle(fontSize: 11)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildChecksTab() {
    final allChecks = _allPayments.where((p) => p.method == PaymentMethod.check).toList();
    final dayChecks = allChecks.where((c) => c.checkDueDate != null && Jalali.fromDateTime(c.checkDueDate!) == _selectedDate).toList();

    return Column(
      children: [
        _buildCustomCalendar(allChecks),
        Expanded(
          child: dayChecks.isEmpty
              ? const Center(child: Text("چکی در این تاریخ یافت نشد"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayChecks.length,
                  itemBuilder: (context, index) => _buildCheckItem(dayChecks[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildCustomCalendar(List<Payment> allChecks) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => setState(() => _viewMonth = _viewMonth.addMonths(-1)), icon: const Icon(Icons.chevron_left)),
              Text("${_viewMonth.formatter.mN} ${_viewMonth.year}".toPersianDigit(), style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => setState(() => _viewMonth = _viewMonth.addMonths(1)), icon: const Icon(Icons.chevron_right)),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: _viewMonth.monthLength + _viewMonth.copy(day: 1).weekDay - 1,
            itemBuilder: (context, index) {
              int dayOffset = _viewMonth.copy(day: 1).weekDay - 1;
              if (index < dayOffset) return const SizedBox();
              int day = index - dayOffset + 1;
              Jalali currentDay = _viewMonth.copy(day: day);
              bool isSelected = currentDay == _selectedDate;
              bool hasCheck = allChecks.any((c) => c.checkDueDate != null && Jalali.fromDateTime(c.checkDueDate!) == currentDay);

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = currentDay),
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : (hasCheck ? Colors.orange.shade50 : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: hasCheck ? Border.all(color: Colors.orange.shade200) : null,
                  ),
                  child: Text("$day".toPersianDigit(), style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : null)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(Payment p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(AppFormatters.formatCurrency(p.amount) + " تومان"),
        subtitle: Text("${_getPaymentTypeLabel(p.type)} - ${_getTargetName(p)}"),
        trailing: Icon(p.isCleared ? Icons.check_circle : Icons.pending, color: p.isCleared ? Colors.green : Colors.orange),
      ),
    );
  }

  Widget _buildReportItem({required String title, required double amount, required String label, required Color color, required IconData icon, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(label, style: TextStyle(fontSize: 10, color: color)),
        trailing: Text(
          amount == 0 ? "تسویه" : "${AppFormatters.formatCurrency(amount.abs())} تومان",
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
        ),
      ),
    );
  }
}
