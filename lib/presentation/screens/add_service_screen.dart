import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../core/data/service_repository.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../widgets/amount_input.dart';
import '../widgets/iranian_plate_input.dart';
import '../widgets/phone_input.dart';

class AddServiceScreen extends StatefulWidget {
  final LoadService? serviceToEdit;
  const AddServiceScreen({super.key, this.serviceToEdit});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceRepository _repository = ServiceRepository();

  List<Driver> _drivers = [];
  List<Car> _cars = [];
  List<LoadType> _loadTypes = [];
  List<Seller> _sellers = [];
  List<Customer> _customers = [];
  List<LogisticsCo> _logisticsCos = [];
  List<BankAccount> _bankAccounts = [];
  
  List<String> _originSuggestions = [];
  List<String> _destinationSuggestions = [];
  List<String> _expenseSuggestions = [];

  Driver? _selectedDriver;
  Car? _selectedCar;
  LoadType? _selectedLoadType;
  Seller? _selectedSeller;
  Customer? _selectedCustomer;
  LogisticsCo? _selectedLogisticsCo;
  BankAccount? _selectedBankAccount;

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _orderCodeController = TextEditingController();
  
  final TextEditingController _logisticsNameController = TextEditingController();
  final TextEditingController _logisticsPhoneController = TextEditingController();
  final TextEditingController _logisticsLocationController = TextEditingController();

  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountOwnerController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  double _fuel = 0;
  bool _fuelInBoL = false;
  double _toll = 0;
  bool _tollInBoL = false;
  double _loadingTip = 0;
  bool _loadingTipInBoL = false;
  double _unloadingTip = 0;
  bool _unloadingTipInBoL = false;
  double _disinfection = 0;
  bool _disinfectionInBoL = false;
  double _billOfLading = 0;
  double _commission = 0;
  bool _commissionInBoL = true;

  // New specific expense fields
  double _loadingWeighbridge = 0;
  bool _loadingWeighbridgeInBoL = false;
  double _loaderLoading = 0;
  bool _loaderLoadingInBoL = false;
  double _tallyClerk = 0;
  bool _tallyClerkInBoL = false;
  double _unloadingWeighbridge = 0;
  bool _unloadingWeighbridgeInBoL = false;
  double _unloadingWorker = 0;
  bool _unloadingWorkerInBoL = false;

  bool _includeInBillOfLading = false;
  
  List<OtherExpense> _otherExpenses = [];

  double _weight = 0;
  double _transportPricePerTon = 0;
  double _purchasePricePerTon = 0;
  
  bool _isAgreedFreight = false;
  double _agreedFreightAmount = 0;
  
  // Driver agreement fields
  double _driverAgreementPercentage = 0;
  bool _isOwnerDriver = false;
  double _extraDriverPay = 0;

  DateTime? _loadingDateTime;
  DateTime? _unloadingDateTime;

  String? _purchaseInvoiceImagePath;
  String? _billOfLadingImagePath;
  String? _weighbridgeImagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData().then((_) {
      if (widget.serviceToEdit != null) {
        _fillDataForEdit();
      } else {
        _generateOrderCode();
      }
    });
  }

  Future<void> _generateOrderCode() async {
    final code = await _repository.generateUniqueOrderCode();
    setState(() {
      _orderCodeController.text = code;
    });
  }

  void _fillDataForEdit() {
    final s = widget.serviceToEdit!;
    setState(() {
      _selectedDriver = _drivers.any((d) => d.id == s.driver.id) ? _drivers.firstWhere((d) => d.id == s.driver.id) : null;
      _selectedCar = _cars.any((c) => c.id == s.car.id) ? _cars.firstWhere((c) => c.id == s.car.id) : null;
      _selectedLoadType = _loadTypes.any((lt) => lt.id == s.loadType.id) ? _loadTypes.firstWhere((lt) => lt.id == s.loadType.id) : null;
      _selectedSeller = _sellers.any((sel) => sel.id == s.seller.id) ? _sellers.firstWhere((sel) => sel.id == s.seller.id) : null;
      _selectedLogisticsCo = _logisticsCos.any((l) => l.id == s.logisticsCo?.id) ? _logisticsCos.firstWhere((l) => l.id == s.logisticsCo!.id) : null;

      if (s.customer != null) {
        _selectedCustomer = _customers.any((c) => c.id == s.customer!.id) ? _customers.firstWhere((c) => c.id == s.customer!.id) : null;
      }
      
      _originController.text = s.origin;
      _destinationController.text = s.destination;
      _orderCodeController.text = s.orderCode;
      
      _logisticsNameController.text = s.logisticsName ?? "";
      _logisticsPhoneController.text = s.logisticsPhone ?? "";
      _logisticsLocationController.text = s.logisticsLocation ?? "";

      _accountNumberController.text = s.fareAccountNumber ?? "";
      _accountOwnerController.text = s.fareAccountOwner ?? "";
      _bankNameController.text = s.fareBankName ?? "";

      try {
        _selectedBankAccount = _bankAccounts.firstWhere((a) => a.accountNumber == s.fareAccountNumber && a.bankName == s.fareBankName);
      } catch (_) {
        _selectedBankAccount = null;
      }

      _weight = s.weight;
      _transportPricePerTon = s.transportPricePerTon;
      _purchasePricePerTon = s.purchasePricePerTon;
      
      _isAgreedFreight = s.isAgreedFreight;
      _agreedFreightAmount = s.agreedFreightAmount;
      
      _driverAgreementPercentage = s.driverAgreementPercentage;
      _isOwnerDriver = s.isOwnerDriver;
      _extraDriverPay = s.extraDriverPay;

      _loadingDateTime = s.loadingDateTime;
      _unloadingDateTime = s.unloadingDateTime;

      _purchaseInvoiceImagePath = s.purchaseInvoiceImagePath;
      _billOfLadingImagePath = s.billOfLadingImagePath;
      _weighbridgeImagePath = s.weighbridgeImagePath;

      _fuel = s.expenses.fuelCost;
      _fuelInBoL = s.expenses.fuelInBoL;
      _toll = s.expenses.tollCost;
      _tollInBoL = s.expenses.tollInBoL;
      _loadingTip = s.expenses.loadingTip;
      _loadingTipInBoL = s.expenses.loadingTipInBoL;
      _unloadingTip = s.expenses.unloadingTip;
      _unloadingTipInBoL = s.expenses.unloadingTipInBoL;
      _disinfection = s.expenses.disinfectionCost;
      _disinfectionInBoL = s.expenses.disinfectionInBoL;
      _billOfLading = s.expenses.billOfLadingCost;
      _commission = s.expenses.commission;
      _commissionInBoL = s.expenses.commissionInBoL;

      _loadingWeighbridge = s.expenses.loadingWeighbridge;
      _loadingWeighbridgeInBoL = s.expenses.loadingWeighbridgeInBoL;
      _loaderLoading = s.expenses.loaderLoading;
      _loaderLoadingInBoL = s.expenses.loaderLoadingInBoL;
      _tallyClerk = s.expenses.tallyClerk;
      _tallyClerkInBoL = s.expenses.tallyClerkInBoL;
      _unloadingWeighbridge = s.expenses.unloadingWeighbridge;
      _unloadingWeighbridgeInBoL = s.expenses.unloadingWeighbridgeInBoL;
      _unloadingWorker = s.expenses.unloadingWorker;
      _unloadingWorkerInBoL = s.expenses.unloadingWorkerInBoL;

      _includeInBillOfLading = s.expenses.includeInBillOfLading;
      _otherExpenses = List.from(s.expenses.otherExpenses);
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final drivers = await _repository.getDrivers();
      final cars = await _repository.getCars();
      final types = await _repository.getLoadTypes();
      final sellers = await _repository.getSellers();
      final customers = await _repository.getCustomers();
      final logistics = await _repository.getLogisticsCos();
      final bankAccounts = await _repository.getBankAccounts();
      
      final origins = await _repository.getSuggestions('origins');
      final destinations = await _repository.getSuggestions('destinations');
      final expenses = await _repository.getSuggestions('expense_titles');

      setState(() {
        _drivers = drivers;
        _cars = cars;
        _loadTypes = types;
        _sellers = sellers;
        _customers = customers;
        _logisticsCos = logistics;
        _bankAccounts = bankAccounts;
        _originSuggestions = origins;
        _destinationSuggestions = destinations;
        _expenseSuggestions = expenses;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در بارگذاری اطلاعات: $e')));
      }
    }
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (type == 'invoice') _purchaseInvoiceImagePath = picked.path;
        else if (type == 'bol') _billOfLadingImagePath = picked.path;
        else if (type == 'weigh') _weighbridgeImagePath = picked.path;
      });
    }
  }

  void _addOtherExpense() {
    final titleController = TextEditingController();
    double amount = 0;
    bool includeInBoL = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('افزودن هزینه جانبی'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(
                controller: titleController,
                label: 'عنوان هزینه (اجباری)',
                suggestions: _expenseSuggestions,
                onChanged: (v) => setDialogState(() {}),
              ),
              const SizedBox(height: 12),
              AmountInput(
                label: 'مبلغ (تومان) - اجباری',
                onChanged: (v) => amount = v,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('اضافه به بارنامه', style: TextStyle(fontSize: 13)),
                value: includeInBoL,
                onChanged: (v) => setDialogState(() => includeInBoL = v ?? false),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً عنوان هزینه را وارد کنید')));
                  return;
                }
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً مبلغ معتبری وارد کنید')));
                  return;
                }
                setState(() {
                  _otherExpenses.add(OtherExpense(
                    title: titleController.text.trim(),
                    amount: amount,
                    includeInBoL: includeInBoL,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLogisticsCoDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
    _showStyledDialog(
      title: 'باربری جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام باربری (اجباری)', icon: Icons.business, isRequired: true),
        const SizedBox(height: 12),
        _buildTextField(controller: phoneController, label: 'شماره تماس', icon: Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _buildTextField(controller: locationController, label: 'شهر یا استان', icon: Icons.location_on_outlined),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final newCo = LogisticsCo(
            id: DateTime.now().millisecondsSinceEpoch.toString(), 
            name: nameController.text, 
            phone: phoneController.text,
            location: locationController.text,
          );
          await _repository.saveLogisticsCo(newCo);
          await _loadInitialData();
          setState(() {
            _selectedLogisticsCo = _logisticsCos.firstWhere((l) => l.id == newCo.id);
          });
          return true;
        }
        return false;
      },
    );
  }

  void _showAddDriverDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    _showStyledDialog(
      title: 'راننده جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام و نام خانوادگی (اجباری)', icon: Icons.person, isRequired: true),
        const SizedBox(height: 12),
        _buildTextField(controller: phoneController, label: 'شماره تماس', icon: Icons.phone, keyboardType: TextInputType.phone),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final names = nameController.text.trim().split(' ');
          final first = names[0];
          final last = names.length > 1 ? names.sublist(1).join(' ') : '';
          
          final newDriver = Driver(id: DateTime.now().millisecondsSinceEpoch.toString(), firstName: first, lastName: last, phone: phoneController.text);
          await _repository.saveDriver(newDriver);
          await _loadInitialData();
          setState(() => _selectedDriver = _drivers.firstWhere((d) => d.id == newDriver.id));
          return true;
        }
        return false;
      },
    );
  }

  void _showAddCarDialog() {
    final nameController = TextEditingController();
    String plateValue = "";
    _showStyledDialog(
      title: 'خودرو جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام خودرو (اجباری)', icon: Icons.local_shipping, isRequired: true),
        const SizedBox(height: 16),
        IranianPlateInput(onChanged: (v) => plateValue = v),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final newCar = Car(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameController.text, plate: plateValue);
          await _repository.saveCar(newCar);
          await _loadInitialData();
          setState(() => _selectedCar = _cars.firstWhere((c) => c.id == newCar.id));
          return true;
        }
        return false;
      },
    );
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final villageController = TextEditingController();
    _showStyledDialog(
      title: 'مشتری جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام و نام خانوادگی (اجباری)', icon: Icons.person_pin, isRequired: true),
        const SizedBox(height: 12),
        _buildTextField(controller: villageController, label: 'روستا/منطقه', icon: Icons.location_city),
        const SizedBox(height: 12),
        PhoneInput(controller: phoneController, label: 'شماره تماس'),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final names = nameController.text.trim().split(' ');
          final first = names[0];
          final last = names.length > 1 ? names.sublist(1).join(' ') : '';

          final newCustomer = Customer(id: DateTime.now().millisecondsSinceEpoch.toString(), firstName: first, lastName: last, phone: phoneController.text, village: villageController.text);
          await _repository.saveCustomer(newCustomer);
          await _loadInitialData();
          setState(() => _selectedCustomer = _customers.firstWhere((c) => c.id == newCustomer.id));
          return true;
        }
        return false;
      },
    );
  }

  void _showAddSellerDialog() {
    final nameController = TextEditingController();
    final productController = TextEditingController();
    _showStyledDialog(
      title: 'فروشنده جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام فروشنده (اجباری)', icon: Icons.store, isRequired: true),
        const SizedBox(height: 12),
        _buildTextField(controller: productController, label: 'نوع کالا', icon: Icons.category),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final newSeller = Seller(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameController.text, product: productController.text);
          await _repository.saveSeller(newSeller);
          await _loadInitialData();
          setState(() => _selectedSeller = _sellers.firstWhere((s) => s.id == newSeller.id));
          return true;
        }
        return false;
      },
    );
  }

  void _showAddLoadTypeDialog() {
    final nameController = TextEditingController();
    _showStyledDialog(
      title: 'نوع بار جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام بار (اجباری)', icon: Icons.category, isRequired: true),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final newType = LoadType(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameController.text);
          await _repository.saveLoadType(newType);
          await _loadInitialData();
          setState(() => _selectedLoadType = _loadTypes.firstWhere((lt) => lt.id == newType.id));
          return true;
        }
        return false;
      },
    );
  }

  void _showAddBankAccountDialog() {
    final bankNameController = TextEditingController();
    final accountController = TextEditingController();
    final ownerController = TextEditingController();
    _showStyledDialog(
      title: 'حساب بانکی جدید',
      children: [
        _buildTextField(controller: bankNameController, label: 'نام بانک (اجباری)', icon: Icons.account_balance, isRequired: true),
        const SizedBox(height: 12),
        _buildTextField(controller: accountController, label: 'شماره حساب/کارت', icon: Icons.credit_card, keyboardType: TextInputType.number, isRequired: true),
        const SizedBox(height: 12),
        _buildTextField(controller: ownerController, label: 'نام صاحب حساب', icon: Icons.person_outline),
      ],
      onConfirm: () async {
        if (bankNameController.text.isNotEmpty && accountController.text.isNotEmpty) {
          final newAcc = BankAccount(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            bankName: bankNameController.text.trim(),
            accountNumber: accountController.text.trim(),
            accountOwner: ownerController.text.trim(),
            initialBalance: 0,
          );
          await _repository.saveBankAccount(newAcc);
          await _loadInitialData();
          setState(() {
            _selectedBankAccount = _bankAccounts.firstWhere((a) => a.id == newAcc.id);
            _bankNameController.text = _selectedBankAccount!.bankName;
            _accountNumberController.text = _selectedBankAccount!.accountNumber;
            _accountOwnerController.text = _selectedBankAccount!.accountOwner;
          });
          return true;
        }
        return false;
      },
    );
  }

  void _showStyledDialog({required String title, required List<Widget> children, required Future<bool> Function() onConfirm}) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: children)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(onPressed: () async { if (await onConfirm() && mounted) Navigator.pop(context); }, child: const Text('ذخیره')),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )
    );
  }

  Future<void> _selectDateTime(bool isPickup) async {
    final pickedDate = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromDateTime((isPickup ? _loadingDateTime : _unloadingDateTime) ?? DateTime.now()),
      firstDate: Jalali(1400, 1, 1),
      lastDate: Jalali(1450, 12, 29),
    );
    
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime((isPickup ? _loadingDateTime : _unloadingDateTime) ?? DateTime.now()),
      );
      
      if (pickedTime != null) {
        final dateTime = pickedDate.toDateTime().add(Duration(hours: pickedTime.hour, minutes: pickedTime.minute));
        setState(() {
          if (isPickup) _loadingDateTime = dateTime;
          else _unloadingDateTime = dateTime;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final currentExpenses = ServiceExpenses(
      fuelCost: _fuel, fuelInBoL: _fuelInBoL,
      tollCost: _toll, tollInBoL: _tollInBoL,
      loadingTip: _loadingTip, loadingTipInBoL: _loadingTipInBoL,
      unloadingTip: _unloadingTip, unloadingTipInBoL: _unloadingTipInBoL,
      disinfectionCost: _disinfection, disinfectionInBoL: _disinfectionInBoL,
      billOfLadingCost: _billOfLading,
      commission: _commission, commissionInBoL: _commissionInBoL,
      loadingWeighbridge: _loadingWeighbridge, loadingWeighbridgeInBoL: _loadingWeighbridgeInBoL,
      loaderLoading: _loaderLoading, loaderLoadingInBoL: _loaderLoadingInBoL,
      tallyClerk: _tallyClerk, tallyClerkInBoL: _tallyClerkInBoL,
      unloadingWeighbridge: _unloadingWeighbridge, unloadingWeighbridgeInBoL: _unloadingWeighbridgeInBoL,
      unloadingWorker: _unloadingWorker, unloadingWorkerInBoL: _unloadingWorkerInBoL,
      otherExpenses: _otherExpenses,
      includeInBillOfLading: _includeInBillOfLading,
    );

    final tempService = LoadService(
      id: "temp", orderCode: "", 
      car: Car(id: "", name: ""), driver: Driver(id: "", firstName: "", lastName: "", phone: ""), 
      loadType: LoadType(id: "", name: ""), seller: Seller(id: "", name: "", product: ""),
      origin: "", destination: "", date: DateTime.now(),
      weight: _weight, transportPricePerTon: _transportPricePerTon,
      isAgreedFreight: _isAgreedFreight, agreedFreightAmount: _agreedFreightAmount,
      expenses: currentExpenses,
      driverAgreementPercentage: _driverAgreementPercentage,
      isOwnerDriver: _isOwnerDriver,
      extraDriverPay: _extraDriverPay,
      loadingDateTime: _loadingDateTime,
      unloadingDateTime: _unloadingDateTime,
    );

    double totalTransport = tempService.totalTransportAmount;
    double bolAmount = currentExpenses.owedToLogistics;
    double netPay = tempService.driverNetPay;
    double netProfit = tempService.netProfit;
    double driverSalary = tempService.driverSalary;
    double ownerShare = tempService.ownerShare;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: Text(widget.serviceToEdit == null ? 'ثبت سرویس جدید' : 'ویرایش سرویس')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildStepCard(
                      title: 'اطلاعات اصلی و راننده',
                      icon: Icons.qr_code_scanner,
                      children: [
                        _buildTextField(controller: _orderCodeController, label: 'کد سفارش', icon: Icons.numbers, readOnly: true),
                        const SizedBox(height: 12),
                        _buildDropdownField<LogisticsCo>(
                          label: 'انتخاب باربری', 
                          icon: Icons.business_outlined, 
                          value: _selectedLogisticsCo, 
                          items: _logisticsCos, 
                          onChanged: (v) {
                            setState(() {
                              _selectedLogisticsCo = v;
                              if (v != null) {
                                _logisticsNameController.text = v.name;
                                _logisticsPhoneController.text = v.phone;
                                _logisticsLocationController.text = v.location ?? "";
                              }
                            });
                          }, 
                          itemLabel: (l) => "${l.name} (${l.location ?? 'بدون مکان'})", 
                          onAddPressed: _showAddLogisticsCoDialog
                        ),
                        if (_selectedLogisticsCo == null) ...[
                          _buildTextField(controller: _logisticsNameController, label: 'نام باربری (ثبت مستقیم)', icon: Icons.business),
                          const SizedBox(height: 12),
                          _buildTextField(controller: _logisticsPhoneController, label: 'تلفن باربری', icon: Icons.phone, keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _buildTextField(controller: _logisticsLocationController, label: 'شهر یا استان باربری', icon: Icons.location_on_outlined),
                          const SizedBox(height: 12),
                        ],
                        _buildDropdownField<Driver>(label: 'انتخاب راننده (اجباری)', icon: Icons.person_outline, value: _selectedDriver, items: _drivers, onChanged: (v) => _selectedDriver = v, itemLabel: (d) => d.fullName, onAddPressed: _showAddDriverDialog),
                        _buildDropdownField<Car>(label: 'انتخاب ماشین (اجباری)', icon: Icons.local_shipping_outlined, value: _selectedCar, items: _cars, onChanged: (v) => _selectedCar = v, itemLabel: (c) => c.name, onAddPressed: _showAddCarDialog),
                        
                        const Divider(height: 32),
                        const Text('توافق با راننده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('راننده و صاحب ماشین یکی هستند', style: TextStyle(fontSize: 13)),
                          value: _isOwnerDriver,
                          onChanged: (v) => setState(() => _isOwnerDriver = v),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        if (!_isOwnerDriver) ...[
                          Row(
                            children: [
                              Expanded(
                                child: AmountInput(
                                  label: 'درصد حقوق راننده', 
                                  unit: 'درصد', 
                                  isDecimal: true,
                                  initialValue: _driverAgreementPercentage, 
                                  onChanged: (v) => setState(() => _driverAgreementPercentage = v)
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AmountInput(
                                  label: 'اضافه پرداختی راننده', 
                                  initialValue: _extraDriverPay, 
                                  onChanged: (v) => setState(() => _extraDriverPay = v)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "حقوق محاسباتی: ${AppFormatters.formatCurrency(driverSalary)} تومان",
                            style: TextStyle(fontSize: 12, color: theme.primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                        const Divider(height: 32),
                        
                        _buildDropdownField<LoadType>(label: 'نوع بار (اجباری)', icon: Icons.category_outlined, value: _selectedLoadType, items: _loadTypes, onChanged: (v) => _selectedLoadType = v, itemLabel: (l) => l.name, onAddPressed: _showAddLoadTypeDialog),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      title: 'اسناد و تصاویر باربری',
                      icon: Icons.photo_library_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildImagePickerButton(
                                label: 'تصویر بارنامه',
                                icon: Icons.document_scanner_outlined,
                                path: _billOfLadingImagePath,
                                onTap: () => _pickImage('bol'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildImagePickerButton(
                                label: 'برگه باسکول',
                                icon: Icons.scale_outlined,
                                path: _weighbridgeImagePath,
                                onTap: () => _pickImage('weigh'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      title: 'طرفین حساب و مسیر',
                      icon: Icons.map_outlined,
                      children: [
                        _buildDropdownField<Seller>(label: 'فروشنده (اجباری)', icon: Icons.store_outlined, value: _selectedSeller, items: _sellers, onChanged: (v) => _selectedSeller = v, itemLabel: (s) => s.name, onAddPressed: _showAddSellerDialog),
                        _buildDropdownField<Customer>(label: 'مشتری (اختیاری)', icon: Icons.person_pin_outlined, value: _selectedCustomer, items: _customers, onChanged: (v) => _selectedCustomer = v, itemLabel: (c) => c.fullName, onAddPressed: _showAddCustomerDialog),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _buildAutocompleteField(controller: _originController, label: 'مبدا (اجباری)', suggestions: _originSuggestions, icon: Icons.location_on_outlined, isRequired: true, onChanged: (v) => setState(() {}))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildAutocompleteField(controller: _destinationController, label: 'مقصد (اجباری)', suggestions: _destinationSuggestions, icon: Icons.flag_outlined, isRequired: true, onChanged: (v) => setState(() {}))),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      title: 'زمان بارگیری و تخلیه',
                      icon: Icons.access_time_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateTimePickerButton(
                                label: 'زمان بارگیری',
                                icon: Icons.upload_outlined,
                                dateTime: _loadingDateTime,
                                onTap: () => _selectDateTime(true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateTimePickerButton(
                                label: 'زمان تخلیه',
                                icon: Icons.download_outlined,
                                dateTime: _unloadingDateTime,
                                onTap: () => _selectDateTime(false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      title: 'جزییات بار و مالی',
                      icon: Icons.payments_outlined,
                      children: [
                        SwitchListTile(
                          title: const Text('کرایه توافقی (بدون محاسبه وزن)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          value: _isAgreedFreight,
                          onChanged: (v) => setState(() => _isAgreedFreight = v),
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(Icons.handshake_outlined, color: theme.primaryColor),
                        ),
                        const SizedBox(height: 8),
                        if (_isAgreedFreight) ...[
                          AmountInput(label: 'مبلغ کرایه توافقی', initialValue: _agreedFreightAmount, onChanged: (v) => setState(() => _agreedFreightAmount = v)),
                          const SizedBox(height: 12),
                          AmountInput(label: 'وزن بار (تن) - فقط برای ثبت در گزارش', unit: 'تن', isDecimal: true, initialValue: _weight, onChanged: (v) => setState(() => _weight = v)),
                        ] else ...[
                          AmountInput(label: 'وزن بار (تن)', unit: 'تن', isDecimal: true, initialValue: _weight, onChanged: (v) => setState(() => _weight = v)),
                          const SizedBox(height: 12),
                          AmountInput(label: 'قیمت هر تن حمل', initialValue: _transportPricePerTon, onChanged: (v) => setState(() => _transportPricePerTon = v)),
                        ],
                        const SizedBox(height: 12),
                        AmountInput(label: 'قیمت هر تن خرید (اختیاری)', initialValue: _purchasePricePerTon, onChanged: (v) => setState(() => _purchasePricePerTon = v)),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage('invoice'),
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(_purchaseInvoiceImagePath == null ? 'افزودن تصویر فاکتور خرید' : 'تصویر فاکتور انتخاب شد'),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                        ),
                        if (_purchaseInvoiceImagePath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Image.file(File(_purchaseInvoiceImagePath!), height: 100, fit: BoxFit.cover),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      title: 'مخارج سرویس',
                      icon: Icons.receipt_long_outlined,
                      children: [
                        AmountInput(label: 'هزینه پایه بارنامه (اجباری)', initialValue: _billOfLading, onChanged: (v) => setState(() => _billOfLading = v)),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('افزودن کل هزینه‌ها به مبلغ بارنامه', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('در صورت فعال‌سازی، کل مخارج در بدهی به باربری لحاظ می‌شود', style: TextStyle(fontSize: 11)),
                          value: _includeInBillOfLading,
                          onChanged: (v) => setState(() => _includeInBillOfLading = v),
                        ),
                        const Divider(),
                        if (!_includeInBillOfLading) ...[
                          Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: const Text('جزییات مخارج (کمیسیون، بارگیری، تخلیه و...)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                              leading: const Icon(Icons.list_alt, size: 20),
                              initiallyExpanded: true,
                              childrenPadding: const EdgeInsets.symmetric(horizontal: 4),
                              children: [
                                _buildExpenseWithToggle(
                                  label: 'کمیسیون باربری', 
                                  amount: _commission, 
                                  inBoL: _commissionInBoL,
                                  onAmountChanged: (v) => setState(() => _commission = v),
                                  onToggleChanged: (v) => setState(() => _commissionInBoL = v),
                                ),
                                _buildExpenseWithToggle(
                                  label: 'سوخت', 
                                  amount: _fuel, 
                                  inBoL: _fuelInBoL,
                                  onAmountChanged: (v) => setState(() => _fuel = v),
                                  onToggleChanged: (v) => setState(() => _fuelInBoL = v),
                                ),
                                _buildExpenseWithToggle(
                                  label: 'عوارض', 
                                  amount: _toll, 
                                  inBoL: _tollInBoL,
                                  onAmountChanged: (v) => setState(() => _toll = v),
                                  onToggleChanged: (v) => setState(() => _tollInBoL = v),
                                ),
                                _buildExpenseWithToggle(
                                  label: 'هزینه ضدعفونی', 
                                  amount: _disinfection, 
                                  inBoL: _disinfectionInBoL,
                                  onAmountChanged: (v) => setState(() => _disinfection = v),
                                  onToggleChanged: (v) => setState(() => _disinfectionInBoL = v),
                                ),
                                
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(children: [
                                    Icon(Icons.upload_outlined, size: 16, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('مخارج بارگیری', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  ]),
                                ),
                                _buildExpenseWithToggle(
                                  label: 'انعام بارگیری', 
                                  amount: _loadingTip, 
                                  inBoL: _loadingTipInBoL,
                                  onAmountChanged: (v) => setState(() => _loadingTip = v),
                                  onToggleChanged: (v) => setState(() => _loadingTipInBoL = v),
                                ),
                                _buildExpenseWithToggle(
                                  label: 'باسکول بارگیری', 
                                  amount: _loadingWeighbridge, 
                                  inBoL: _loadingWeighbridgeInBoL,
                                  onAmountChanged: (v) => setState(() => _loadingWeighbridge = v),
                                  onToggleChanged: (v) => setState(() => _loadingWeighbridgeInBoL = v),
                                ),
                                _buildExpenseWithToggle(
                                  label: 'بارگیری با لودر', 
                                  amount: _loaderLoading, 
                                  inBoL: _loaderLoadingInBoL,
                                  onAmountChanged: (v) => setState(() => _loaderLoading = v),
                                  onToggleChanged: (v) => setState(() => _loaderLoadingInBoL = v),
                                ),
                                _buildExpenseWithToggle(
                                  label: 'بارشمار', 
                                  amount: _tallyClerk, 
                                  inBoL: _tallyClerkInBoL,
                                  onAmountChanged: (v) => setState(() => _tallyClerk = v),
                                  onToggleChanged: (v) => setState(() => _tallyClerkInBoL = v),
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(children: [
                                    Icon(Icons.download_outlined, size: 16, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('مخارج تخلیه', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ]),
                                ),
                                _buildExpenseWithToggle(
                                  label: 'انعام تخلیه', 
                                  amount: _unloadingTip, 
                                  inBoL: _unloadingTipInBoL,
                                  onAmountChanged: (v) => setState(() => _unloadingTip = v),
                                  onToggleChanged: (v) => setState(() => _unloadingTipInBoL = v),
                                ),
                                _buildExpenseWithToggle(
                                  label: 'باسکول تخلیه', 
                                  amount: _unloadingWeighbridge, 
                                  inBoL: _unloadingWeighbridgeInBoL,
                                  onAmountChanged: (v) => setState(() => _unloadingWeighbridge = v),
                                  onToggleChanged: (v) => setState(() => _unloadingWeighbridgeInBoL = v),
                                ),
                                _buildExpenseWithToggle(
                                  label: 'کارگر تخلیه', 
                                  amount: _unloadingWorker, 
                                  inBoL: _unloadingWorkerInBoL,
                                  onAmountChanged: (v) => setState(() => _unloadingWorker = v),
                                  onToggleChanged: (v) => setState(() => _unloadingWorkerInBoL = v),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          AmountInput(label: 'کمیسیون باربری', initialValue: _commission, onChanged: (v) => setState(() => _commission = v)),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: AmountInput(label: 'سوخت', initialValue: _fuel, onChanged: (v) => setState(() => _fuel = v))),
                            const SizedBox(width: 12),
                            Expanded(child: AmountInput(label: 'عوارض', initialValue: _toll, onChanged: (v) => setState(() => _toll = v))),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: AmountInput(label: 'انعام بارگیری', initialValue: _loadingTip, onChanged: (v) => setState(() => _loadingTip = v))),
                            const SizedBox(width: 12),
                            Expanded(child: AmountInput(label: 'باسکول بارگیری', initialValue: _loadingWeighbridge, onChanged: (v) => setState(() => _loadingWeighbridge = v))),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: AmountInput(label: 'بارگیری با لودر', initialValue: _loaderLoading, onChanged: (v) => setState(() => _loaderLoading = v))),
                            const SizedBox(width: 12),
                            Expanded(child: AmountInput(label: 'بارشمار', initialValue: _tallyClerk, onChanged: (v) => setState(() => _tallyClerk = v))),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: AmountInput(label: 'انعام تخلیه', initialValue: _unloadingTip, onChanged: (v) => setState(() => _unloadingTip = v))),
                            const SizedBox(width: 12),
                            Expanded(child: AmountInput(label: 'باسکول تخلیه', initialValue: _unloadingWeighbridge, onChanged: (v) => setState(() => _unloadingWeighbridge = v))),
                          ]),
                          const SizedBox(height: 12),
                          AmountInput(label: 'کارگر تخلیه', initialValue: _unloadingWorker, onChanged: (v) => setState(() => _unloadingWorker = v)),
                          const SizedBox(height: 12),
                          AmountInput(label: 'هزینه ضدعفونی', initialValue: _disinfection, onChanged: (v) => setState(() => _disinfection = v)),
                        ],
                        const Divider(height: 32),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('سایر هزینه‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          TextButton.icon(onPressed: _addOtherExpense, icon: const Icon(Icons.add, size: 18), label: const Text('افزودن')),
                        ]),
                        ..._otherExpenses.map((exp) => ListTile(
                          dense: true,
                          title: Row(
                            children: [
                              Text(exp.title),
                              if (exp.includeInBoL) 
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('در بارنامه', style: TextStyle(fontSize: 9, color: Colors.blue)),
                                ),
                            ],
                          ),
                          subtitle: Text("${AppFormatters.formatCurrency(exp.amount)} تومان"),
                          trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: () => setState(() => _otherExpenses.remove(exp))),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      title: 'اطلاعات واریز کرایه',
                      icon: Icons.account_balance_outlined,
                      children: [
                        _buildDropdownField<BankAccount>(
                          label: 'انتخاب حساب ذخیره شده',
                          icon: Icons.account_balance_wallet_outlined,
                          value: _selectedBankAccount,
                          items: _bankAccounts,
                          onChanged: (v) {
                            setState(() {
                              _selectedBankAccount = v;
                              if (v != null) {
                                _bankNameController.text = v.bankName;
                                _accountNumberController.text = v.accountNumber;
                                _accountOwnerController.text = v.accountOwner;
                              }
                            });
                          },
                          itemLabel: (a) => "${a.bankName} - ${a.accountOwner}",
                          onAddPressed: _showAddBankAccountDialog,
                          isRequired: false,
                        ),
                        const Divider(height: 32),
                        _buildTextField(controller: _bankNameController, label: 'نام بانک', icon: Icons.account_balance),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _accountNumberController, label: 'شماره حساب/کارت', icon: Icons.credit_card, keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _accountOwnerController, label: 'نام صاحب حساب', icon: Icons.person_outline),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSummaryCard(totalTransport, bolAmount, netPay, netProfit, driverSalary, ownerShare, theme),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveService,
                        style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Text(widget.serviceToEdit == null ? 'ثبت نهایی سرویس' : 'ذخیره تغییرات', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepCard({required String title, required IconData icon, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEAECF0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 20, color: theme.primaryColor), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDateTimePickerButton({required String label, required IconData icon, required DateTime? dateTime, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dateTime != null ? Colors.blue : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: dateTime != null ? Colors.blue : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (dateTime != null) ...[
              const SizedBox(height: 4),
              Text(
                "${AppFormatters.formatPersianDateTime(dateTime)}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerButton({required String label, required IconData icon, required String? path, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: path != null ? Colors.green : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            if (path == null) ...[
              Icon(icon, color: Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(path), height: 40, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 4),
              const Text('تغییر عکس', style: TextStyle(fontSize: 10, color: Colors.green)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseWithToggle({
    required String label, 
    required double amount, 
    required bool inBoL,
    required Function(double) onAmountChanged,
    required Function(bool) onToggleChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          AmountInput(label: label, initialValue: amount, onChanged: onAmountChanged),
          CheckboxListTile(
            title: const Text('اضافه به بارنامه', style: TextStyle(fontSize: 12)),
            value: inBoL,
            onChanged: (v) => onToggleChanged(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
          const Divider(height: 1, indent: 8, endIndent: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double transport, double bolAmount, double netPay, double netProfit, double driverSalary, double ownerShare, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.primaryColor.withOpacity(0.1))),
      child: Column(
        children: [
          _buildCalcRow('جمع کرایه حمل کل:', transport, theme),
          _buildCalcRow('جمع مبالغ بارنامه:', bolAmount, theme, color: Colors.orange.shade800),
          const Divider(height: 16),
          _buildCalcRow('صافی (دریافتی از باربری):', netPay, theme, isBold: true, color: Colors.blue.shade800),
          _buildCalcRow('سود واقعی سرویس:', netProfit, theme, isBold: true, color: Colors.green.shade700),
          if (!_isOwnerDriver) ...[
            const Divider(height: 16),
            _buildCalcRow('حقوق پرداختی به راننده:', driverSalary, theme, color: Colors.deepPurple),
            _buildCalcRow('سهم خالص مالک ماشین:', ownerShare, theme, isBold: true, color: Colors.teal.shade800),
          ],
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, double amount, ThemeData theme, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("${AppFormatters.formatCurrency(amount)} تومان", style: TextStyle(fontSize: isBold ? 15 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, bool readOnly = false, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'لطفاً $label را وارد کنید';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required List<String> suggestions,
    IconData? icon,
    bool isRequired = false,
    required Function(String) onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return suggestions;
          }
          return suggestions.where((String option) {
            return option.contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          controller.text = selection;
          onChanged(selection);
        },
        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
          if (controller.text.isNotEmpty && textController.text.isEmpty) {
            textController.text = controller.text;
          }
          textController.addListener(() {
            controller.text = textController.text;
            onChanged(textController.text);
          });

          return TextFormField(
            controller: textController,
            focusNode: focusNode,
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'لطفاً $label را وارد کنید';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: icon != null ? Icon(icon, size: 20) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topRight,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: constraints.maxWidth,
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return ListTile(
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label, 
    required IconData icon, 
    required T? value, 
    required List<T> items, 
    required void Function(T?) onChanged, 
    required String Function(T) itemLabel, 
    VoidCallback? onAddPressed,
    bool isRequired = true,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<T>(
              value: value,
              validator: isRequired ? (v) => v == null ? 'لطفاً یک مورد را انتخاب کنید' : null : null,
              decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(itemLabel(i)))).toList(),
              onChanged: (v) => setState(() => onChanged(v)),
            ),
          ),
          if (onAddPressed != null) ...[
            const SizedBox(width: 8),
            IconButton(onPressed: onAddPressed, icon: Icon(Icons.add_circle, color: theme.primaryColor)),
          ]
        ],
      ),
    );
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate() || _billOfLading == 0) {
      return;
    }

    if (_selectedDriver == null || _selectedCar == null || _selectedSeller == null || _selectedLoadType == null) {
       return;
    }

    final expenses = ServiceExpenses(
      fuelCost: _fuel, 
      fuelInBoL: _fuelInBoL,
      tollCost: _toll, 
      tollInBoL: _tollInBoL,
      loadingTip: _loadingTip, 
      loadingTipInBoL: _loadingTipInBoL,
      unloadingTip: _unloadingTip, 
      unloadingTipInBoL: _unloadingTipInBoL,
      disinfectionCost: _disinfection,
      disinfectionInBoL: _disinfectionInBoL,
      billOfLadingCost: _billOfLading, 
      commission: _commission, 
      commissionInBoL: _commissionInBoL,

      loadingWeighbridge: _loadingWeighbridge,
      loadingWeighbridgeInBoL: _loadingWeighbridgeInBoL,
      loaderLoading: _loaderLoading,
      loaderLoadingInBoL: _loaderLoadingInBoL,
      tallyClerk: _tallyClerk,
      tallyClerkInBoL: _tallyClerkInBoL,
      unloadingWeighbridge: _unloadingWeighbridge,
      unloadingWeighbridgeInBoL: _unloadingWeighbridgeInBoL,
      unloadingWorker: _unloadingWorker,
      unloadingWorkerInBoL: _unloadingWorkerInBoL,

      otherExpenses: _otherExpenses,
      includeInBillOfLading: _includeInBillOfLading,
    );
    
    final newService = LoadService(
      id: widget.serviceToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), 
      orderCode: _orderCodeController.text, 
      car: _selectedCar!, 
      driver: _selectedDriver!, 
      loadType: _selectedLoadType!, 
      seller: _selectedSeller!, 
      customer: _selectedCustomer, 
      logisticsCo: _selectedLogisticsCo, 
      origin: _originController.text, 
      destination: _destinationController.text, 
      date: widget.serviceToEdit?.date ?? DateTime.now(), 
      loadingDateTime: _loadingDateTime,
      unloadingDateTime: _unloadingDateTime,
      weight: _weight, 
      transportPricePerTon: _transportPricePerTon, 
      purchasePricePerTon: _purchasePricePerTon, 
      expenses: expenses, 
      purchaseInvoiceImagePath: _purchaseInvoiceImagePath,
      billOfLadingImagePath: _billOfLadingImagePath,
      weighbridgeImagePath: _weighbridgeImagePath,
      fareAccountNumber: _accountNumberController.text,
      fareAccountOwner: _accountOwnerController.text,
      fareBankName: _bankNameController.text,
      logisticsName: _logisticsNameController.text,
      logisticsPhone: _logisticsPhoneController.text,
      logisticsLocation: _logisticsLocationController.text,
      isAgreedFreight: _isAgreedFreight,
      agreedFreightAmount: _agreedFreightAmount,
      driverAgreementPercentage: _driverAgreementPercentage,
      isOwnerDriver: _isOwnerDriver,
      extraDriverPay: _extraDriverPay,
    );

    try {
      await _repository.saveService(newService);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ذخیره: $e')));
    }
  }
}
