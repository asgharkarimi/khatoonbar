import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../widgets/amount_input.dart';

class AddPaymentScreen extends StatefulWidget {
  final LoadService service;
  final bool isCollection;
  final String? customSellerId;
  final String? customCustomerId;
  final String? customLogisticsId;
  final String? customDriverId;

  const AddPaymentScreen({
    super.key,
    required this.service,
    required this.isCollection,
    this.customSellerId,
    this.customCustomerId,
    this.customLogisticsId,
    this.customDriverId,
  });

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _checkNumberController = TextEditingController();
  
  double _amount = 0;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  DateTime? _checkDueDate;
  String? _imagePath;
  bool _isCleared = true; 
  final ImagePicker _picker = ImagePicker();

  List<BankAccount> _myBankAccounts = [];
  BankAccount? _selectedMyAccount;
  bool _isLoading = true;

  double _overallDebt = 0;
  double _overallPaid = 0;
  double _overallPending = 0;
  bool _isStatsLoading = false;

  dynamic _targetObject; // Can be Seller, Customer, LogisticsCo, or Driver

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _autoFillCheckBankInfo();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final accounts = await DatabaseHelper.instance.getAllBankAccounts();
    await _loadFinanceStats();
    await _identifyTarget();
    setState(() {
      _myBankAccounts = accounts;
      _isLoading = false;
    });
  }

  Future<void> _identifyTarget() async {
    if (widget.customSellerId != null) {
      final sellers = await DatabaseHelper.instance.getAllSellers();
      _targetObject = sellers.firstWhere((s) => s.id == widget.customSellerId);
    } else if (widget.customCustomerId != null) {
      final customers = await DatabaseHelper.instance.getAllCustomers();
      _targetObject = customers.firstWhere((c) => c.id == widget.customCustomerId);
    } else if (widget.customLogisticsId != null) {
      final logistics = await DatabaseHelper.instance.getAllLogisticsCos();
      _targetObject = logistics.firstWhere((l) => l.id == widget.customLogisticsId);
    } else if (widget.customDriverId != null) {
      final drivers = await DatabaseHelper.instance.getAllDrivers();
      _targetObject = drivers.firstWhere((d) => d.id == widget.customDriverId);
    } else {
      _targetObject = widget.isCollection ? widget.service.customer : widget.service.seller;
    }
  }

  void _autoFillCheckBankInfo() {
    if (widget.customLogisticsId != null) {
      _bankNameController.text = widget.service.logisticsCo?.bankName ?? "";
    } else if (widget.customDriverId != null) {
      _bankNameController.text = widget.service.driver.bankName ?? "";
    } else if (!widget.isCollection) {
      _bankNameController.text = widget.service.seller.bankName ?? "";
    } else {
      _bankNameController.text = widget.service.customer?.bankName ?? "";
    }
  }

  Future<void> _loadFinanceStats() async {
    setState(() => _isStatsLoading = true);
    final allServices = await DatabaseHelper.instance.getAllServices();
    final allPayments = await DatabaseHelper.instance.getAllPayments();

    double debt = 0;
    double paid = 0;
    double pending = 0;

    if (widget.customSellerId != null) {
      final sellerServices = allServices.where((s) => s.seller.id == widget.customSellerId).toList();
      debt = sellerServices.fold(0.0, (sum, s) => sum + s.totalPurchaseAmount);
      final relevantPayments = allPayments.where((p) => p.type == PaymentType.toSeller && (p.sellerId == widget.customSellerId || (p.serviceId != null && sellerServices.any((s) => s.id == p.serviceId))));
      paid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
      pending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
    } else if (widget.customCustomerId != null) {
      final customerServices = allServices.where((s) => s.customer?.id == widget.customCustomerId).toList();
      debt = customerServices.fold(0.0, (sum, s) => sum + s.totalServicePriceForCustomer);
      final relevantPayments = allPayments.where((p) => p.type == PaymentType.fromCustomer && (p.customerId == widget.customCustomerId || (p.serviceId != null && customerServices.any((s) => s.id == p.serviceId))));
      paid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
      pending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
    } else if (widget.customLogisticsId != null) {
      final logisticsServices = allServices.where((s) => s.logisticsCo?.id == widget.customLogisticsId).toList();
      debt = logisticsServices.fold(0.0, (sum, s) => sum + s.expenses.owedToLogistics);
      final relevantPayments = allPayments.where((p) => p.type == PaymentType.toLogistics && (p.logisticsId == widget.customLogisticsId || (p.serviceId != null && logisticsServices.any((s) => s.id == p.serviceId))));
      paid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
      pending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
    } else if (widget.customDriverId != null) {
      final driverServices = allServices.where((s) => s.driver.id == widget.customDriverId).toList();
      debt = driverServices.fold(0.0, (sum, s) => sum + s.netProfit);
      final relevantPayments = allPayments.where((p) => p.type == PaymentType.toDriver && (p.driverId == widget.customDriverId || (p.serviceId != null && driverServices.any((s) => s.id == p.serviceId))));
      paid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
      pending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
    }

    setState(() {
      _overallDebt = debt;
      _overallPaid = paid;
      _overallPending = pending;
      _isStatsLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String targetName = "";
    if (_targetObject is Seller) targetName = (_targetObject as Seller).name;
    else if (_targetObject is Customer) targetName = (_targetObject as Customer).fullName;
    else if (_targetObject is LogisticsCo) targetName = (_targetObject as LogisticsCo).name;
    else if (_targetObject is Driver) targetName = (_targetObject as Driver).fullName;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isCollection ? 'ثبت دریافتی' : 'ثبت پرداختی')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFinanceSummary(targetName, theme),
                  if (!widget.isCollection) _buildTargetBankInfoCard(theme),
                  const SizedBox(height: 24),
                  AmountInput(
                    label: 'مبلغ (تومان) - اجباری',
                    onChanged: (val) => _amount = val,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel(widget.isCollection ? 'واریز به حساب من:' : 'پرداخت از حساب من:'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<BankAccount>(
                    value: _selectedMyAccount,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'انتخاب حساب بانکی شخصی',
                    ),
                    items: _myBankAccounts.map((a) => DropdownMenuItem(value: a, child: Text("${a.bankName} (${a.accountOwner})"))).toList(),
                    onChanged: (val) => setState(() {
                      _selectedMyAccount = val;
                      if (!widget.isCollection && val != null) {
                        _descriptionController.text = "پرداخت از حساب ${val.bankName}";
                      }
                    }),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel('روش پرداخت'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<PaymentMethod>(
                    value: _selectedMethod,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: PaymentMethod.cash, child: Text('نقدی')),
                      DropdownMenuItem(value: PaymentMethod.card, child: Text('کارت به کارت')),
                      DropdownMenuItem(value: PaymentMethod.check, child: Text('چک')),
                      DropdownMenuItem(value: PaymentMethod.sheba, child: Text('شبا')),
                    ],
                    onChanged: (val) => setState(() { 
                      _selectedMethod = val!; 
                      _isCleared = (_selectedMethod != PaymentMethod.check); 
                    }),
                  ),
                  
                  if (_selectedMethod == PaymentMethod.check) ...[
                    const SizedBox(height: 20),
                    _buildLabel('اطلاعات چک'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _bankNameController,
                      validator: (v) => (v == null || v.isEmpty) ? 'نام بانک را وارد کنید' : null,
                      decoration: InputDecoration(labelText: 'نام بانک چک', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _checkNumberController,
                      validator: (v) => (v == null || v.isEmpty) ? 'شماره چک را وارد کنید' : null,
                      decoration: InputDecoration(labelText: 'شماره چک', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildDatePicker(
                      value: _checkDueDate,
                      hint: 'تاریخ سررسید چک',
                      onTap: () async {
                        Jalali? picked = await showPersianDatePicker(context: context, initialDate: Jalali.now(), firstDate: Jalali(1400, 1, 1), lastDate: Jalali(1450, 12, 29));
                        if (picked != null) setState(() => _checkDueDate = picked.toDateTime());
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  _buildLabel('توضیحات'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel('تصویر رسید یا چک (اختیاری)'),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: Colors.grey.shade50),
                      child: _imagePath == null 
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 32), SizedBox(height: 8), Text('افزودن تصویر', style: TextStyle(color: Colors.grey, fontSize: 12))])
                        : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_imagePath!), fit: BoxFit.cover)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _savePayment, child: const Text('ثبت نهایی تراکنش', style: TextStyle(fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));

  Widget _buildDatePicker({required DateTime? value, required String hint, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(value == null ? hint : value.toPersianDate(), style: TextStyle(color: value == null ? Colors.grey : Colors.black)), const Icon(Icons.calendar_today, size: 20, color: Colors.grey)]),
      ),
    );
  }

  Widget _buildFinanceSummary(String targetName, ThemeData theme) {
    if (_isStatsLoading) return const Center(child: CircularProgressIndicator());
    double totalDebt = 0, totalPaid = 0, totalPending = 0;

    bool isGeneral = widget.customSellerId != null || widget.customCustomerId != null || widget.customLogisticsId != null || widget.customDriverId != null;

    if (isGeneral) {
      totalDebt = _overallDebt; totalPaid = _overallPaid; totalPending = _overallPending;
    } else {
      if (widget.isCollection) {
        totalDebt = widget.service.totalServicePriceForCustomer; totalPaid = widget.service.totalCollectedFromCustomer; totalPending = widget.service.pendingCustomerChecks;
      } else {
        // Here we need to check if it's to seller, logistics or driver
        if (widget.customLogisticsId != null) {
          totalDebt = widget.service.expenses.owedToLogistics; totalPaid = widget.service.totalPaidToLogistics; totalPending = widget.service.pendingLogisticsChecks;
        } else {
          totalDebt = widget.service.totalPurchaseAmount; totalPaid = widget.service.totalPaidToSeller; totalPending = widget.service.pendingSellerChecks;
        }
      }
    }
    
    double remaining = totalDebt - totalPaid - totalPending;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2))),
      child: Column(children: [
        Text("طرف حساب: $targetName", style: const TextStyle(fontWeight: FontWeight.bold)),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(widget.isCollection ? "کل طلب:" : "کل بدهی/سود:"), Text("${AppFormatters.formatCurrency(totalDebt)} تومان")]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("نقد جابجا شده:"), Text("${AppFormatters.formatCurrency(totalPaid)} تومان", style: const TextStyle(color: Colors.green))]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("چک در جریان:"), Text("${AppFormatters.formatCurrency(totalPending)} تومان", style: const TextStyle(color: Colors.orange))]),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("مانده نهایی:"), Text(remaining <= 0 ? "تسویه شده" : "${AppFormatters.formatCurrency(remaining)} تومان", style: TextStyle(fontWeight: FontWeight.bold, color: remaining <= 0 ? Colors.green : Colors.red))]),
      ]),
    );
  }

  Widget _buildTargetBankInfoCard(ThemeData theme) {
    String? bank, account, owner;
    if (_targetObject is Seller) {
      final s = _targetObject as Seller;
      bank = s.bankName; account = s.accountNumber; owner = s.accountOwner;
    } else if (_targetObject is LogisticsCo) {
      final l = _targetObject as LogisticsCo;
      bank = l.bankName; account = l.accountNumber; owner = l.accountOwner;
    } else if (_targetObject is Driver) {
      final d = _targetObject as Driver;
      bank = d.bankName; account = d.accountNumber; owner = d.accountOwner;
    } else if (_targetObject is Customer) {
      final c = _targetObject as Customer;
      bank = c.bankName; account = c.accountNumber; owner = c.accountOwner;
    }

    if ((bank == null || bank.isEmpty) && (account == null || account.isEmpty)) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.account_balance, size: 16, color: Colors.amber), SizedBox(width: 8), Text("اطلاعات بانکی مقصد:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown))]),
          const SizedBox(height: 8),
          if (bank != null && bank.isNotEmpty) Text("بانک: $bank", style: const TextStyle(fontSize: 12)),
          if (owner != null && owner.isNotEmpty) Text("صاحب حساب: $owner", style: const TextStyle(fontSize: 12)),
          if (account != null && account.isNotEmpty) Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("شماره: ${account.toPersianDigit()}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () {
                Clipboard.setData(ClipboardData(text: account!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("شماره حساب کپی شد"), duration: Duration(seconds: 1)));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً مبلغ معتبری وارد کنید'))); return;
    }

    PaymentType pType = widget.isCollection ? PaymentType.fromCustomer : PaymentType.toSeller;
    if (widget.customLogisticsId != null) pType = PaymentType.toLogistics;
    if (widget.customDriverId != null) pType = PaymentType.toDriver;

    final newPayment = Payment(
      type: pType, method: _selectedMethod, amount: _amount, date: _selectedDate,
      description: "${_descriptionController.text.trim()} ${(_selectedMyAccount != null ? ' - حساب ${_selectedMyAccount!.bankName}' : '')}", 
      checkDueDate: _checkDueDate, receiptImagePath: _selectedMethod != PaymentMethod.check ? _imagePath : null, checkImagePath: _selectedMethod == PaymentMethod.check ? _imagePath : null,
      sellerId: widget.customSellerId, customerId: widget.customCustomerId, logisticsId: widget.customLogisticsId, driverId: widget.customDriverId,
      myAccountId: _selectedMyAccount?.id, bankName: _bankNameController.text.trim(), checkNumber: _checkNumberController.text.trim(), isCleared: _isCleared,
    );

    try {
      await DatabaseHelper.instance.insertPayment(newPayment, 
        serviceId: (widget.customSellerId == null && widget.customCustomerId == null && widget.customLogisticsId == null && widget.customDriverId == null) ? widget.service.id : null,
        sellerId: widget.customSellerId, customerId: widget.customCustomerId, logisticsId: widget.customLogisticsId, driverId: widget.customDriverId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
    }
  }
}
