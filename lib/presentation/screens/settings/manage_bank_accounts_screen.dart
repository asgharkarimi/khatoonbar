import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';
import '../../widgets/amount_input.dart';

class ManageBankAccountsScreen extends StatefulWidget {
  const ManageBankAccountsScreen({super.key});

  @override
  State<ManageBankAccountsScreen> createState() => _ManageBankAccountsScreenState();
}

class _ManageBankAccountsScreenState extends State<ManageBankAccountsScreen> {
  List<BankAccount> _accounts = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accounts = await DatabaseHelper.instance.getAllBankAccounts();
    setState(() {
      _accounts = accounts;
      _isLoading = false;
    });
  }

  void _showAddAccountDialog() {
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final accountOwnerController = TextEditingController();
    final cardNumberController = TextEditingController();
    final shebaController = TextEditingController();
    double initialBalance = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن حساب بانکی'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: bankNameController,
                  decoration: const InputDecoration(labelText: 'نام بانک (اجباری)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'نام بانک را وارد کنید' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: accountNumberController,
                  decoration: const InputDecoration(labelText: 'شماره حساب (اجباری)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'شماره حساب را وارد کنید' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: accountOwnerController,
                  decoration: const InputDecoration(labelText: 'نام صاحب حساب (اجباری)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'نام صاحب حساب را وارد کنید' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cardNumberController,
                  decoration: const InputDecoration(labelText: 'شماره کارت (اختیاری)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: shebaController,
                  decoration: const InputDecoration(labelText: 'شماره شبا (اختیاری)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                AmountInput(
                  label: 'موجودی اولیه (تومان)',
                  onChanged: (val) => initialBalance = val,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newAccount = BankAccount(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  bankName: bankNameController.text.trim(),
                  accountNumber: accountNumberController.text.trim(),
                  accountOwner: accountOwnerController.text.trim(),
                  cardNumber: cardNumberController.text.trim(),
                  sheba: shebaController.text.trim(),
                  initialBalance: initialBalance,
                );
                await DatabaseHelper.instance.insertBankAccount(newAccount);
                if (mounted) {
                  Navigator.pop(context);
                  _loadAccounts();
                }
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
      appBar: AppBar(title: const Text('مدیریت حساب‌های من')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('هنوز هیچ حسابی ثبت نکرده‌اید'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final account = _accounts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.account_balance, color: Colors.blue),
                        ),
                        title: Text(account.bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("صاحب حساب: ${account.accountOwner}"),
                            Text("شماره: ${account.accountNumber}"),
                            if (account.cardNumber != null && account.cardNumber!.isNotEmpty)
                              Text("کارت: ${account.cardNumber}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('حذف حساب'),
                                content: const Text('آیا از حذف این حساب بانکی مطمئن هستید؟'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await DatabaseHelper.instance.delete('bank_accounts', account.id);
                              _loadAccounts();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountDialog,
        icon: const Icon(Icons.add),
        label: const Text('افزودن حساب جدید'),
      ),
    );
  }
}
