import 'dart:io';
import '../../models/models.dart';
import '../database/database_helper.dart';

class ServiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> saveService(LoadService service) async => await _dbHelper.insert('load_services', service.toMap());
  
  Future<List<LoadService>> getAllServices() async => await _dbHelper.getAllServices();
  
  Future<void> deleteService(String id) async {
    final services = await getAllServices();
    LoadService? service;
    try {
      service = services.firstWhere((s) => s.id == id);
    } catch (e) {
      return;
    }

    List<String?> filesToDelete = [];
    filesToDelete.add(service.purchaseInvoiceImagePath);
    for (var exp in service.expenses.otherExpenses) {
      filesToDelete.add(exp.receiptImagePath);
    }

    final payments = await _dbHelper.queryAll('payments');
    for (var pMap in payments) {
      if (pMap['serviceId'] == id) {
        final payment = Payment.fromMap(pMap);
        filesToDelete.add(payment.receiptImagePath);
        filesToDelete.add(payment.checkImagePath);
        await _dbHelper.delete('payments', pMap['id']);
      }
    }

    for (var path in filesToDelete) {
      if (path != null && path.isNotEmpty) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Silent fail on file delete
        }
      }
    }

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
      if (codeInt != null && codeInt > maxCode) maxCode = codeInt;
    }
    return (maxCode + 1).toString();
  }
  
  Future<List<Driver>> getDrivers() async => await _dbHelper.getAllDrivers();
  Future<List<Car>> getCars() async => await _dbHelper.getAllCars();
  Future<List<Seller>> getSellers() async => await _dbHelper.getAllSellers();
  Future<List<Customer>> getCustomers() async => await _dbHelper.getAllCustomers();
  Future<List<LoadType>> getLoadTypes() async => await _dbHelper.getAllLoadTypes();
  Future<List<LogisticsCo>> getLogisticsCos() async => await _dbHelper.getAllLogisticsCos(); // متد جدید

  Future<void> saveDriver(Driver driver) async => await _dbHelper.insertDriver(driver);
  Future<void> saveCar(Car car) async => await _dbHelper.insertCar(car);
  Future<void> saveCustomer(Customer customer) async => await _dbHelper.insertCustomer(customer);
  Future<void> saveSeller(Seller seller) async => await _dbHelper.insertSeller(seller);
  Future<void> saveLoadType(LoadType type) async => await _dbHelper.insertLoadType(type);
  Future<void> saveLogisticsCo(LogisticsCo co) async => await _dbHelper.insertLogisticsCo(co); // متد جدید

  Future<void> saveMaintenance(Maintenance m) async => await _dbHelper.insertMaintenance(m);
  Future<List<Maintenance>> getMaintenances() async => await _dbHelper.getAllMaintenances();
  Future<void> deleteMaintenance(String id) async => await _dbHelper.delete('maintenances', id);

  Future<void> savePayment(Payment payment, {String? serviceId, String? sellerId, String? customerId}) async {
    await _dbHelper.insertPayment(payment, serviceId: serviceId, sellerId: sellerId, customerId: customerId);
  }

  Future<List<Payment>> getPayments() async => await _dbHelper.getAllPayments();
  Future<void> deletePayment(String id) async => await _dbHelper.delete('payments', id);

  // --- محاسبات دقیق مالی ---

  Future<double> getTotalServiceProfitInRange(DateTime start, DateTime end) async {
    final services = await getAllServices();
    return services
        .where((s) => (s.date.isAfter(start) || s.date.isAtSameMomentAs(start)) && (s.date.isBefore(end) || s.date.isAtSameMomentAs(end)))
        .fold<double>(0.0, (sum, s) => sum + s.netProfit);
  }

  Future<double> getRealNetProfitInRange(DateTime start, DateTime end) async {
    final serviceProfit = await getTotalServiceProfitInRange(start, end);
    
    final maintenanceList = await getMaintenances();
    final carExpensesList = await _dbHelper.getAllCarExpenses();

    double totalMaintenance = maintenanceList
        .where((m) => (m.date.isAfter(start) || m.date.isAtSameMomentAs(start)) && (m.date.isBefore(end) || m.date.isAtSameMomentAs(end)))
        .fold(0.0, (sum, m) => sum + m.cost);

    double totalCarExpenses = carExpensesList
        .where((e) => (e.date.isAfter(start) || e.date.isAtSameMomentAs(start)) && (e.date.isBefore(end) || e.date.isAtSameMomentAs(end)))
        .fold(0.0, (sum, e) => sum + e.amount);

    return serviceProfit - totalMaintenance - totalCarExpenses;
  }

  Future<double> getTotalUnpaidCustomerDebts() async {
    final services = await getAllServices();
    final allPayments = await getPayments();

    double totalServiceAmount = services.fold(0.0, (sum, s) => sum + s.totalServicePriceForCustomer);
    double totalCollected = allPayments
        .where((p) => p.type == PaymentType.fromCustomer && p.isCleared)
        .fold(0.0, (sum, p) => sum + p.amount);

    return totalServiceAmount - totalCollected;
  }

  Future<double> getTotalUnpaidSellerDebts() async {
    final services = await getAllServices();
    final allPayments = await getPayments();

    double totalPurchaseAmount = services.fold(0.0, (sum, s) => sum + s.totalPurchaseAmount);
    double totalPaid = allPayments
        .where((p) => p.type == PaymentType.toSeller && p.isCleared)
        .fold(0.0, (sum, p) => sum + p.amount);

    return totalPurchaseAmount - totalPaid;
  }

  Future<double> getCurrentCashBalance() async {
    final allPayments = await getPayments();
    final maintenanceList = await getMaintenances();
    final carExpensesList = await _dbHelper.getAllCarExpenses();
    final services = await getAllServices();

    double cashIn = allPayments
        .where((p) => p.type == PaymentType.fromCustomer && p.isCleared)
        .fold(0.0, (sum, p) => sum + p.amount);

    double cashOutToSellers = allPayments
        .where((p) => p.type == PaymentType.toSeller && p.isCleared)
        .fold(0.0, (sum, p) => sum + p.amount);

    double serviceExpenses = services.fold(0.0, (sum, s) => sum + s.expenses.total);
    double maintenanceCosts = maintenanceList.fold(0.0, (sum, m) => sum + m.cost);
    double carExpenses = carExpensesList.fold(0.0, (sum, e) => sum + e.amount);

    return cashIn - cashOutToSellers - serviceExpenses - maintenanceCosts - carExpenses;
  }
}
