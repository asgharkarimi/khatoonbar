import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/models.dart';
import '../../widgets/phone_input.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  List<Driver> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshDrivers();
  }

  Future<void> _refreshDrivers() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllDrivers();
    setState(() {
      _drivers = data;
      _isLoading = false;
    });
  }

  void _showDriverDialog({Driver? driver}) {
    final firstNameController = TextEditingController(text: driver?.firstName);
    final lastNameController = TextEditingController(text: driver?.lastName);
    final phoneController = TextEditingController(text: driver?.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver == null ? 'افزودن راننده جدید' : 'ویرایش راننده', style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'نام')),
              const SizedBox(height: 8),
              TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'نام خانوادگی')),
              const SizedBox(height: 16),
              PhoneInput(controller: phoneController, label: 'شماره همراه راننده'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.isNotEmpty && lastNameController.text.isNotEmpty) {
                final newDriver = Driver(
                  id: driver?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  phone: phoneController.text,
                );
                await DatabaseHelper.instance.insertDriver(newDriver);
                if (mounted) Navigator.pop(context);
                _refreshDrivers();
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
      appBar: AppBar(title: const Text('مدیریت رانندگان')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drivers.isEmpty
              ? const Center(child: Text('راننده‌ای ثبت نشده است'))
              : ListView.builder(
                  itemCount: _drivers.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final driver = _drivers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: const Icon(Icons.person, color: Colors.green),
                        ),
                        title: Text(driver.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(driver.phone),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showDriverDialog(driver: driver),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('تایید حذف'),
                                    content: Text('آیا از حذف "${driver.fullName}" اطمینان دارید؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await DatabaseHelper.instance.delete('drivers', driver.id);
                                  _refreshDrivers();
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
        onPressed: () => _showDriverDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
