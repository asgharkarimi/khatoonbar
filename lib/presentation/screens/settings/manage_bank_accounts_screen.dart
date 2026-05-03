import 'package:flutter/material.dart';
import '../../../core/data/service_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';

class ManageBankAccountsScreen extends StatefulWidget {
  const ManageBankAccountsScreen({super.key});

  @override
  State<ManageBankAccountsScreen> createState() => _ManageBankAccountsScreenState();
}

class _ManageBankAccountsScreenState extends State<ManageBankAccountsScreen> {
  final ServiceRepository _repository = ServiceRepository();
  List<BankAccount> _accounts = [];
  Map<String, double> _balances = {};
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accounts = await _repository.getBankAccounts();
    Map<String, double> balances = {};
    for (var acc in accounts) {
      balances[acc.id] = await _repository.getAccountBalance(acc.id);
    }
    setState(() {
      _accounts = accounts;
      _balances = balances;
      _isLoading = false;
    });
  }

  void _showAddAccountDialog() {
    final bankNameController = TextEditingController();
    final accountInfoController = TextEditingController();
    final accountOwnerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_outlined, color: Colors.green.shade700, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'اطلاعات واریز کرایه',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  _buildStyledField(
                    controller: bankNameController,
                    hint: 'نام بانک',
                    icon: Icons.account_balance_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildStyledField(
                    controller: accountInfoController,
                    hint: 'شماره حساب/کارت',
                    icon: Icons.credit_card_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildStyledField(
                    controller: accountOwnerController,
                    hint: 'نام صاحب حساب',
                    icon: Icons.person_outline_rounded,
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newAccount = BankAccount(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    bankName: bankNameController.text.trim(),
                    accountNumber: accountInfoController.text.trim(),
                    accountOwner: accountOwnerController.text.trim(),
                    initialBalance: 0,
                  );
                  await _repository.saveBankAccount(newAccount);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadAccounts();
                  }
                }
              },
              child: const Text('ذخیره اطلاعات', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.green.shade600, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'این فیلد اجباری است' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('مدیریت حساب‌های بانکی'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _accounts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.blueGrey.shade100),
                        const SizedBox(height: 16),
                        const Text(
                          'هنوز هیچ حسابی ثبت نکرده‌اید',
                          style: TextStyle(color: Colors.blueGrey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      final currentBalance = _balances[account.id] ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.account_balance, color: Colors.blue),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    account.bankName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                  ),
                                  Text(
                                    AppFormatters.formatCurrency(currentBalance),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: currentBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    "صاحب حساب: ${account.accountOwner}",
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                  Text(
                                    "شماره: ${account.accountNumber}",
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: AlertDialog(
                                        title: const Text('حذف حساب'),
                                        content: const Text('آیا از حذف این حساب بانکی مطمئن هستید؟'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('بله', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _repository.deleteBankAccount(account.id);
                                    _loadAccounts();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddAccountDialog,
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text('افزودن حساب جدید', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
