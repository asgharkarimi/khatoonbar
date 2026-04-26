import '../../models/models.dart';
import '../database/database_helper.dart';

class ServiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> saveService(LoadService service) async => await _dbHelper.insert('load_services', service.toMap());
  
  Future<List<LoadService>> getAllServices() async => await _dbHelper.getAllServices();
  
  Future<void> deleteService(String id) async {
    // ابتدا تمام پرداخت‌های مربوط به این سرویس را حذف می‌کنیم
    final payments = await _dbHelper.queryAll('payments');
    for (var p in payments) {
      if (p['serviceId'] == id) {
        await _dbHelper.delete('payments', p['id']);
      }
    }
    // سپس خود سرویس را حذف می‌کنیم
    await _dbHelper.delete('load_services', id);
  }

  Future<bool> isOrderCodeDuplicate(String code, {String? excludeId}) async {
    final services = await _dbHelper.getAllServices();
    return services.any((s) => s.orderCode == code && s.id != excludeId);
  }

  Future<String> generateUniqueOrderCode() async {
    final services = await _dbHelper.getAllServices();
    int maxCode = 1000;
    
    for (var s in services) {
      final codeInt = int.tryParse(s.orderCode);
      if (codeInt != null && codeInt > maxCode) {
        maxCode = codeInt;
      }
    }
    
    return (maxCode + 1).toString();
  }
  
  Future<List<Driver>> getDrivers() async => await _dbHelper.getAllDrivers();
  Future<List<Car>> getCars() async => await _dbHelper.getAllCars();
  Future<List<Seller>> getSellers() async => await _dbHelper.getAllSellers();
  Future<List<Customer>> getCustomers() async => await _dbHelper.getAllCustomers();
  Future<List<LoadType>> getLoadTypes() async => await _dbHelper.getAllLoadTypes();

  Future<void> savePayment(Payment payment, {String? serviceId, String? sellerId, String? customerId}) async {
    await _dbHelper.insertPayment(
      payment, 
      serviceId: serviceId, 
      sellerId: sellerId, 
      customerId: customerId,
    );
  }

  Future<List<Payment>> getPayments() async => await _dbHelper.getAllPayments();
  
  Future<void> deletePayment(String id) async => await _dbHelper.delete('payments', id);
}
