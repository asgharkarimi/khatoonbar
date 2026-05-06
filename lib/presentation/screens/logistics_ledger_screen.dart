import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_service.dart';
import '../../models/models.dart';
import 'add_payment_screen.dart';
import 'bulk_logistics_settlement_screen.dart';
import 'service_details_screen.dart';

class LogisticsLedgerScreen extends StatefulWidget {
  final LogisticsCo logisticsCo;
  const LogisticsLedgerScreen({super.key, required this.logisticsCo});

  @override
  State<LogisticsLedgerScreen> createState() => _LogisticsLedgerScreenState();
}

class _LogisticsLedgerScreenState extends State<LogisticsLedgerScreen> with SingleTickerProviderStateMixin {
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
      _services = allServices.where((s) => s.logisticsCo?.id == widget.logisticsCo.id).toList();
      
      final logisticsServiceIds = _services.map((s) => s.id).toSet();
      final filteredPayments = allPayments.where((p) => 
        p.type == PaymentType.toLogistics && (
          p.logisticsId == widget.logisticsCo.id || 
          (p.serviceId != null && logisticsServiceIds.contains(p.serviceId))
        )
      ).toList();

      final Map<String, Payment> uniquePayments = {};
      for (var p in filteredPayments) {
        if (p.id != null) {
          uniquePayments[p.id!] = p;
        }
      }
      
      _generalPayments = uniquePayments.values.toList();
      _generalPayments.sort((a, b) => b.date.compareTo(a.date));
      _isLoading = false;
    });
  }

  Future<void> _toggleCheckStatus(Payment p) async {
    final updatedPayment = Payment(
      id: p.id,
      serviceId: p.serviceId,
      sellerId: p.sellerId,
      customerId: p.customerId,
      logisticsId: p.logisticsId,
      myAccountId: p.myAccountId,
      type: p.type,
      method: p.method,
      amount: p.amount,
      date: p.date,
      description: p.description,
      receiptImagePath: p.receiptImagePath,
      checkDueDate: p.checkDueDate,
      checkImagePath: p.checkImagePath,
      bankName: p.bankName,
      checkNumber: p.checkNumber,
      isCleared: !p.isCleared,
    );

    await DatabaseHelper.instance.insertPayment(updatedPayment);
    _loadData();
  }

  Future<void> _deletePayment(String id) async {
    await DatabaseHelper.instance.delete('payments', id);
    _loadData();
  }

  void _showImageDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(title: const Text('تصویر تراکنش'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
            Flexible(child: SingleChildScrollView(child: Image.file(File(path), fit: BoxFit.contain))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalDebt = _services.fold(0, (sum, s) => sum + s.expenses.owedToLogistics);
    double totalPaid = _generalPayments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);
    double pendingChecks = _generalPayments.where((p) => p.method == PaymentMethod.check && !p.isCleared).fold(0, (sum, p) => sum + p.amount);
    double balance = totalDebt - totalPaid - pendingChecks;

    return Scaffold(
      appBar: AppBar(
        title: Text("صورت‌حساب باربری: ${widget.logisticsCo.name}"),
        actions: [
          if (widget.logisticsCo.accountNumber != null && widget.logisticsCo.accountNumber!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.logisticsCo.accountNumber!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("شماره حساب باربری کپی شد")));
              },
              tooltip: 'کپی شماره حساب',
            ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BulkLogisticsSettlementScreen(initialLogisticsCo: widget.logisticsCo))
              );
              if (result == true) _loadData();
            },
            tooltip: 'تسویه گروهی',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => PdfService.generateAndPrintLogisticsLedger(widget.logisticsCo, _services, _generalPayments),
            tooltip: 'خروجی PDF',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "سرویس‌ها (بدهی ما)", icon: Icon(Icons.history_outlined)),
            Tab(text: "پرداختی‌های ما", icon: Icon(Icons.payments_outlined)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildBalanceHeader(totalDebt, totalPaid, pendingChecks, balance),
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
                  seller: Seller(id: '', name: '', product: ''), 
                  origin: '', 
                  destination: '', 
                  date: DateTime.now(), 
                  weight: 0, 
                  transportPricePerTon: 0, 
                  expenses: ServiceExpenses()
                ),
                isCollection: false,
                customLogisticsId: widget.logisticsCo.id,
              ),
            ),
          );
          if (result == true) _loadData();
        },
        label: const Text("ثبت پرداختی جدید"),
        icon: const Icon(Icons.add_card),
        backgroundColor: Colors.orange.shade800,
      ),
    );
  }

  Widget _buildBalanceHeader(double debt, double paid, double checks, double balance) {
    String statusLabel = "مانده بدهی نهایی ما:";
    if (balance <= 0) {
      statusLabel = "تسویه شده / بستانکار:";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Card(
        color: balance > 0 ? Colors.orange.shade50 : (balance < 0 ? Colors.green.shade50 : Colors.blue.shade50),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: BorderSide(color: balance > 0 ? Colors.orange.shade100 : (balance < 0 ? Colors.green.shade100 : Colors.blue.shade100))
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
                      color: balance > 0 ? Colors.orange.shade900 : (balance < 0 ? Colors.green.shade900 : Colors.blue.shade900), 
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
                    _headerInfoItem("کل هزینه بارنامه", debt, Colors.black87),
                    const VerticalDivider(),
                    _headerInfoItem("پرداخت شده", paid, Colors.green.shade700),
                    const VerticalDivider(),
                    _headerInfoItem("چک معلق", checks, Colors.orange.shade800),
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
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(AppFormatters.formatCurrency(amount), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildServicesList() {
    if (_services.isEmpty) return _buildEmptyState("سرویسی یافت نشد");
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
    final remaining = s.remainingLogisticsDebt;
    final isSettled = s.isLogisticsSettled;

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
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(isSettled ? Icons.check_circle : Icons.pending_outlined, size: 12, color: isSettled ? Colors.green : Colors.orange),
                const SizedBox(width: 4),
                Text(
                  isSettled ? "تسویه کامل" : "مانده بدهی: ${AppFormatters.formatCurrency(remaining)}",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSettled ? Colors.green : Colors.orange.shade800),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatters.formatCurrency(s.expenses.owedToLogistics),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const Text("بارنامه + کمیسیون", style: TextStyle(fontSize: 9, color: Colors.grey)),
          ],
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
      color: isPendingCheck ? Colors.orange.shade50.withOpacity(0.5) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isPendingCheck ? progressBarColor.withOpacity(0.3) : Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              onLongPress: () => _showPaymentOptions(p),
              leading: CircleAvatar(
                backgroundColor: isPendingCheck ? progressBarColor.withOpacity(0.1) : Colors.green.shade100,
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.receiptImagePath != null || p.checkImagePath != null)
                    IconButton(icon: const Icon(Icons.image_outlined, color: Colors.blueGrey), onPressed: () => _showImageDialog((p.receiptImagePath ?? p.checkImagePath)!)),
                  if (isPendingCheck)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: progressBarColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        daysLeft <= 0 ? "امروز" : "$daysLeft روز", 
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
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

  void _showPaymentOptions(Payment p) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.method == PaymentMethod.check)
              ListTile(
                leading: Icon(p.isCleared ? Icons.history : Icons.check_circle, color: Colors.blue),
                title: Text(p.isCleared ? "تغییر وضعیت به در جریان" : "تایید وصول چک"),
                onTap: () {
                  Navigator.pop(context);
                  _toggleCheckStatus(p);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("حذف کامل این تراکنش"),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(p);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(Payment p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("حذف تراکنش"),
        content: const Text("آیا از حذف دائمی این تراکنش اطمینان دارید؟ این عمل قابل بازگشت نیست."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("انصراف")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (p.id != null) _deletePayment(p.id!);
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("حذف نهایی")
          ),
        ],
      ),
    );
  }
}
