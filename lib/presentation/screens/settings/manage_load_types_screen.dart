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

  void _showAddLoadTypeDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن نوع بار جدید', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'نام بار (مثلاً آجر، سیمان)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newType = LoadType(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                );
                await DatabaseHelper.instance.insertLoadType(newType);
                if (mounted) Navigator.pop(context);
                _refreshLoadTypes();
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
                        trailing: IconButton(
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
                      ),
                    );
                  },
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLoadTypeDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
