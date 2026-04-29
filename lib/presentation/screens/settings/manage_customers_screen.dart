import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
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

  void _showAddCustomerDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final villageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن مشتری (گیرنده) جدید', style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'نام')),
              const SizedBox(height: 8),
              TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'نام خانوادگی')),
              const SizedBox(height: 8),
              TextField(controller: villageController, decoration: const InputDecoration(labelText: 'روستا/شهر')),
              const SizedBox(height: 16),
              PhoneInput(controller: phoneController, label: 'شماره تلفن'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.isNotEmpty && lastNameController.text.isNotEmpty) {
                final newCustomer = Customer(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  phone: phoneController.text,
                  village: villageController.text,
                );
                await DatabaseHelper.instance.insertCustomer(newCustomer);
                if (mounted) Navigator.pop(context);
                _refreshCustomers();
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
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
                            MaterialPageRoute(
                              builder: (context) => CustomerLedgerScreen(customer: customer),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            const SizedBox(width: 8),
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
                                  await DatabaseHelper.instance.delete('customers', customer.id);
                                  _refreshCustomers();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
