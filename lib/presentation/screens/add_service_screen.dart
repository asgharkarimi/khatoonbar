import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../core/data/service_repository.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../widgets/amount_input.dart';

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

  Driver? _selectedDriver;
  Car? _selectedCar;
  LoadType? _selectedLoadType;
  Seller? _selectedSeller;
  Customer? _selectedCustomer;

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _orderCodeController = TextEditingController();

  double _weight = 0;
  double _transportPricePerTon = 0;
  double _purchasePricePerTon = 0;
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
      if (s.customer != null) {
        _selectedCustomer = _customers.any((c) => c.id == s.customer!.id) ? _customers.firstWhere((c) => c.id == s.customer!.id) : null;
      }
      
      _originController.text = s.origin;
      _destinationController.text = s.destination;
      _orderCodeController.text = s.orderCode;
      _weight = s.weight;
      _transportPricePerTon = s.transportPricePerTon;
      _purchasePricePerTon = s.purchasePricePerTon;
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final drivers = await _repository.getDrivers();
      final cars = await _repository.getCars();
      final types = await _repository.getLoadTypes();
      final sellers = await _repository.getSellers();
      final customers = await _repository.getCustomers();

      setState(() {
        _drivers = drivers;
        _cars = cars;
        _loadTypes = types;
        _sellers = sellers;
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری اطلاعات پایه: $e')),
        );
      }
    }
  }

  void _showAddDriverDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();

    _showStyledDialog(
      title: 'افزودن راننده جدید',
      children: [
        _buildTextField(controller: firstNameController, label: 'نام', icon: Icons.person_outline),
        const SizedBox(height: 12),
        _buildTextField(controller: lastNameController, label: 'نام خانوادگی', icon: Icons.person_outline),
        const SizedBox(height: 12),
        _buildTextField(controller: phoneController, label: 'شماره تلفن', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
      ],
      onConfirm: () async {
        if (firstNameController.text.isNotEmpty && lastNameController.text.isNotEmpty) {
          final newItem = Driver(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            phone: phoneController.text,
          );
          await DatabaseHelper.instance.insertDriver(newItem);
          await _loadInitialData();
          setState(() {
            _selectedDriver = _drivers.firstWhere((d) => d.id == newItem.id, orElse: () => newItem);
          });
          return true;
        }
        return false;
      },
    );
  }

  void _showAddCarDialog() {
    final nameController = TextEditingController();

    _showStyledDialog(
      title: 'افزودن ماشین جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام ماشین', icon: Icons.local_shipping_outlined),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final newItem = Car(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: nameController.text,
          );
          await DatabaseHelper.instance.insertCar(newItem);
          await _loadInitialData();
          setState(() {
            _selectedCar = _cars.firstWhere((c) => c.id == newItem.id, orElse: () => newItem);
          });
          return true;
        }
        return false;
      },
    );
  }

  void _showAddLoadTypeDialog() {
    final nameController = TextEditingController();

    _showStyledDialog(
      title: 'افزودن نوع بار جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام بار (مثلا سیمان)', icon: Icons.category_outlined),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final newItem = LoadType(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: nameController.text,
          );
          await DatabaseHelper.instance.insertLoadType(newItem);
          await _loadInitialData();
          setState(() {
            _selectedLoadType = _loadTypes.firstWhere((lt) => lt.id == newItem.id, orElse: () => newItem);
          });
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
      title: 'افزودن فروشنده جدید',
      children: [
        _buildTextField(controller: nameController, label: 'نام فروشگاه / شرکت', icon: Icons.store_outlined),
        const SizedBox(height: 12),
        _buildTextField(controller: productController, label: 'محصول اصلی', icon: Icons.inventory_2_outlined),
      ],
      onConfirm: () async {
        if (nameController.text.isNotEmpty) {
          final newItem = Seller(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: nameController.text,
            product: productController.text,
          );
          await DatabaseHelper.instance.insertSeller(newItem);
          await _loadInitialData();
          setState(() {
            _selectedSeller = _sellers.firstWhere((s) => s.id == newItem.id, orElse: () => newItem);
          });
          return true;
        }
        return false;
      },
    );
  }

  void _showAddCustomerDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final villageController = TextEditingController();

    _showStyledDialog(
      title: 'افزودن مشتری جدید',
      children: [
        _buildTextField(controller: firstNameController, label: 'نام', icon: Icons.person_outline),
        const SizedBox(height: 12),
        _buildTextField(controller: lastNameController, label: 'نام خانوادگی', icon: Icons.person_outline),
        const SizedBox(height: 12),
        _buildTextField(controller: villageController, label: 'نام روستا', icon: Icons.location_city_outlined),
        const SizedBox(height: 12),
        _buildTextField(controller: phoneController, label: 'شماره تلفن', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
      ],
      onConfirm: () async {
        if (firstNameController.text.isNotEmpty && lastNameController.text.isNotEmpty) {
          final newCustomer = Customer(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            phone: phoneController.text,
            village: villageController.text,
          );
          await DatabaseHelper.instance.insertCustomer(newCustomer);
          await _loadInitialData();
          setState(() {
            _selectedCustomer = _customers.firstWhere((c) => c.id == newCustomer.id, orElse: () => newCustomer);
          });
          return true;
        }
        return false;
      },
    );
  }

  // متد کمکی برای نمایش دیالوگ با استایل یکسان
  void _showStyledDialog({
    required String title,
    required List<Widget> children,
    required Future<bool> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await onConfirm();
              if (success && mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    double totalTransport = _weight * _transportPricePerTon;
    double totalPurchase = _weight * _purchasePricePerTon;
    double grandTotal = totalTransport + totalPurchase;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.serviceToEdit == null ? 'ثبت سرویس جدید' : 'ویرایش سرویس'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepCard(
                      title: 'شناسه و اطلاعات اصلی',
                      icon: Icons.qr_code_scanner,
                      children: [
                        _buildTextField(
                          controller: _orderCodeController,
                          label: 'کد سفارش / شماره حواله',
                          icon: Icons.numbers,
                          readOnly: true,
                          hint: 'در حال تولید خودکار...',
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownField<Driver>(
                          label: 'انتخاب راننده',
                          icon: Icons.person_outline,
                          value: _selectedDriver,
                          items: _drivers,
                          onChanged: (val) => _selectedDriver = val,
                          itemLabel: (d) => d.fullName,
                          onAddPressed: _showAddDriverDialog,
                        ),
                        _buildDropdownField<Car>(
                          label: 'انتخاب ماشین',
                          icon: Icons.local_shipping_outlined,
                          value: _selectedCar,
                          items: _cars,
                          onChanged: (val) => _selectedCar = val,
                          itemLabel: (c) => c.name,
                          onAddPressed: _showAddCarDialog,
                        ),
                        _buildDropdownField<LoadType>(
                          label: 'نوع بار',
                          icon: Icons.category_outlined,
                          value: _selectedLoadType,
                          items: _loadTypes,
                          onChanged: (val) => _selectedLoadType = val,
                          itemLabel: (lt) => lt.name,
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
                          label: 'فروشنده / شرکت',
                          icon: Icons.store_outlined,
                          value: _selectedSeller,
                          items: _sellers,
                          onChanged: (val) => _selectedSeller = val,
                          itemLabel: (s) => s.name,
                          onAddPressed: _showAddSellerDialog,
                        ),
                        _buildDropdownField<Customer>(
                          label: 'مشتری (گیرنده)',
                          icon: Icons.person_pin_outlined,
                          value: _selectedCustomer,
                          items: _customers,
                          onChanged: (val) => _selectedCustomer = val,
                          itemLabel: (c) => c.fullName, 
                          onAddPressed: _showAddCustomerDialog,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _originController,
                                label: 'مبدا',
                                icon: Icons.location_on_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _destinationController,
                                label: 'مقصد',
                                icon: Icons.flag_outlined,
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
                        AmountInput(
                          label: 'وزن بار (تن)',
                          unit: 'تن',
                          isDecimal: true,
                          initialValue: widget.serviceToEdit?.weight,
                          onChanged: (val) => setState(() => _weight = val),
                        ),
                        const SizedBox(height: 12),
                        AmountInput(
                          label: 'قیمت هر تن حمل (تومان)',
                          initialValue: widget.serviceToEdit?.transportPricePerTon,
                          onChanged: (val) => setState(() => _transportPricePerTon = val),
                        ),
                        const SizedBox(height: 12),
                        AmountInput(
                          label: 'قیمت هر تن خرید (اختیاری)',
                          hint: 'در صورت مسئولیت حمل توسط راننده، می‌تواند 0 باشد',
                          initialValue: widget.serviceToEdit?.purchasePricePerTon,
                          onChanged: (val) => setState(() => _purchasePricePerTon = val),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          _buildCalcRow('جمع کرایه حمل:', totalTransport, theme),
                          if (_purchasePricePerTon > 0) ...[
                            const SizedBox(height: 8),
                            _buildCalcRow('جمع مبلغ خرید بار:', totalPurchase, theme),
                          ],
                          const Divider(height: 24),
                          _buildCalcRow(
                            'مبلغ کل نهایی (بدهی مشتری):', 
                            grandTotal, 
                            theme, 
                            isBold: true,
                            color: theme.colorScheme.primary
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          widget.serviceToEdit == null ? 'ثبت و ذخیره نهایی' : 'اعمال تغییرات',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCalcRow(String label, double amount, ThemeData theme, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          "${AppFormatters.formatCurrency(amount)} تومان",
          style: TextStyle(
            fontSize: isBold ? 15 : 13, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
            fontFamily: 'IranYekan'
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D2939),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF2F4F7), height: 1),
          ),
          ...children,
        ],
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<T>(
              value: value,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                ),
              ),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(itemLabel(i)))).toList(),
              onChanged: (val) => setState(() => onChanged(val)),
            ),
          ),
          if (onAddPressed != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_circle_outline),
              color: Theme.of(context).primaryColor,
              tooltip: 'افزودن جدید',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
      ),
    );
  }

  Future<void> _saveService() async {
    if (_selectedDriver == null || _selectedCar == null || _selectedSeller == null || _selectedLoadType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا تمامی فیلدهای ستاره‌دار را پر کنید')),
      );
      return;
    }

    final orderCode = _orderCodeController.text.trim();
    if (orderCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا کد سفارش را وارد کنید')),
      );
      return;
    }

    if (_transportPricePerTon <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا: هزینه حمل نمی‌تواند صفر باشد.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // بررسی مجدد تکراری نبودن کد قبل از ذخیره نهایی
    final isDuplicate = await _repository.isOrderCodeDuplicate(orderCode, excludeId: widget.serviceToEdit?.id);
    if (isDuplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا: این کد سفارش قبلاً ثبت شده است. در حال تولید کد جدید...'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // تولید مجدد کد در صورت بروز تکرار ناخواسته
      await _generateOrderCode();
      return;
    }

    final newService = LoadService(
      id: widget.serviceToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      orderCode: orderCode,
      car: _selectedCar!,
      driver: _selectedDriver!,
      loadType: _selectedLoadType!,
      seller: _selectedSeller!,
      customer: _selectedCustomer,
      origin: _originController.text,
      destination: _destinationController.text,
      date: widget.serviceToEdit?.date ?? DateTime.now(),
      weight: _weight,
      transportPricePerTon: _transportPricePerTon,
      purchasePricePerTon: _purchasePricePerTon,
      expenses: widget.serviceToEdit?.expenses ?? ServiceExpenses(),
    );

    try {
      await _repository.saveService(newService);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.serviceToEdit == null ? 'سرویس با موفقیت ثبت شد' : 'تغییرات با موفقیت ذخیره شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره‌سازی: $e')),
        );
      }
    }
  }
}
