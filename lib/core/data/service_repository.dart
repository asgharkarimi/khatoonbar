import 'dart:io';
import '../../models/models.dart';
import '../database/database_helper.dart';

class ServiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> saveService(LoadService service) async {
    await _dbHelper.insert('load_services', service.toMap());
    
    // ذخیره خودکار پیشنهادات برای فیلدهای متنی
    await addSuggestion('origins', service.origin);
    await addSuggestion('destinations', service.destination);
    
    if (service.logisticsName != null && service.logisticsName!.isNotEmpty) {
      await addSuggestion('logistics_names', service.logisticsName!);
    }
    
    if (service.fareBankName != null && service.fareBankName!.isNotEmpty) {
      await addSuggestion('bank_names', service.fareBankName!);
    }
    
    if (service.fareAccountOwner != null && service.fareAccountOwner!.isNotEmpty) {
      await addSuggestion('account_owners', service.fareAccountOwner!);
    }

    for (var exp in service.expenses.otherExpenses) {
      await addSuggestion('expense_titles', exp.title);
    }

    // ذخیره پیشنهادات نام عوارضی
    for (var toll in service.expenses.tolls) {
      if (toll.name.isNotEmpty) {
        await addSuggestion('toll_names', toll.name);
      }
    }
  }
  
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
          // Silent fail
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
  Future<List<LogisticsCo>> getLogisticsCos() async => await _dbHelper.getAllLogisticsCos();
  Future<List<BankAccount>> getBankAccounts() async => await _dbHelper.getAllBankAccounts();

  Future<void> saveDriver(Driver driver) async => await _dbHelper.insertDriver(driver);
  Future<void> saveCar(Car car) async => await _dbHelper.insertCar(car);
  Future<void> saveCustomer(Customer customer) async => await _dbHelper.insertCustomer(customer);
  Future<void> saveSeller(Seller seller) async => await _dbHelper.insertSeller(seller);
  Future<void> saveLoadType(LoadType type) async => await _dbHelper.insertLoadType(type);
  Future<void> saveLogisticsCo(LogisticsCo co) async => await _dbHelper.insertLogisticsCo(co);
  Future<void> saveBankAccount(BankAccount acc) async => await _dbHelper.insertBankAccount(acc);

  Future<void> saveMaintenance(Maintenance m) async => await _dbHelper.insertMaintenance(m);
  Future<List<Maintenance>> getMaintenances() async => await _dbHelper.getAllMaintenances();
  Future<void> deleteMaintenance(String id) async {
    final mList = await getMaintenances();
    try {
      final m = mList.firstWhere((item) => item.id == id);
      if (m.receiptImagePath != null && m.receiptImagePath!.isNotEmpty) {
        final file = File(m.receiptImagePath!);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    await _dbHelper.delete('maintenances', id);
  }

  Future<void> saveCarExpense(CarExpense e) async => await _dbHelper.insertCarExpense(e);
  Future<List<CarExpense>> getCarExpenses() async => await _dbHelper.getAllCarExpenses();
  Future<void> deleteCarExpense(String id) async {
    final eList = await getCarExpenses();
    try {
      final e = eList.firstWhere((item) => item.id == id);
      if (e.receiptImagePath != null && e.receiptImagePath!.isNotEmpty) {
        final file = File(e.receiptImagePath!);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    await _dbHelper.delete('car_expenses', id);
  }
  
  Future<void> deleteBankAccount(String id) async => await _dbHelper.delete('bank_accounts', id);

  Future<void> savePayment(Payment payment, {String? serviceId, String? sellerId, String? customerId, String? logisticsId, String? driverId}) async {
    await _dbHelper.insertPayment(payment, serviceId: serviceId, sellerId: sellerId, customerId: customerId, logisticsId: logisticsId, driverId: driverId);
  }

  Future<List<Payment>> getPayments() async => await _dbHelper.getAllPayments();
  
  Future<void> deletePayment(String id) async {
    final pList = await getPayments();
    try {
      final p = pList.firstWhere((item) => item.id == id);
      if (p.receiptImagePath != null && p.receiptImagePath!.isNotEmpty) {
        final file = File(p.receiptImagePath!);
        if (await file.exists()) await file.delete();
      }
      if (p.checkImagePath != null && p.checkImagePath!.isNotEmpty) {
        final file = File(p.checkImagePath!);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    await _dbHelper.delete('payments', id);
  }

  // --- Suggestions ---
  Future<List<String>> getSuggestions(String key) async => await _dbHelper.getSuggestions(key);
  Future<void> addSuggestion(String key, String value) async => await _dbHelper.addSuggestion(key, value);

  // --- Individual Balance Methods ---

  Future<double> getCustomerBalance(String customerId) async {
    final services = await getAllServices();
    final payments = await getPayments();
    
    final customerServices = services.where((s) => s.customer?.id == customerId).toList();
    double totalBilling = customerServices.fold(0.0, (sum, s) => sum + s.totalServicePriceForCustomer);
    
    final customerServiceIds = customerServices.map((s) => s.id).toSet();
    final relevantPayments = payments.where((p) => p.type == PaymentType.fromCustomer && (p.customerId == customerId || (p.serviceId != null && customerServiceIds.contains(p.serviceId))));
    
    double totalPaid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
    double totalPending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
    
    return totalBilling - totalPaid - totalPending;
  }

  Future<double> getSellerBalance(String sellerId) async {
    final services = await getAllServices();
    final payments = await getPayments();
    
    final sellerServices = services.where((s) => s.seller.id == sellerId).toList();
    double totalBilling = sellerServices.fold(0.0, (sum, s) => sum + s.totalPurchaseAmount);
    
    final sellerServiceIds = sellerServices.map((s) => s.id).toSet();
    final relevantPayments = payments.where((p) => p.type == PaymentType.toSeller && (p.sellerId == sellerId || (p.serviceId != null && sellerServiceIds.contains(p.serviceId))));
    
    double totalPaid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
    double totalPending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
    
    return totalBilling - totalPaid - totalPending;
  }

  Future<double> getLogisticsBalance(String logisticsId) async {
    final services = await getAllServices();
    final payments = await getPayments();
    
    final logisticsServices = services.where((s) => s.logisticsCo?.id == logisticsId).toList();
    double totalBilling = logisticsServices.fold(0.0, (sum, s) => sum + s.expenses.owedToLogistics);
    
    final logisticsServiceIds = logisticsServices.map((s) => s.id).toSet();
    final relevantPayments = payments.where((p) => p.type == PaymentType.toLogistics && (p.logisticsId == logisticsId || (p.serviceId != null && logisticsServiceIds.contains(p.serviceId))));
    
    double totalPaid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
    double totalPending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
    
    return totalBilling - totalPaid - totalPending;
  }

  Future<double> getDriverBalance(String driverId) async {
    final services = await getAllServices();
    final payments = await getPayments();
    
    final driverServices = services.where((s) => s.driver.id == driverId).toList();
    double totalEarned = driverServices.fold(0.0, (sum, s) => sum + s.netProfit);
    
    final driverServiceIds = driverServices.map((s) => s.id).toSet();
    final relevantPayments = payments.where((p) => p.type == PaymentType.toDriver && (p.driverId == driverId || (p.serviceId != null && driverServiceIds.contains(p.serviceId))));
    
    double totalPaid = relevantPayments.where((p) => p.isCleared).fold(0.0, (sum, p) => sum + p.amount);
    double totalPending = relevantPayments.where((p) => !p.isCleared && p.method == PaymentMethod.check).fold(0.0, (sum, p) => sum + p.amount);
    
    return totalEarned - totalPaid - totalPending;
  }

  // --- Aggregate Financial Stats ---

  Future<double> getTotalUnpaidCustomerDebts() async {
    final customers = await getCustomers();
    double total = 0;
    for (var c in customers) {
      double bal = await getCustomerBalance(c.id);
      if (bal > 0) total += bal;
    }
    return total;
  }

  Future<double> getTotalUnpaidSellerDebts() async {
    final sellers = await getSellers();
    double total = 0;
    for (var s in sellers) {
      double bal = await getSellerBalance(s.id);
      if (bal > 0) total += bal;
    }
    return total;
  }

  Future<double> getTotalUnpaidLogisticsDebts() async {
    final logistics = await getLogisticsCos();
    double total = 0;
    for (var l in logistics) {
      double bal = await getLogisticsBalance(l.id);
      if (bal > 0) total += bal;
    }
    return total;
  }

  Future<double> getCurrentCashBalance() async {
    final allPayments = await getPayments();
    final maintenanceList = await getMaintenances();
    final carExpensesList = await getCarExpenses();
    final services = await getAllServices();
    final bankAccounts = await getBankAccounts();

    double cashIn = allPayments
        .where((p) => p.type == PaymentType.fromCustomer && p.isCleared)
        .fold(0.0, (sum, p) => sum + p.amount);

    double cashOutToSellers = allPayments
        .where((p) => p.type == PaymentType.toSeller && p.isCleared)
        .fold(0.0, (sum, p) => sum + p.amount);
        
    double cashOutToLogistics = allPayments
        .where((p) => p.type == PaymentType.toLogistics && p.isCleared)
        .fold(0.0, (sum, p) => sum + p.amount);
        
    double cashOutToDrivers = allPayments
        .where((p) => p.type == PaymentType.toDriver && p.isCleared)
        .fold(0.0, (sum, p) => sum + p.amount);

    double directCashExpenses = services.fold(0.0, (sum, s) => sum + (s.expenses.total - s.expenses.owedToLogistics));
    double maintenanceCosts = maintenanceList.fold(0.0, (sum, m) => sum + m.cost);
    double carExpenses = carExpensesList.fold(0.0, (sum, e) => sum + e.amount);
    
    double initialBankBalances = bankAccounts.fold(0.0, (sum, acc) => sum + acc.initialBalance);

    return initialBankBalances + cashIn - cashOutToSellers - cashOutToLogistics - cashOutToDrivers - directCashExpenses - maintenanceCosts - carExpenses;
  }
  
  Future<double> getAccountBalance(String accountId) async {
    final bankAccounts = await getBankAccounts();
    final account = bankAccounts.firstWhere((a) => a.id == accountId);
    
    final allPayments = await getPayments();
    final clearedPayments = allPayments.where((p) => p.myAccountId == accountId && p.isCleared);
    
    double incoming = clearedPayments
        .where((p) => p.type == PaymentType.fromCustomer)
        .fold(0.0, (sum, p) => sum + p.amount);
        
    double outgoing = clearedPayments
        .where((p) => p.type != PaymentType.fromCustomer)
        .fold(0.0, (sum, p) => sum + p.amount);
        
    return account.initialBalance + incoming - outgoing;
  }

  Future<List<dynamic>> getAllTransactions() async {
    final payments = await getPayments();
    final maintenance = await getMaintenances();
    final carExpenses = await getCarExpenses();
    
    List<dynamic> all = [];
    all.addAll(payments);
    all.addAll(maintenance);
    all.addAll(carExpenses);
    
    all.sort((a, b) {
      DateTime dateA = (a is Payment) ? a.date : (a is Maintenance ? a.date : (a as CarExpense).date);
      DateTime dateB = (b is Payment) ? b.date : (b is Maintenance ? b.date : (b as CarExpense).date);
      return dateB.compareTo(dateA);
    });
    
    return all;
  }
}
