import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';
import '../../widgets/amount_input.dart';

class ManageChecksScreen extends StatefulWidget {
  const ManageChecksScreen({super.key});

  @override
  State<ManageChecksScreen> createState() => _ManageChecksScreenState();
}

class _ManageChecksScreenState extends State<ManageChecksScreen> {
  List<Payment> _allChecks = [];
  List<Seller> _sellers = [];
  List<Driver> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final payments = await DatabaseHelper.instance.getAllPayments();
    final sellers = await DatabaseHelper.instance.getAllSellers();
    final drivers = await DatabaseHelper.instance.getAllDrivers();
    
    setState(() {
      _allChecks = payments.where((p) => p.method == PaymentMethod.check).toList();
      _allChecks.sort((a, b) => (a.checkDueDate ?? DateTime.now()).compareTo(b.checkDueDate ?? DateTime.now()));
      _sellers = sellers;
      _drivers = drivers;
      _isLoading = false;
    });
  }

  void _showEditDialog(Payment p) {
    final bankController = TextEditingController(text: p.bankName);
    final numberController = TextEditingController(text: p.checkNumber);
    final descController = TextEditingController(text: p.description);
    double amount = p.amount;
    DateTime? dueDate = p.checkDueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ویرایش اطلاعات چک', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AmountInput(label: 'مبلغ چک', initialValue: amount, onChanged: (v) => amount = v),
                const SizedBox(height: 12),
                TextField(controller: bankController, decoration: const InputDecoration(labelText: 'نام بانک', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: numberController, decoration: const InputDecoration(labelText: 'شماره چک', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    Jalali? picked = await showPersianDatePicker(
                      context: context, 
                      initialDate: Jalali.fromDateTime(dueDate ?? DateTime.now()), 
                      firstDate: Jalali(1400, 1, 1), 
                      lastDate: Jalali(1450, 12, 29)
                    );
                    if (picked != null) setDialogState(() => dueDate = picked.toDateTime());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dueDate == null ? 'تاریخ سررسید' : dueDate!.toPersianDate().toPersianDigit()),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'توضیحات', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                final updated = Payment(
                  id: p.id, 
                  serviceId: p.serviceId, 
                  sellerId: p.sellerId, 
                  customerId: p.customerId,
                  logisticsId: p.logisticsId, 
                  driverId: p.driverId, 
                  myAccountId: p.myAccountId,
                  type: p.type, 
                  method: p.method, 
                  amount: amount, 
                  date: p.date,
                  description: descController.text, 
                  checkDueDate: dueDate,
                  bankName: bankController.text, 
                  checkNumber: numberController.text,
                  status: p.status, 
                  isCleared: p.isCleared, 
                  transferredToId: p.transferredToId,
                );
                await DatabaseHelper.instance.insertPayment(updated);
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('ذخیره تغییرات'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(Payment p, CheckStatus status) async {
    final updated = Payment(
      id: p.id, 
      serviceId: p.serviceId, 
      sellerId: p.sellerId, 
      customerId: p.customerId,
      logisticsId: p.logisticsId, 
      driverId: p.driverId, 
      myAccountId: p.myAccountId,
      type: p.type, 
      method: p.method, 
      amount: p.amount, 
      date: p.date,
      description: p.description, 
      checkDueDate: p.checkDueDate,
      bankName: p.bankName, 
      checkNumber: p.checkNumber,
      status: status, 
      isCleared: status == CheckStatus.cleared || status == CheckStatus.transferred,
      transferredToId: p.transferredToId,
    );
    await DatabaseHelper.instance.insertPayment(updated);
    _loadData();
  }

  void _showTransferDialog(Payment p) {
    if (p.type != PaymentType.fromCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فقط چک‌های دریافتی قابل واگذاری هستند')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('واگذاری چک به:'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('فروشنده (شرکت/ماسه شویی)'), onTap: () { Navigator.pop(context); _pickTarget(p, 'seller'); }),
            ListTile(title: const Text('راننده'), onTap: () { Navigator.pop(context); _pickTarget(p, 'driver'); }),
          ],
        ),
      ),
    );
  }

  void _pickTarget(Payment p, String type) {
    showDialog(
      context: context,
      builder: (context) {
        List<dynamic> items = type == 'seller' ? _sellers : _drivers;
        return AlertDialog(
          title: Text(type == 'seller' ? 'انتخاب فروشنده' : 'انتخاب راننده'),
          content: SizedBox(width: double.maxFinite, child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(type == 'seller' ? items[index].name : items[index].fullName),
              onTap: () { Navigator.pop(context); _executeTransfer(p, items[index], type); },
            ),
          )),
        );
      }
    );
  }

  Future<void> _executeTransfer(Payment p, dynamic target, String type) async {
    final updatedP = Payment(
      id: p.id, 
      serviceId: p.serviceId, 
      sellerId: p.sellerId, 
      customerId: p.customerId,
      logisticsId: p.logisticsId, 
      driverId: p.driverId, 
      myAccountId: p.myAccountId,
      type: p.type, 
      method: p.method, 
      amount: p.amount, 
      date: p.date,
      description: "${p.description ?? ''} (واگذار به ${type == 'seller' ? target.name : target.fullName})",
      checkDueDate: p.checkDueDate, 
      bankName: p.bankName, 
      checkNumber: p.checkNumber,
      status: CheckStatus.transferred, 
      isCleared: true, 
      transferredToId: target.id,
    );
    
    final receiptPayment = Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sellerId: type == 'seller' ? target.id : null,
      driverId: type == 'driver' ? target.id : null,
      type: type == 'seller' ? PaymentType.toSeller : PaymentType.toDriver,
      method: PaymentMethod.check, 
      amount: p.amount, 
      date: DateTime.now(),
      description: "واگذاری چک (${p.bankName} - ${p.checkNumber})",
      checkDueDate: p.checkDueDate, 
      bankName: p.bankName, 
      checkNumber: p.checkNumber,
      status: CheckStatus.cleared, 
      isCleared: true,
    );
    
    await DatabaseHelper.instance.insertPayment(updatedP);
    await DatabaseHelper.instance.insertPayment(receiptPayment);
    _loadData();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('چک با موفقیت واگذار شد')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت و عملیات چک‌ها')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) :
      _allChecks.isEmpty ? const Center(child: Text('چکی یافت نشد')) :
      ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allChecks.length,
        itemBuilder: (context, index) {
          final p = _allChecks[index];
          Color col = p.status == CheckStatus.cleared ? Colors.green : (p.status == CheckStatus.bounced ? Colors.red : Colors.orange);
          String statusLabel = "در جریان";
          if (p.status == CheckStatus.cleared) statusLabel = "وصول شده";
          if (p.status == CheckStatus.bounced) statusLabel = "برگشتی";
          if (p.status == CheckStatus.transferred) statusLabel = "واگذار شده";

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: col.withOpacity(0.3))),
            child: Column(
              children: [
                ListTile(
                  title: Text("${AppFormatters.formatCurrency(p.amount)} تومان", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("بانک ${p.bankName} - سررسید: ${p.checkDueDate?.toPersianDate().toPersianDigit()}", style: TextStyle(color: col, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(statusLabel, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue), onPressed: () => _showEditDialog(p)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (p.status == CheckStatus.pending) ...[
                        TextButton(onPressed: () => _updateStatus(p, CheckStatus.cleared), child: const Text('وصول', style: TextStyle(color: Colors.green))),
                        TextButton(onPressed: () => _updateStatus(p, CheckStatus.bounced), child: const Text('برگشت', style: TextStyle(color: Colors.red))),
                        if (p.type == PaymentType.fromCustomer)
                          TextButton(onPressed: () => _showTransferDialog(p), child: const Text('واگذاری', style: TextStyle(color: Colors.purple))),
                      ] else 
                        TextButton(onPressed: () => _updateStatus(p, CheckStatus.pending), child: const Text('بازگشت به در جریان', style: TextStyle(color: Colors.grey, fontSize: 11))),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () async {
                        bool? confirm = await showDialog<bool>(
                          context: context, 
                          builder: (c) => AlertDialog(
                            title: const Text('حذف تراکنش چک؟'), 
                            content: const Text('آیا از حذف دائمی این چک اطمینان دارید؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('خیر')), 
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('بله، حذف شود'))
                            ]
                          )
                        );
                        if (confirm == true) {
                          await DatabaseHelper.instance.delete('payments', p.id!); 
                          _loadData();
                        }
                      }),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
