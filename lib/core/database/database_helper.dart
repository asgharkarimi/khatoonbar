import 'package:hive/hive.dart';
import '../../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  // Seed default data if boxes are empty
  Future<void> seedDefaultData() async {
    // Seed load types
    final loadTypeBox = Hive.box('load_types');
    if (loadTypeBox.isEmpty) {
      final defaults = [
        LoadType(id: '1', name: 'آجر'),
        LoadType(id: '2', name: 'سیمان'),
        LoadType(id: '3', name: 'شن'),
        LoadType(id: '4', name: 'ماسه'),
        LoadType(id: '5', name: 'آرد'),
        LoadType(id: '6', name: 'چوب'),
      ];
      for (var item in defaults) {
        await loadTypeBox.put(item.id, item.toMap());
      }
    }

    // Seed default cars
    final carBox = Hive.box('cars');
    if (carBox.isEmpty) {
      final defaultCars = [
        Car(id: 'c1', name: 'فوتون', plate: '---'),
        Car(id: 'c2', name: 'آمیکو', plate: '---'),
      ];
      for (var car in defaultCars) {
        await carBox.put(car.id, car.toMap());
      }
    }
  }

  Future<void> insert(String table, Map<String, dynamic> row) async {
    final box = Hive.box(table);
    final String id = row['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final Map<String, dynamic> data = Map<String, dynamic>.from(row);
    if (data['id'] == null) {
      data['id'] = id;
    }
    await box.put(id, data);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final box = Hive.box(table);
    return box.values.map((e) {
      if (e is Map) {
        return Map<String, dynamic>.from(e);
      }
      return <String, dynamic>{};
    }).toList();
  }

  Future<int> delete(String table, String id) async {
    final box = Hive.box(table);
    await box.delete(id);
    return 1;
  }

  // --- Specialized Methods ---

  // Drivers
  Future<void> insertDriver(Driver driver) async => await insert('drivers', driver.toMap());
  Future<List<Driver>> getAllDrivers() async {
    final res = await queryAll('drivers');
    return res.map((m) => Driver.fromMap(m)).toList();
  }

  // Cars
  Future<void> insertCar(Car car) async => await insert('cars', car.toMap());
  Future<List<Car>> getAllCars() async {
    final res = await queryAll('cars');
    return res.map((m) => Car.fromMap(m)).toList();
  }

  // Customers
  Future<void> insertCustomer(Customer customer) async => await insert('customers', customer.toMap());
  Future<List<Customer>> getAllCustomers() async {
    final res = await queryAll('customers');
    return res.map((m) => Customer.fromMap(m)).toList();
  }

  // Sellers
  Future<void> insertSeller(Seller seller) async => await insert('sellers', seller.toMap());
  Future<List<Seller>> getAllSellers() async {
    final res = await queryAll('sellers');
    return res.map((m) => Seller.fromMap(m)).toList();
  }

  // LoadTypes
  Future<void> insertLoadType(LoadType type) async => await insert('load_types', type.toMap());
  Future<List<LoadType>> getAllLoadTypes() async {
    final res = await queryAll('load_types');
    return res.map((m) => LoadType.fromMap(m)).toList();
  }

  // Car Expenses
  Future<void> insertCarExpense(CarExpense expense) async => await insert('car_expenses', expense.toMap());
  Future<List<CarExpense>> getAllCarExpenses() async {
    final res = await queryAll('car_expenses');
    return res.map((m) => CarExpense.fromMap(m)).toList();
  }

  // Services
  Future<List<LoadService>> getAllServices() async {
    final servicesJson = await queryAll('load_services');
    
    servicesJson.sort((a, b) {
      final dateA = a['date'] as String? ?? '';
      final dateB = b['date'] as String? ?? '';
      return dateB.compareTo(dateA);
    });
    
    final paymentsJson = await queryAll('payments');
    final carsJson = await queryAll('cars');
    final driversJson = await queryAll('drivers');
    final sellersJson = await queryAll('sellers');
    final loadTypesJson = await queryAll('load_types');
    final customersJson = await queryAll('customers');

    List<LoadService> services = [];
    for (var s in servicesJson) {
      final String? serviceId = s['id'];
      if (serviceId == null) continue;
      
      final servicePayments = paymentsJson
          .where((p) => p['serviceId'] == serviceId)
          .map((p) => Payment.fromMap(p))
          .toList();

      final Map<String, dynamic> carMap = carsJson.firstWhere((c) => c['id'] == s['carId'], orElse: () => <String, dynamic>{});
      final Map<String, dynamic> driverMap = driversJson.firstWhere((d) => d['id'] == s['driverId'], orElse: () => <String, dynamic>{});
      final Map<String, dynamic> sellerMap = sellersJson.firstWhere((sel) => sel['id'] == s['sellerId'], orElse: () => <String, dynamic>{});
      final Map<String, dynamic> typeMap = loadTypesJson.firstWhere((t) => t['id'] == s['loadTypeId'], orElse: () => <String, dynamic>{});
      
      final customerId = s['customerId'];
      final Map<String, dynamic> customerMap = (customerId != null && customerId.toString().isNotEmpty)
          ? customersJson.firstWhere((cust) => cust['id'] == customerId, orElse: () => <String, dynamic>{})
          : <String, dynamic>{};

      if (carMap.isNotEmpty && driverMap.isNotEmpty) {
        services.add(LoadService.fromMap(
          s,
          car: Car.fromMap(carMap),
          driver: Driver.fromMap(driverMap),
          loadType: typeMap.isNotEmpty ? LoadType.fromMap(typeMap) : LoadType(id: '1', name: 'نامشخص'),
          seller: sellerMap.isNotEmpty ? Seller.fromMap(sellerMap) : Seller(id: '1', name: 'نامشخص', product: ''),
          customer: customerMap.isNotEmpty ? Customer.fromMap(customerMap) : null,
          paymentsToSeller: servicePayments.where((p) => p.type == PaymentType.toSeller).toList(),
          collectionsFromCustomer: servicePayments.where((p) => p.type == PaymentType.fromCustomer).toList(),
        ));
      }
    }
    return services;
  }
  
  // برای جلوگیری از خطا، پارامتر دوم را به صورت اختیاریِ موقعیتی یا نام‌دار مدیریت می‌کنیم
  Future<void> insertPayment(Payment payment, {String? serviceId, String? sellerId, String? customerId}) async {
    final map = payment.toMap();
    if (serviceId != null) map['serviceId'] = serviceId;
    if (sellerId != null) map['sellerId'] = sellerId;
    if (customerId != null) map['customerId'] = customerId;
    
    if (map['id'] == null) map['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    await insert('payments', map);
  }

  Future<List<Payment>> getAllPayments() async {
    final res = await queryAll('payments');
    return res.map((m) => Payment.fromMap(m)).toList();
  }
}
