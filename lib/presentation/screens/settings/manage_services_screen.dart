import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../../core/data/service_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/biometric_helper.dart';
import '../../../models/models.dart';
import '../add_service_screen.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final ServiceRepository _repository = ServiceRepository();
  List<LoadService> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshServices();
  }

  Future<void> _refreshServices() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAllServices();
    setState(() {
      _services = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteService(LoadService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تایید حذف'),
        content: Text('آیا از حذف سرویس با کد "${service.orderCode}" اطمینان دارید؟ تمامی تراکنش‌های مربوط به این سرویس نیز حذف خواهند شد.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله، حذف شود')),
        ],
      ),
    );

    if (confirm == true) {
      // احراز هویت بیومتریک قبل از حذف قطعی
      bool authenticated = await BiometricHelper.authenticate(
        reason: 'تایید هویت برای حذف سرویس ${service.orderCode}'
      );

      if (authenticated) {
        await _repository.deleteService(service.id);
        _refreshServices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سرویس با موفقیت حذف شد')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عدم تایید هویت. عملیات حذف لغو شد.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت سرویس‌ها')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text('سرویسی ثبت نشده است'))
              : ListView.builder(
                  itemCount: _services.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final s = _services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.local_shipping, color: Colors.blue),
                        ),
                        title: Text("${s.loadType.name} (${s.orderCode.toPersianDigit()})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("راننده: ${s.driver.fullName}", style: const TextStyle(fontSize: 11)),
                            Text("مقصد: ${s.destination}", style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AddServiceScreen(serviceToEdit: s)),
                                );
                                if (result == true) _refreshServices();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteService(s),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
