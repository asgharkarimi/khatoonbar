import 'dart:io';
import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../core/data/service_repository.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import 'add_service_screen.dart';
import 'add_payment_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final LoadService service;
  const ServiceDetailsScreen({super.key, required this.service});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  late LoadService _currentService;
  final ServiceRepository _repository = ServiceRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentService = widget.service;
  }

  Future<void> _refreshService() async {
    setState(() => _isLoading = true);
    final services = await _repository.getAllServices();
    setState(() {
      _currentService = services.firstWhere((s) => s.id == _currentService.id);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text("جزییات سرویس ${_currentService.orderCode}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddServiceScreen(serviceToEdit: _currentService)),
              );
              if (result == true) _refreshService();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusHeader(theme),
                  const SizedBox(height: 16),
                  _buildMainInfoCard(theme),
                  const SizedBox(height: 16),
                  _buildRouteAndTimingCard(theme),
                  const SizedBox(height: 16),
                  _buildFinancialCard(theme),
                  const SizedBox(height: 16),
                  _buildExpensesCard(theme),
                  const SizedBox(height: 16),
                  _buildImagesCard(theme),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      // استفاده از bottomNavigationBar به جای bottomSheet برای مدیریت بهتر فاصله
      bottomNavigationBar: _buildBottomActions(theme),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    bool isSettled = _currentService.isCustomerSettled;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isSettled ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSettled ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(isSettled ? Icons.check_circle : Icons.pending_actions, 
               color: isSettled ? Colors.green : Colors.orange),
          const SizedBox(width: 12),
          Text(
            isSettled ? "تسویه شده با مشتری" : "دارای مانده بدهی مشتری",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSettled ? Colors.green.shade900 : Colors.orange.shade900,
            ),
          ),
          const Spacer(),
          Text(
            _currentService.date.toPersianDate(),
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(ThemeData theme) {
    return _buildCard(
      title: "اطلاعات پایه",
      icon: Icons.info_outline,
      children: [
        _buildDataRow("راننده:", _currentService.driver.fullName),
        _buildDataRow("خودرو:", _currentService.car.name + (_currentService.car.plate != null ? " (${_currentService.car.plate})" : "")),
        _buildDataRow("نوع بار:", _currentService.loadType.name),
        _buildDataRow("فروشنده:", _currentService.seller.name),
        if (_currentService.customer != null)
          _buildDataRow("مشتری:", _currentService.customer!.fullName),
      ],
    );
  }

  Widget _buildRouteAndTimingCard(ThemeData theme) {
    return _buildCard(
      title: "مسیر و زمان‌بندی",
      icon: Icons.map_outlined,
      children: [
        _buildDataRow("مبدا:", _currentService.origin),
        _buildDataRow("مقصد:", _currentService.destination),
        const Divider(),
        if (_currentService.loadingDateTime != null)
          _buildDataRow("زمان بارگیری:", AppFormatters.formatPersianDateTime(_currentService.loadingDateTime!)),
        if (_currentService.unloadingDateTime != null)
          _buildDataRow("زمان تخلیه:", AppFormatters.formatPersianDateTime(_currentService.unloadingDateTime!)),
      ],
    );
  }

  Widget _buildFinancialCard(ThemeData theme) {
    return _buildCard(
      title: "محاسبات مالی",
      icon: Icons.payments_outlined,
      children: [
        _buildDataRow("وزن بار:", "${_currentService.weight} تن"),
        if (!_currentService.isAgreedFreight)
          _buildDataRow("قیمت حمل (هر تن):", "${AppFormatters.formatCurrency(_currentService.transportPricePerTon)} تومان"),
        _buildDataRow("کرایه حمل کل:", "${AppFormatters.formatCurrency(_currentService.totalTransportAmount)} تومان", isBold: true),
        const Divider(),
        _buildDataRow("قیمت خرید (هر تن):", "${AppFormatters.formatCurrency(_currentService.purchasePricePerTon)} تومان"),
        _buildDataRow("مبلغ خرید کل:", "${AppFormatters.formatCurrency(_currentService.totalPurchaseAmount)} تومان", isBold: true),
        const Divider(),
        _buildDataRow("جمع کل بدهی مشتری:", "${AppFormatters.formatCurrency(_currentService.totalServicePriceForCustomer)} تومان", color: Colors.blue.shade900, isBold: true),
      ],
    );
  }

  Widget _buildExpensesCard(ThemeData theme) {
    final ex = _currentService.expenses;
    return _buildCard(
      title: "مخارج و جزییات بارنامه",
      icon: Icons.receipt_long_outlined,
      children: [
        _buildDataRow("پایه بارنامه:", AppFormatters.formatCurrency(ex.billOfLadingCost)),
        _buildDataRow("کمیسیون:", AppFormatters.formatCurrency(ex.commission)),
        
        if (ex.loadingWeighbridge > 0 || ex.loaderLoading > 0 || ex.tallyClerk > 0 || ex.loadingTip > 0) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: Text("مخارج بارگیری:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          if (ex.loadingTip > 0) _buildDataRow("انعام بارگیری:", AppFormatters.formatCurrency(ex.loadingTip)),
          if (ex.loadingWeighbridge > 0) _buildDataRow("باسکول بارگیری:", AppFormatters.formatCurrency(ex.loadingWeighbridge)),
          if (ex.loaderLoading > 0) _buildDataRow("لودر:", AppFormatters.formatCurrency(ex.loaderLoading)),
          if (ex.tallyClerk > 0) _buildDataRow("بارشمار:", AppFormatters.formatCurrency(ex.tallyClerk)),
        ],

        if (ex.unloadingWeighbridge > 0 || ex.unloadingWorker > 0 || ex.unloadingTip > 0) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: Text("مخارج تخلیه:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
          ),
          if (ex.unloadingTip > 0) _buildDataRow("انعام تخلیه:", AppFormatters.formatCurrency(ex.unloadingTip)),
          if (ex.unloadingWeighbridge > 0) _buildDataRow("باسکول تخلیه:", AppFormatters.formatCurrency(ex.unloadingWeighbridge)),
          if (ex.unloadingWorker > 0) _buildDataRow("کارگر تخلیه:", AppFormatters.formatCurrency(ex.unloadingWorker)),
        ],

        if (ex.fuelCost > 0) _buildDataRow("سوخت:", AppFormatters.formatCurrency(ex.fuelCost)),
        if (ex.tollCost > 0) _buildDataRow("عوارض:", AppFormatters.formatCurrency(ex.tollCost)),
        
        ...ex.otherExpenses.map((e) => _buildDataRow(e.title, AppFormatters.formatCurrency(e.amount))),
        
        const Divider(),
        _buildDataRow("قابل پرداخت به باربری:", AppFormatters.formatCurrency(ex.owedToLogistics), isBold: true, color: Colors.orange.shade900),
        _buildDataRow("جمع کل مخارج:", AppFormatters.formatCurrency(ex.total), isBold: true, color: Colors.red.shade900),
        const Divider(),
        _buildDataRow("سود خالص (صافی):", AppFormatters.formatCurrency(_currentService.netProfit), isBold: true, color: Colors.green.shade900),
      ],
    );
  }

  Widget _buildImagesCard(ThemeData theme) {
    return _buildCard(
      title: "تصاویر اسناد",
      icon: Icons.image_outlined,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (_currentService.billOfLadingImagePath != null)
                _buildImageThumb("بارنامه", _currentService.billOfLadingImagePath!),
              if (_currentService.weighbridgeImagePath != null)
                _buildImageThumb("باسکول", _currentService.weighbridgeImagePath!),
              if (_currentService.purchaseInvoiceImagePath != null)
                _buildImageThumb("فاکتور خرید", _currentService.purchaseInvoiceImagePath!),
            ],
          ),
        ),
        if (_currentService.billOfLadingImagePath == null && 
            _currentService.weighbridgeImagePath == null && 
            _currentService.purchaseInvoiceImagePath == null)
          const Text("تصویری ثبت نشده است", style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildImageThumb(String label, String path) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddPaymentScreen(service: _currentService, isCollection: true)),
                  );
                  if (result == true) _refreshService();
                },
                icon: const Icon(Icons.add_card),
                label: const Text("دریافت از مشتری"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddPaymentScreen(service: _currentService, isCollection: false)),
                  );
                  if (result == true) _refreshService();
                },
                icon: const Icon(Icons.payments_outlined),
                label: const Text("پرداخت به فروشنده"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تایید حذف"),
        content: const Text("آیا از حذف این سرویس و تمام تراکنش‌های مرتبط با آن اطمینان دارید؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("انصراف")),
          TextButton(
            onPressed: () async {
              await _repository.deleteService(_currentService.id);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context, true);
              }
            },
            child: const Text("حذف نهایی", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
