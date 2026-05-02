import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  List<Payment> _allRelatedPayments = [];
  bool _isLoading = true;
  late TabController _tabController;
  final ServiceRepository _repository = ServiceRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); 
    _currentService = widget.service;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final allServices = await _repository.getAllServices();
    final allPayments = await _repository.getPayments();
    
    setState(() {
      _currentService = allServices.firstWhere((s) => s.id == _currentService.id);
      
      // اصلاح فیلتر: شامل تراکنش‌های مستقیم سرویس + تراکنش‌های کلی مشتری + تراکنش‌های کلی فروشنده
      _allRelatedPayments = allPayments.where((p) {
        bool isDirect = p.serviceId == _currentService.id;
        bool isGeneralCustomer = p.customerId != null && p.customerId == _currentService.customer?.id;
        bool isGeneralSeller = p.sellerId != null && p.sellerId == _currentService.seller.id;
        return isDirect || isGeneralCustomer || isGeneralSeller;
      }).toList();
      
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
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _editService();
              else if (value == 'delete') _confirmDeleteService();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('ویرایش سرویس')),
              const PopupMenuItem(value: 'delete', child: Text('حذف سرویس')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'اطلاعات'),
            Tab(text: 'هزینه‌ها'), 
            Tab(text: 'تراکنش‌ها'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildExpensesTab(), 
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

  Widget _buildExpensesTab() {
    final exp = _currentService.expenses;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildExpenseSection('هزینه‌های ثابت سرویس', [
          _buildInfoRow('هزینه بارنامه', "${AppFormatters.formatCurrency(exp.billOfLadingCost)} تومان"),
          _buildInfoRow('سوخت', "${AppFormatters.formatCurrency(exp.fuelCost)} تومان"),
          _buildInfoRow('عوارض', "${AppFormatters.formatCurrency(exp.tollCost)} تومان"),
          _buildInfoRow('انعام بارگیری', "${AppFormatters.formatCurrency(exp.loadingTip)} تومان"),
          _buildInfoRow('انعام تخلیه', "${AppFormatters.formatCurrency(exp.unloadingTip)} تومان"),
          _buildInfoRow('کمیسیون', "${AppFormatters.formatCurrency(exp.commission)} تومان"),
        ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('سایر هزینه‌ها و رسیدها', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            TextButton.icon(
              onPressed: _addExpenseToService,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('افزودن هزینه'),
            ),
          ],
        ),
        if (exp.otherExpenses.isNotEmpty)
          _buildExpenseSection('', 
            exp.otherExpenses.map((e) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.title, style: const TextStyle(fontSize: 14)),
              subtitle: Text("${AppFormatters.formatCurrency(e.amount)} تومان", style: const TextStyle(color: Colors.red)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (e.receiptImagePath != null)
                    IconButton(
                      icon: const Icon(Icons.receipt_long, color: Colors.blue),
                      onPressed: () => _showImageDialog(e.receiptImagePath!, 'تصویر رسید'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                    onPressed: () => _removeExpenseFromService(e),
                  ),
                ],
              ),
            )).toList()
          ),
        const Divider(height: 32),
        _buildInfoRow('جمع کل هزینه‌ها', "${AppFormatters.formatCurrency(exp.total)} تومان", isBold: true, color: Colors.red),
      ],
    );
  }

  Widget _buildExpenseSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const Divider(),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoSection('مشخصات', [
            _buildInfoRow('کد سفارش', _currentService.orderCode.toPersianDigit(), isBold: true),
            _buildInfoRow('مشتری', _currentService.customer?.fullName ?? 'ثبت نشده'),
            _buildInfoRow('نوع بار', _currentService.loadType.name),
            _buildInfoRow('وزن', "${_currentService.weight.toString().toPersianDigit()} تن"),
            _buildInfoRow('مسیر', "${_currentService.origin} به ${_currentService.destination}"),
            if (_currentService.logisticsCo != null)
              _buildInfoRow('باربری', _currentService.logisticsCo!.name),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('مالی و اطلاعات واریز', [
            _buildInfoRow('مجموع کرایه حمل', "${AppFormatters.formatCurrency(_currentService.totalTransportAmount)} تومان"),
            if (_currentService.purchasePricePerTon > 0) ...[
              _buildInfoRow('قیمت هر تن خرید', "${AppFormatters.formatCurrency(_currentService.purchasePricePerTon)} تومان"),
              _buildInfoRow('جمع کل خرید', "${AppFormatters.formatCurrency(_currentService.totalPurchaseAmount)} تومان"),
            ],
            const Divider(),
            if (_currentService.fareAccountNumber != null && _currentService.fareAccountNumber!.isNotEmpty) ...[
              const Text('اطلاعات حساب واریز کرایه:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              _buildInfoRow('شماره حساب/کارت', _currentService.fareAccountNumber!.toPersianDigit()),
              _buildInfoRow('صاحب حساب', _currentService.fareAccountOwner ?? "---"),
              _buildInfoRow('بانک', _currentService.fareBankName ?? "---"),
              const Divider(),
            ],
            _buildInfoRow('سود خالص سرویس', "${AppFormatters.formatCurrency(_currentService.netProfit)} تومان", isBold: true, color: Colors.green),
            if (_currentService.purchaseInvoiceImagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () => _showImageDialog(_currentService.purchaseInvoiceImagePath!, 'فاکتور خرید'),
                  icon: const Icon(Icons.receipt_outlined),
                  label: const Text('مشاهده فاکتور خرید'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    final customerPayments = _allRelatedPayments.where((p) => p.type == PaymentType.fromCustomer).toList();
    final sellerPayments = _allRelatedPayments.where((p) => p.type == PaymentType.toSeller).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPaymentListSection('تراکنش‌های مشتری', customerPayments, Colors.blue),
        const SizedBox(height: 24),
        if (_currentService.purchasePricePerTon > 0)
          _buildPaymentListSection('تراکنش‌های مربوط به فروشنده', sellerPayments, Colors.red),
      ],
    );
  }

  void _editService() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddServiceScreen(serviceToEdit: _currentService)));
    if (result == true) _refreshData();
  }

  Future<void> _confirmDeleteService() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سرویس'),
        content: const Text('آیا مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('حذف')),
        ],
      ),
    );
    if (res == true) {
      await _repository.deleteService(_currentService.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _showImageDialog(String path, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(title: Text(title), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
            Flexible(child: SingleChildScrollView(child: Image.file(File(path), fit: BoxFit.contain))),
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
            ListTile(leading: const Icon(Icons.add_chart, color: Colors.blue), title: const Text('دریافتی از مشتری'), onTap: () => _navToAddPayment(true)),
            if (_currentService.purchasePricePerTon > 0)
              ListTile(leading: const Icon(Icons.payments_outlined, color: Colors.red), title: const Text('پرداختی به فروشنده'), onTap: () => _navToAddPayment(false)),
            ListTile(leading: const Icon(Icons.receipt_long, color: Colors.orange), title: const Text('ثبت هزینه جانبی'), onTap: () {
              Navigator.pop(context);
              _addExpenseToService();
            }),
          ],
        ),
      ),
    );
  }

  void _addExpenseToService() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String? imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('افزودن هزینه جانبی'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان هزینه')),
              const SizedBox(height: 12),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ (تومان)')),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) setDialogState(() => imagePath = picked.path);
                },
                icon: const Icon(Icons.image_outlined),
                label: Text(imagePath == null ? 'انتخاب رسید' : 'رسید انتخاب شد'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  final newExpense = OtherExpense(
                    title: titleController.text,
                    amount: double.tryParse(amountController.text) ?? 0,
                    receiptImagePath: imagePath,
                  );
                  
                  _currentService.expenses.otherExpenses.add(newExpense);
                  await _repository.saveService(_currentService);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshData();
                  }
                }
              },
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeExpenseFromService(OtherExpense exp) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف هزینه'),
        content: Text('آیا از حذف "${exp.title}" مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('حذف')),
        ],
      ),
    );

    if (res == true) {
      _currentService.expenses.otherExpenses.remove(exp);
      await _repository.saveService(_currentService);
      _refreshData();
    }
  }

  void _navToAddPayment(bool isCollection) async {
    Navigator.pop(context);
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddPaymentScreen(service: _currentService, isCollection: isCollection)));
    if (result == true) _refreshData();
  }

  Widget _buildPaymentListSection(String title, List<Payment> payments, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (payments.isEmpty) const Text('تراکنشی ثبت نشده', style: TextStyle(color: Colors.grey, fontSize: 12))
        else ...payments.map((p) => Card(
          elevation: p.serviceId == _currentService.id ? 2 : 0, 
          color: p.serviceId == _currentService.id ? Colors.white : Colors.grey.shade50,
          child: ListTile(
            leading: Icon(
              p.method == PaymentMethod.check ? Icons.assignment : Icons.account_balance_wallet,
              color: color,
            ),
            title: Text("${AppFormatters.formatCurrency(p.amount)} تومان", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${p.date.toPersianDate()} - ${p.description ?? ''}"),
                if (p.method == PaymentMethod.check) ...[
                  Text("سررسید: ${p.checkDueDate?.toPersianDate()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orange)),
                  Text("بانک: ${p.bankName ?? ''} - ش: ${p.checkNumber ?? ''}", style: const TextStyle(fontSize: 10)),
                ],
                if (p.serviceId != _currentService.id)
                  const Text("(تراکنش کلی مربوط به طرف حساب)", style: TextStyle(fontSize: 9, color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
            trailing: p.receiptImagePath != null || p.checkImagePath != null 
              ? IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: () => _showImageDialog((p.receiptImagePath ?? p.checkImagePath)!, 'تصویر رسید/چک'),
                )
              : (p.method == PaymentMethod.check && !p.isCleared ? const Icon(Icons.pending, color: Colors.orange, size: 20) : null),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
      const Divider(), ...children,
    ])));
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
    ]));
  }
}
