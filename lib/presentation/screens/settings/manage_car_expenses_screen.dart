import 'dart:io';
import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';
import '../../widgets/amount_input.dart';

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
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      _cars = cars;
      _isLoading = false;
    });
  }

  void _showAddExpenseDialog() {
    final descriptionController = TextEditingController();
    double amount = 0;
    DateTime selectedDate = DateTime.now();
    Car? selectedCar = _cars.isNotEmpty ? _cars.first : null;
    String? imagePath;

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
                    value: selectedCar,
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
                  AmountInput(
                    label: 'مبلغ (تومان)',
                    onChanged: (val) => amount = val,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                    title: const Text('تاریخ هزینه', style: TextStyle(fontSize: 14)),
                    subtitle: Text(selectedDate.toPersianDate()),
                    trailing: const Icon(Icons.calendar_today, size: 20),
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
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) setDialogState(() => imagePath = picked.path);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: imagePath == null 
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                              Text('افزودن تصویر رسید', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(imagePath!), fit: BoxFit.cover),
                          ),
                    ),
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
                  final expense = CarExpense(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    carId: selectedCar!.id,
                    description: descriptionController.text.trim(),
                    amount: amount,
                    date: selectedDate,
                    receiptImagePath: imagePath,
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

  void _showImageDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(title: const Text('تصویر رسید'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
            Flexible(child: SingleChildScrollView(child: Image.file(File(path), fit: BoxFit.contain))),
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
                            if (expense.receiptImagePath != null)
                              IconButton(
                                icon: const Icon(Icons.receipt_long, color: Colors.blue),
                                onPressed: () => _showImageDialog(expense.receiptImagePath!),
                              ),
                            Text(
                              "${AppFormatters.formatCurrency(expense.amount)}",
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
