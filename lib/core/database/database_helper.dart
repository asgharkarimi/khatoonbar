import 'package:hive/hive.dart';
import '../../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<void> seedDefaultData() async {
    // ۱. نوع بار
    final loadTypeBox = Hive.box('load_types');
    if (loadTypeBox.isEmpty) {
      final defaults = [
        LoadType(id: 'lt1', name: 'سیمان کیسه‌ای'),
        LoadType(id: 'lt2', name: 'آجر فشاری'),
        LoadType(id: 'lt3', name: 'میلگرد'),
      ];
      for (var item in defaults) await loadTypeBox.put(item.id, item.toMap());
    }

    // ۲. خودروها
    final carBox = Hive.box('cars');
    if (carBox.isEmpty) {
      final defaultCars = [
        Car(id: 'c1', name: 'فوتون ۴۳۰', plate: '12-345-ب-67'),
        Car(id: 'c2', name: 'آمیکو تک', plate: '98-765-ج-43'),
      ];
      for (var car in defaultCars) await carBox.put(car.id, car.toMap());
    }

    // ۳. رانندگان
    final driverBox = Hive.box('drivers');
    if (driverBox.isEmpty) {
      final driver = Driver(
        id: 'd1', 
        firstName: 'محمد', 
        lastName: 'رضایی', 
        phone: '09123456789',
        bankName: 'ملی',
        accountNumber: '6037991122334455',
        accountOwner: 'محمد رضایی'
      );
      await driverBox.put(driver.id, driver.toMap());
    }

    // ۴. مشتریان (گیرندگان)
    final customerBox = Hive.box('customers');
    if (customerBox.isEmpty) {
      final customer = Customer(
        id: 'cust1', 
        firstName: 'اصغر', 
        lastName: 'فرهادی', 
        phone: '09351112233', 
        village: 'روستای نمونه',
        bankName: 'تجارت'
      );
      await customerBox.put(customer.id, customer.toMap());
    }

    // ۵. فروشندگان
    final sellerBox = Hive.box('sellers');
    if (sellerBox.isEmpty) {
      final seller = Seller(
        id: 'sel1', 
        name: 'کارخانه سیمان سپاهان', 
        product: 'سیمان تیپ ۲'
      );
      await sellerBox.put(seller.id, seller.toMap());
    }

    // ۶. باربری‌ها
    final logisticsBox = Hive.box('logistics_cos');
    if (logisticsBox.isEmpty) {
      final co = LogisticsCo(
        id: 'log1', 
        name: 'باربری خلیج فارس', 
        phone: '021-55667788',
        location: 'پایانه شرق'
      );
      await logisticsBox.put(co.id, co.toMap());
    }

    // ۷. حساب‌های بانکی من
    final bankBox = Hive.box('bank_accounts');
    if (bankBox.isEmpty) {
      final acc = BankAccount(
        id: 'my_acc1', 
        bankName: 'بانک ملت', 
        accountNumber: '1234567890', 
        accountOwner: 'مدیریت خاتون بار',
        initialBalance: 50000000
      );
      await bankBox.put(acc.id, acc.toMap());
    }

    // ۸. سرویس دوره‌ای (یادآور)
    final maintenanceBox = Hive.box('maintenances');
    if (maintenanceBox.isEmpty) {
      final m = Maintenance(
        id: 'm1',
        carId: 'c1',
        type: 'تعویض روغن و فیلتر',
        date: DateTime.now().subtract(const Duration(days: 10)),
        cost: 1800000,
        currentKm: 45000,
        nextKm: 50000,
        nextDate: DateTime.now().add(const Duration(days: 2)), // ۲ روز دیگه خبر بده
        description: 'روغن ۱۰-۴۰ اسپیدی'
      );
      await maintenanceBox.put(m.id, m.toMap());
    }

    // ۹. مخارج متفرقه خودرو
    final expenseBox = Hive.box('car_expenses');
    if (expenseBox.isEmpty) {
      final e = CarExpense(
        id: 'e1',
        carId: 'c1',
        description: 'پنچرگیری و تنظیم باد',
        amount: 250000,
        date: DateTime.now().subtract(const Duration(days: 1))
      );
      await expenseBox.put(e.id, e.toMap());
    }

    // ۱۰. ثبت یک سرویس نمونه
    final serviceBox = Hive.box('load_services');
    if (serviceBox.isEmpty) {
      final serviceId = 'test_service_1';
      final expenses = ServiceExpenses(
        billOfLadingCost: 850000,
        commission: 150000,
        fuelCost: 400000,
        loadingTip: 50000,
        unloadingTip: 50000,
        loadingWeighbridge: 30000, // فیلد جدید
        unloadingWorker: 120000,   // فیلد جدید
        commissionInBoL: true,
      );

      final service = LoadService(
        id: serviceId,
        orderCode: '1001',
        car: Car(id: 'c1', name: 'فوتون ۴۳۰'),
        driver: Driver(id: 'd1', firstName: 'محمد', lastName: 'رضایی', phone: '09123456789'),
        loadType: LoadType(id: 'lt1', name: 'سیمان کیسه‌ای'),
        seller: Seller(id: 'sel1', name: 'کارخانه سیمان سپاهان', product: 'سیمان'),
        customer: Customer(id: 'cust1', firstName: 'اصغر', lastName: 'فرهادی', phone: '09351112233'),
        logisticsCo: LogisticsCo(id: 'log1', name: 'باربری خلیج فارس', phone: '021'),
        origin: 'اصفهان',
        destination: 'تهران',
        date: DateTime.now().subtract(const Duration(days: 1)),
        weight: 25.5,
        transportPricePerTon: 250000,
        purchasePricePerTon: 1200000,
        expenses: expenses,
      );
      await serviceBox.put(service.id, service.toMap());

      // ۱۱. تراکنش‌های مالی سرویس
      final paymentBox = Hive.box('payments');
      
      // پرداخت به فروشنده
      final p1 = Payment(
        id: 'p1', serviceId: serviceId, sellerId: 'sel1', type: PaymentType.toSeller,
        method: PaymentMethod.cash, amount: 20000000, date: DateTime.now(),
        myAccountId: 'my_acc1', isCleared: true,
      );
      await paymentBox.put(p1.id, p1.toMap());

      // چک دریافتی از مشتری (سررسید نزدیک)
      final p2 = Payment(
        id: 'p2', serviceId: serviceId, customerId: 'cust1', type: PaymentType.fromCustomer,
        method: PaymentMethod.check, amount: 15000000, date: DateTime.now(),
        checkDueDate: DateTime.now().add(const Duration(days: 3)), // ۳ روز دیگه سررسیده
        bankName: 'صادرات', checkNumber: 'CH-1001', isCleared: false, status: CheckStatus.pending,
      );
      await paymentBox.put(p2.id, p2.toMap());
    }

    // ۱۲. پیشنهادات خودکار
    final suggestionBox = Hive.box('suggestions');
    if (suggestionBox.isEmpty) {
      await suggestionBox.put('origins', ['اصفهان', 'یزد', 'کرمان', 'سمنان']);
      await suggestionBox.put('destinations', ['تهران', 'کرج', 'قم', 'قزوین']);
      await suggestionBox.put('expense_titles', ['انعام انباردار', 'جریمه پلیس راه', 'پارکینگ']);
    }
  }

  Future<void> insert(String table, Map<String, dynamic> row) async {
    final box = Hive.box(table);
    final String id = row['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    final Map<String, dynamic> data = Map<String, dynamic>.from(row);
    if (data['id'] == null) data['id'] = id;
    await box.put(id, data);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final box = Hive.box(table);
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<int> delete(String table, String id) async {
    await Hive.box(table).delete(id);
    return 1;
  }

  Future<List<String>> getSuggestions(String key) async {
    final box = Hive.box('suggestions');
    return List<String>.from(box.get(key) ?? []);
  }

  Future<void> addSuggestion(String key, String value) async {
    if (value.trim().isEmpty) return;
    final box = Hive.box('suggestions');
    List<String> current = List<String>.from(box.get(key) ?? []);
    if (!current.contains(value.trim())) {
      current.add(value.trim());
      await box.put(key, current);
    }
  }

  Future<void> insertBankAccount(BankAccount account) async => await insert('bank_accounts', account.toMap());
  Future<List<BankAccount>> getAllBankAccounts() async {
    final res = await queryAll('bank_accounts');
    return res.map((m) => BankAccount.fromMap(m)).toList();
  }

  Future<void> insertDriver(Driver driver) async => await insert('drivers', driver.toMap());
  Future<List<Driver>> getAllDrivers() async {
    final res = await queryAll('drivers');
    return res.map((m) => Driver.fromMap(m)).toList();
  }

  Future<void> insertCar(Car car) async => await insert('cars', car.toMap());
  Future<List<Car>> getAllCars() async {
    final res = await queryAll('cars');
    return res.map((m) => Car.fromMap(m)).toList();
  }

  Future<void> insertLogisticsCo(LogisticsCo co) async => await insert('logistics_cos', co.toMap());
  Future<List<LogisticsCo>> getAllLogisticsCos() async {
    final res = await queryAll('logistics_cos');
    return res.map((m) => LogisticsCo.fromMap(m)).toList();
  }

  Future<void> insertCustomer(Customer customer) async => await insert('customers', customer.toMap());
  Future<List<Customer>> getAllCustomers() async {
    final res = await queryAll('customers');
    return res.map((m) => Customer.fromMap(m)).toList();
  }

  Future<void> insertSeller(Seller seller) async => await insert('sellers', seller.toMap());
  Future<List<Seller>> getAllSellers() async {
    final res = await queryAll('sellers');
    return res.map((m) => Seller.fromMap(m)).toList();
  }

  Future<void> insertLoadType(LoadType type) async => await insert('load_types', type.toMap());
  Future<List<LoadType>> getAllLoadTypes() async {
    final res = await queryAll('load_types');
    return res.map((m) => LoadType.fromMap(m)).toList();
  }

  Future<void> insertMaintenance(Maintenance maintenance) async => await insert('maintenances', maintenance.toMap());
  Future<List<Maintenance>> getAllMaintenances() async {
    final res = await queryAll('maintenances');
    return res.map((m) => Maintenance.fromMap(m)).toList();
  }

  Future<void> insertCarExpense(CarExpense expense) async => await insert('car_expenses', expense.toMap());
  Future<List<CarExpense>> getAllCarExpenses() async {
    final res = await queryAll('car_expenses');
    return res.map((m) => CarExpense.fromMap(m)).toList();
  }

  Future<List<LoadService>> getAllServices() async {
    final servicesJson = await queryAll('load_services');
    final paymentsJson = await queryAll('payments');
    final carsJson = await queryAll('cars');
    final driversJson = await queryAll('drivers');
    final sellersJson = await queryAll('sellers');
    final loadTypesJson = await queryAll('load_types');
    final customersJson = await queryAll('customers');
    final logisticsJson = await queryAll('logistics_cos');

    servicesJson.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    List<LoadService> services = [];
    for (var s in servicesJson) {
      final String? serviceId = s['id'];
      if (serviceId == null) continue;
      
      final servicePayments = paymentsJson.where((p) => p['serviceId'] == serviceId).map((p) => Payment.fromMap(p)).toList();

      final carMap = carsJson.firstWhere((c) => c['id'] == s['carId'], orElse: () => {});
      final driverMap = driversJson.firstWhere((d) => d['id'] == s['driverId'], orElse: () => {});
      final sellerMap = sellersJson.firstWhere((sel) => sel['id'] == s['sellerId'], orElse: () => {});
      final typeMap = loadTypesJson.firstWhere((t) => t['id'] == s['loadTypeId'], orElse: () => {});
      final customerMap = customersJson.firstWhere((cust) => cust['id'] == s['customerId'], orElse: () => {});
      final logisticsMap = logisticsJson.firstWhere((l) => l['id'] == s['logisticsId'], orElse: () => {});

      if (carMap.isNotEmpty && driverMap.isNotEmpty) {
        services.add(LoadService.fromMap(
          s,
          car: Car.fromMap(carMap),
          driver: Driver.fromMap(driverMap),
          loadType: LoadType.fromMap(typeMap.isNotEmpty ? typeMap : {'id': '1', 'name': 'نامشخص'}),
          seller: Seller.fromMap(sellerMap.isNotEmpty ? sellerMap : {'id': '1', 'name': 'نامشخص', 'product': ''}),
          customer: customerMap.isNotEmpty ? Customer.fromMap(customerMap) : null,
          logisticsCo: logisticsMap.isNotEmpty ? LogisticsCo.fromMap(logisticsMap) : null,
          paymentsToSeller: servicePayments.where((p) => p.type == PaymentType.toSeller).toList(),
          collectionsFromCustomer: servicePayments.where((p) => p.type == PaymentType.fromCustomer).toList(),
          paymentsToLogistics: servicePayments.where((p) => p.type == PaymentType.toLogistics).toList(),
          paymentsToDriver: servicePayments.where((p) => p.type == PaymentType.toDriver).toList(),
        ));
      }
    }
    return services;
  }
  
  Future<void> insertPayment(Payment payment, {String? serviceId, String? sellerId, String? customerId, String? logisticsId, String? driverId}) async {
    final map = payment.toMap();
    if (serviceId != null) map['serviceId'] = serviceId;
    if (sellerId != null) map['sellerId'] = sellerId;
    if (customerId != null) map['customerId'] = customerId;
    if (logisticsId != null) map['logisticsId'] = logisticsId;
    if (driverId != null) map['driverId'] = driverId;
    
    if (map['id'] == null) map['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    await insert('payments', map);
  }

  Future<List<Payment>> getAllPayments() async {
    final res = await queryAll('payments');
    return res.map((m) => Payment.fromMap(m)).toList();
  }
}
