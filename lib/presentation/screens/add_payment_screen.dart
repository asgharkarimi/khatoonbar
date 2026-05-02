import 'dart:io';
import 'package:flutter/material.dart';
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

  const AddPaymentScreen({
    super.key,
    required this.service,
    required this.isCollection,
    this.customSellerId,
    this.customCustomerId,
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
  bool _isStatsLoading = false;

  List<LoadService> _unsettledServices = [];
  final List<String> _selectedServiceCodes = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _autoFillBankInfo();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final accounts = await DatabaseHelper.instance.getAllBankAccounts();
    await _loadFinanceStats();
    setState(() {
      _myBankAccounts = accounts;
      _isLoading = false;
    });
  }

  void _autoFillBankInfo() {
    if (!widget.isCollection) {
      if (widget.customSellerId != null || widget.service.seller.id.isNotEmpty) {
         _bankNameController.text = widget.service.seller.bankName ?? "";
      }
    } else {
      if (widget.customCustomerId != null || (widget.service.customer != null)) {
         _bankNameController.text = widget.service.customer?.bankName ?? "";
      }
    }
  }

  Future<void> _loadFinanceStats() async {
    setState(() => _isStatsLoading = true);
    final allServices = await DatabaseHelper.instance.getAllServices();
    final allPayments = await DatabaseHelper.instance.getAllPayments();

    double debt = 0;
    double paid = 0;

    if (widget.customSellerId != null) {
      final sellerServices = allServices.where((s) => s.seller.id == widget.customSellerId).toList();
      debt = sellerServices.fold(0.0, (sum, s) => sum + s.totalPurchaseAmount);
      paid = allPayments
          .where((p) => (p.sellerId == widget.customSellerId || sellerServices.any((s) => s.id == p.serviceId)) && p.isCleared)
          .fold(0.0, (sum, p) => sum + p.amount);
      _unsettledServices = sellerServices.where((s) => s.remainingDebtToSeller > 0).toList();
    } else if (widget.customCustomerId != null) {
      final customerServices = allServices.where((s) => s.customer?.id == widget.customCustomerId).toList();
      debt = customerServices.fold(0.0, (sum, s) => sum + s.totalServicePriceForCustomer);
      paid = allPayments
          .where((p) => (p.customerId == widget.customCustomerId || customerServices.any((s) => s.id == p.serviceId)) && p.isCleared)
          .fold(0.0, (sum, p) => sum + p.amount);
      _unsettledServices = customerServices.where((s) => s.remainingCustomerDebt > 0).toList();
    }

    setState(() {
      _overallDebt = debt;
      _overallPaid = paid;
      _isStatsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isGeneral = widget.customSellerId != null || widget.customCustomerId != null;
    String targetName = widget.customSellerId != null ? widget.service.seller.name : (widget.isCollection ? (widget.service.customer?.fullName ?? 'مشتری') : widget.service.seller.name);

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
                  _buildFinanceSummary(targetName, theme, isGeneral),
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
                    validator: (v) => (v == null || v.isEmpty) ? 'توضیحات را وارد کنید' : null,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _savePayment,
                      child: const Text('ثبت نهایی تراکنش', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
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

  Widget _buildFinanceSummary(String targetName, ThemeData theme, bool isGeneral) {
    if (isGeneral && _isStatsLoading) return const Center(child: CircularProgressIndicator());
    double totalDebt = isGeneral ? _overallDebt : (widget.isCollection ? widget.service.totalServicePriceForCustomer : widget.service.totalPurchaseAmount);
    double totalPaid = isGeneral ? _overallPaid : (widget.isCollection ? widget.service.totalCollectedFromCustomer : widget.service.totalPaidToSeller);
    double remaining = totalDebt - totalPaid;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2))),
      child: Column(children: [
        Text("طرف حساب: $targetName", style: const TextStyle(fontWeight: FontWeight.bold)),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(widget.isCollection ? "کل طلب:" : "کل بدهی:"), Text("${AppFormatters.formatCurrency(totalDebt)} تومان")]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("مانده نهایی:"), Text(remaining <= 0 ? "تسویه شده" : "${AppFormatters.formatCurrency(remaining)} تومان", style: TextStyle(fontWeight: FontWeight.bold, color: remaining <= 0 ? Colors.green : Colors.red))]),
      ]),
    );
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً مبلغ معتبری وارد کنید')));
      return;
    }

    final newPayment = Payment(
      type: widget.isCollection ? PaymentType.fromCustomer : PaymentType.toSeller,
      method: _selectedMethod, 
      amount: _amount, 
      date: _selectedDate,
      description: "${_descriptionController.text.trim()} ${(_selectedMyAccount != null ? ' - حساب ${_selectedMyAccount!.bankName}' : '')}", 
      checkDueDate: _checkDueDate,
      sellerId: widget.customSellerId, 
      customerId: widget.customCustomerId,
      bankName: _bankNameController.text.trim(), 
      checkNumber: _checkNumberController.text.trim(), 
      isCleared: _isCleared,
    );

    try {
      await DatabaseHelper.instance.insertPayment(newPayment, serviceId: (widget.customSellerId == null && widget.customCustomerId == null) ? widget.service.id : null);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
    }
  }
}
