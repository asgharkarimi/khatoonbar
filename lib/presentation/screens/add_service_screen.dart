import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../core/data/service_repository.dart';
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
  List<LogisticsCo> _logisticsCos = [];
  
  List<String> _originSuggestions = [];
  List<String> _destinationSuggestions = [];

  Driver? _selectedDriver;
  Car? _selectedCar;
  LoadType? _selectedLoadType;
  Seller? _selectedSeller;
  Customer? _selectedCustomer;
  LogisticsCo? _selectedLogisticsCo;

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _orderCodeController = TextEditingController();

  double _fuel = 0, _billOfLading = 0, _commission = 0, _weight = 0, _transportPricePerTon = 0, _purchasePricePerTon = 0;
  bool _isAgreedFreight = false, _isOwnerDriver = false;
  double _agreedFreightAmount = 0, _driverAgreementPercentage = 0, _extraDriverPay = 0;

  String? _purchaseInvoiceImagePath, _billOfLadingImagePath, _weighbridgeImagePath;
  String? _fuelImagePath, _commissionImagePath, _tollImagePath;

  List<TollItem> _tolls = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData().then((_) {
      if (widget.serviceToEdit != null) _fillDataForEdit();
      else _generateOrderCode();
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
      final origins = await _repository.getSuggestions('origins');
      final destinations = await _repository.getSuggestions('destinations');
      
      setState(() {
        _drivers = drivers; _cars = cars; _loadTypes = types; _sellers = sellers; _customers = customers; _logisticsCos = logistics;
        _originSuggestions = origins; _destinationSuggestions = destinations;
        _isLoading = false;
      });
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _generateOrderCode() async {
    final code = await _repository.generateUniqueOrderCode();
    setState(() => _orderCodeController.text = code);
  }

  void _fillDataForEdit() {
    final s = widget.serviceToEdit!;
    setState(() {
      _selectedDriver = _drivers.where((d) => d.id == s.driver.id).firstOrNull ?? s.driver;
      _selectedCar = _cars.where((c) => c.id == s.car.id).firstOrNull ?? s.car;
      _selectedLoadType = _loadTypes.where((lt) => lt.id == s.loadType.id).firstOrNull ?? s.loadType;
      _selectedSeller = _sellers.where((sel) => sel.id == s.seller.id).firstOrNull ?? s.seller;
      if (s.customer != null) _selectedCustomer = _customers.where((c) => c.id == s.customer!.id).firstOrNull ?? s.customer!;
      
      _originController.text = s.origin; _destinationController.text = s.destination; _orderCodeController.text = s.orderCode;
      _weight = s.weight; _transportPricePerTon = s.transportPricePerTon; _purchasePricePerTon = s.purchasePricePerTon;
      _isAgreedFreight = s.isAgreedFreight; _agreedFreightAmount = s.agreedFreightAmount;
      _isOwnerDriver = s.isOwnerDriver; _driverAgreementPercentage = s.driverAgreementPercentage; _extraDriverPay = s.extraDriverPay;
      
      _purchaseInvoiceImagePath = s.purchaseInvoiceImagePath; _billOfLadingImagePath = s.billOfLadingImagePath; _weighbridgeImagePath = s.weighbridgeImagePath;
      _fuel = s.expenses.fuelCost; _fuelImagePath = s.expenses.fuelImagePath;
      _billOfLading = s.expenses.billOfLadingCost; _commission = s.expenses.commission; _commissionImagePath = s.expenses.commissionImagePath;
      _tollImagePath = s.expenses.tollImagePath;
      _tolls = List.from(s.expenses.tolls);
    });
  }

  Future<void> _pickImage(String type) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (type == 'invoice') _purchaseInvoiceImagePath = picked.path;
        else if (type == 'bol') _billOfLadingImagePath = picked.path;
        else if (type == 'weigh') _weighbridgeImagePath = picked.path;
        else if (type == 'fuel') _fuelImagePath = picked.path;
        else if (type == 'commission') _commissionImagePath = picked.path;
        else if (type == 'toll') _tollImagePath = picked.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: Text(widget.serviceToEdit == null ? 'ثبت سرویس جدید' : 'ویرایش سرویس')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(children: [
        _buildStepCard(title: 'اطلاعات اصلی', icon: Icons.assignment_outlined, children: [
          _buildTextField(controller: _orderCodeController, label: 'کد سفارش', icon: Icons.numbers, readOnly: true),
          _buildDropdownField<Driver>(label: 'انتخاب راننده', icon: Icons.person, value: _selectedDriver, items: _drivers, onChanged: (v) => _selectedDriver = v, itemLabel: (d) => d.fullName),
          _buildDropdownField<Car>(label: 'انتخاب ماشین', icon: Icons.local_shipping, value: _selectedCar, items: _cars, onChanged: (v) => _selectedCar = v, itemLabel: (c) => c.name),
          _buildDropdownField<LoadType>(label: 'نوع بار', icon: Icons.category, value: _selectedLoadType, items: _loadTypes, onChanged: (v) => _selectedLoadType = v, itemLabel: (l) => l.name),
        ]),
        _buildStepCard(title: 'طرفین و مسیر', icon: Icons.map_outlined, children: [
          _buildDropdownField<Seller>(label: 'فروشنده', icon: Icons.store, value: _selectedSeller, items: _sellers, onChanged: (v) => _selectedSeller = v, itemLabel: (s) => s.name),
          _buildDropdownField<Customer>(label: 'مشتری', icon: Icons.person_pin, value: _selectedCustomer, items: _customers, onChanged: (v) => _selectedCustomer = v, itemLabel: (c) => c.fullName),
          Row(children: [
            Expanded(child: _buildAutocompleteField(controller: _originController, label: 'مبدا', icon: Icons.location_on)),
            const SizedBox(width: 8),
            Expanded(child: _buildAutocompleteField(controller: _destinationController, label: 'مقصد', icon: Icons.flag)),
          ]),
        ]),
        _buildStepCard(title: 'جزییات بار و اسناد تصویری', icon: Icons.camera_alt_outlined, children: [
          if (!_isAgreedFreight) ...[
            AmountInput(label: 'وزن بار (تن)', unit: 'تن', isDecimal: true, initialValue: _weight, onChanged: (v) => setState(() => _weight = v)),
            const SizedBox(height: 12),
            AmountInput(label: 'قیمت هر تن حمل', initialValue: _transportPricePerTon, onChanged: (v) => setState(() => _transportPricePerTon = v)),
          ] else AmountInput(label: 'مبلغ توافقی', initialValue: _agreedFreightAmount, onChanged: (v) => setState(() => _agreedFreightAmount = v)),
          SwitchListTile(title: const Text('کرایه توافقی', style: TextStyle(fontSize: 13)), value: _isAgreedFreight, onChanged: (v) => setState(() => _isAgreedFreight = v), contentPadding: EdgeInsets.zero),
          const Divider(height: 24),
          const Text("تصاویر اصلی (بارنامه، باسکول، فاکتور خرید)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildImageBtn(label: 'بارنامه', icon: Icons.assignment, path: _billOfLadingImagePath, onTap: () => _pickImage('bol'))),
            const SizedBox(width: 8),
            Expanded(child: _buildImageBtn(label: 'باسکول', icon: Icons.scale, path: _weighbridgeImagePath, onTap: () => _pickImage('weigh'))),
            const SizedBox(width: 8),
            Expanded(child: _buildImageBtn(label: 'فاکتور', icon: Icons.receipt, path: _purchaseInvoiceImagePath, onTap: () => _pickImage('invoice'))),
          ]),
        ]),
        _buildStepCard(title: 'مخارج و رسیدها', icon: Icons.receipt_long, children: [
          AmountInput(label: 'هزینه پایه بارنامه', initialValue: _billOfLading, onChanged: (v) => setState(() => _billOfLading = v)),
          _buildExpenseRow(label: 'کمیسیون', amount: _commission, path: _commissionImagePath, onAmt: (v) => _commission = v, onPic: () => _pickImage('commission')),
          _buildExpenseRow(label: 'سوخت', amount: _fuel, path: _fuelImagePath, onAmt: (v) => _fuel = v, onPic: () => _pickImage('fuel')),
          
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("لیست عوارض", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              IconButton(onPressed: () => setState(() => _tolls.add(TollItem(name: '', amount: 0))), icon: const Icon(Icons.add_circle, color: Colors.blue)),
            ],
          ),
          ..._tolls.asMap().entries.map((entry) {
            int idx = entry.key;
            TollItem toll = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(flex: 3, child: TextFormField(
                    initialValue: toll.name,
                    decoration: InputDecoration(labelText: 'نام عوارض (مثلا عوارض کاشان)', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    onChanged: (v) => _tolls[idx] = TollItem(name: v, amount: toll.amount),
                  )),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: AmountInput(
                    label: 'مبلغ',
                    initialValue: toll.amount,
                    onChanged: (v) => _tolls[idx] = TollItem(name: toll.name, amount: v),
                  )),
                  IconButton(onPressed: () => setState(() => _tolls.removeAt(idx)), icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20)),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          _buildImageBtn(label: 'تصویر کلی رسیدهای عوارض', icon: Icons.toll, path: _tollImagePath, onTap: () => _pickImage('toll')),
        ]),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _saveService, style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('ثبت نهایی و ذخیره سرویس', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        const SizedBox(height: 40),
      ]))),
    );
  }

  Widget _buildStepCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 20, color: Colors.blue), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]), const Divider(height: 24), ...children]));
  }

  Widget _buildImageBtn({required String label, required IconData icon, required String? path, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: path != null ? Colors.green : Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: path != null ? Colors.green.withOpacity(0.05) : Colors.transparent), child: Column(children: [Icon(icon, color: path != null ? Colors.green : Colors.grey, size: 24), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, color: path != null ? Colors.green : Colors.grey))])));
  }

  Widget _buildExpenseRow({required String label, required double amount, String? path, required Function(double) onAmt, required VoidCallback onPic}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Expanded(child: AmountInput(label: label, initialValue: amount, onChanged: onAmt)), const SizedBox(width: 8), IconButton(onPressed: onPic, icon: Icon(path == null ? Icons.attach_file : Icons.check_circle, color: path == null ? Colors.grey : Colors.green, size: 24))]));
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool readOnly = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: controller, readOnly: readOnly, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))));
  }

  Widget _buildAutocompleteField({required TextEditingController controller, required String label, IconData? icon}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: controller, decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon, size: 20) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))));
  }

  Widget _buildDropdownField<T>({required String label, required IconData icon, required T? value, required List<T> items, required void Function(T?) onChanged, required String Function(T) itemLabel}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<T>(value: value, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), items: items.map((i) => DropdownMenuItem(value: i, child: Text(itemLabel(i)))).toList(), onChanged: (v) => setState(() => onChanged(v))));
  }

  Future<void> _saveService() async {
    if (_selectedDriver == null || _selectedCar == null || _selectedSeller == null || _selectedLoadType == null) return;
    final exp = ServiceExpenses(
      fuelCost: _fuel, fuelImagePath: _fuelImagePath, billOfLadingCost: _billOfLading, commission: _commission, commissionImagePath: _commissionImagePath, tollImagePath: _tollImagePath,
      otherExpenses: widget.serviceToEdit?.expenses.otherExpenses ?? [], tolls: _tolls,
    );
    final s = LoadService(id: widget.serviceToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), orderCode: _orderCodeController.text, car: _selectedCar!, driver: _selectedDriver!, loadType: _selectedLoadType!, seller: _selectedSeller!, customer: _selectedCustomer, origin: _originController.text, destination: _destinationController.text, date: widget.serviceToEdit?.date ?? DateTime.now(), weight: _weight, transportPricePerTon: _transportPricePerTon, purchasePricePerTon: _purchasePricePerTon, expenses: exp, purchaseInvoiceImagePath: _purchaseInvoiceImagePath, billOfLadingImagePath: _billOfLadingImagePath, weighbridgeImagePath: _weighbridgeImagePath, isAgreedFreight: _isAgreedFreight, agreedFreightAmount: _agreedFreightAmount, driverAgreementPercentage: _driverAgreementPercentage, isOwnerDriver: _isOwnerDriver, extraDriverPay: _extraDriverPay, isFinalized: widget.serviceToEdit?.isFinalized ?? false);
    await _repository.saveService(s);
    if (mounted) Navigator.pop(context, true);
  }
}
