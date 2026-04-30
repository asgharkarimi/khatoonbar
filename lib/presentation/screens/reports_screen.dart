import 'dart:io';
import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
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

  String _getTargetName(Payment p) {
    if (p.type == PaymentType.fromCustomer) {
      final c = _customers.firstWhere((c) => c.id == p.customerId, orElse: () => Customer(id: '', firstName: 'نامشخص', lastName: '', phone: ''));
      return c.fullName;
    } else {
      final s = _sellers.firstWhere((s) => s.id == p.sellerId, orElse: () => Seller(id: '', name: 'نامشخص', product: ''));
      return s.name;
    }
  }

  void _showImageDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.file(File(path), fit: BoxFit.cover),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    double totalCustomerBilling = _services.fold(0.0, (sum, s) => sum + s.totalServicePriceForCustomer);
    double totalCustomerCollected = _allPayments.where((p) => p.type == PaymentType.fromCustomer && p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
    double totalDriversProfit = _services.fold(0.0, (sum, s) => sum + s.netProfit);

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارشات و دفاتر حساب'),
        actions: [
          if (_tabController.index != 3)
            PopupMenuButton<AccountFilter>(
              icon: const Icon(Icons.filter_list),
              onSelected: (filter) => setState(() => _currentFilter = filter),
              itemBuilder: (context) => [
                const PopupMenuItem(value: AccountFilter.all, child: Text('همه موارد')),
                const PopupMenuItem(value: AccountFilter.inDebt, child: Text('فقط بدهکاران')),
                const PopupMenuItem(value: AccountFilter.settled, child: Text('فقط تسویه شده')),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.today_outlined),
              onPressed: () => setState(() {
                _selectedDate = Jalali.now();
                _viewMonth = Jalali.now();
              }),
              tooltip: 'امروز',
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(text: 'مشتریان', icon: Icon(Icons.group_outlined)),
            Tab(text: 'شرکت‌ها', icon: Icon(Icons.business_outlined)),
            Tab(text: 'رانندگان', icon: Icon(Icons.person_pin_outlined)),
            Tab(text: 'چک‌ها', icon: Icon(Icons.event_note_outlined)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index != 3) _buildFilterIndicator(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCustomerTab(totalCustomerBilling, totalCustomerCollected),
                _buildSellerTab(),
                _buildDriverTab(totalDriversProfit),
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
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
      color: Colors.grey.shade50, 
      child: Text("وضعیت نمایش: $label", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))
    );
  }

  Widget _buildChecksTab() {
    final allChecks = _allPayments.where((p) => p.method == PaymentMethod.check).toList();
    final dayChecks = allChecks.where((c) {
      if (c.checkDueDate == null) return false;
      final jDate = Jalali.fromDateTime(c.checkDueDate!);
      return jDate.year == _selectedDate.year && jDate.month == _selectedDate.month && jDate.day == _selectedDate.day;
    }).toList();

    return Column(
      children: [
        _buildCustomCalendar(allChecks),
        const Divider(height: 1),
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: Column(
              children: [
                _buildDayHeader(dayChecks.length),
                Expanded(
                  child: dayChecks.isEmpty
                      ? _buildEmptyState("در این تاریخ چکی ثبت نشده است")
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: dayChecks.length,
                          itemBuilder: (context, index) => _buildDetailedCheckItem(dayChecks[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomCalendar(List<Payment> allChecks) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => setState(() => _viewMonth = _viewMonth.addMonths(-1)), icon: const Icon(Icons.chevron_left, color: Colors.blueGrey)),
              Text("${_viewMonth.formatter.mN} ${_viewMonth.year}".toPersianDigit(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              IconButton(onPressed: () => setState(() => _viewMonth = _viewMonth.addMonths(1)), icon: const Icon(Icons.chevron_right, color: Colors.blueGrey)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'].map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 2, crossAxisSpacing: 2),
            itemCount: _viewMonth.monthLength + _viewMonth.copy(day: 1).weekDay - 1,
            itemBuilder: (context, index) {
              int dayOffset = _viewMonth.copy(day: 1).weekDay - 1;
              if (index < dayOffset) return const SizedBox();
              
              int day = index - dayOffset + 1;
              Jalali currentDay = _viewMonth.copy(day: day);
              bool isSelected = currentDay == _selectedDate;
              bool isToday = currentDay == Jalali.now();
              
              // اصلاح منطق تشخیص وجود چک برای دقت بیشتر
              bool hasCheck = allChecks.any((c) {
                if (c.checkDueDate == null) return false;
                final jCheckDate = Jalali.fromDateTime(c.checkDueDate!);
                return jCheckDate.year == currentDay.year && 
                       jCheckDate.month == currentDay.month && 
                       jCheckDate.day == currentDay.day;
              });
              
              bool hasIncoming = allChecks.any((c) => c.type == PaymentType.fromCustomer && !c.isCleared && c.checkDueDate != null && Jalali.fromDateTime(c.checkDueDate!) == currentDay);
              bool hasOutgoing = allChecks.any((c) => c.type == PaymentType.toSeller && !c.isCleared && c.checkDueDate != null && Jalali.fromDateTime(c.checkDueDate!) == currentDay);

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = currentDay),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : (isToday ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$day".toPersianDigit(), 
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white 
                              : (hasCheck ? Colors.amber.shade700 : (isToday ? Theme.of(context).primaryColor : Colors.black87)), 
                          fontSize: 14, 
                          fontWeight: isSelected || isToday || hasCheck ? FontWeight.bold : FontWeight.normal
                        )
                      ),
                      if (hasIncoming || hasOutgoing)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasIncoming) Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                              if (hasIncoming && hasOutgoing) const SizedBox(width: 2),
                              if (hasOutgoing) Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                            ],
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
            child: const Icon(Icons.calendar_month, size: 16, color: Colors.blueGrey),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedDate.formatFullDate(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
              Text(count > 0 ? "$count چک ثبت شده".toPersianDigit() : "بدون رویداد مالی", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCheckItem(Payment p) {
    final now = DateTime.now();
    final difference = p.checkDueDate!.difference(now).inDays;
    
    // نوار پیشرفت: هرچی نزدیک‌تر می‌شیم کمتر می‌شه (معکوس)
    double progress = (difference / 15.0).clamp(0.0, 1.0);
    
    Color color = Colors.green;
    if (difference <= 3) color = Colors.red;
    else if (difference <= 7) color = Colors.orange;

    bool isFromCustomer = p.type == PaymentType.fromCustomer;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: p.isCleared ? Colors.green.shade100 : Colors.white)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: p.isCleared ? Colors.green.shade50 : color.withOpacity(0.1),
                  child: Icon(isFromCustomer ? Icons.arrow_downward : Icons.arrow_upward, color: p.isCleared ? Colors.green : color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppFormatters.formatCurrency(p.amount) + " تومان", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: p.isCleared ? Colors.blueGrey : color)),
                      Text(_getTargetName(p), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (p.checkImagePath != null)
                  IconButton(onPressed: () => _showImageDialog(p.checkImagePath!), icon: const Icon(Icons.image_outlined, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 16),
            if (!p.isCleared) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(difference <= 0 ? "⚠️ امروز سررسید است" : "$difference روز تا سررسید".toPersianDigit(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                  Text("${(progress * 100).toInt()}% مانده".toPersianDigit(), style: TextStyle(fontSize: 10, color: color)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 10,
                ),
              ),
            ] else 
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text("این چک وصول شده است", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                _checkInfoTag(Icons.account_balance, p.bankName ?? '---'),
                const SizedBox(width: 8),
                _checkInfoTag(Icons.tag, p.checkNumber ?? '---'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkInfoTag(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(child: Text(text.toPersianDigit(), style: const TextStyle(fontSize: 10, color: Colors.black54, overflow: TextOverflow.ellipsis))),
          ],
        ),
      ),
    );
  }

  // --- تب‌های قدیمی (مشتریان، شرکت‌ها، رانندگان) ---

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
