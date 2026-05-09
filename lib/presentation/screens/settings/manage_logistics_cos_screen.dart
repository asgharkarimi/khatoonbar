import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/models.dart';
import '../../widgets/phone_input.dart';

class ManageLogisticsCosScreen extends StatefulWidget {
  const ManageLogisticsCosScreen({super.key});

  @override
  State<ManageLogisticsCosScreen> createState() => _ManageLogisticsCosScreenState();
}

class _ManageLogisticsCosScreenState extends State<ManageLogisticsCosScreen> {
  List<LogisticsCo> _logisticsCos = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _refreshLogisticsCos();
  }

  Future<void> _refreshLogisticsCos() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllLogisticsCos();
    setState(() {
      _logisticsCos = data;
      _isLoading = false;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('امکان برقراری تماس وجود ندارد')),
        );
      }
    }
  }

  void _showLogisticsCoDialog({LogisticsCo? co}) {
    final nameController = TextEditingController(text: co?.name);
    final phoneController = TextEditingController(text: co?.phone);
    final bankController = TextEditingController(text: co?.bankName);
    final accountController = TextEditingController(text: co?.accountNumber);
    final ownerController = TextEditingController(text: co?.accountOwner);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(co == null ? 'افزودن باربری جدید' : 'ویرایش باربری', style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'نام باربری (اجباری)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'نام باربری را وارد کنید' : null,
                ),
                const SizedBox(height: 12),
                PhoneInput(controller: phoneController, label: 'شماره تماس باربری'),
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
                final newCo = LogisticsCo(
                  id: co?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  bankName: bankController.text.trim(),
                  accountNumber: accountController.text.trim(),
                  accountOwner: ownerController.text.trim(),
                );
                await DatabaseHelper.instance.insertLogisticsCo(newCo);
                if (mounted) Navigator.pop(context);
                _refreshLogisticsCos();
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
      appBar: AppBar(title: const Text('مدیریت باربری‌ها')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logisticsCos.isEmpty
              ? const Center(child: Text('باربری ثبت نشده است'))
              : ListView.builder(
                  itemCount: _logisticsCos.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final co = _logisticsCos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.business, color: Colors.blue),
                        ),
                        title: Text(co.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: InkWell(
                          onTap: co.phone.isNotEmpty ? () => _makePhoneCall(co.phone) : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(co.phone, style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showLogisticsCoDialog(co: co),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('تایید حذف'),
                                    content: Text('آیا از حذف باربری "${co.name}" اطمینان دارید؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await DatabaseHelper.instance.delete('logistics_cos', co.id);
                                  _refreshLogisticsCos();
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
        onPressed: () => _showLogisticsCoDialog(),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('افزودن باربری جدید', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
