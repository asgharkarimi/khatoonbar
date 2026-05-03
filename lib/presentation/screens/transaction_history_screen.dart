import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../core/data/service_repository.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ServiceRepository _repository = ServiceRepository();
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAllTransactions();
    setState(() {
      _transactions = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ریز تراکنش‌های مالی (دفتر کل)'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final item = _transactions[index];
                    if (item is Payment) return _buildPaymentTile(item);
                    if (item is Maintenance) return _buildMaintenanceTile(item);
                    if (item is CarExpense) return _buildCarExpenseTile(item);
                    return const SizedBox();
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('هیچ تراکنشی ثبت نشده است', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(Payment p) {
    bool isIncoming = p.type == PaymentType.fromCustomer;
    bool isPending = p.method == PaymentMethod.check && !p.isCleared;
    Color color = isIncoming ? Colors.green : Colors.red;
    if (isPending) color = Colors.orange.shade800;
    
    IconData icon = isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
    
    String target = "";
    if (p.type == PaymentType.fromCustomer) target = "مشتری";
    else if (p.type == PaymentType.toSeller) target = "فروشنده";
    else target = "باربری";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isPending ? Colors.orange.shade200 : Colors.transparent),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${AppFormatters.formatCurrency(p.amount)} تومان",
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            if (isPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                child: const Text("در جریان", style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${p.date.toPersianDate()} - $target"),
            if (p.description != null && p.description!.isNotEmpty)
              Text(p.description!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (p.method == PaymentMethod.check && p.checkDueDate != null)
              Text("سررسید: ${p.checkDueDate!.toPersianDate()}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Text(
          p.method == PaymentMethod.check ? "چک" : (p.method == PaymentMethod.cash ? "نقد" : (p.method == PaymentMethod.card ? "کارت" : "شبا")),
          style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
        ),
      ),
    );
  }

  Widget _buildMaintenanceTile(Maintenance m) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child: const Icon(Icons.build_circle, color: Colors.red, size: 20),
        ),
        title: Text(
          "${AppFormatters.formatCurrency(m.cost)} تومان",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        subtitle: Text("${m.date.toPersianDate()} - سرویس: ${m.type}"),
        trailing: const Text("هزینه نت", style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
      ),
    );
  }

  Widget _buildCarExpenseTile(CarExpense e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child: const Icon(Icons.handyman, color: Colors.red, size: 20),
        ),
        title: Text(
          "${AppFormatters.formatCurrency(e.amount)} تومان",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        subtitle: Text("${e.date.toPersianDate()} - ${e.description}"),
        trailing: const Text("هزینه متفرقه", style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
      ),
    );
  }
}
