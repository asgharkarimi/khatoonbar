import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/biometric_helper.dart';
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
  final _formKey = GlobalKey<FormState>();

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
    final bankController = TextEditingController(text: driver?.bankName);
    final accountController = TextEditingController(text: driver?.accountNumber);
    final ownerController = TextEditingController(text: driver?.accountOwner);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver == null ? 'افزودن راننده جدید' : 'ویرایش راننده', style: const TextStyle(fontSize: 16)),
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
                PhoneInput(controller: phoneController, label: 'شماره همراه راننده'),
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
                final newDriver = Driver(
                  id: driver?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  phone: phoneController.text.trim(),
                  bankName: bankController.text.trim(),
                  accountNumber: accountController.text.trim(),
                  accountOwner: ownerController.text.trim(),
                );
                await DatabaseHelper.instance.insertDriver(newDriver);
                if (mounted) Navigator.pop(context);
                _refreshDrivers();
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
                                  bool authenticated = await BiometricHelper.authenticate(
                                    reason: 'تایید هویت برای حذف راننده ${driver.fullName}'
                                  );
                                  if (authenticated) {
                                    await DatabaseHelper.instance.delete('drivers', driver.id);
                                    _refreshDrivers();
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
        onPressed: () => _showDriverDialog(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('افزودن راننده جدید', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
