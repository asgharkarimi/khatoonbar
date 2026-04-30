import 'package:flutter/material.dart';
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

  void _showLogisticsCoDialog({LogisticsCo? co}) {
    final nameController = TextEditingController(text: co?.name);
    final phoneController = TextEditingController(text: co?.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(co == null ? 'افزودن باربری جدید' : 'ویرایش باربری', style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'نام باربری'),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              PhoneInput(controller: phoneController, label: 'شماره تماس باربری'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newCo = LogisticsCo(
                  id: co?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  phone: phoneController.text,
                );
                await DatabaseHelper.instance.insertLogisticsCo(newCo);
                if (mounted) Navigator.pop(context);
                _refreshLogisticsCos();
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
                        subtitle: Text(co.phone),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogisticsCoDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
