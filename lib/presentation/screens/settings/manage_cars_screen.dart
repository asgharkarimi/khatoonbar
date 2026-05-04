import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/biometric_helper.dart';
import '../../../models/models.dart';
import '../../widgets/iranian_plate_input.dart';
import '../../widgets/plate_widget.dart';

class ManageCarsScreen extends StatefulWidget {
  const ManageCarsScreen({super.key});

  @override
  State<ManageCarsScreen> createState() => _ManageCarsScreenState();
}

class _ManageCarsScreenState extends State<ManageCarsScreen> {
  List<Car> _cars = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _refreshCars();
  }

  Future<void> _refreshCars() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllCars();
    setState(() {
      _cars = data;
      _isLoading = false;
    });
  }

  void _showCarDialog({Car? car}) {
    final nameController = TextEditingController(text: car?.name);
    String plateValue = car?.plate ?? "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(car == null ? 'افزودن ماشین جدید' : 'ویرایش ماشین', style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController, 
                  decoration: const InputDecoration(labelText: 'نام ماشین (اجباری)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'نام ماشین را وارد کنید' : null,
                ),
                const SizedBox(height: 16),
                const Text('شماره پلاک:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                IranianPlateInput(
                  initialValue: plateValue,
                  onChanged: (v) => plateValue = v,
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
                final newCar = Car(
                  id: car?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  plate: plateValue,
                );
                await DatabaseHelper.instance.insertCar(newCar);
                if (mounted) Navigator.pop(context);
                _refreshCars();
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
      appBar: AppBar(title: const Text('مدیریت ماشین‌ها')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cars.isEmpty
              ? const Center(child: Text('ماشینی ثبت نشده است'))
              : ListView.builder(
                  itemCount: _cars.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final car = _cars[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            child: const Icon(Icons.local_shipping, color: Colors.orange),
                          ),
                          title: Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: car.plate != null && car.plate!.isNotEmpty && car.plate != "---"
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: PlateWidget(plate: car.plate!, scale: 0.85),
                                )
                              : const Text("بدون پلاک", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                onPressed: () => _showCarDialog(car: car),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('تایید حذف'),
                                      content: Text('آیا از حذف "${car.name}" اطمینان دارید؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله')),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    bool authenticated = await BiometricHelper.authenticate(
                                      reason: 'تایید هویت برای حذف ماشین ${car.name}'
                                    );
                                    if (authenticated) {
                                      await DatabaseHelper.instance.delete('cars', car.id);
                                      _refreshCars();
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عدم تایید هویت. حذف لغو شد.')));
                                      }
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCarDialog(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('افزودن ماشین جدید', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
