import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../core/data/service_repository.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_service.dart';
import '../../models/models.dart';
import '../widgets/amount_input.dart';
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

  Future<void> _finalizeService() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تایید نهایی کردن سرویس"),
        content: const Text("پس از ثبت نهایی، امکان ویرایش مخارج و جزئیات مسیر وجود نخواهد داشت. آیا از اتمام سفر اطمینان دارید؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("انصراف")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("بله، ثبت نهایی شود"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final finalizedService = LoadService(
          id: _currentService.id,
          orderCode: _currentService.orderCode,
          car: _currentService.car,
          driver: _currentService.driver,
          loadType: _currentService.loadType,
          seller: _currentService.seller,
          customer: _currentService.customer,
          logisticsCo: _currentService.logisticsCo,
          origin: _currentService.origin,
          destination: _currentService.destination,
          date: _currentService.date,
          loadingDateTime: _currentService.loadingDateTime,
          unloadingDateTime: _currentService.unloadingDateTime,
          weight: _currentService.weight,
          transportPricePerTon: _currentService.transportPricePerTon,
          purchasePricePerTon: _currentService.purchasePricePerTon,
          expenses: _currentService.expenses,
          purchaseInvoiceImagePath: _currentService.purchaseInvoiceImagePath,
          billOfLadingImagePath: _currentService.billOfLadingImagePath,
          weighbridgeImagePath: _currentService.weighbridgeImagePath,
          fareAccountNumber: _currentService.fareAccountNumber,
          fareAccountOwner: _currentService.fareAccountOwner,
          fareBankName: _currentService.fareBankName,
          logisticsName: _currentService.logisticsName,
          logisticsPhone: _currentService.logisticsPhone,
          logisticsLocation: _currentService.logisticsLocation,
          isAgreedFreight: _currentService.isAgreedFreight,
          agreedFreightAmount: _currentService.agreedFreightAmount,
          driverAgreementPercentage: _currentService.driverAgreementPercentage,
          isOwnerDriver: _currentService.isOwnerDriver,
          extraDriverPay: _currentService.extraDriverPay,
          isFinalized: true,
        );
        await _repository.saveService(finalizedService);
        await _refreshService();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("سرویس با موفقیت نهایی و قفل شد")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطا در نهایی‌سازی: $e")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _quickAddExpense(String type) async {
    double amount = 0;
    String tollName = "";
    String title = type == 'fuel' ? 'سوخت' : 'عوارضی';
    String? imagePath;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("ثبت سریع $title"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == 'toll') ...[
                TextField(
                  decoration: const InputDecoration(labelText: "نام عوارض (مثلا عوارض کاشان)", border: OutlineInputBorder()),
                  onChanged: (v) => tollName = v,
                ),
                const SizedBox(height: 12),
              ],
              AmountInput(label: "مبلغ (تومان)", onChanged: (v) => amount = v),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) setDialogState(() => imagePath = picked.path);
                },
                icon: Icon(imagePath == null ? Icons.add_a_photo : Icons.check_circle, color: imagePath == null ? null : Colors.green),
                label: Text(imagePath == null ? "افزودن تصویر رسید" : "تصویر انتخاب شد"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("انصراف")),
            ElevatedButton(
              onPressed: () {
                if (amount > 0) Navigator.pop(context, true);
              },
              child: const Text("ثبت"),
            ),
          ],
        ),
      ),
    ).then((value) async {
      if (value == true) {
        setState(() => _isLoading = true);
        final currentExp = _currentService.expenses;
        if (type == 'fuel') {
          currentExp.fuelCost += amount;
          if (imagePath != null) currentExp.fuelImagePath = imagePath;
        } else {
          currentExp.tolls.add(TollItem(name: tollName.isEmpty ? "عوارض ثبت شده" : tollName, amount: amount));
          if (imagePath != null) currentExp.tollImagePath = imagePath;
        }
        
        await _repository.saveService(_currentService);
        await _refreshService();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFinalized = _currentService.isFinalized;
    
    return Scaffold(
      appBar: AppBar(
        title: Text("جزییات سرویس ${_currentService.orderCode}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: "گزارش‌گیری و چاپ",
            onPressed: () => PdfService.generateAndPrintService(_currentService),
          ),
          if (!isFinalized)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: "ویرایش کامل",
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
                  if (!isFinalized) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ActionChip(
                            avatar: const Icon(Icons.local_gas_station, size: 16, color: Colors.white),
                            label: const Text("ثبت سوخت در مسیر"),
                            backgroundColor: Colors.blueGrey,
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                            onPressed: () => _quickAddExpense('fuel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ActionChip(
                            avatar: const Icon(Icons.toll, size: 16, color: Colors.white),
                            label: const Text("ثبت عوارضی در مسیر"),
                            backgroundColor: Colors.blueGrey,
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                            onPressed: () => _quickAddExpense('toll'),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  const SizedBox(height: 24),
                  if (!isFinalized)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _finalizeService,
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text("اتمام سفر و ثبت نهایی (قفل سرویس)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomActions(theme),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    bool isSettled = _currentService.isCustomerSettled;
    bool finalized = _currentService.isFinalized;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: finalized ? Colors.blue.shade50 : (isSettled ? Colors.green.shade50 : Colors.orange.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: finalized ? Colors.blue.shade200 : (isSettled ? Colors.green.shade200 : Colors.orange.shade200)),
      ),
      child: Row(
        children: [
          Icon(finalized ? Icons.lock : (isSettled ? Icons.check_circle : Icons.pending_actions), 
               color: finalized ? Colors.blue : (isSettled ? Colors.green : Colors.orange)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                finalized ? "سرویس نهایی و بایگانی شده" : (isSettled ? "تسویه شده با مشتری" : "در حال انجام / تسویه نشده"),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: finalized ? Colors.blue.shade900 : (isSettled ? Colors.green.shade900 : Colors.orange.shade900),
                ),
              ),
              if (finalized)
                const Text("امکان تغییر مخارج وجود ندارد", style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
            ],
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
        if (_currentService.seller.phone != null && _currentService.seller.phone!.isNotEmpty)
          _buildDataRow("تلفن فروشنده:", _currentService.seller.phone!),
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
        _buildDataRow("کرایه کلی (ناخالص):", "${AppFormatters.formatCurrency(_currentService.totalTransportAmount)} تومان", isBold: true, color: theme.primaryColor),
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
        _buildDataRow("کرایه کلی:", AppFormatters.formatCurrency(_currentService.totalTransportAmount), isBold: true),
        _buildDataRow("صافی (دریافتی راننده):", AppFormatters.formatCurrency(_currentService.driverNetPay), color: Colors.blue.shade800),
        _buildDataRow("جمع مبالغ بارنامه:", AppFormatters.formatCurrency(ex.owedToLogistics), color: Colors.orange.shade800),
        const Divider(),
        _buildDataRow("پایه بارنامه:", AppFormatters.formatCurrency(ex.billOfLadingCost)),
        _buildDataRow("کمیسیون:", AppFormatters.formatCurrency(ex.commission), hasImage: ex.commissionImagePath != null),
        
        if (ex.loadingWeighbridge > 0 || ex.loaderLoading > 0 || ex.tallyClerk > 0 || ex.loadingTip > 0) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: Text("مخارج بارگیری:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          if (ex.loadingTip > 0) _buildDataRow("انعام بارگیری:", AppFormatters.formatCurrency(ex.loadingTip), hasImage: ex.loadingTipImagePath != null),
          if (ex.loadingWeighbridge > 0) _buildDataRow("باسکول بارگیری:", AppFormatters.formatCurrency(ex.loadingWeighbridge), hasImage: ex.loadingWeighbridgeImagePath != null),
          if (ex.loaderLoading > 0) _buildDataRow("لودر:", AppFormatters.formatCurrency(ex.loaderLoading), hasImage: ex.loaderLoadingImagePath != null),
          if (ex.tallyClerk > 0) _buildDataRow("بارشمار:", AppFormatters.formatCurrency(ex.tallyClerk), hasImage: ex.tallyClerkImagePath != null),
        ],

        if (ex.unloadingWeighbridge > 0 || ex.unloadingWorker > 0 || ex.unloadingTip > 0) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: Text("مخارج تخلیه:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
          ),
          if (ex.unloadingTip > 0) _buildDataRow("انعام تخلیه:", AppFormatters.formatCurrency(ex.unloadingTip), hasImage: ex.unloadingTipImagePath != null),
          if (ex.unloadingWeighbridge > 0) _buildDataRow("باسکول تخلیه:", AppFormatters.formatCurrency(ex.unloadingWeighbridge), hasImage: ex.unloadingWeighbridgeImagePath != null),
          if (ex.unloadingWorker > 0) _buildDataRow("کارگر تخلیه:", AppFormatters.formatCurrency(ex.unloadingWorker), hasImage: ex.unloadingWorkerImagePath != null),
        ],

        if (ex.fuelCost > 0) _buildDataRow("سوخت:", AppFormatters.formatCurrency(ex.fuelCost), hasImage: ex.fuelImagePath != null),
        
        if (ex.tolls.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: Text("جزییات عوارض:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          ...ex.tolls.map((t) => _buildDataRow(t.name.isEmpty ? "عوارضی" : t.name, AppFormatters.formatCurrency(t.amount))),
          _buildDataRow("مجموع عوارض:", AppFormatters.formatCurrency(ex.totalTolls), isBold: true, hasImage: ex.tollImagePath != null),
        ],
        
        if (ex.disinfectionCost > 0) _buildDataRow("ضدعفونی:", AppFormatters.formatCurrency(ex.disinfectionCost), hasImage: ex.disinfectionImagePath != null),
        
        ...ex.otherExpenses.map((e) => _buildDataRow(e.title, AppFormatters.formatCurrency(e.amount), hasImage: e.receiptImagePath != null)),
        
        const Divider(),
        _buildDataRow("قابل پرداخت به باربری:", AppFormatters.formatCurrency(ex.owedToLogistics), isBold: true, color: Colors.orange.shade900),
        _buildDataRow("جمع کل مخارج:", AppFormatters.formatCurrency(ex.total), isBold: true, color: Colors.red.shade900),
        const Divider(),
        _buildDataRow("سود واقعی سرویس:", AppFormatters.formatCurrency(_currentService.netProfit), isBold: true, color: Colors.green.shade900),
      ],
    );
  }

  Widget _buildImagesCard(ThemeData theme) {
    final ex = _currentService.expenses;
    final List<Widget> imageThumbs = [];

    // ۱. تصاویر اصلی سرویس
    if (_currentService.billOfLadingImagePath != null && _currentService.billOfLadingImagePath!.isNotEmpty)
      imageThumbs.add(_buildImageThumb("بارنامه", _currentService.billOfLadingImagePath!));
    if (_currentService.weighbridgeImagePath != null && _currentService.weighbridgeImagePath!.isNotEmpty)
      imageThumbs.add(_buildImageThumb("باسکول کل", _currentService.weighbridgeImagePath!));
    if (_currentService.purchaseInvoiceImagePath != null && _currentService.purchaseInvoiceImagePath!.isNotEmpty)
      imageThumbs.add(_buildImageThumb("فاکتور خرید", _currentService.purchaseInvoiceImagePath!));

    // ۲. تصاویر هزینه‌ها
    if (ex.fuelImagePath != null && ex.fuelImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("سوخت", ex.fuelImagePath!));
    if (ex.tollImagePath != null && ex.tollImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("عوارض", ex.tollImagePath!));
    if (ex.loadingTipImagePath != null && ex.loadingTipImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("انعام بارگیری", ex.loadingTipImagePath!));
    if (ex.unloadingTipImagePath != null && ex.unloadingTipImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("انعام تخلیه", ex.unloadingTipImagePath!));
    if (ex.disinfectionImagePath != null && ex.disinfectionImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("ضدعفونی", ex.disinfectionImagePath!));
    if (ex.commissionImagePath != null && ex.commissionImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("کمیسیون", ex.commissionImagePath!));
    if (ex.loadingWeighbridgeImagePath != null && ex.loadingWeighbridgeImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("باسکول بارگیری", ex.loadingWeighbridgeImagePath!));
    if (ex.loaderLoadingImagePath != null && ex.loaderLoadingImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("لودر", ex.loaderLoadingImagePath!));
    if (ex.tallyClerkImagePath != null && ex.tallyClerkImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("بارشمار", ex.tallyClerkImagePath!));
    if (ex.unloadingWeighbridgeImagePath != null && ex.unloadingWeighbridgeImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("باسکول تخلیه", ex.unloadingWeighbridgeImagePath!));
    if (ex.unloadingWorkerImagePath != null && ex.unloadingWorkerImagePath!.isNotEmpty) imageThumbs.add(_buildImageThumb("کارگر تخلیه", ex.unloadingWorkerImagePath!));
    
    for (var other in ex.otherExpenses) {
      if (other.receiptImagePath != null && other.receiptImagePath!.isNotEmpty)
        imageThumbs.add(_buildImageThumb("هزینه: ${other.title}", other.receiptImagePath!));
    }

    // ۳. تصاویر تراکنش‌های مالی (دریافتی/پرداختی)
    final allPayments = [
      ..._currentService.paymentsToSeller,
      ..._currentService.collectionsFromCustomer,
      ..._currentService.paymentsToLogistics,
      ..._currentService.paymentsToDriver,
    ];

    for (var p in allPayments) {
      if (p.receiptImagePath != null && p.receiptImagePath!.isNotEmpty) {
        String label = "رسید: ";
        if (p.type == PaymentType.fromCustomer) label += "دریافت مشتری";
        else if (p.type == PaymentType.toSeller) label += "پرداخت فروشنده";
        else label += "تراکنش مالی";
        imageThumbs.add(_buildImageThumb(label, p.receiptImagePath!));
      }
      if (p.checkImagePath != null && p.checkImagePath!.isNotEmpty) {
        imageThumbs.add(_buildImageThumb("چک: ${p.bankName ?? ''}", p.checkImagePath!));
      }
    }

    return _buildCard(
      title: "تصاویر اسناد و رسیدها",
      icon: Icons.image_outlined,
      children: [
        if (imageThumbs.isEmpty)
          const Text("تصویری ثبت نشده است", style: TextStyle(fontSize: 12, color: Colors.grey))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: imageThumbs),
          ),
      ],
    );
  }

  Widget _buildImageThumb(String label, String path) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(File(path)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(blurRadius: 10)]))
                ],
              ),
            ),
          );
        },
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 80,
              child: Text(label, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
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

  Widget _buildDataRow(String label, String value, {bool isBold = false, Color? color, bool hasImage = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              if (hasImage) ...[
                const SizedBox(width: 4),
                const Icon(Icons.attach_file, size: 14, color: Colors.blue),
              ],
            ],
          ),
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
