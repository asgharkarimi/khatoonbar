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
  final _formKey = GlobalKey<FormState>();

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

  void _showSellerDialog({Seller? seller}) {
    final nameController = TextEditingController(text: seller?.name);
    final productController = TextEditingController(text: seller?.product);
    final bankController = TextEditingController(text: seller?.bankName);
    final accountController = TextEditingController(text: seller?.accountNumber);
    final ownerController = TextEditingController(text: seller?.accountOwner);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(seller == null ? 'افزودن فروشنده جدید' : 'ویرایش فروشنده', style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController, 
                  decoration: const InputDecoration(labelText: 'نام شرکت یا فروشنده (اجباری)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'نام را وارد کنید' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: productController, 
                  decoration: const InputDecoration(labelText: 'محصول (مثلاً ماسه، آجر)', border: OutlineInputBorder()),
                ),
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
                final newSeller = Seller(
                  id: seller?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  product: productController.text.trim(),
                  bankName: bankController.text.trim(),
                  accountNumber: accountController.text.trim(),
                  accountOwner: ownerController.text.trim(),
                );
                await DatabaseHelper.instance.insertSeller(newSeller);
                if (mounted) Navigator.pop(context);
                _refreshSellers();
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showSellerDialog(seller: seller),
                            ),
                            IconButton(
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSellerDialog(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('افزودن فروشنده جدید', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
