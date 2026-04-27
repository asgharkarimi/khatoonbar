import 'package:flutter_test/flutter_test.dart';
import 'package:khatoonbar/models/models.dart';

void main() {
  group('تست جریان کاری مالی (Userflow)', () {
    test('تست ثبت سرویس و پرداخت ۳ مرحله‌ای مشتری و تسویه فروشنده', () {
      // ۱. تعریف مشخصات پایه
      final testCar = Car(id: 'c1', name: 'فوتون');
      final testDriver = Driver(id: 'd1', firstName: 'اصغر', lastName: 'اصغری', phone: '0912');
      final testLoadType = LoadType(id: 'lt1', name: 'ماسه');
      final testSeller = Seller(id: 's1', name: 'ماسه شویی صدف', product: 'ماسه شسته');
      final testCustomer = Customer(id: 'cust1', firstName: 'جواد', lastName: 'جوادی', phone: '0935');

      // ۲. ثبت یک سرویس جدید
      // وزن: ۳۰ تن، خرید: ۱۰۰ هزار، حمل: ۵۰ هزار
      // کل خرید: ۳ میلیون، کل حمل: ۱.۵ میلیون -> جمع کل: ۴.۵ میلیون تومان
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
        expenses: ServiceExpenses(fuelCost: 200000), // ۲۰۰ هزار تومن گازوئیل
      );

      expect(service.totalServicePriceForCustomer, 4500000);
      expect(service.totalPurchaseAmount, 3000000);

      // ۳. مرحله اول دریافتی از مشتری: ۱.۵ میلیون نقد
      final p1 = Payment(
        id: 'p1', type: PaymentType.fromCustomer, method: PaymentMethod.cash,
        amount: 1500000, date: DateTime.now(), isCleared: true,
      );

      // ۴. مرحله دوم دریافتی از مشتری: ۱.۵ میلیون چک (وصول نشده)
      final p2 = Payment(
        id: 'p2', type: PaymentType.fromCustomer, method: PaymentMethod.check,
        amount: 1500000, date: DateTime.now(), isCleared: false,
      );

      // ۵. مرحله سوم دریافتی از مشتری: ۱.۵ میلیون کارت به کارت
      final p3 = Payment(
        id: 'p3', type: PaymentType.fromCustomer, method: PaymentMethod.card,
        amount: 1500000, date: DateTime.now(), isCleared: true,
      );

      // شبیه‌سازی سرویس با تراکنش‌ها
      final updatedService = LoadService.fromMap(
        service.toMap(),
        car: testCar, driver: testDriver, loadType: testLoadType, seller: testSeller, customer: testCustomer,
        collectionsFromCustomer: [p1, p2, p3],
        paymentsToSeller: [],
      );

      // بررسی وضعیت طلب از مشتری:
      // کل: ۴.۵ میلیون. دریافتی (فقط نقد شده‌ها p1 و p3): ۳ میلیون.
      // مانده طلب باید ۱.۵ میلیون باشد (چون چک p2 هنوز وصول نشده)
      expect(updatedService.totalCollectedFromCustomer, 3000000);
      expect(updatedService.remainingCustomerDebt, 1500000);

      // ۶. تسویه با فروشنده (۳ میلیون تومان شبا)
      final paySeller = Payment(
        id: 'p_sell', type: PaymentType.toSeller, method: PaymentMethod.sheba,
        amount: 3000000, date: DateTime.now(), isCleared: true,
      );

      final finalService = LoadService.fromMap(
        updatedService.toMap(),
        car: testCar, driver: testDriver, loadType: testLoadType, seller: testSeller, customer: testCustomer,
        collectionsFromCustomer: updatedService.collectionsFromCustomer,
        paymentsToSeller: [paySeller],
      );

      // بررسی نهایی:
      expect(finalService.remainingDebtToSeller, 0); // تسویه شد
      expect(finalService.isSellerSettled, true);
      
      // بررسی سود خالص واقعی این سرویس:
      // کرایه حمل: ۱.۵ میلیون - هزینه سوخت: ۲۰۰ هزار = ۱.۳ میلیون سود
      expect(finalService.netProfit, 1300000);
    });
  });
}
