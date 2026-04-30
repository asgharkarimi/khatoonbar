import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_service.dart';
import '../../models/models.dart';
import 'add_payment_screen.dart';
import 'service_details_screen.dart';

class SellerLedgerScreen extends StatefulWidget {
  final Seller seller;
  const SellerLedgerScreen({super.key, required this.seller});

  @override
  State<SellerLedgerScreen> createState() => _SellerLedgerScreenState();
}

class _SellerLedgerScreenState extends State<SellerLedgerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LoadService> _services = [];
  List<Payment> _generalPayments = [];
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
    final allServices = await DatabaseHelper.instance.getAllServices();
    final allPayments = await DatabaseHelper.instance.getAllPayments();
    
    setState(() {
      _services = allServices.where((s) => s.seller.id == widget.seller.id).toList();
      _generalPayments = allPayments.where((p) => 
        p.sellerId == widget.seller.id || 
        _services.any((s) => s.id == p.serviceId)
      ).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalDebt = _services.fold(0, (sum, s) => sum + s.totalPurchaseAmount);
    double totalPaid = _generalPayments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);
    double balance = totalDebt - totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text("دفتر حساب: ${widget.seller.name}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => PdfService.generateAndPrintSellerLedger(widget.seller, _services, _generalPayments),
            tooltip: 'خروجی PDF',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "بارها (بدهی)", icon: Icon(Icons.local_shipping_outlined)),
            Tab(text: "پرداخت‌ها (بستانکاری)", icon: Icon(Icons.payments_outlined)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildBalanceHeader(totalDebt, totalPaid, balance),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildServicesList(),
                    _buildPaymentsList(),
                  ],
                ),
              ),
            ],
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPaymentScreen(
                service: _services.isNotEmpty ? _services.first : LoadService(
                  id: 'temp', 
                  orderCode: 'TEMP',
                  car: Car(id: '', name: '', plate: ''), 
                  driver: Driver(id: '', firstName: '', lastName: '', phone: ''), 
                  loadType: LoadType(id: '', name: ''), 
                  seller: widget.seller, 
                  origin: '', 
                  destination: '', 
                  date: DateTime.now(), 
                  weight: 0, 
                  transportPricePerTon: 0, 
                  expenses: ServiceExpenses()
                ),
                isCollection: false,
                customSellerId: widget.seller.id,
              ),
            ),
          );
          if (result == true) _loadData();
        },
        label: const Text("ثبت چک / پرداخت کلی"),
        icon: const Icon(Icons.add_card),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  Widget _buildBalanceHeader(double debt, double paid, double balance) {
    String statusLabel = "تسویه شده";
    if (balance > 0) {
      statusLabel = "مانده بدهی شما:";
    } else if (balance < 0) {
      statusLabel = "بستانکاری (طلب شما):";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Card(
        color: balance > 0 ? Colors.red.shade50 : (balance < 0 ? Colors.green.shade50 : Colors.blue.shade50),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: BorderSide(color: balance > 0 ? Colors.red.shade100 : (balance < 0 ? Colors.green.shade100 : Colors.blue.shade100))
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(statusLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "${AppFormatters.formatCurrency(balance.abs())} تومان",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: balance > 0 ? Colors.red.shade900 : (balance < 0 ? Colors.green.shade900 : Colors.blue.shade900), 
                      fontSize: 18
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _headerInfoItem("کل خرید", debt, Colors.black87),
                    const VerticalDivider(),
                    _headerInfoItem("کل پرداختی", paid, Colors.green.shade700),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerInfoItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(AppFormatters.formatCurrency(amount), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildServicesList() {
    if (_services.isEmpty) return _buildEmptyState("باری یافت نشد");
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) => _buildServiceTile(_services[index]),
    );
  }

  Widget _buildPaymentsList() {
    if (_generalPayments.isEmpty) return _buildEmptyState("تراکنشی یافت نشد");
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _generalPayments.length,
      itemBuilder: (context, index) => _buildPaymentTile(_generalPayments[index]),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildServiceTile(LoadService s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () async {
          final result = await Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => ServiceDetailsScreen(service: s))
          );
          if (result == true || result == null) _loadData();
        },
        title: Text("${s.loadType.name} - ${s.weight.toString().toPersianDigit()} تن", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(s.date.toPersianDate(), style: const TextStyle(fontSize: 11)),
              ],
            ),
            if (s.orderCode.isNotEmpty)
              Text("کد سفارش: ${s.orderCode}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          ],
        ),
        trailing: Text(
          AppFormatters.formatCurrency(s.totalPurchaseAmount),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildPaymentTile(Payment p) {
    bool isPendingCheck = p.method == PaymentMethod.check && !p.isCleared;
    int daysLeft = 0;
    double progress = 0;
    Color progressBarColor = Colors.green;

    if (isPendingCheck && p.checkDueDate != null) {
      daysLeft = p.checkDueDate!.difference(DateTime.now()).inDays;
      progress = 1.0 - (daysLeft / 15.0).clamp(0.0, 1.0);
      
      if (daysLeft <= 3) {
        progressBarColor = Colors.red;
      } else if (daysLeft <= 7) {
        progressBarColor = Colors.orange;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isPendingCheck ? Colors.orange.shade50.withValues(alpha: 0.5) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isPendingCheck ? progressBarColor.withValues(alpha: 0.3) : Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: isPendingCheck ? progressBarColor.withValues(alpha: 0.1) : Colors.green.shade100,
                child: Icon(
                  p.method == PaymentMethod.check ? Icons.assignment : Icons.account_balance_wallet, 
                  color: isPendingCheck ? progressBarColor : Colors.green
                ),
              ),
              title: Text("${AppFormatters.formatCurrency(p.amount)} تومان", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${p.date.toPersianDate()} ${p.description ?? ''}"),
                  if (p.method == PaymentMethod.check)
                    Text("سررسید: ${p.checkDueDate?.toPersianDate() ?? ''}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: isPendingCheck 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: progressBarColor, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          daysLeft <= 0 ? "امروز" : "$daysLeft روز مانده", 
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  )
                : const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
            if (isPendingCheck)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(progressBarColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
