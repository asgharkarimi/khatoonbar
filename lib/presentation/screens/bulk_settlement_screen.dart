import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../core/data/service_repository.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../widgets/amount_input.dart';

class BulkSettlementScreen extends StatefulWidget {
  const BulkSettlementScreen({super.key});

  @override
  State<BulkSettlementScreen> createState() => _BulkSettlementScreenState();
}

class _BulkSettlementScreenState extends State<BulkSettlementScreen> {
  final ServiceRepository _repository = ServiceRepository();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  List<Seller> _sellers = [];
  Seller? _selectedSeller;
  List<LoadService> _unsettledServices = [];
  final Set<String> _selectedServiceIds = {};

  double _paymentAmount = 0;
  PaymentMethod _selectedMethod = PaymentMethod.check;
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime? _checkDueDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final sellers = await _repository.getSellers();
    setState(() {
      _sellers = sellers;
      _isLoading = false;
    });
  }

  Future<void> _loadUnsettledServices(String sellerId) async {
    setState(() => _isLoading = true);
    final allServices = await _repository.getAllServices();
    setState(() {
      _unsettledServices = allServices
          .where((s) => s.seller.id == sellerId && !s.isSellerSettled)
          .toList();
      _selectedServiceIds.clear();
      _isLoading = false;
    });
  }

  double get _totalSelectedDebt {
    return _unsettledServices
        .where((s) => _selectedServiceIds.contains(s.id))
        .fold(0, (sum, s) => sum + s.remainingDebtToSeller);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تسویه گروهی با فروشنده')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('۱. انتخاب فروشنده'),
                    DropdownButtonFormField<Seller>(
                      value: _selectedSeller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.store),
                      ),
                      validator: (v) => v == null ? 'لطفاً فروشنده را انتخاب کنید' : null,
                      items: _sellers.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        setState(() => _selectedSeller = val);
                        if (val != null) _loadUnsettledServices(val.id);
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_selectedSeller != null) ...[
                      _buildSectionTitle('۲. انتخاب سرویس‌های مورد نظر'),
                      if (_unsettledServices.isEmpty)
                        const Text('هیچ سرویس تسویه نشده‌ای برای این فروشنده یافت نشد.')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _unsettledServices.length,
                          itemBuilder: (context, index) {
                            final service = _unsettledServices[index];
                            final isSelected = _selectedServiceIds.contains(service.id);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: isSelected ? theme.primaryColor : Colors.transparent, width: 2),
                              ),
                              child: CheckboxListTile(
                                value: isSelected,
                                title: Text("${service.loadType.name} - ${service.orderCode}"),
                                subtitle: Text("مانده بدهی: ${AppFormatters.formatCurrency(service.remainingDebtToSeller)} تومان"),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedServiceIds.add(service.id);
                                    } else {
                                      _selectedServiceIds.remove(service.id);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('۳. اطلاعات پرداخت'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "جمع بدهی انتخاب شده: ${AppFormatters.formatCurrency(_totalSelectedDebt)} تومان",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AmountInput(
                        label: 'مبلغ پرداختی (کل چک یا فیش)',
                        onChanged: (val) => setState(() => _paymentAmount = val),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PaymentMethod>(
                        value: _selectedMethod,
                        decoration: const InputDecoration(labelText: 'روش پرداخت', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: PaymentMethod.cash, child: Text('نقدی')),
                          DropdownMenuItem(value: PaymentMethod.card, child: Text('کارت به کارت')),
                          DropdownMenuItem(value: PaymentMethod.check, child: Text('چک')),
                          DropdownMenuItem(value: PaymentMethod.sheba, child: Text('شبا')),
                        ],
                        onChanged: (val) => setState(() => _selectedMethod = val!),
                      ),
                      if (_selectedMethod == PaymentMethod.check) ...[
                        const SizedBox(height: 16),
                        ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                          title: const Text('تاریخ سررسید چک'),
                          subtitle: Text(_checkDueDate == null ? 'برای انتخاب کلیک کنید' : _checkDueDate!.toPersianDate()),
                          trailing: const Icon(Icons.calendar_month),
                          onTap: () async {
                            final picked = await showPersianDatePicker(
                              context: context,
                              locale: const Locale('fa', 'IR'),
                              initialDate: Jalali.now(),
                              firstDate: Jalali(1400),
                              lastDate: Jalali(1450),
                            );
                            if (picked != null) setState(() => _checkDueDate = picked.toDateTime());
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        validator: (v) => (v == null || v.isEmpty) ? 'لطفاً توضیحات را وارد کنید' : null,
                        decoration: const InputDecoration(labelText: 'توضیحات (مثلاً شماره چک یا پیگیری)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveBulkPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('ثبت نهایی تسویه گروهی'),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _saveBulkPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً حداقل یک سرویس را انتخاب کنید')));
      return;
    }

    if (_paymentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً مبلغ پرداختی را وارد کنید')));
      return;
    }

    if (_selectedMethod == PaymentMethod.check && _checkDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً تاریخ سررسید چک را انتخاب کنید')));
      return;
    }

    try {
      double remainingToDistribute = _paymentAmount;
      final servicesToPay = _unsettledServices
          .where((s) => _selectedServiceIds.contains(s.id))
          .toList();

      for (var service in servicesToPay) {
        if (remainingToDistribute <= 0) break;

        double debt = service.remainingDebtToSeller;
        double amountForThisService = remainingToDistribute >= debt ? debt : remainingToDistribute;

        final payment = Payment(
          id: DateTime.now().millisecondsSinceEpoch.toString() + service.id,
          serviceId: service.id,
          type: PaymentType.toSeller,
          method: _selectedMethod,
          amount: amountForThisService,
          date: _selectedDate,
          description: "${_descriptionController.text} (تسویه گروهی)",
          checkDueDate: _checkDueDate,
          isCleared: _selectedMethod != PaymentMethod.check,
        );

        await _repository.savePayment(payment, serviceId: service.id);
        remainingToDistribute -= amountForThisService;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تسویه گروهی با موفقیت ثبت شد'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ثبت: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
