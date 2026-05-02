import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';

class ManageCarExpensesScreen extends StatefulWidget {
  const ManageCarExpensesScreen({super.key});

  @override
  State<ManageCarExpensesScreen> createState() => _ManageCarExpensesScreenState();
}

class _ManageCarExpensesScreenState extends State<ManageCarExpensesScreen> {
  List<CarExpense> _expenses = [];
  List<Car> _cars = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final expenses = await DatabaseHelper.instance.getAllCarExpenses();
    final cars = await DatabaseHelper.instance.getAllCars();
    setState(() {
      _expenses = expenses;
      _cars = cars;
      _isLoading = false;
    });
  }

  void _showAddExpenseDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    Car? selectedCar;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ثبت هزینه جدید ماشین', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Car>(
                    decoration: const InputDecoration(labelText: 'انتخاب ماشین', border: OutlineInputBorder()),
                    items: _cars.map((car) => DropdownMenuItem(
                      value: car,
                      child: Text(car.name),
                    )).toList(),
                    validator: (v) => v == null ? 'لطفاً ماشین را انتخاب کنید' : null,
                    onChanged: (value) => setDialogState(() => selectedCar = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'شرح هزینه (مثلاً لاستیک، بیمه)', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'شرح هزینه را وارد کنید' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'مبلغ (تومان)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'مبلغ را وارد کنید' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final expense = CarExpense(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    carId: selectedCar!.id,
                    description: descriptionController.text.trim(),
                    amount: double.tryParse(amountController.text) ?? 0,
                    date: DateTime.now(),
                  );
                  await DatabaseHelper.instance.insertCarExpense(expense);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هزینه با موفقیت ثبت شد'), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('هزینه‌های متفرقه ماشین')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? const Center(child: Text('هیچ هزینه‌ای ثبت نشده است'))
              : ListView.builder(
                  itemCount: _expenses.length,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    final car = _cars.firstWhere((c) => c.id == expense.carId, 
                        orElse: () => Car(id: '', name: 'نامشخص'));
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          child: const Icon(Icons.build, color: Colors.orange),
                        ),
                        title: Text("${car.name} - ${expense.description}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(expense.date.toPersianDate()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${AppFormatters.formatCurrency(expense.amount)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            const SizedBox(width: 4),
                            const Text("تومان", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('تایید حذف'),
                                    content: const Text('آیا از حذف این هزینه اطمینان دارید؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await DatabaseHelper.instance.delete('car_expenses', expense.id);
                                  _loadData();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ثبت هزینه جدید ماشین', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
