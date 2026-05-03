import 'dart:io';
import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/data/service_repository.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final ServiceRepository _repository = ServiceRepository();
  final _formKey = GlobalKey<FormState>();
  List<Maintenance> _maintenances = [];
  List<Car> _cars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final m = await _repository.getMaintenances();
      final c = await _repository.getCars();
      if (!mounted) return;
      setState(() {
        _maintenances = m;
        _maintenances.sort((a, b) => b.date.compareTo(a.date));
        _cars = c;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showAddMaintenanceDialog() {
    final typeController = TextEditingController();
    final costController = TextEditingController();
    final kmController = TextEditingController();
    final nextKmController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    DateTime? nextDate;
    Car? selectedCar = _cars.isNotEmpty ? _cars.first : null;
    String? imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ثبت سرویس دوره‌ای (نت)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Car>(
                    value: selectedCar,
                    items: _cars.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (v) => setDialogState(() => selectedCar = v),
                    validator: (v) => v == null ? 'لطفاً خودرو را انتخاب کنید' : null,
                    decoration: const InputDecoration(labelText: 'انتخاب خودرو', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: typeController,
                    validator: (v) => (v == null || v.isEmpty) ? 'نوع سرویس را وارد کنید' : null,
                    decoration: const InputDecoration(labelText: 'نوع سرویس (مثلا: تعویض روغن)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'مبلغ را وارد کنید' : null,
                    decoration: const InputDecoration(labelText: 'هزینه (تومان)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: kmController,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'کیلومتر فعلی را وارد کنید' : null,
                    decoration: const InputDecoration(labelText: 'کیلومتر فعلی', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nextKmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'کیلومتر سرویس بعدی (اختیاری)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                    title: const Text('موعد زمانی بعدی (اختیاری)', style: TextStyle(fontSize: 12)),
                    subtitle: Text(nextDate == null ? 'انتخاب نشده' : nextDate!.toPersianDate()),
                    trailing: const Icon(Icons.calendar_month, size: 20),
                    onTap: () async {
                      final picked = await showPersianDatePicker(
                        context: context,
                        initialDate: Jalali.now(),
                        firstDate: Jalali.now(),
                        lastDate: Jalali(1450),
                      );
                      if (picked != null) setDialogState(() => nextDate = picked.toDateTime());
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) setDialogState(() => imagePath = picked.path);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: imagePath == null 
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                              Text('افزودن تصویر فاکتور/رسید', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(imagePath!), fit: BoxFit.cover),
                          ),
                    ),
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
                  final m = Maintenance(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    carId: selectedCar!.id,
                    type: typeController.text,
                    date: selectedDate,
                    cost: double.tryParse(costController.text) ?? 0,
                    currentKm: int.tryParse(kmController.text),
                    nextKm: int.tryParse(nextKmController.text),
                    nextDate: nextDate,
                    receiptImagePath: imagePath,
                  );

                  await _repository.saveMaintenance(m);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سرویس با موفقیت ثبت شد'), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Maintenance m) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سرویس'),
        content: Text('آیا از حذف سرویس "${m.type}" اطمینان دارید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف نهایی')
          ),
        ],
      ),
    );
    if (res == true) {
      await _repository.deleteMaintenance(m.id);
      _loadData();
    }
  }

  void _showImageDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(title: const Text('تصویر رسید سرویس'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
            Flexible(child: SingleChildScrollView(child: Image.file(File(path), fit: BoxFit.contain))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سرویس‌های دوره‌ای (نت)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _maintenances.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('هنوز هیچ سرویسی ثبت نشده است'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _maintenances.length,
                  itemBuilder: (context, index) {
                    final m = _maintenances[index];
                    final car = _cars.firstWhere((c) => c.id == m.carId, orElse: () => Car(id: '', name: 'نامشخص'));
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onLongPress: () => _confirmDelete(m),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.build_circle_outlined, color: Colors.blue),
                        ),
                        title: Text("${m.type} - ${car.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("تاریخ: ${m.date.toPersianDate()}"),
                            Text("هزینه: ${AppFormatters.formatCurrency(m.cost)} تومان"),
                            if (m.currentKm != null) Text("کیلومتر: ${m.currentKm.toString().toPersianDigit()}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.receiptImagePath != null)
                              IconButton(
                                icon: const Icon(Icons.receipt_long, color: Colors.blue),
                                onPressed: () => _showImageDialog(m.receiptImagePath!),
                              ),
                            if (m.nextKm != null || m.nextDate != null)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('سرویس بعدی', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                  if (m.nextKm != null)
                                    Text("${m.nextKm}".toPersianDigit(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 11)),
                                  if (m.nextDate != null)
                                    Text(m.nextDate!.toPersianDate(), style: const TextStyle(fontSize: 10, color: Colors.red)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMaintenanceDialog,
        icon: const Icon(Icons.add),
        label: const Text('ثبت سرویس جدید'),
      ),
    );
  }
}
