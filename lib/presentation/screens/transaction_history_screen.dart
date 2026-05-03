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
  List<dynamic> _groupedTransactions = [];
  Map<String, LoadService> _servicesMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAllTransactions();
    final services = await _repository.getAllServices();
    
    _servicesMap = {for (var s in services) s.id: s};
    
    List<dynamic> grouped = [];
    Set<String> processedServiceIds = {};

    for (var item in data) {
      if (item is Payment && item.serviceId != null) {
        if (processedServiceIds.contains(item.serviceId)) continue;
        
        // Find all transactions (payments) for this service in the entire list
        final servicePayments = data.whereType<Payment>().where((p) => p.serviceId == item.serviceId).toList();
        // They are already sorted by repository, but we want to keep them together
        grouped.add(servicePayments);
        processedServiceIds.add(item.serviceId!);
      } else {
        grouped.add(item);
      }
    }

    setState(() {
      _groupedTransactions = grouped;
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
          : _groupedTransactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groupedTransactions.length,
                  itemBuilder: (context, index) {
                    final item = _groupedTransactions[index];
                    if (item is List<Payment>) return _buildServiceGroup(item);
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

  Widget _buildServiceGroup(List<Payment> payments) {
    final serviceId = payments.first.serviceId;
    final service = _servicesMap[serviceId];
    final orderCode = service?.orderCode ?? "---";
    final route = service != null ? "${service.origin} به ${service.destination}" : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
        color: Colors.blue.shade50.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text("سرویس: $orderCode", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                const Spacer(),
                if (route.isNotEmpty)
                  Text(route, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...payments.map((p) => _buildPaymentTile(p, isInsideGroup: true)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(Payment p, {bool isInsideGroup = false}) {
    bool isIncoming = p.type == PaymentType.fromCustomer;
    bool isPending = p.method == PaymentMethod.check && !p.isCleared;
    Color color = isIncoming ? Colors.green : Colors.red;
    if (isPending) color = Colors.orange.shade800;
    
    IconData icon = isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
    
    String target = "";
    if (p.type == PaymentType.fromCustomer) target = "مشتری";
    else if (p.type == PaymentType.toSeller) target = "فروشنده";
    else if (p.type == PaymentType.toLogistics) target = "باربری";
    else target = "راننده";

    final service = p.serviceId != null ? _servicesMap[p.serviceId] : null;

    return Card(
      margin: isInsideGroup ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4) : const EdgeInsets.only(bottom: 12),
      elevation: isInsideGroup ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isPending ? Colors.orange.shade200 : (isInsideGroup ? Colors.blue.shade50 : Colors.transparent)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            if (!isInsideGroup && service != null)
              Text("سرویس: ${service.orderCode}", style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
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
