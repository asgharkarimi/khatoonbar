import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../core/data/service_repository.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../widgets/amount_input.dart';

class BulkCollectionScreen extends StatefulWidget {
  final Customer? initialCustomer;
  const BulkCollectionScreen({super.key, this.initialCustomer});

  @override
  State<BulkCollectionScreen> createState() => _BulkCollectionScreenState();
}

class _BulkCollectionScreenState extends State<BulkCollectionScreen> {
  final ServiceRepository _repository = ServiceRepository();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  List<LoadService> _unsettledServices = [];
  final Set<String> _selectedServiceIds = {};

  double _paymentAmount = 0;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime? _checkDueDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final customers = await _repository.getCustomers();
    setState(() {
      _customers = customers;
      if (widget.initialCustomer != null) {
        _selectedCustomer = customers.firstWhere((c) => c.id == widget.initialCustomer!.id, orElse: () => widget.initialCustomer!);
      }
      _isLoading = false;
    });
    if (_selectedCustomer != null) {
      _loadUnsettledServices(_selectedCustomer!.id);
    }
  }

  Future<void> _loadUnsettledServices(String customerId) async {
    setState(() => _isLoading = true);
    final allServices = await _repository.getAllServices();
    setState(() {
      _unsettledServices = allServices
          .where((s) => s.customer?.id == customerId && s.finalBalanceCustomerDebt > 0)
          .toList();
      _selectedServiceIds.clear();
      _isLoading = false;
    });
  }

  double get _totalSelectedDebt {
    return _unsettledServices
        .where((s) => _selectedServiceIds.contains(s.id))
        .fold(0, (sum, s) => sum + s.finalBalanceCustomerDebt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('دریافت گروهی از مشتری')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('۱. انتخاب مشتری'),
                    DropdownButtonFormField<Customer>(
                      value: _selectedCustomer,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (v) => v == null ? 'لطفاً مشتری را انتخاب کنید' : null,
                      items: _customers.map((c) => DropdownMenuItem(value: c, child: Text(c.fullName))).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCustomer = val);
                        if (val != null) _loadUnsettledServices(val.id);
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_selectedCustomer != null) ...[
                      _buildSectionTitle('۲. انتخاب سرویس‌های مورد نظر'),
                      if (_unsettledServices.isEmpty)
                        const Text('هیچ سرویس تسویه نشده‌ای (با مانده بدهی نهایی) برای این مشتری یافت نشد.')
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
                                side: BorderSide(color: isSelected ? Colors.green : Colors.transparent, width: 2),
                              ),
                              child: CheckboxListTile(
                                value: isSelected,
                                activeColor: Colors.green,
                                title: Text("${service.loadType.name} - ${service.orderCode}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("مانده طلب نهایی: ${AppFormatters.formatCurrency(service.finalBalanceCustomerDebt)} تومان"),
                                    if (service.pendingCustomerChecks > 0)
                                      Text("چک در جریان: ${AppFormatters.formatCurrency(service.pendingCustomerChecks)} تومان", style: const TextStyle(fontSize: 10, color: Colors.orange)),
                                  ],
                                ),
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
                      _buildSectionTitle('۳. اطلاعات دریافتی'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "جمع طلب انتخاب شده: ${AppFormatters.formatCurrency(_totalSelectedDebt)} تومان",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AmountInput(
                        label: 'مبلغ دریافتی (کل چک یا فیش)',
                        onChanged: (val) => setState(() => _paymentAmount = val),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PaymentMethod>(
                        value: _selectedMethod,
                        decoration: const InputDecoration(labelText: 'روش دریافت', border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'توضیحات (مثلاً شماره چک یا فیش)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveBulkCollection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('ثبت نهایی دریافت گروهی'),
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

  Future<void> _saveBulkCollection() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً حداقل یک سرویس را انتخاب کنید')));
      return;
    }

    if (_paymentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً مبلغ دریافتی را وارد کنید')));
      return;
    }

    try {
      double remainingToDistribute = _paymentAmount;
      final servicesToCollect = _unsettledServices
          .where((s) => _selectedServiceIds.contains(s.id))
          .toList();

      for (var service in servicesToCollect) {
        if (remainingToDistribute <= 0) break;

        double debt = service.finalBalanceCustomerDebt;
        double amountForThisService = remainingToDistribute >= debt ? debt : remainingToDistribute;

        final payment = Payment(
          id: DateTime.now().millisecondsSinceEpoch.toString() + service.id,
          serviceId: service.id,
          type: PaymentType.fromCustomer,
          method: _selectedMethod,
          amount: amountForThisService,
          date: _selectedDate,
          description: "${_descriptionController.text} (دریافت گروهی)",
          checkDueDate: _checkDueDate,
          isCleared: _selectedMethod != PaymentMethod.check,
        );

        await _repository.savePayment(payment, serviceId: service.id, customerId: _selectedCustomer?.id);
        remainingToDistribute -= amountForThisService;
      }

      // If there's still money left, it's a general payment to the customer (overpayment/prepayment)
      if (remainingToDistribute > 0) {
          final extraPayment = Payment(
          id: DateTime.now().millisecondsSinceEpoch.toString() + "extra",
          customerId: _selectedCustomer?.id,
          type: PaymentType.fromCustomer,
          method: _selectedMethod,
          amount: remainingToDistribute,
          date: _selectedDate,
          description: "${_descriptionController.text} (مازاد دریافت گروهی)",
          checkDueDate: _checkDueDate,
          isCleared: _selectedMethod != PaymentMethod.check,
        );
        await _repository.savePayment(extraPayment, customerId: _selectedCustomer?.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دریافت گروهی با موفقیت ثبت شد'), backgroundColor: Colors.green),
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
