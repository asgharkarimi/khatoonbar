import '../../models/models.dart';

class MockData {
  static bool useTestData = true;

  static List<Driver> drivers = [
    Driver(id: '1', firstName: 'اصغر', lastName: 'کریمی', phone: '09123456789'),
    Driver(id: '2', firstName: 'محمد', lastName: 'رضایی', phone: '09987654321'),
  ];

  static List<Car> cars = [
    Car(id: '1', name: 'کامیون بنز', plate: '12-ب-345-زنجان'),
    Car(id: '2', name: 'ولوو FH', plate: '98-ج-765-تهران'),
  ];

  static List<Seller> sellers = [
    Seller(id: '1', name: 'ماسه شویی ماهنشان', product: 'ماسه'),
    Seller(id: '2', name: 'سیمان خمسه', product: 'سیمان'),
    Seller(id: '3', name: 'آجر سفال زنجان', product: 'آجر'),
  ];

  static List<LoadType> loadTypes = [
    LoadType(id: '1', name: 'آجر'),
    LoadType(id: '2', name: 'ماسه'),
    LoadType(id: '3', name: 'سیمان'),
    LoadType(id: '4', name: 'آرد'),
    LoadType(id: '5', name: 'چوب'),
    LoadType(id: '6', name: 'شن'),
  ];

  static List<Customer> customers = [
    Customer(id: '1', firstName: 'حسین', lastName: 'کریمی', phone: '09121111111'),
    Customer(id: '2', firstName: 'علی', lastName: 'احمدی', phone: '09122222222'),
  ];

  static List<LoadService> loadServices = [
    // 1. اصغر کریمی - خرید ماسه از ماهنشان و تحویل به حسین کریمی
    LoadService(
      id: '1',
      orderCode: '1001',
      car: cars[0],
      driver: drivers[0],
      loadType: loadTypes[1],
      seller: sellers[0],
      customer: customers[0],
      origin: 'ماهنشان',
      destination: 'روستای قوزلو',
      date: DateTime.now(),
      weight: 23,
      transportPricePerTon: 600000,
      purchasePricePerTon: 500000,
      expenses: ServiceExpenses(),
      paymentsToSeller: [],
      collectionsFromCustomer: [],
    ),
    // 2. محمد رضایی - فقط حمل بار زنجان به تهران
    LoadService(
      id: '2',
      orderCode: '1002',
      car: cars[1],
      driver: drivers[1],
      loadType: loadTypes[2],
      seller: sellers[1],
      origin: 'زنجان',
      destination: 'تهران',
      date: DateTime.now().subtract(const Duration(days: 1)),
      weight: 34,
      transportPricePerTon: 650000,
      purchasePricePerTon: 0,
      expenses: ServiceExpenses(),
    ),
    // 3. اصغر کریمی - خرید آجر با یک چک پرداختی به فروشنده
    LoadService(
      id: '3',
      orderCode: '1003',
      car: cars[0],
      driver: drivers[0],
      loadType: loadTypes[0],
      seller: sellers[2],
      origin: 'زنجان',
      destination: 'ابهر',
      date: DateTime.now().subtract(const Duration(days: 2)),
      weight: 15,
      transportPricePerTon: 450000,
      purchasePricePerTon: 800000,
      expenses: ServiceExpenses(),
      paymentsToSeller: [
        Payment(
          type: PaymentType.toSeller,
          method: PaymentMethod.check,
          amount: 5000000,
          date: DateTime.now().subtract(const Duration(days: 1)),
          checkDueDate: DateTime.now().add(const Duration(days: 30)),
          isCleared: false,
        ),
      ],
    ),
    // 4. حمل بار توسط محمد رضایی با دریافت بخشی از مبلغ از مشتری
    LoadService(
      id: '4',
      orderCode: '1004',
      car: cars[1],
      driver: drivers[1],
      loadType: loadTypes[3],
      seller: sellers[1],
      origin: 'زنجان',
      destination: 'قزوین',
      date: DateTime.now().subtract(const Duration(days: 3)),
      weight: 12,
      transportPricePerTon: 500000,
      purchasePricePerTon: 0,
      expenses: ServiceExpenses(),
      collectionsFromCustomer: [
        Payment(
          type: PaymentType.fromCustomer,
          method: PaymentMethod.cash,
          amount: 2000000,
          date: DateTime.now(),
        ),
      ],
    ),
  ];
}
