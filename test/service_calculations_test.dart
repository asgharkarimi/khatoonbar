import 'package:flutter_test/flutter_test.dart';
import 'package:khatoonbar/models/models.dart';

void main() {
  group('تست جامع جریان کاری مالی (Full Workflow Test)', () {
    test('سناریوی کامل: ثبت سرویس، پرداختی مشتری، تسویه فروشنده و محاسبه حقوق راننده', () {
      // ۱. تعاریف پایه
      final testCar = Car(id: 'c1', name: 'فوتون');
      final testDriver = Driver(id: 'd1', firstName: 'اصغر', lastName: 'اصغری', phone: '0912');
      final testSeller = Seller(id: 's1', name: 'معدن صدف', product: 'ماسه');
      final testCustomer = Customer(id: 'cust1', firstName: 'جواد', lastName: 'جوادی', phone: '0935');
      final testLoadType = LoadType(id: 'lt1', name: 'ماسه شسته');

      // ۲. ثبت سرویس جدید
      // وزن: ۳۰ تن، خرید: ۱۰۰،۰۰۰، حمل: ۵۰،۰۰۰
      // کل خرید: ۳،۰۰۰،۰۰۰ | کل حمل: ۱،۵۰۰،۰۰۰ | جمع کل مشتری: ۴،۵۰۰،۰۰۰
      final service = LoadService(
        id: 'srv_100',
        orderCode: '100',
        car: testCar,
        driver: testDriver,
        loadType: testLoadType,
        seller: testSeller,
        customer: testCustomer,
        origin: 'شهریار',
        destination: 'تهران',
        date: DateTime.now(),
        weight: 30.0,
        transportPricePerTon: 50000,
        purchasePricePerTon: 100000,
        expenses: ServiceExpenses(
          billOfLadingCost: 100000, // پایه بارنامه
          commission: 50000,        // کمیسیون
          commissionInBoL: true,    // کمیسیون در بارنامه لحاظ شود
          fuelCost: 200000,         // هزینه گازوئیل (جزو هزینه‌های جاری، نه بارنامه)
        ),
        driverAgreementPercentage: 20, // ۲۰ درصد از کرایه حمل برای راننده
        isOwnerDriver: false,          // راننده مالک نیست
      );

      // بررسی محاسبات اولیه
      expect(service.totalPurchaseAmount, 3000000);
      expect(service.totalTransportAmount, 1500000);
      expect(service.totalServicePriceForCustomer, 4500000);

      // ۳. محاسبات باربری و صافی راننده
      // طلب باربری: پایه بارنامه (۱۰۰) + کمیسیون (۵۰) = ۱۵۰،۰۰۰
      expect(service.expenses.owedToLogistics, 150000);
      // صافی راننده از باربری: کرایه کل (۱.۵م) - سهم باربری (۱۵۰ک) = ۱،۳۵۰،۰۰۰
      expect(service.driverNetPay, 1350000);

      // ۴. دریافتی از مشتری (ترکیبی: نقد و چک پاس نشده)
      final p1 = Payment(
        id: 'p1', type: PaymentType.fromCustomer, method: PaymentMethod.cash,
        amount: 3000000, date: DateTime.now(),
      );
      final p2 = Payment(
        id: 'p2', type: PaymentType.fromCustomer, method: PaymentMethod.check,
        amount: 1500000, date: DateTime.now(), 
        isCleared: false, status: CheckStatus.pending, // مهم: چک پاس نشده
      );

      final serviceWithPayments = LoadService.fromMap(
        service.toMap(),
        car: testCar, driver: testDriver, loadType: testLoadType, seller: testSeller, customer: testCustomer,
        collectionsFromCustomer: [p1, p2],
      );

      // بررسی وضعیت طلب مشتری
      // فقط p1 لحاظ می‌شود چون p2 چک پاس نشده است
      expect(serviceWithPayments.totalCollectedFromCustomer, 3000000);
      expect(serviceWithPayments.remainingCustomerDebt, 1500000);
      expect(serviceWithPayments.pendingCustomerChecks, 1500000);
      expect(serviceWithPayments.finalBalanceCustomerDebt, 0); // با احتساب چک‌های در جریان

      // ۵. سود و سهم مالک
      // هزینه کل سرویس: پایه بارنامه (۱۰۰) + کمیسیون (۵۰) + سوخت (۲۰۰) = ۳۵۰،۰۰۰
      expect(service.expenses.total, 350000);
      // سود خالص سرویس: کرایه حمل (۱.۵م) - کل هزینه‌ها (۳۵۰ک) = ۱،۱۵۰،۰۰۰
      expect(serviceWithPayments.netProfit, 1150000);
      // حقوق راننده (۲۰٪ از ۱.۵م): ۳۰۰،۰۰۰
      expect(serviceWithPayments.driverSalary, 300000);
      // سهم مالک: سود خالص (۱.۱۵م) - حقوق راننده (۳۰۰ک) = ۸۵۰،۰۰۰
      expect(serviceWithPayments.ownerShare, 850000);

      // ۶. تسویه با فروشنده
      final paySeller = Payment(
        id: 'ps1', type: PaymentType.toSeller, method: PaymentMethod.sheba,
        amount: 3000000, date: DateTime.now(),
      );
      
      final finalService = LoadService.fromMap(
        serviceWithPayments.toMap(),
        car: testCar, driver: testDriver, loadType: testLoadType, seller: testSeller, customer: testCustomer,
        collectionsFromCustomer: serviceWithPayments.collectionsFromCustomer,
        paymentsToSeller: [paySeller],
      );

      expect(finalService.remainingDebtToSeller, 0);
      expect(finalService.isSellerSettled, true);
    });

    test('تست کرایه توافقی (Agreed Freight)', () {
      final service = LoadService(
        id: 'srv_200',
        orderCode: '201',
        car: Car(id: 'c', name: 'f'),
        driver: Driver(id: 'd', firstName: 'a', lastName: 'b', phone: 'p'),
        loadType: LoadType(id: 'l', name: 'n'),
        seller: Seller(id: 's', name: 'n', product: 'p'),
        origin: 'A',
        destination: 'B',
        date: DateTime.now(),
        weight: 25.0,
        transportPricePerTon: 100000, // ۲.۵ میلیون در حالت عادی
        isAgreedFreight: true,
        agreedFreightAmount: 2000000, // توافق شده روی ۲ میلیون
        expenses: ServiceExpenses(),
      );

      expect(service.totalTransportAmount, 2000000);
    });
  });
}
