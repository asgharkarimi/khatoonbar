import 'dart:io';
import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../core/data/service_repository.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_service.dart';
import '../../models/models.dart';
import 'add_payment_screen.dart';
import 'add_service_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final LoadService service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> with SingleTickerProviderStateMixin {
  late LoadService _currentService;
  bool _isLoading = true;
  late TabController _tabController;
  final ServiceRepository _repository = ServiceRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _currentService = widget.service;
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final allServices = await _repository.getAllServices();
    setState(() {
      _currentService = allServices.firstWhere((s) => s.id == _currentService.id);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات کامل سرویس'),
        actions: [
          IconButton(
            onPressed: () => PdfService.generateAndPrintService(_currentService),
            icon: const Icon(Icons.print),
            tooltip: 'چاپ فاکتور',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editService();
              } else if (value == 'delete') {
                _confirmDeleteService();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('ویرایش سرویس'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('حذف سرویس'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'اطلاعات بار'),
            Tab(text: 'لیست تراکنش‌ها'),
          ],
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildPaymentsTab(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentTypePicker(),
        label: const Text('ثبت تراکنش'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editService() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServiceScreen(serviceToEdit: _currentService),
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _confirmDeleteService() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سرویس'),
        content: const Text('آیا از حذف این سرویس و تمام تراکنش‌های آن مطمئن هستید؟ این عملیات غیرقابل بازگشت است.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('بله، حذف شود'),
          ),
        ],
      ),
    );

    if (res == true) {
      await _repository.deleteService(_currentService.id);
      if (mounted) {
        Navigator.pop(context, true); // بازگشت به لیست سرویس‌ها
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سرویس با موفقیت حذف شد'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoTab() {
    bool isTransportOnly = _currentService.purchasePricePerTon == 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoSection('مشخصات سرویس', [
            _buildInfoRow('کد سفارش', _currentService.orderCode.toPersianDigit(), isBold: true),
            _buildInfoRow('مشتری', _currentService.customer?.fullName ?? 'ثبت نشده'),
            _buildInfoRow('نوع بار', _currentService.loadType.name),
            _buildInfoRow('وزن', "${_currentService.weight.toString().toPersianDigit()} تن"),
            _buildInfoRow('مسیر', "${_currentService.origin} به ${_currentService.destination}"),
            _buildInfoRow('راننده', _currentService.driver.fullName),
            _buildInfoRow('ماشین', _currentService.car.name),
            _buildInfoRow('تاریخ', _currentService.date.toPersianDate()),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('محاسبات مالی', [
            _buildInfoRow('کرایه حمل (واحد)', "${AppFormatters.formatCurrency(_currentService.transportPricePerTon)} تومان"),
            if (!isTransportOnly)
              _buildInfoRow('قیمت خرید (واحد)', "${AppFormatters.formatCurrency(_currentService.purchasePricePerTon)} تومان"),
            const Divider(),
            _buildInfoRow('مجموع بدهی مشتری', "${AppFormatters.formatCurrency(_currentService.totalServicePriceForCustomer)} تومان", isBold: true, color: Colors.blue.shade900),
          ]),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    bool isTransportOnly = _currentService.purchasePricePerTon == 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFinanceSummaryCard(),
        const SizedBox(height: 20),
        _buildPaymentListSection('دریافتی‌ها از مشتری', _currentService.collectionsFromCustomer, Colors.blue),
        if (!isTransportOnly) ...[
          const SizedBox(height: 24),
          _buildPaymentListSection('پرداختی‌ها به فروشنده', _currentService.paymentsToSeller, Colors.red),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFinanceSummaryCard() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryMiniRow('مانده از مشتری:', _currentService.remainingCustomerDebt, Colors.blue.shade800),
            const SizedBox(height: 8),
            _buildSummaryMiniRow('مانده به فروشنده:', _currentService.remainingDebtToSeller, Colors.red.shade800),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMiniRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          amount <= 0 ? "تسویه شده" : "${AppFormatters.formatCurrency(amount)} تومان",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: amount <= 0 ? Colors.green : color
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentListSection(String title, List<Payment> payments, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, color: color),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        if (payments.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('تراکنشی یافت نشد', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ))
        else
          ...payments.map((p) => _buildPaymentCard(p)).toList(),
      ],
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    String? imagePath = payment.method == PaymentMethod.check ? payment.checkImagePath : payment.receiptImagePath;
    bool isPendingCheck = payment.method == PaymentMethod.check && !payment.isCleared;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isPendingCheck ? 0 : 1,
      color: isPendingCheck ? Colors.orange.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPendingCheck ? BorderSide(color: Colors.orange.shade200) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPendingCheck ? Colors.orange.shade100 : Colors.grey.shade100,
          child: Icon(_getMethodIcon(payment.method), 
            size: 18, 
            color: isPendingCheck ? Colors.orange.shade900 : Colors.grey.shade700
          ),
        ),
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              "${AppFormatters.formatCurrency(payment.amount)} تومان",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (isPendingCheck)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                child: const Text('در انتظار وصول', style: TextStyle(color: Colors.white, fontSize: 9)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${_getMethodName(payment.method)} - ${payment.date.toPersianDate()}", style: const TextStyle(fontSize: 11)),
            if (payment.method == PaymentMethod.check && payment.checkDueDate != null)
              Text("سررسید: ${payment.checkDueDate!.toPersianDate()}", 
                style: TextStyle(fontSize: 11, color: isPendingCheck ? Colors.deepOrange : Colors.grey)
              ),
            if (payment.description != null && payment.description!.isNotEmpty)
              Text(payment.description!, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPendingCheck)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
                tooltip: 'تأیید وصول چک',
                onPressed: () => _confirmClearance(payment),
              ),
            if (imagePath != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.image_outlined, color: Colors.blue, size: 20),
                onPressed: () => _showImageDialog(imagePath),
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              onPressed: () => _confirmDeletePayment(payment.id!),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearance(Payment payment) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید وصول چک'),
        content: Text('آیا مطمئن هستید که چک به مبلغ ${AppFormatters.formatCurrency(payment.amount)} تومان وصول شده است؟\nبا تأیید این مورد، مبلغ از بدهی کسر خواهد شد.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله، وصول شد')),
        ],
      ),
    );

    if (res == true) {
      final updatedPayment = Payment(
        id: payment.id,
        serviceId: payment.serviceId,
        sellerId: payment.sellerId,
        customerId: payment.customerId,
        type: payment.type,
        method: payment.method,
        amount: payment.amount,
        date: payment.date,
        description: payment.description,
        receiptImagePath: payment.receiptImagePath,
        checkDueDate: payment.checkDueDate,
        checkImagePath: payment.checkImagePath,
        isCleared: true,
      );

      await DatabaseHelper.instance.insertPayment(updatedPayment);
      _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وضعیت چک به وصول شده تغییر یافت'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _showImageDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('تصویر رسید/چک', style: TextStyle(fontSize: 16)),
              leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showPaymentTypePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_chart, color: Colors.blue),
              title: const Text('ثبت دریافتی از مشتری'),
              onTap: () => _navToAddPayment(true),
            ),
            if (_currentService.purchasePricePerTon > 0)
              ListTile(
                leading: const Icon(Icons.payments_outlined, color: Colors.red),
                title: const Text('ثبت پرداختی به فروشنده'),
                onTap: () => _navToAddPayment(false),
              ),
          ],
        ),
      ),
    );
  }

  void _navToAddPayment(bool isCollection) async {
    Navigator.pop(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPaymentScreen(service: _currentService, isCollection: isCollection),
      ),
    );
    if (result == true) _refreshData();
  }

  Future<void> _confirmDeletePayment(String id) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف تراکنش'),
        content: const Text('آیا مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (res == true) {
      await _repository.deletePayment(id);
      _refreshData();
    }
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Icons.money;
      case PaymentMethod.card: return Icons.credit_card;
      case PaymentMethod.check: return Icons.assignment;
      case PaymentMethod.sheba: return Icons.account_balance;
    }
  }

  String _getMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return "نقدی";
      case PaymentMethod.card: return "کارت به کارت";
      case PaymentMethod.check: return "چک";
      case PaymentMethod.sheba: return "شبا";
    }
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
