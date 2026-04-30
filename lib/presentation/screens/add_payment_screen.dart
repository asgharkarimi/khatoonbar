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

  double _overallDebt = 0;
  double _overallPaid = 0;
  bool _isStatsLoading = false;

  // برای مدیریت انتخاب بارها
  List<LoadService> _unsettledServices = [];
  final List<String> _selectedServiceCodes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
      
      // پیدا کردن بارهای تسویه نشده این شرکت
      _unsettledServices = sellerServices.where((s) => s.remainingDebtToSeller > 0).toList();

    } else if (widget.customCustomerId != null) {
      final customerServices = allServices.where((s) => s.customer?.id == widget.customCustomerId).toList();
      debt = customerServices.fold(0.0, (sum, s) => sum + s.totalServicePriceForCustomer);
      paid = allPayments
          .where((p) => (p.customerId == widget.customCustomerId || customerServices.any((s) => s.id == p.serviceId)) && p.isCleared)
          .fold(0.0, (sum, p) => sum + p.amount);

      // پیدا کردن بارهای تسویه نشده این مشتری
      _unsettledServices = customerServices.where((s) => s.remainingCustomerDebt > 0).toList();
    }

    setState(() {
      _overallDebt = debt;
      _overallPaid = paid;
      _isStatsLoading = false;
    });
  }

  void _updateDescriptionWithCodes() {
    if (_selectedServiceCodes.isEmpty) return;
    
    String prefix = "بابت بارهای: ";
    String codes = _selectedServiceCodes.join('، ');
    
    // پاک کردن متون قبلی که با "بابت بارهای" شروع میشدن برای جلوگیری از تکرار
    String currentText = _descriptionController.text;
    if (currentText.contains(prefix)) {
      currentText = currentText.split(prefix)[0].trim();
    }
    
    _descriptionController.text = currentText.isEmpty ? "$prefix$codes" : "$currentText ($prefix$codes)";
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _bankNameController.dispose();
    _checkNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isGeneral = widget.customSellerId != null || widget.customCustomerId != null;
    
    String title = isGeneral 
        ? (widget.isCollection ? 'ثبت دریافت کلی' : 'ثبت پرداخت کلی / چک')
        : (widget.isCollection ? 'ثبت دریافتی از مشتری' : 'ثبت پرداختی به فروشنده');
        
    String targetName = widget.customSellerId != null 
        ? widget.service.seller.name 
        : (widget.isCollection ? (widget.service.customer?.fullName ?? 'مشتری') : widget.service.seller.name);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinanceSummary(targetName, theme, isGeneral),
              const SizedBox(height: 24),
              AmountInput(
                label: 'مبلغ (تومان)',
                onChanged: (val) => _amount = val,
              ),
              const SizedBox(height: 20),
              
              if (isGeneral && _unsettledServices.isNotEmpty) ...[
                _buildLabel('انتخاب بارهای مربوط به این تراکنش:'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _unsettledServices.map((s) {
                      bool isSelected = _selectedServiceCodes.contains(s.orderCode);
                      double rem = widget.isCollection ? s.remainingCustomerDebt : s.remainingDebtToSeller;
                      return CheckboxListTile(
                        title: Text("${s.loadType.name} (${s.orderCode})", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text("مانده: ${AppFormatters.formatCurrency(rem)} تومان", style: const TextStyle(fontSize: 11)),
                        value: isSelected,
                        dense: true,
                        activeColor: theme.primaryColor,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedServiceCodes.add(s.orderCode);
                            } else {
                              _selectedServiceCodes.remove(s.orderCode);
                            }
                            _updateDescriptionWithCodes();
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _buildLabel('توضیحات'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: isGeneral ? 'مثلا: بابت تسویه حساب' : 'مثلا: علی‌الحساب',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('روش پرداخت'),
              const SizedBox(height: 10),
              DropdownButtonFormField<PaymentMethod>(
                value: _selectedMethod,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: PaymentMethod.cash, child: Text('نقدی')),
                  DropdownMenuItem(value: PaymentMethod.card, child: Text('کارت به کارت')),
                  DropdownMenuItem(value: PaymentMethod.check, child: Text('چک')),
                  DropdownMenuItem(value: PaymentMethod.sheba, child: Text('شبا')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedMethod = val!;
                    _isCleared = (_selectedMethod != PaymentMethod.check);
                  });
                },
              ),
              
              if (_selectedMethod == PaymentMethod.check) ...[
                const SizedBox(height: 20),
                _buildLabel('اطلاعات چک'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bankNameController,
                  decoration: InputDecoration(
                    labelText: 'نام بانک صادر کننده',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _checkNumberController,
                  decoration: InputDecoration(
                    labelText: 'شماره چک',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                _buildLabel('تاریخ سررسید چک'),
                const SizedBox(height: 10),
                _buildDatePicker(
                  value: _checkDueDate,
                  hint: 'انتخاب تاریخ سررسید',
                  onTap: () async {
                    // تغییر initialDate به Jalali.now() برای نمایش تاریخ امروز به صورت پیش‌فرض
                    Jalali? picked = await showPersianDatePicker(
                      context: context,
                      initialDate: Jalali.now(),
                      firstDate: Jalali(1400, 1, 1),
                      lastDate: Jalali(1450, 12, 29),
                    );
                    if (picked != null) setState(() => _checkDueDate = picked.toDateTime());
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('آیا چک وصول شده است؟', style: TextStyle(fontSize: 14)),
                  value: _isCleared,
                  onChanged: (val) => setState(() => _isCleared = val),
                  activeColor: Colors.green,
                ),
              ],

              if (_selectedMethod == PaymentMethod.card || _selectedMethod == PaymentMethod.sheba) ...[
                const SizedBox(height: 20),
                _buildLabel('اطلاعات واریز'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bankNameController,
                  decoration: InputDecoration(
                    labelText: 'نام بانک مبدا/مقصد',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              _buildLabel(_selectedMethod == PaymentMethod.check ? 'تصویر چک' : 'تصویر رسید تراکنش'),
              const SizedBox(height: 10),
              _buildImagePicker(),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _savePayment,
                  child: const Text('تایید و ثبت نهایی', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: _imagePath == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('برای ثبت تصویر کلیک کنید', style: TextStyle(color: Colors.grey)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 15,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 15, color: Colors.white),
                        onPressed: () => setState(() => _imagePath = null),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
  }

  Widget _buildDatePicker({required DateTime? value, required String hint, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value == null ? hint : value.toPersianDate(), 
              style: TextStyle(color: value == null ? Colors.grey : Colors.black)
            ),
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceSummary(String targetName, ThemeData theme, bool isGeneral) {
    if (isGeneral && _isStatsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    double totalDebt = isGeneral ? _overallDebt : (widget.isCollection 
        ? widget.service.totalServicePriceForCustomer 
        : widget.service.totalPurchaseAmount);
    
    double totalPaid = isGeneral ? _overallPaid : (widget.isCollection 
        ? widget.service.totalCollectedFromCustomer 
        : widget.service.totalPaidToSeller);
    
    double remaining = totalDebt - totalPaid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            isGeneral ? "خلاصه کل حساب $targetName" : "خلاصه وضعیت مالی این سرویس", 
            style: const TextStyle(fontWeight: FontWeight.bold)
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.isCollection ? "کل طلب از مشتری:" : "کل بدهی به فروشنده:"),
              Text("${AppFormatters.formatCurrency(totalDebt)} تومان"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("مانده نهایی بدهی:"),
              Text(
                remaining <= 0 
                  ? "تسویه شده" 
                  : "${AppFormatters.formatCurrency(remaining)} تومان",
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: remaining <= 0 ? Colors.green : Colors.red
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _savePayment() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا مبلغ را وارد کنید')));
      return;
    }

    final newPayment = Payment(
      type: widget.isCollection ? PaymentType.fromCustomer : PaymentType.toSeller,
      method: _selectedMethod,
      amount: _amount,
      date: _selectedDate,
      description: _descriptionController.text.trim(),
      checkDueDate: _checkDueDate,
      sellerId: widget.customSellerId,
      customerId: widget.customCustomerId,
      receiptImagePath: _selectedMethod != PaymentMethod.check ? _imagePath : null,
      checkImagePath: _selectedMethod == PaymentMethod.check ? _imagePath : null,
      bankName: _bankNameController.text.trim(),
      checkNumber: _checkNumberController.text.trim(),
      isCleared: _isCleared,
    );

    try {
      await DatabaseHelper.instance.insertPayment(
        newPayment, 
        serviceId: (widget.customSellerId == null && widget.customCustomerId == null) ? widget.service.id : null,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تراکنش با موفقیت ثبت شد'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }
}
