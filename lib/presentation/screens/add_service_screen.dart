import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/data/service_repository.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../widgets/amount_input.dart';
import '../widgets/iranian_plate_input.dart';

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

  Driver? _selectedDriver;
  Car? _selectedCar;
  LoadType? _selectedLoadType;
  Seller? _selectedSeller;
  Customer? _selectedCustomer;
  LogisticsCo? _selectedLogisticsCo;

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _orderCodeController = TextEditingController();
  
  // اطلاعات باربری (ثبت مستقیم)
  final TextEditingController _logisticsNameController = TextEditingController();
  final TextEditingController _logisticsPhoneController = TextEditingController();

  // اطلاعات حساب بانکی
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountOwnerController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  double _fuel = 0;
  double _toll = 0;
  double _loadingTip = 0;
  double _unloadingTip = 0;
  double _billOfLading = 0;
  
  List<OtherExpense> _otherExpenses = [];

  double _weight = 0;
  double _transportPricePerTon = 0;
  double _purchasePricePerTon = 0;
  String? _purchaseInvoiceImagePath;
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

      _accountNumberController.text = s.fareAccountNumber ?? "";
      _accountOwnerController.text = s.fareAccountOwner ?? "";
      _bankNameController.text = s.fareBankName ?? "";

      _weight = s.weight;
      _transportPricePerTon = s.transportPricePerTon;
      _purchasePricePerTon = s.purchasePricePerTon;
      _purchaseInvoiceImagePath = s.purchaseInvoiceImagePath;

      _fuel = s.expenses.fuelCost;
      _toll = s.expenses.tollCost;
      _loadingTip = s.expenses.loadingTip;
      _unloadingTip = s.expenses.unloadingTip;
      _billOfLading = s.expenses.billOfLadingCost;
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

      setState(() {
        _drivers = drivers;
        _cars = cars;
        _loadTypes = types;
        _sellers = sellers;
        _customers = customers;
        _logisticsCos = logistics;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در بارگذاری اطلاعات: $e')));
      }
    }
  }

  void _addOtherExpense() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String? imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('افزودن هزینه جانبی'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان هزینه')),
              const SizedBox(height: 12),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ (تومان)')),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final source = await _showImageSourceDialog();
                  if (source != null) {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: source);
                    if (picked != null) setDialogState(() => imagePath = picked.path);
                  }
                },
                icon: const Icon(Icons.image_outlined),
                label: Text(imagePath == null ? 'انتخاب رسید' : 'رسید انتخاب شد'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  setState(() {
                    _otherExpenses.add(OtherExpense(
                      title: titleController.text,
                      amount: double.tryParse(amountController.text) ?? 0,
                      receiptImagePath: imagePath,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('انتخاب منبع تصویر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.camera_alt_outlined, 'دوربین', ImageSource.camera),
                _buildSourceOption(Icons.photo_library_outlined, 'گارلی', ImageSource.gallery),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, ImageSource source) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _pickPurchaseInvoice() async {
    final source = await _showImageSourceDialog();
    if (source != null) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _purchaseInvoiceImagePath = picked.path;
        });
      }
    }
  }

  void _showAddLogisticsCoDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    _showStyledDialog(
      title: 'باربری جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام باربری', icon: Icons.business),
        const SizedBox(height: 12),
        _buildTextField(controller: phoneController, label: 'شماره تماس', icon: Icons.phone, keyboardType: TextInputType.phone),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final newCo = LogisticsCo(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameController.text, phone: phoneController.text);
          await _repository.saveLogisticsCo(newCo);
          await _loadInitialData();
          setState(() {
            _selectedLogisticsCo = _logisticsCos.firstWhere((l) => l.id == newCo.id);
            _logisticsNameController.text = newCo.name;
            _logisticsPhoneController.text = newCo.phone;
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
    final bankController = TextEditingController();
    final accountController = TextEditingController();
    final ownerController = TextEditingController();

    _showStyledDialog(
      title: 'راننده جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام و نام خانوادگی', icon: Icons.person),
        const SizedBox(height: 12),
        _buildTextField(controller: phoneController, label: 'شماره تماس', icon: Icons.phone, keyboardType: TextInputType.phone),
        const Divider(height: 32),
        const Text('اطلاعات بانکی پیش‌فرض (اختیاری)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        _buildTextField(controller: bankController, label: 'نام بانک', icon: Icons.account_balance),
        const SizedBox(height: 12),
        _buildTextField(controller: accountController, label: 'شماره حساب/کارت', icon: Icons.credit_card, keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _buildTextField(controller: ownerController, label: 'نام صاحب حساب', icon: Icons.person_outline),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final names = nameController.text.trim().split(' ');
          final first = names[0];
          final last = names.length > 1 ? names.sublist(1).join(' ') : '';
          
          final newDriver = Driver(
            id: DateTime.now().millisecondsSinceEpoch.toString(), 
            firstName: first, 
            lastName: last, 
            phone: phoneController.text,
            bankName: bankController.text,
            accountNumber: accountController.text,
            accountOwner: ownerController.text,
          );
          await _repository.saveDriver(newDriver);
          await _loadInitialData();
          setState(() {
            _selectedDriver = _drivers.firstWhere((d) => d.id == newDriver.id);
            // پر کردن خودکار فیلدهای بانکی در فرم اصلی
            _bankNameController.text = newDriver.bankName ?? "";
            _accountNumberController.text = newDriver.accountNumber ?? "";
            _accountOwnerController.text = newDriver.accountOwner ?? "";
          });
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
        _buildTextField(controller: nameController, label: 'نام خودرو', icon: Icons.local_shipping),
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
        _buildTextField(controller: nameController, label: 'نام و نام خانوادگی', icon: Icons.person_pin),
        const SizedBox(height: 12),
        _buildTextField(controller: phoneController, label: 'شماره تماس', icon: Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _buildTextField(controller: villageController, label: 'روستا/منطقه', icon: Icons.location_city),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final names = nameController.text.trim().split(' ');
          final first = names[0];
          final last = names.length > 1 ? names.sublist(1).join(' ') : '';

          final newCustomer = Customer(
            id: DateTime.now().millisecondsSinceEpoch.toString(), 
            firstName: first, 
            lastName: last, 
            phone: phoneController.text,
            village: villageController.text,
          );
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
      title: 'فروشنده/شرکت جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام فروشنده', icon: Icons.store),
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
        _buildTextField(controller: nameController, label: 'نام بار', icon: Icons.category),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    double totalTransport = _weight * _transportPricePerTon;
    double totalPurchase = _weight * _purchasePricePerTon;
    
    double otherExpensesSum = _otherExpenses.fold(0, (sum, item) => sum + item.amount);
    double fixedExpensesSum = _fuel + _toll + _loadingTip + _unloadingTip + _billOfLading;
    double totalExpenses = fixedExpensesSum + otherExpensesSum;
    double netProfit = totalTransport - totalExpenses;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                      title: 'اطلاعات اصلی',
                      icon: Icons.qr_code_scanner,
                      children: [
                        _buildTextField(controller: _orderCodeController, label: 'کد سفارش', icon: Icons.numbers, readOnly: true),
                        const SizedBox(height: 12),
                        _buildDropdownField<LogisticsCo>(
                          label: 'انتخاب باربری از لیست', 
                          icon: Icons.business_outlined, 
                          value: _selectedLogisticsCo, 
                          items: _logisticsCos, 
                          onChanged: (v) {
                            _selectedLogisticsCo = v;
                            if (v != null) {
                              _logisticsNameController.text = v.name;
                              _logisticsPhoneController.text = v.phone;
                            }
                          }, 
                          itemLabel: (l) => l.name,
                          onAddPressed: _showAddLogisticsCoDialog,
                        ),
                        if (_selectedLogisticsCo == null) ...[
                          _buildTextField(controller: _logisticsNameController, label: 'نام باربری (ثبت مستقیم)', icon: Icons.business),
                          const SizedBox(height: 12),
                          _buildTextField(controller: _logisticsPhoneController, label: 'تلفن باربری', icon: Icons.phone, keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                        ],
                        _buildDropdownField<Driver>(
                          label: 'انتخاب راننده', 
                          icon: Icons.person_outline, 
                          value: _selectedDriver, 
                          items: _drivers, 
                          onChanged: (v) {
                            _selectedDriver = v;
                            if (v != null) {
                              // پر کردن خودکار فیلدهای بانکی با انتخاب راننده
                              _bankNameController.text = v.bankName ?? "";
                              _accountNumberController.text = v.accountNumber ?? "";
                              _accountOwnerController.text = v.accountOwner ?? "";
                            }
                          },
                          itemLabel: (d) => d.fullName,
                          onAddPressed: _showAddDriverDialog,
                        ),
                        _buildDropdownField<Car>(
                          label: 'انتخاب ماشین', 
                          icon: Icons.local_shipping_outlined, 
                          value: _selectedCar, 
                          items: _cars, 
                          onChanged: (v) => _selectedCar = v, 
                          itemLabel: (c) => c.name,
                          onAddPressed: _showAddCarDialog,
                        ),
                        _buildDropdownField<LoadType>(
                          label: 'نوع بار', 
                          icon: Icons.category_outlined, 
                          value: _selectedLoadType, 
                          items: _loadTypes, 
                          onChanged: (v) => _selectedLoadType = v, 
                          itemLabel: (l) => l.name,
                          onAddPressed: _showAddLoadTypeDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      title: 'طرفین حساب و مسیر',
                      icon: Icons.map_outlined,
                      children: [
                        _buildDropdownField<Seller>(
                          label: 'فروشنده', 
                          icon: Icons.store_outlined, 
                          value: _selectedSeller, 
                          items: _sellers, 
                          onChanged: (v) => _selectedSeller = v, 
                          itemLabel: (s) => s.name,
                          onAddPressed: _showAddSellerDialog,
                        ),
                        _buildDropdownField<Customer>(
                          label: 'مشتری', 
                          icon: Icons.person_pin_outlined, 
                          value: _selectedCustomer, 
                          items: _customers, 
                          onChanged: (v) => _selectedCustomer = v, 
                          itemLabel: (c) => c.fullName,
                          onAddPressed: _showAddCustomerDialog,
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _buildTextField(controller: _originController, label: 'مبدا', icon: Icons.location_on_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(controller: _destinationController, label: 'مقصد', icon: Icons.flag_outlined)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      title: 'جزییات بار و مالی',
                      icon: Icons.payments_outlined,
                      children: [
                        AmountInput(label: 'وزن بار (تن)', unit: 'تن', isDecimal: true, initialValue: _weight, onChanged: (v) => setState(() => _weight = v)),
                        const SizedBox(height: 12),
                        AmountInput(label: 'قیمت هر تن حمل', initialValue: _transportPricePerTon, onChanged: (v) => setState(() => _transportPricePerTon = v)),
                        const SizedBox(height: 12),
                        AmountInput(label: 'قیمت هر تن خرید', initialValue: _purchasePricePerTon, onChanged: (v) => setState(() => _purchasePricePerTon = v)),
                        
                        const Divider(height: 32),
                        const Text('اطلاعات حساب جهت واریز کرایه:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _accountNumberController, label: 'شماره حساب / کارت', icon: Icons.credit_card_outlined, keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _accountOwnerController, label: 'نام صاحب حساب', icon: Icons.person_outline),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _bankNameController, label: 'نام بانک', icon: Icons.account_balance_outlined),

                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _pickPurchaseInvoice,
                          icon: Icon(_purchaseInvoiceImagePath == null ? Icons.attach_file_outlined : Icons.check_circle_outline),
                          label: Text(_purchaseInvoiceImagePath == null ? 'بارگذاری مدارک' : 'مدارک بارگذاری شد'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: _purchaseInvoiceImagePath == null ? theme.primaryColor : Colors.green,
                          ),
                        ),
                        if (_purchaseInvoiceImagePath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(_purchaseInvoiceImagePath!), width: 50, height: 50, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => setState(() => _purchaseInvoiceImagePath = null),
                                  child: const Text('حذف مدارک', style: TextStyle(color: Colors.red, fontSize: 12)),
                                )
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      title: 'مخارج و هزینه‌های سرویس',
                      icon: Icons.receipt_long_outlined,
                      children: [
                        AmountInput(label: 'هزینه بارنامه (الزامی)', initialValue: _billOfLading, onChanged: (v) => setState(() => _billOfLading = v)),
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
                          Expanded(child: AmountInput(label: 'انعام تخلیه', initialValue: _unloadingTip, onChanged: (v) => setState(() => _unloadingTip = v))),
                        ]),
                        const Divider(height: 32),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('سایر هزینه‌ها (با رسید)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          TextButton.icon(onPressed: _addOtherExpense, icon: const Icon(Icons.add, size: 18), label: const Text('افزودن')),
                        ]),
                        ..._otherExpenses.map((exp) => ListTile(
                          dense: true,
                          title: Text(exp.title),
                          subtitle: Text("${AppFormatters.formatCurrency(exp.amount)} تومان"),
                          trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: () => setState(() => _otherExpenses.remove(exp))),
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSummaryCard(totalTransport, totalPurchase, totalExpenses, netProfit, theme),
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

  Widget _buildSummaryCard(double transport, double purchase, double expenses, double profit, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.primaryColor.withOpacity(0.1))),
      child: Column(
        children: [
          _buildCalcRow('جمع کرایه حمل:', transport, theme),
          if (purchase > 0) _buildCalcRow('جمع مبلغ خرید:', purchase, theme),
          _buildCalcRow('جمع کل هزینه‌ها:', expenses, theme, color: Colors.red),
          const Divider(height: 24),
          _buildCalcRow('سود خالص (از حمل):', profit, theme, isBold: true, color: Colors.green.shade700),
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

  Widget _buildStepCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEAECF0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 20, color: Theme.of(context).primaryColor), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<T>(
              value: value,
              decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(itemLabel(i)))).toList(),
              onChanged: (v) => setState(() => onChanged(v)),
            ),
          ),
          if (onAddPressed != null) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: onAddPressed,
                icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
                tooltip: 'افزودن سریع',
              ),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate() || _billOfLading == 0) {
      if (_billOfLading == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً مبلغ بارنامه را وارد کنید')));
      }
      return;
    }

    if (_selectedDriver == null || _selectedCar == null || _selectedSeller == null || _selectedLoadType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا تمامی موارد ضروری را انتخاب کنید')));
      return;
    }

    final expenses = ServiceExpenses(
      fuelCost: _fuel,
      tollCost: _toll,
      loadingTip: _loadingTip,
      unloadingTip: _unloadingTip,
      billOfLadingCost: _billOfLading,
      commission: 0,
      otherExpenses: _otherExpenses,
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
      logisticsName: _logisticsNameController.text,
      logisticsPhone: _logisticsPhoneController.text,
      origin: _originController.text,
      destination: _destinationController.text,
      date: widget.serviceToEdit?.date ?? DateTime.now(),
      weight: _weight,
      transportPricePerTon: _transportPricePerTon,
      purchasePricePerTon: _purchasePricePerTon,
      expenses: expenses,
      purchaseInvoiceImagePath: _purchaseInvoiceImagePath,
      fareAccountNumber: _accountNumberController.text.trim(),
      fareAccountOwner: _accountOwnerController.text.trim(),
      fareBankName: _bankNameController.text.trim(),
    );

    try {
      await _repository.saveService(newService);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ذخیره: $e')));
    }
  }
}
