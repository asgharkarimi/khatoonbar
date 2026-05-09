import 'dart:convert';

class BankAccount {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountOwner;
  final String? cardNumber;
  final String? sheba;
  final double initialBalance;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountOwner,
    this.cardNumber,
    this.sheba,
    this.initialBalance = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountOwner': accountOwner,
    'cardNumber': cardNumber,
    'sheba': sheba,
    'initialBalance': initialBalance,
  };

  factory BankAccount.fromMap(Map<String, dynamic> map) => BankAccount(
    id: map['id'],
    bankName: map['bankName'],
    accountNumber: map['accountNumber'],
    accountOwner: map['accountOwner'],
    cardNumber: map['cardNumber'],
    sheba: map['sheba'],
    initialBalance: (map['initialBalance'] as num? ?? 0).toDouble(),
  );
}

class Driver {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? bankName;
  final String? accountNumber;
  final String? accountOwner;

  Driver({
    required this.id, 
    required this.firstName, 
    required this.lastName, 
    required this.phone,
    this.bankName,
    this.accountNumber,
    this.accountOwner,
  });

  String get fullName => "$firstName $lastName";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Driver && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountOwner': accountOwner,
  };

  factory Driver.fromMap(Map<String, dynamic> map) => Driver(
    id: map['id'],
    firstName: map['firstName'],
    lastName: map['lastName'],
    phone: map['phone'],
    bankName: map['bankName'],
    accountNumber: map['accountNumber'],
    accountOwner: map['accountOwner'],
  );
}

class Car {
  final String id;
  final String name;
  final String? plate;

  Car({required this.id, required this.name, this.plate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Car && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'plate': plate,
  };

  factory Car.fromMap(Map<String, dynamic> map) => Car(
    id: map['id'],
    name: map['name'],
    plate: map['plate'],
  );
}

class LogisticsCo {
  final String id;
  final String name;
  final String phone;
  final String? location; // شهر یا استان
  final String? bankName;
  final String? accountNumber;
  final String? accountOwner;

  LogisticsCo({
    required this.id, 
    required this.name, 
    required this.phone,
    this.location,
    this.bankName,
    this.accountNumber,
    this.accountOwner,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogisticsCo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'location': location,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountOwner': accountOwner,
  };

  factory LogisticsCo.fromMap(Map<String, dynamic> map) => LogisticsCo(
    id: map['id'],
    name: map['name'],
    phone: map['phone'],
    location: map['location'],
    bankName: map['bankName'],
    accountNumber: map['accountNumber'],
    accountOwner: map['accountOwner'],
  );
}

class CarExpense {
  final String id;
  final String carId;
  final String description; 
  final double amount;
  final DateTime date;
  final String? receiptImagePath;

  CarExpense({
    required this.id,
    required this.carId,
    required this.description,
    required this.amount,
    required this.date,
    this.receiptImagePath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'carId': carId,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'receiptImagePath': receiptImagePath,
  };

  factory CarExpense.fromMap(Map<String, dynamic> map) => CarExpense(
    id: map['id'],
    carId: map['carId'],
    description: map['description'],
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date']),
    receiptImagePath: map['receiptImagePath'],
  );
}

class Maintenance {
  final String id;
  final String carId;
  final String type;
  final DateTime date;
  final double cost;
  final int? currentKm;
  final int? nextKm;
  final DateTime? nextDate;
  final String? description;
  final String? receiptImagePath;

  Maintenance({
    required this.id,
    required this.carId,
    required this.type,
    required this.date,
    required this.cost,
    this.currentKm,
    this.nextKm,
    this.nextDate,
    this.description,
    this.receiptImagePath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'carId': carId,
    'type': type,
    'date': date.toIso8601String(),
    'cost': cost,
    'currentKm': currentKm,
    'nextKm': nextKm,
    'nextDate': nextDate?.toIso8601String(),
    'description': description,
    'receiptImagePath': receiptImagePath,
  };

  factory Maintenance.fromMap(Map<String, dynamic> map) => Maintenance(
    id: map['id'],
    carId: map['carId'],
    type: map['type'],
    date: DateTime.parse(map['date']),
    cost: (map['cost'] as num).toDouble(),
    currentKm: map['currentKm'],
    nextKm: map['nextKm'],
    nextDate: map['nextDate'] != null ? DateTime.parse(map['nextDate']) : null,
    description: map['description'],
    receiptImagePath: map['receiptImagePath'],
  );
}

class LoadType {
  final String id;
  final String name;

  LoadType({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadType && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
  };

  factory LoadType.fromMap(Map<String, dynamic> map) => LoadType(
    id: map['id'],
    name: map['name'],
  );
}

class Seller {
  final String id;
  final String name;
  final String product;
  final String? bankName;
  final String? accountNumber;
  final String? accountOwner;

  Seller({
    required this.id, 
    required this.name, 
    required this.product,
    this.bankName,
    this.accountNumber,
    this.accountOwner,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Seller && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'product': product,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountOwner': accountOwner,
  };

  factory Seller.fromMap(Map<String, dynamic> map) => Seller(
    id: map['id'],
    name: map['name'],
    product: map['product'],
    bankName: map['bankName'],
    accountNumber: map['accountNumber'],
    accountOwner: map['accountOwner'],
  );
}

class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String village;
  final String? bankName;
  final String? accountNumber;
  final String? accountOwner;

  Customer({
    required this.id, 
    required this.firstName, 
    required this.lastName, 
    required this.phone,
    this.village = "", 
    this.bankName,
    this.accountNumber,
    this.accountOwner,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  String get fullName => village.isNotEmpty ? "$firstName $lastName ($village)" : "$firstName $lastName";

  Map<String, dynamic> toMap() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'village': village,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountOwner': accountOwner,
  };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
    id: map['id'],
    firstName: map['firstName'],
    lastName: map['lastName'],
    phone: map['phone'],
    village: map['village'] ?? "",
    bankName: map['bankName'],
    accountNumber: map['accountNumber'],
    accountOwner: map['accountOwner'],
  );
}

class OtherExpense {
  final String title;
  final double amount;
  final String? receiptImagePath;
  final bool includeInBoL;

  OtherExpense({
    required this.title,
    required this.amount,
    this.receiptImagePath,
    this.includeInBoL = false,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'receiptImagePath': receiptImagePath,
    'includeInBoL': includeInBoL,
  };

  factory OtherExpense.fromMap(Map<String, dynamic> map) => OtherExpense(
    title: map['title'] ?? '',
    amount: (map['amount'] ?? 0 as num).toDouble(),
    receiptImagePath: map['receiptImagePath'],
    includeInBoL: map['includeInBoL'] ?? false,
  );
}

class ServiceExpenses {
  double billOfLadingCost;
  double tollCost;
  bool tollInBoL;
  double fuelCost;
  bool fuelInBoL;
  double loadingTip;
  bool loadingTipInBoL;
  double unloadingTip;
  bool unloadingTipInBoL;
  double disinfectionCost;
  bool disinfectionInBoL;
  double commission;
  bool commissionInBoL;
  
  // New specific fields
  double loadingWeighbridge;
  bool loadingWeighbridgeInBoL;
  double loaderLoading;
  bool loaderLoadingInBoL;
  double tallyClerk;
  bool tallyClerkInBoL;
  double unloadingWeighbridge;
  bool unloadingWeighbridgeInBoL;
  double unloadingWorker;
  bool unloadingWorkerInBoL;

  List<OtherExpense> otherExpenses;
  bool includeInBillOfLading;

  ServiceExpenses({
    this.billOfLadingCost = 0,
    this.tollCost = 0,
    this.tollInBoL = false,
    this.fuelCost = 0,
    this.fuelInBoL = false,
    this.loadingTip = 0,
    this.loadingTipInBoL = false,
    this.unloadingTip = 0,
    this.unloadingTipInBoL = false,
    this.disinfectionCost = 0,
    this.disinfectionInBoL = false,
    this.commission = 0,
    this.commissionInBoL = true,
    this.loadingWeighbridge = 0,
    this.loadingWeighbridgeInBoL = false,
    this.loaderLoading = 0,
    this.loaderLoadingInBoL = false,
    this.tallyClerk = 0,
    this.tallyClerkInBoL = false,
    this.unloadingWeighbridge = 0,
    this.unloadingWeighbridgeInBoL = false,
    this.unloadingWorker = 0,
    this.unloadingWorkerInBoL = false,
    this.otherExpenses = const [],
    this.includeInBillOfLading = false,
  });

  /// جمع کل مخارج (هر نوع هزینه‌ای که برای این سرویس انجام شده)
  double get total => billOfLadingCost + tollCost + fuelCost + loadingTip + unloadingTip + disinfectionCost + commission + 
      loadingWeighbridge + loaderLoading + tallyClerk + unloadingWeighbridge + unloadingWorker +
      otherExpenses.fold(0, (sum, item) => sum + item.amount);

  /// مبلغی که باید به باربری پرداخت شود (پایه بارنامه + هزینه‌های انتخابی)
  double get owedToLogistics {
    if (includeInBillOfLading) return total;
    
    double amount = billOfLadingCost;
    if (commissionInBoL) amount += commission;
    if (tollInBoL) amount += tollCost;
    if (fuelInBoL) amount += fuelCost;
    if (loadingTipInBoL) amount += loadingTip;
    if (unloadingTipInBoL) amount += unloadingTip;
    if (disinfectionInBoL) amount += disinfectionCost;
    if (loadingWeighbridgeInBoL) amount += loadingWeighbridge;
    if (loaderLoadingInBoL) amount += loaderLoading;
    if (tallyClerkInBoL) amount += tallyClerk;
    if (unloadingWeighbridgeInBoL) amount += unloadingWeighbridge;
    if (unloadingWorkerInBoL) amount += unloadingWorker;

    for (var exp in otherExpenses) {
      if (exp.includeInBoL) amount += exp.amount;
    }
    return amount;
  }

  Map<String, dynamic> toMap() => {
    'billOfLadingCost': billOfLadingCost,
    'tollCost': tollCost,
    'tollInBoL': tollInBoL,
    'fuelCost': fuelCost,
    'fuelInBoL': fuelInBoL,
    'loadingTip': loadingTip,
    'loadingTipInBoL': loadingTipInBoL,
    'unloadingTip': unloadingTip,
    'unloadingTipInBoL': unloadingTipInBoL,
    'disinfectionCost': disinfectionCost,
    'disinfectionInBoL': disinfectionInBoL,
    'commission': commission,
    'commissionInBoL': commissionInBoL,
    'loadingWeighbridge': loadingWeighbridge,
    'loadingWeighbridgeInBoL': loadingWeighbridgeInBoL,
    'loaderLoading': loaderLoading,
    'loaderLoadingInBoL': loaderLoadingInBoL,
    'tallyClerk': tallyClerk,
    'tallyClerkInBoL': tallyClerkInBoL,
    'unloadingWeighbridge': unloadingWeighbridge,
    'unloadingWeighbridgeInBoL': unloadingWeighbridgeInBoL,
    'unloadingWorker': unloadingWorker,
    'unloadingWorkerInBoL': unloadingWorkerInBoL,
    'otherExpenses': otherExpenses.map((e) => e.toMap()).toList(),
    'includeInBillOfLading': includeInBillOfLading,
  };

  factory ServiceExpenses.fromMap(Map<String, dynamic> map) {
    var othersList = map['otherExpenses'] as List? ?? [];
    return ServiceExpenses(
      billOfLadingCost: (map['billOfLadingCost'] ?? 0 as num).toDouble(),
      tollCost: (map['tollCost'] ?? 0 as num).toDouble(),
      tollInBoL: map['tollInBoL'] ?? false,
      fuelCost: (map['fuelCost'] ?? 0 as num).toDouble(),
      fuelInBoL: map['fuelInBoL'] ?? false,
      loadingTip: (map['loadingTip'] ?? 0 as num).toDouble(),
      loadingTipInBoL: map['loadingTipInBoL'] ?? false,
      unloadingTip: (map['unloadingTip'] ?? 0 as num).toDouble(),
      unloadingTipInBoL: map['unloadingTipInBoL'] ?? false,
      disinfectionCost: (map['disinfectionCost'] ?? 0 as num).toDouble(),
      disinfectionInBoL: map['disinfectionInBoL'] ?? false,
      commission: (map['commission'] ?? 0 as num).toDouble(),
      commissionInBoL: map['commissionInBoL'] ?? true,
      loadingWeighbridge: (map['loadingWeighbridge'] ?? 0 as num).toDouble(),
      loadingWeighbridgeInBoL: map['loadingWeighbridgeInBoL'] ?? false,
      loaderLoading: (map['loaderLoading'] ?? 0 as num).toDouble(),
      loaderLoadingInBoL: map['loaderLoadingInBoL'] ?? false,
      tallyClerk: (map['tallyClerk'] ?? 0 as num).toDouble(),
      tallyClerkInBoL: map['tallyClerkInBoL'] ?? false,
      unloadingWeighbridge: (map['unloadingWeighbridge'] ?? 0 as num).toDouble(),
      unloadingWeighbridgeInBoL: map['unloadingWeighbridgeInBoL'] ?? false,
      unloadingWorker: (map['unloadingWorker'] ?? 0 as num).toDouble(),
      unloadingWorkerInBoL: map['unloadingWorkerInBoL'] ?? false,
      otherExpenses: othersList.map((e) => OtherExpense.fromMap(Map<String, dynamic>.from(e))).toList(),
      includeInBillOfLading: map['includeInBillOfLading'] ?? false,
    );
  }
}

enum PaymentType { toSeller, fromCustomer, toLogistics, toDriver }
enum PaymentMethod { cash, check, card, sheba }
enum CheckStatus { pending, cleared, bounced, transferred }

class Payment {
  final String? id;
  final String? serviceId;
  final String? sellerId;
  final String? customerId;
  final String? logisticsId;
  final String? driverId;
  final String? myAccountId; 
  final PaymentType type;
  final PaymentMethod method;
  final double amount;
  final DateTime date;
  final String? description;
  final String? receiptImagePath;
  final DateTime? checkDueDate;
  final String? checkImagePath;
  final String? bankName;
  final String? checkNumber;
  final bool isCleared; 
  final CheckStatus status;
  final int graceDays;
  final String? transferredToId; 

  Payment({
    this.id,
    this.serviceId,
    this.sellerId,
    this.customerId,
    this.logisticsId,
    this.driverId,
    this.myAccountId,
    required this.type,
    required this.method,
    required this.amount,
    required this.date,
    this.description,
    this.receiptImagePath,
    this.checkDueDate,
    this.checkImagePath,
    this.bankName,
    this.checkNumber,
    this.isCleared = true,
    this.status = CheckStatus.cleared,
    this.graceDays = 0,
    this.transferredToId,
  });

  DateTime? get effectiveCheckDueDate => checkDueDate?.add(Duration(days: graceDays));

  Map<String, dynamic> toMap() => {
    'id': id,
    'serviceId': serviceId,
    'sellerId': sellerId,
    'customerId': customerId,
    'logisticsId': logisticsId,
    'driverId': driverId,
    'myAccountId': myAccountId,
    'type': type.index,
    'method': method.index,
    'amount': amount,
    'date': date.toIso8601String(),
    'description': description,
    'receiptImagePath': receiptImagePath,
    'checkDueDate': checkDueDate?.toIso8601String(),
    'checkImagePath': checkImagePath,
    'bankName': bankName,
    'checkNumber': checkNumber,
    'isCleared': isCleared,
    'status': status.index,
    'graceDays': graceDays,
    'transferredToId': transferredToId,
  };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    id: map['id'],
    serviceId: map['serviceId'],
    sellerId: map['sellerId'],
    customerId: map['customerId'],
    logisticsId: map['logisticsId'],
    driverId: map['driverId'],
    myAccountId: map['myAccountId'],
    type: PaymentType.values[map['type']],
    method: PaymentMethod.values[map['method']],
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date']),
    description: map['description'],
    receiptImagePath: map['receiptImagePath'],
    checkDueDate: map['checkDueDate'] != null ? DateTime.parse(map['checkDueDate']) : null,
    checkImagePath: map['checkImagePath'],
    bankName: map['bankName'],
    checkNumber: map['checkNumber'],
    isCleared: map['isCleared'] ?? true,
    status: map['status'] != null ? CheckStatus.values[map['status']] : (map['isCleared'] == false ? CheckStatus.pending : CheckStatus.cleared),
    graceDays: map['graceDays'] ?? 0,
    transferredToId: map['transferredToId'],
  );
}

class LoadService {
  final String id;
  final String orderCode;
  final Car car;
  final Driver driver;
  final LoadType loadType;
  final Seller seller;
  final Customer? customer;
  final LogisticsCo? logisticsCo;
  final String origin;
  final String destination;
  final DateTime date;
  final DateTime? loadingDateTime;
  final DateTime? unloadingDateTime;
  final double weight;
  final double transportPricePerTon;
  final double purchasePricePerTon;
  final List<Payment> paymentsToSeller;
  final List<Payment> collectionsFromCustomer;
  final List<Payment> paymentsToLogistics;
  final List<Payment> paymentsToDriver;
  final ServiceExpenses expenses;
  final String? purchaseInvoiceImagePath;
  final String? billOfLadingImagePath; // عکس بارنامه
  final String? weighbridgeImagePath; // عکس باسکول

  final String? fareAccountNumber;
  final String? fareAccountOwner;
  final String? fareBankName;

  final String? logisticsName;
  final String? logisticsPhone;
  final String? logisticsLocation;

  final bool isAgreedFreight;
  final double agreedFreightAmount;

  final double driverAgreementPercentage;
  final bool isOwnerDriver;
  final double extraDriverPay;

  LoadService({
    required this.id,
    required this.orderCode,
    required this.car,
    required this.driver,
    required this.loadType,
    required this.seller,
    this.customer,
    this.logisticsCo,
    required this.origin,
    required this.destination,
    required this.date,
    this.loadingDateTime,
    this.unloadingDateTime,
    required this.weight,
    required this.transportPricePerTon,
    this.purchasePricePerTon = 0,
    this.paymentsToSeller = const [],
    this.collectionsFromCustomer = const [],
    this.paymentsToLogistics = const [],
    this.paymentsToDriver = const [],
    required this.expenses,
    this.purchaseInvoiceImagePath,
    this.billOfLadingImagePath,
    this.weighbridgeImagePath,
    this.fareAccountNumber,
    this.fareAccountOwner,
    this.fareBankName,
    this.logisticsName,
    this.logisticsPhone,
    this.logisticsLocation,
    this.isAgreedFreight = false,
    this.agreedFreightAmount = 0,
    this.driverAgreementPercentage = 0,
    this.isOwnerDriver = false,
    this.extraDriverPay = 0,
  });

  double get totalPurchaseAmount => weight * purchasePricePerTon;
  
  double get totalPaidToSeller => paymentsToSeller
      .where((p) => p.status == CheckStatus.cleared || p.method != PaymentMethod.check)
      .fold(0.0, (sum, item) => sum + item.amount);
      
  double get pendingSellerChecks => paymentsToSeller
      .where((p) => p.method == PaymentMethod.check && p.status == CheckStatus.pending)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get remainingDebtToSeller => totalPurchaseAmount - totalPaidToSeller;
  double get finalBalanceToSeller => totalPurchaseAmount - totalPaidToSeller - pendingSellerChecks;

  double get totalTransportAmount => isAgreedFreight ? agreedFreightAmount : weight * transportPricePerTon;
  double get totalServicePriceForCustomer => totalPurchaseAmount + totalTransportAmount;
  
  double get totalCollectedFromCustomer => collectionsFromCustomer
      .where((p) => p.status == CheckStatus.cleared || p.status == CheckStatus.transferred || p.method != PaymentMethod.check)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get pendingCustomerChecks => collectionsFromCustomer
      .where((p) => p.method == PaymentMethod.check && p.status == CheckStatus.pending)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get remainingCustomerDebt => totalServicePriceForCustomer - totalCollectedFromCustomer;
  double get finalBalanceCustomerDebt => totalServicePriceForCustomer - totalCollectedFromCustomer - pendingCustomerChecks;

  double get totalPaidToLogistics => paymentsToLogistics
      .where((p) => p.status == CheckStatus.cleared || p.method != PaymentMethod.check)
      .fold(0.0, (sum, item) => sum + item.amount);
      
  double get pendingLogisticsChecks => paymentsToLogistics
      .where((p) => p.method == PaymentMethod.check && p.status == CheckStatus.pending)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get remainingLogisticsDebt => expenses.owedToLogistics - totalPaidToLogistics;
  double get finalBalanceLogisticsDebt => expenses.owedToLogistics - totalPaidToLogistics - pendingLogisticsChecks;

  double get totalPaidToDriver => paymentsToDriver
      .where((p) => p.status == CheckStatus.cleared || p.method != PaymentMethod.check)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get pendingDriverChecks => paymentsToDriver
      .where((p) => p.method == PaymentMethod.check && p.status == CheckStatus.pending)
      .fold(0.0, (sum, item) => sum + item.amount);

  /// سود خالص سرویس (سود مالک خودرو): کرایه حمل کل منهای تمام هزینه‌های انجام شده
  double get netProfit => totalTransportAmount - expenses.total;

  /// مبلغ "صافی" که راننده باید از باربری دریافت کند: کرایه حمل منهای مبالغ بارنامه
  double get driverNetPay => totalTransportAmount - expenses.owedToLogistics;

  /// حقوق راننده بر اساس درصد توافقی از کرایه کل + اضافه پرداختی
  double get driverSalary => (totalTransportAmount * driverAgreementPercentage / 100) + extraDriverPay;

  /// سهم مالک ماشین پس از کسر حقوق راننده (اگر راننده و مالک یکی نباشند)
  /// اگر راننده و مالک یکی باشند، سهم مالک همان سود خالص است.
  double get ownerShare => isOwnerDriver ? netProfit : netProfit - driverSalary;

  bool get isSellerSettled => remainingDebtToSeller <= 0;
  bool get isCustomerSettled => remainingCustomerDebt <= 0;
  bool get isLogisticsSettled => remainingLogisticsDebt <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderCode': orderCode,
      'carId': car.id,
      'driverId': driver.id,
      'loadTypeId': loadType.id,
      'sellerId': seller.id,
      'customerId': customer?.id,
      'logisticsId': logisticsCo?.id,
      'origin': origin,
      'destination': destination,
      'date': date.toIso8601String(),
      'loadingDateTime': loadingDateTime?.toIso8601String(),
      'unloadingDateTime': unloadingDateTime?.toIso8601String(),
      'weight': weight,
      'transportPricePerTon': transportPricePerTon,
      'purchasePricePerTon': purchasePricePerTon,
      'expenses': jsonEncode(expenses.toMap()),
      'purchaseInvoiceImagePath': purchaseInvoiceImagePath,
      'billOfLadingImagePath': billOfLadingImagePath,
      'weighbridgeImagePath': weighbridgeImagePath,
      'fareAccountNumber': fareAccountNumber,
      'fareAccountOwner': fareAccountOwner,
      'fareBankName': fareBankName,
      'logisticsName': logisticsName,
      'logisticsPhone': logisticsPhone,
      'logisticsLocation': logisticsLocation,
      'isAgreedFreight': isAgreedFreight ? 1 : 0,
      'agreedFreightAmount': agreedFreightAmount,
      'driverAgreementPercentage': driverAgreementPercentage,
      'isOwnerDriver': isOwnerDriver ? 1 : 0,
      'extraDriverPay': extraDriverPay,
    };
  }

  factory LoadService.fromMap(
    Map<String, dynamic> map, {
    required Car car,
    required Driver driver,
    required LoadType loadType,
    required Seller seller,
    Customer? customer,
    LogisticsCo? logisticsCo,
    List<Payment> paymentsToSeller = const [],
    List<Payment> collectionsFromCustomer = const [],
    List<Payment> paymentsToLogistics = const [],
    List<Payment> paymentsToDriver = const [],
  }) {
    return LoadService(
      id: map['id'],
      orderCode: map['orderCode'] ?? '',
      car: car,
      driver: driver,
      loadType: loadType,
      seller: seller,
      customer: customer,
      logisticsCo: logisticsCo,
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      date: DateTime.parse(map['date']),
      loadingDateTime: map['loadingDateTime'] != null ? DateTime.parse(map['loadingDateTime']) : null,
      unloadingDateTime: map['unloadingDateTime'] != null ? DateTime.parse(map['unloadingDateTime']) : null,
      weight: (map['weight'] as num).toDouble(),
      transportPricePerTon: (map['transportPricePerTon'] as num).toDouble(),
      purchasePricePerTon: (map['purchasePricePerTon'] as num).toDouble(),
      paymentsToSeller: paymentsToSeller,
      collectionsFromCustomer: collectionsFromCustomer,
      paymentsToLogistics: paymentsToLogistics,
      paymentsToDriver: paymentsToDriver,
      expenses: ServiceExpenses.fromMap(jsonDecode(map['expenses'])),
      purchaseInvoiceImagePath: map['purchaseInvoiceImagePath'],
      billOfLadingImagePath: map['billOfLadingImagePath'],
      weighbridgeImagePath: map['weighbridgeImagePath'],
      fareAccountNumber: map['fareAccountNumber'],
      fareAccountOwner: map['fareAccountOwner'],
      fareBankName: map['fareBankName'],
      logisticsName: map['logisticsName'],
      logisticsPhone: map['logisticsPhone'],
      logisticsLocation: map['logisticsLocation'],
      isAgreedFreight: (map['isAgreedFreight'] ?? 0) == 1,
      agreedFreightAmount: (map['agreedFreightAmount'] ?? 0 as num).toDouble(),
      driverAgreementPercentage: (map['driverAgreementPercentage'] as num? ?? 0).toDouble(),
      isOwnerDriver: (map['isOwnerDriver'] ?? 0) == 1,
      extraDriverPay: (map['extraDriverPay'] as num? ?? 0).toDouble(),
    );
  }
}
