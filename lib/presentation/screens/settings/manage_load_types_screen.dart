import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/models.dart';

class ManageLoadTypesScreen extends StatefulWidget {
  const ManageLoadTypesScreen({super.key});

  @override
  State<ManageLoadTypesScreen> createState() => _ManageLoadTypesScreenState();
}

class _ManageLoadTypesScreenState extends State<ManageLoadTypesScreen> {
  List<LoadType> _loadTypes = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _refreshLoadTypes();
  }

  Future<void> _refreshLoadTypes() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllLoadTypes();
    setState(() {
      _loadTypes = data;
      _isLoading = false;
    });
  }

  void _showLoadTypeDialog({LoadType? loadType}) {
    final nameController = TextEditingController(text: loadType?.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loadType == null ? 'افزودن نوع بار جدید' : 'ویرایش نوع بار', style: const TextStyle(fontSize: 16)),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'نام بار (مثلاً آجر، سیمان)', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.isEmpty) ? 'نام بار را وارد کنید' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newType = LoadType(
                  id: loadType?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                );
                await DatabaseHelper.instance.insertLoadType(newType);
                if (mounted) Navigator.pop(context);
                _refreshLoadTypes();
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
      appBar: AppBar(title: const Text('مدیریت انواع بار')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadTypes.isEmpty
              ? const Center(child: Text('موردی ثبت نشده است'))
              : ListView.builder(
                  itemCount: _loadTypes.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final type = _loadTypes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          child: const Icon(Icons.category, color: Colors.purple),
                        ),
                        title: Text(type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showLoadTypeDialog(loadType: type),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('تایید حذف'),
                                    content: Text('آیا از حذف "${type.name}" اطمینان دارید؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await DatabaseHelper.instance.delete('load_types', type.id);
                                  _refreshLoadTypes();
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
        onPressed: () => _showLoadTypeDialog(),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('افزودن نوع بار جدید', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
