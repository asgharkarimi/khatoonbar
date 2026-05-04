import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/biometric_helper.dart';
import '../../../models/models.dart';
import '../../widgets/phone_input.dart';
import '../customer_ledger_screen.dart';

class ManageCustomersScreen extends StatefulWidget {
  const ManageCustomersScreen({super.key});

  @override
  State<ManageCustomersScreen> createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _refreshCustomers();
  }

  Future<void> _refreshCustomers() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllCustomers();
    setState(() {
      _customers = data;
      _isLoading = false;
    });
  }

  void _showCustomerDialog({Customer? customer}) {
    final firstNameController = TextEditingController(text: customer?.firstName);
    final lastNameController = TextEditingController(text: customer?.lastName);
    final phoneController = TextEditingController(text: customer?.phone);
    final villageController = TextEditingController(text: customer?.village);
    final bankController = TextEditingController(text: customer?.bankName);
    final accountController = TextEditingController(text: customer?.accountNumber);
    final ownerController = TextEditingController(text: customer?.accountOwner);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'افزودن مشتری جدید' : 'ویرایش مشتری', style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameController, 
                  decoration: const InputDecoration(labelText: 'نام (اجباری)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'نام را وارد کنید' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameController, 
                  decoration: const InputDecoration(labelText: 'نام خانوادگی (اجباری)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'نام خانوادگی را وارد کنید' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(controller: villageController, decoration: const InputDecoration(labelText: 'روستا/شهر', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                PhoneInput(controller: phoneController, label: 'شماره تلفن'),
                const Divider(height: 32),
                const Text('اطلاعات بانکی (اختیاری)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 12),
                TextFormField(controller: bankController, decoration: const InputDecoration(labelText: 'نام بانک', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextFormField(controller: accountController, decoration: const InputDecoration(labelText: 'شماره حساب/کارت', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextFormField(controller: ownerController, decoration: const InputDecoration(labelText: 'نام صاحب حساب', border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newCustomer = Customer(
                  id: customer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  phone: phoneController.text.trim(),
                  village: villageController.text.trim(),
                  bankName: bankController.text.trim(),
                  accountNumber: accountController.text.trim(),
                  accountOwner: ownerController.text.trim(),
                );
                await DatabaseHelper.instance.insertCustomer(newCustomer);
                if (mounted) Navigator.pop(context);
                _refreshCustomers();
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت مشتریان (گیرندگان)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
              ? const Center(child: Text('مشتری‌ای ثبت نشده است'))
              : ListView.builder(
                  itemCount: _customers.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(customer.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(customer.phone),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CustomerLedgerScreen(customer: customer)),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showCustomerDialog(customer: customer),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('تایید حذف'),
                                    content: Text('آیا از حذف "${customer.fullName}" اطمینان دارید؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  bool authenticated = await BiometricHelper.authenticate(
                                    reason: 'تایید هویت برای حذف مشتری ${customer.fullName}'
                                  );
                                  if (authenticated) {
                                    await DatabaseHelper.instance.delete('customers', customer.id);
                                    _refreshCustomers();
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عدم تایید هویت. حذف لغو شد.')));
                                    }
                                  }
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
        onPressed: () => _showCustomerDialog(),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('افزودن مشتری جدید', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
