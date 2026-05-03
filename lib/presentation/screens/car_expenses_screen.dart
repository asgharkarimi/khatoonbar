import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../core/data/service_repository.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../widgets/amount_input.dart';

class CarExpensesScreen extends StatefulWidget {
  const CarExpensesScreen({super.key});

  @override
  State<CarExpensesScreen> createState() => _CarExpensesScreenState();
}

class _CarExpensesScreenState extends State<CarExpensesScreen> {
  final ServiceRepository _repository = ServiceRepository();
  final _formKey = GlobalKey<FormState>();
  List<CarExpense> _expenses = [];
  List<Car> _cars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final e = await _repository.getCarExpenses();
    final c = await _repository.getCars();
    setState(() {
      _expenses = e;
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      _cars = c;
      _isLoading = false;
    });
  }

  void _showAddExpenseDialog() {
    final descriptionController = TextEditingController();
    double amount = 0;
    DateTime selectedDate = DateTime.now();
    Car? selectedCar = _cars.isNotEmpty ? _cars.first : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ثبت هزینه متفرقه خودرو'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Car>(
                    value: selectedCar,
                    items: _cars.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (v) => setDialogState(() => selectedCar = v),
                    validator: (v) => v == null ? 'لطفاً خودرو را انتخاب کنید' : null,
                    decoration: const InputDecoration(labelText: 'انتخاب خودرو', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    validator: (v) => (v == null || v.isEmpty) ? 'توضیحات هزینه را وارد کنید' : null,
                    decoration: const InputDecoration(labelText: 'شرح هزینه (مثلا: بیمه، تعمیر گیربکس)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  AmountInput(
                    label: 'مبلغ هزینه (تومان)',
                    onChanged: (val) => amount = val,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                    title: const Text('تاریخ هزینه'),
                    subtitle: Text(selectedDate.toPersianDate()),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showPersianDatePicker(
                        context: context,
                        initialDate: Jalali.fromDateTime(selectedDate),
                        firstDate: Jalali(1400),
                        lastDate: Jalali(1450),
                      );
                      if (picked != null) setDialogState(() => selectedDate = picked.toDateTime());
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() && amount > 0) {
                  final e = CarExpense(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    carId: selectedCar!.id,
                    description: descriptionController.text,
                    amount: amount,
                    date: selectedDate,
                  );

                  await _repository.saveCarExpense(e);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('هزینه‌های متفرقه خودرو')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final e = _expenses[index];
                    final car = _cars.firstWhere((c) => c.id == e.carId, orElse: () => Car(id: '', name: 'نامشخص'));
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade50,
                          child: const Icon(Icons.handyman_outlined, color: Colors.orange),
                        ),
                        title: Text("${e.description} - ${car.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(e.date.toPersianDate()),
                        trailing: Text(
                          "${AppFormatters.formatCurrency(e.amount)} تومان",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        onLongPress: () => _confirmDelete(e.id),
                      ),
                    );
                  },
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('ثبت هزینه جدید'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('هنوز هیچ هزینه‌ای ثبت نشده است'),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف هزینه'),
        content: const Text('آیا مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('حذف')),
        ],
      ),
    );
    if (res == true) {
      await _repository.deleteCarExpense(id);
      _loadData();
    }
  }
}
