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
          title: const Text('ثبت هزینه جدید ماشین', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Car>(
                  decoration: const InputDecoration(labelText: 'انتخاب ماشین'),
                  items: _cars.map((car) => DropdownMenuItem(
                    value: car,
                    child: Text(car.name),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => selectedCar = value),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'شرح هزینه (مثلاً لاستیک، بیمه)'),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'مبلغ (تومان)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                if (selectedCar != null && amountController.text.isNotEmpty) {
                  final expense = CarExpense(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    carId: selectedCar!.id,
                    description: descriptionController.text,
                    amount: double.tryParse(amountController.text) ?? 0,
                    date: DateTime.now(),
                  );
                  await DatabaseHelper.instance.insertCarExpense(expense);
                  if (mounted) Navigator.pop(context);
                  _loadData();
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
      appBar: AppBar(title: const Text('هزینه‌های متفرقه ماشین')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? const Center(child: Text('هیچ هزینه‌ای ثبت نشده است'))
              : ListView.builder(
                  itemCount: _expenses.length,
                  padding: const EdgeInsets.all(16),
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
                        title: Text("${car.name} - ${expense.description}"),
                        subtitle: Text(expense.date.toPersianDate()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${AppFormatters.formatCurrency(expense.amount)} تومان",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        label: const Text('ثبت هزینه جدید'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
