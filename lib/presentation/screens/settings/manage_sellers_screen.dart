import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/models.dart';

class ManageSellersScreen extends StatefulWidget {
  const ManageSellersScreen({super.key});

  @override
  State<ManageSellersScreen> createState() => _ManageSellersScreenState();
}

class _ManageSellersScreenState extends State<ManageSellersScreen> {
  List<Seller> _sellers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshSellers();
  }

  Future<void> _refreshSellers() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllSellers();
    setState(() {
      _sellers = data;
      _isLoading = false;
    });
  }

  void _showAddSellerDialog() {
    final nameController = TextEditingController();
    final productController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن فروشنده جدید', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'نام شرکت یا فروشنده')),
            TextField(controller: productController, decoration: const InputDecoration(labelText: 'محصول (مثلاً ماسه، آجر)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newSeller = Seller(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  product: productController.text,
                );
                await DatabaseHelper.instance.insertSeller(newSeller);
                if (mounted) Navigator.pop(context);
                _refreshSellers();
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
      appBar: AppBar(title: const Text('مدیریت فروشندگان')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sellers.isEmpty
              ? const Center(child: Text('فروشنده‌ای ثبت نشده است'))
              : ListView.builder(
                  itemCount: _sellers.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final seller = _sellers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.withOpacity(0.1),
                          child: const Icon(Icons.storefront, color: Colors.teal),
                        ),
                        title: Text(seller.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(seller.product),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('تایید حذف'),
                                content: Text('آیا از حذف "${seller.name}" اطمینان دارید؟'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await DatabaseHelper.instance.delete('sellers', seller.id);
                              _refreshSellers();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSellerDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
