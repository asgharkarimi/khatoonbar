import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../models/models.dart';
import 'formatters.dart';
import 'persian_text_shaper.dart';

class PdfService {
  static const PdfColor primaryColor = PdfColors.blueGrey800;
  static const PdfColor accentColor = PdfColors.blueGrey50;
  static const PdfColor secondaryColor = PdfColors.blue800;

  static String _fix(String? text) {
    if (text == null || text.isEmpty) return "";
    try {
      return PersianTextShaper.shape(text.trim());
    } catch (e) {
      return text ?? "";
    }
  }

  static Future<pw.Font> _getFont() async {
    try {
      final fontData = await rootBundle.load("assets/fonts/iranyekan.ttf");
      return pw.Font.ttf(fontData);
    } catch (e) {
      debugPrint("Error loading font: $e");
      return pw.Font.helvetica(); 
    }
  }

  static Future<pw.ThemeData> _getTheme() async {
    final font = await _getFont();
    return pw.ThemeData.withFont(
      base: font,
      bold: font,
    );
  }

  static Future<pw.ImageProvider?> _loadImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (await file.exists()) {
        return pw.MemoryImage(await file.readAsBytes());
      }
    } catch (e) {
      debugPrint("Error loading image for PDF: $e");
    }
    return null;
  }

  static Future<bool> generateAndPrintService(LoadService service) async {
    try {
      final pdf = pw.Document();
      final theme = await _getTheme();
      final isTransportOnly = service.purchasePricePerTon == 0;
      final exp = service.expenses;

      String logisticsName = service.logisticsCo?.name ?? service.logisticsName ?? "";

      // بارگذاری تمامی تصاویر موجود (هزینه‌ها، مدارک و رسیدها)
      final List<MapEntry<String, pw.ImageProvider>> attachedImages = [];
      
      final imagePaths = {
        "فاکتور خرید": service.purchaseInvoiceImagePath,
        "تصویر بارنامه": service.billOfLadingImagePath,
        "تصویر باسکول": service.weighbridgeImagePath,
        "رسید سوخت": exp.fuelImagePath,
        "رسید عوارض": exp.tollImagePath,
        "کمیسیون": exp.commissionImagePath,
        "انعام بارگیری": exp.loadingTipImagePath,
        "انعام تخلیه": exp.unloadingTipImagePath,
        "ضدعفونی": exp.disinfectionImagePath,
        "باسکول بارگیری": exp.loadingWeighbridgeImagePath,
        "لودر": exp.loaderLoadingImagePath,
        "بارشمار": exp.tallyClerkImagePath,
        "باسکول تخلیه": exp.unloadingWeighbridgeImagePath,
        "کارگر تخلیه": exp.unloadingWorkerImagePath,
      };

      for (var entry in imagePaths.entries) {
        final img = await _loadImage(entry.value);
        if (img != null) attachedImages.add(MapEntry(entry.key, img));
      }

      // افزودن تصاویر هزینه‌های جانبی
      for (var other in exp.otherExpenses) {
        final img = await _loadImage(other.receiptImagePath);
        if (img != null) attachedImages.add(MapEntry("هزینه: ${other.title}", img));
      }

      // افزودن تمامی رسیدهای پرداخت و تصاویر چک‌های مرتبط با این سرویس
      final allPayments = [
        ...service.paymentsToSeller,
        ...service.collectionsFromCustomer,
        ...service.paymentsToLogistics,
        ...service.paymentsToDriver,
      ];

      for (var p in allPayments) {
        final receiptImg = await _loadImage(p.receiptImagePath);
        if (receiptImg != null) {
          String label = "رسید: ";
          if (p.type == PaymentType.toSeller) label += "پرداخت به فروشنده";
          else if (p.type == PaymentType.fromCustomer) label += "دریافت از مشتری";
          else if (p.type == PaymentType.toLogistics) label += "پرداخت به باربری";
          else if (p.type == PaymentType.toDriver) label += "پرداخت به راننده";
          attachedImages.add(MapEntry("$label (${AppFormatters.formatCurrency(p.amount)} تومان)", receiptImg));
        }
        final checkImg = await _loadImage(p.checkImagePath);
        if (checkImg != null) {
          attachedImages.add(MapEntry("چک: ${p.bankName ?? ''} - ${p.checkNumber ?? ''}", checkImg));
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(30),
          footer: (context) => _buildFooter(pageNumber: context.pageNumber, totalPages: context.pagesCount),
          build: (context) => [
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildHeader("صورت‌حساب جامع حمل بار و مخارج"),
                  pw.SizedBox(height: 15),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _infoText("کد سفارش:", service.orderCode.toPersianDigit()),
                      _infoText("تاریخ ثبت:", service.date.toPersianDate()),
                      _infoText("وضعیت نهایی:", service.isFinalized ? "تکمیل شده" : "در جریان"),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                  
                  _buildSectionTitle("اطلاعات طرفین و خودرو"),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          _rowInfo("راننده:", service.driver.fullName),
                          _rowInfo("خودرو:", "${service.car.name} (${service.car.plate ?? 'بدون پلاک'})"),
                        ]
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          _rowInfo("مشتری:", service.customer?.fullName ?? "---"),
                          _rowInfo("فروشنده:", service.seller.name),
                          if (logisticsName.isNotEmpty) _rowInfo("باربری:", logisticsName),
                        ]
                      ),
                    ]
                  ),

                  pw.SizedBox(height: 10),
                  _buildSectionTitle("جزئیات بار و زمان‌بندی"),
                  _rowInfo("نوع کالا:", service.loadType.name),
                  _rowInfo("مسیر جابجایی:", "${service.origin} به ${service.destination}"),
                  _rowInfo("وزن خالص:", "${service.weight.toString().toPersianDigit()} تن"),
                  if (service.loadingDateTime != null) 
                    _rowInfo("زمان بارگیری:", AppFormatters.formatPersianDateTime(service.loadingDateTime!).toPersianDigit()),
                  if (service.unloadingDateTime != null) 
                    _rowInfo("زمان تخلیه:", AppFormatters.formatPersianDateTime(service.unloadingDateTime!).toPersianDigit()),
                  
                  pw.SizedBox(height: 10),
                  _buildSectionTitle("ریز محاسبات مالی و مخارج بارنامه"),
                  _rowInfo("هزینه پایه بارنامه:", "${AppFormatters.formatCurrency(exp.billOfLadingCost)} تومان"),
                  
                  // لیست جامع تمامی مخارج
                  if (exp.commission > 0) _rowInfo("کمیسیون باربری:", "${AppFormatters.formatCurrency(exp.commission)} تومان", isBold: exp.commissionInBoL),
                  if (exp.totalTolls > 0) _rowInfo("مجموع عوارض مسیر:", "${AppFormatters.formatCurrency(exp.totalTolls)} تومان", isBold: exp.tollInBoL),
                  if (exp.fuelCost > 0) _rowInfo("هزینه سوخت:", "${AppFormatters.formatCurrency(exp.fuelCost)} تومان", isBold: exp.fuelInBoL),
                  
                  if (exp.loadingTip > 0) _rowInfo("انعام بارگیری:", "${AppFormatters.formatCurrency(exp.loadingTip)} تومان"),
                  if (exp.loadingWeighbridge > 0) _rowInfo("باسکول بارگیری:", "${AppFormatters.formatCurrency(exp.loadingWeighbridge)} تومان"),
                  if (exp.loaderLoading > 0) _rowInfo("هزینه لودر:", "${AppFormatters.formatCurrency(exp.loaderLoading)} تومان"),
                  if (exp.tallyClerk > 0) _rowInfo("هزینه بارشمار:", "${AppFormatters.formatCurrency(exp.tallyClerk)} تومان"),
                  
                  if (exp.unloadingTip > 0) _rowInfo("انعام تخلیه:", "${AppFormatters.formatCurrency(exp.unloadingTip)} تومان"),
                  if (exp.unloadingWeighbridge > 0) _rowInfo("باسکول تخلیه:", "${AppFormatters.formatCurrency(exp.unloadingWeighbridge)} تومان"),
                  if (exp.unloadingWorker > 0) _rowInfo("کارگر تخلیه:", "${AppFormatters.formatCurrency(exp.unloadingWorker)} تومان"),
                  
                  if (exp.disinfectionCost > 0) _rowInfo("هزینه ضدعفونی:", "${AppFormatters.formatCurrency(exp.disinfectionCost)} تومان"),
                  
                  for (var e in exp.otherExpenses)
                    if (e.amount > 0) _rowInfo("${e.title}:", "${AppFormatters.formatCurrency(e.amount)} تومان", isBold: e.includeInBoL),
                  
                  pw.Divider(color: PdfColors.grey400),
                  _rowInfo("جمع کل مخارج سرویس:", "${AppFormatters.formatCurrency(exp.total)} تومان", isBold: true),
                  _rowInfo("مبلغ قابل پرداخت به باربری:", "${AppFormatters.formatCurrency(exp.owedToLogistics)} تومان", isBold: true, color: PdfColors.orange900),

                  if (allPayments.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    _buildSectionTitle("خلاصه تراکنش‌های مالی و رسیدها"),
                    for (var p in allPayments)
                      _rowInfo(
                        "${_getPaymentTypeLabel(p.type)} (${_getPaymentMethodName(p.method)}):", 
                        "${AppFormatters.formatCurrency(p.amount)} تومان",
                        color: p.type == PaymentType.fromCustomer ? PdfColors.green800 : PdfColors.red800,
                      ),
                  ],

                  pw.SizedBox(height: 10),
                  _buildSectionTitle("خلاصه نهایی و سوددهی"),
                  if (!isTransportOnly)
                    _rowInfo("مبلغ خرید کالا:", "${AppFormatters.formatCurrency(service.totalPurchaseAmount)} تومان"),
                  _rowInfo("کل کرایه حمل:", "${AppFormatters.formatCurrency(service.totalTransportAmount)} تومان"),
                  _rowInfo("سود خالص (صافی):", "${AppFormatters.formatCurrency(service.netProfit)} تومان", isBold: true, color: PdfColors.green900),
                  
                  if (!service.isOwnerDriver) ...[
                    _rowInfo("حقوق راننده (${service.driverAgreementPercentage}%):", "${AppFormatters.formatCurrency(service.driverSalary)} تومان"),
                    _rowInfo("سهم خالص مالک:", "${AppFormatters.formatCurrency(service.ownerShare)} تومان", isBold: true),
                  ],

                  pw.SizedBox(height: 15),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: accentColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: secondaryColor, width: 1),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(_fix("${AppFormatters.formatCurrency(service.totalServicePriceForCustomer)} تومان"),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: secondaryColor)),
                        pw.Text(_fix(isTransportOnly ? "جمع کل مبلغ قابل پرداخت:" : "جمع کل فاکتور مشتری (کالا + حمل):"),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: secondaryColor)),
                      ],
                    ),
                  ),
                  
                  if (service.fareAccountNumber != null && service.fareAccountNumber!.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    _rowInfo("واریز کرایه به:", "${service.fareAccountOwner ?? ''} (${service.fareBankName ?? ''})"),
                    _rowInfo("شماره حساب/کارت:", service.fareAccountNumber!.toPersianDigit()),
                  ],
                  
                  pw.SizedBox(height: 30),
                  _buildSignatures(),
                ],
              ),
            ),
            
            // صفحه تصاویر پیوست
            if (attachedImages.isNotEmpty) ...[
              pw.NewPage(),
              _buildSectionTitle("پیوست‌ها و تصاویر اسناد"),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 20,
                runSpacing: 20,
                children: attachedImages.map((entry) => pw.Column(
                  children: [
                    pw.Container(
                      width: 240,
                      height: 180,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                      ),
                      child: pw.Image(entry.value, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 240,
                      child: pw.Center(
                        child: pw.Text(_fix(entry.key), 
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )).toList(),
              ),
            ],
          ],
        ),
      );

      return await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Service-${service.orderCode}');
    } catch (e) {
      debugPrint("PDF Error: $e");
      return false;
    }
  }

  static String _getPaymentTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.toSeller: return "پرداخت به فروشنده";
      case PaymentType.fromCustomer: return "دریافت از مشتری";
      case PaymentType.toLogistics: return "پرداخت به باربری";
      case PaymentType.toDriver: return "پرداخت به راننده";
    }
  }

  static Future<bool> generateAndPrintCustomerLedger(Customer customer, List<LoadService> services, List<Payment> payments) async {
    try {
      final pdf = pw.Document();
      final theme = await _getTheme();

      double totalDebt = services.fold(0, (sum, s) => sum + s.totalServicePriceForCustomer);
      double totalPaid = payments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);
      double pendingChecks = payments.where((p) => p.method == PaymentMethod.check && !p.isCleared).fold(0, (sum, p) => sum + p.amount);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          header: (context) => _buildHeader("صورت‌حساب مالی مشتری: ${customer.fullName}"),
          footer: (context) => _buildFooter(pageNumber: context.pageNumber, totalPages: context.pagesCount),
          build: (context) => [
            _buildSectionTitle("لیست سرویس‌های انجام شده"),
            _buildTable(
              ['ردیف', 'تاریخ', 'نوع بار', 'وزن', 'مبلغ کل'],
              services.asMap().entries.map((e) => [
                (e.key + 1).toString().toPersianDigit(),
                e.value.date.toPersianDate(),
                e.value.loadType.name,
                e.value.weight.toString().toPersianDigit(),
                AppFormatters.formatCurrency(e.value.totalServicePriceForCustomer),
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle("لیست دریافتی‌ها"),
            _buildTable(
              ['ردیف', 'تاریخ', 'روش', 'وضعیت', 'مبلغ'],
              payments.asMap().entries.map((e) => [
                (e.key + 1).toString().toPersianDigit(),
                e.value.date.toPersianDate(),
                _getPaymentMethodName(e.value.method),
                e.value.isCleared ? "وصول شده" : "در جریان",
                AppFormatters.formatCurrency(e.value.amount),
              ]).toList(),
            ),
            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: _buildSummaryBox("بدهی کل:", totalDebt, "دریافتی نقد:", totalPaid, "چک در جریان:", pendingChecks),
            ),
          ],
        ),
      );

      return await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Ledger-${customer.fullName}');
    } catch (e) {
      debugPrint("PDF Ledger Error: $e");
      return false;
    }
  }

  static Future<bool> generateAndPrintSellerLedger(Seller seller, List<LoadService> services, List<Payment> payments) async {
    try {
      final pdf = pw.Document();
      final theme = await _getTheme();

      double totalDebt = services.fold(0, (sum, s) => sum + s.totalPurchaseAmount);
      double totalPaid = payments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);
      double pendingChecks = payments.where((p) => p.method == PaymentMethod.check && !p.isCleared).fold(0, (sum, p) => sum + p.amount);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          header: (context) => _buildHeader("صورت‌حساب مالی فروشنده: ${seller.name}"),
          footer: (context) => _buildFooter(pageNumber: context.pageNumber, totalPages: context.pagesCount),
          build: (context) => [
            _buildSectionTitle("لیست بارهای خریداری شده"),
            _buildTable(
              ['ردیف', 'تاریخ', 'نوع بار', 'وزن', 'فی خرید', 'مبلغ کل'],
              services.asMap().entries.map((e) => [
                (e.key + 1).toString().toPersianDigit(),
                e.value.date.toPersianDate(),
                e.value.loadType.name,
                e.value.weight.toString().toPersianDigit(),
                AppFormatters.formatCurrency(e.value.purchasePricePerTon),
                AppFormatters.formatCurrency(e.value.totalPurchaseAmount),
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle("لیست پرداختی‌ها"),
            _buildTable(
              ['ردیف', 'تاریخ', 'روش', 'وضعیت', 'مبلغ'],
              payments.asMap().entries.map((e) => [
                (e.key + 1).toString().toPersianDigit(),
                e.value.date.toPersianDate(),
                _getPaymentMethodName(e.value.method),
                e.value.isCleared ? "پرداخت شده" : "چک معوق",
                AppFormatters.formatCurrency(e.value.amount),
              ]).toList(),
            ),
            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: _buildSummaryBox("بدهی کل ما:", totalDebt, "پرداختی نقد:", totalPaid, "چک در جریان:", pendingChecks),
            ),
          ],
        ),
      );

      return await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Ledger-${seller.name}');
    } catch (e) {
      debugPrint("PDF Seller Ledger Error: $e");
      return false;
    }
  }

  static Future<bool> generateAndPrintLogisticsLedger(LogisticsCo co, List<LoadService> services, List<Payment> payments) async {
    try {
      final pdf = pw.Document();
      final theme = await _getTheme();

      double totalDebt = services.fold(0, (sum, s) => sum + s.expenses.owedToLogistics);
      double totalPaid = payments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);
      double pendingChecks = payments.where((p) => p.method == PaymentMethod.check && !p.isCleared).fold(0, (sum, p) => sum + p.amount);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          header: (context) => _buildHeader("صورت‌حساب مالی باربری: ${co.name}"),
          footer: (context) => _buildFooter(pageNumber: context.pageNumber, totalPages: context.pagesCount),
          build: (context) => [
            _buildSectionTitle("لیست سرویس‌های انجام شده (هزینه بارنامه و کمیسیون)"),
            _buildTable(
              ['ردیف', 'تاریخ', 'نوع بار', 'کد سفارش', 'مبلغ طلب'],
              services.asMap().entries.map((e) => [
                (e.key + 1).toString().toPersianDigit(),
                e.value.date.toPersianDate(),
                e.value.loadType.name,
                e.value.orderCode.toPersianDigit(),
                AppFormatters.formatCurrency(e.value.expenses.owedToLogistics),
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle("لیست پرداختی‌ها"),
            _buildTable(
              ['ردیف', 'تاریخ', 'روش', 'وضعیت', 'مبلغ'],
              payments.asMap().entries.map((e) => [
                (e.key + 1).toString().toPersianDigit(),
                e.value.date.toPersianDate(),
                _getPaymentMethodName(e.value.method),
                e.value.isCleared ? "پرداخت شده" : "چک معوق",
                AppFormatters.formatCurrency(e.value.amount),
              ]).toList(),
            ),
            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: _buildSummaryBox("بدهی کل ما:", totalDebt, "پرداختی نقد:", totalPaid, "چک در جریان:", pendingChecks),
            ),
          ],
        ),
      );

      return await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Ledger-${co.name}');
    } catch (e) {
      debugPrint("PDF Logistics Ledger Error: $e");
      return false;
    }
  }

  static Future<bool> generateAndPrintDriverLedger(Driver driver, List<LoadService> services, List<Payment> payments) async {
    try {
      final pdf = pw.Document();
      final theme = await _getTheme();

      double totalEarned = services.fold(0, (sum, s) => sum + (s.isOwnerDriver ? s.netProfit : s.driverSalary));
      double totalPaid = payments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);
      double pendingChecks = payments.where((p) => p.method == PaymentMethod.check && !p.isCleared).fold(0, (sum, p) => sum + p.amount);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          header: (context) => _buildHeader("صورت‌حساب مالی راننده: ${driver.fullName}"),
          footer: (context) => _buildFooter(pageNumber: context.pageNumber, totalPages: context.pagesCount),
          build: (context) => [
            _buildSectionTitle("لیست سرویس‌های انجام شده"),
            _buildTable(
              ['ردیف', 'تاریخ', 'نوع بار', 'کد سفارش', 'مبلغ کارکرد'],
              services.asMap().entries.map((e) => [
                (e.key + 1).toString().toPersianDigit(),
                e.value.date.toPersianDate(),
                e.value.loadType.name,
                e.value.orderCode.toPersianDigit(),
                AppFormatters.formatCurrency(e.value.isOwnerDriver ? e.value.netProfit : e.value.driverSalary),
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle("لیست پرداختی‌ها"),
            _buildTable(
              ['ردیف', 'تاریخ', 'روش', 'وضعیت', 'مبلغ'],
              payments.asMap().entries.map((e) => [
                (e.key + 1).toString().toPersianDigit(),
                e.value.date.toPersianDate(),
                _getPaymentMethodName(e.value.method),
                e.value.isCleared ? "پرداخت شده" : "چک معوق",
                AppFormatters.formatCurrency(e.value.amount),
              ]).toList(),
            ),
            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: _buildSummaryBox("کل طلب راننده:", totalEarned, "پرداختی نقد:", totalPaid, "چک در جریان:", pendingChecks),
            ),
          ],
        ),
      );

      return await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Ledger-${driver.fullName}');
    } catch (e) {
      debugPrint("PDF Driver Ledger Error: $e");
      return false;
    }
  }

  static Future<bool> generateAndPrintGeneralReport(String title, List<String> headers, List<List<String>> data) async {
    try {
      final pdf = pw.Document();
      final theme = await _getTheme();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          header: (context) => _buildHeader(title),
          footer: (context) => _buildFooter(pageNumber: context.pageNumber, totalPages: context.pagesCount),
          build: (context) => [
            _buildTable(headers, data),
          ],
        ),
      );
      return await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Report');
    } catch (e) {
      debugPrint("PDF General Report Error: $e");
      return false;
    }
  }

  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      children: [
        pw.Center(child: pw.Text(_fix(title), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor))),
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text(_fix("سامانه مدیریت خاتون بار"), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
        pw.Divider(thickness: 1, color: primaryColor),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 10, bottom: 5),
      padding: const pw.EdgeInsets.only(right: 5),
      decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: secondaryColor, width: 3))),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(_fix(title), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: secondaryColor)),
      ),
    );
  }

  static pw.Widget _rowInfo(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(_fix(value), style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
          pw.SizedBox(width: 8),
          pw.Text(_fix(label), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _infoText(String label, String value) {
    return pw.Text(_fix("$label $value"), style: const pw.TextStyle(fontSize: 8));
  }

  static pw.Widget _buildTable(List<String> headers, List<List<String>> data) {
    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.TableHelper.fromTextArray(
        headers: headers.reversed.map((e) => _fix(e)).toList(),
        data: data.map((row) => row.reversed.map((cell) => _fix(cell)).toList()).toList(),
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: primaryColor),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellAlignment: pw.Alignment.center,
      ),
    );
  }

  static pw.Widget _buildSummaryBox(String label1, double amount1, String label2, double amount2, String label3, double amount3) {
    final balance = amount1 - amount2 - amount3;
    return pw.Container(
      width: 220,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(color: accentColor, border: pw.Border.all(color: primaryColor, width: 0.5)),
      child: pw.Column(
        children: [
          _sumRow(label1, amount1),
          _sumRow(label2, amount2),
          _sumRow(label3, amount3),
          pw.Divider(thickness: 0.5),
          _sumRow("مانده نهایی:", balance, isBold: true),
        ],
      ),
    );
  }

  static pw.Widget _sumRow(String label, double amount, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(_fix("${AppFormatters.formatCurrency(amount.abs())} تومان"), style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : null)),
        pw.Text(_fix(label), style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : null)),
      ],
    );
  }

  static pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(_fix("مهر و امضای باربری"), style: const pw.TextStyle(fontSize: 8)),
        pw.Text(_fix("امضای مشتری / راننده"), style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static pw.Widget _buildFooter({int? pageNumber, int? totalPages}) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_fix(DateTime.now().toPersianDate()), style: const pw.TextStyle(fontSize: 7)),
            if (pageNumber != null) pw.Text(_fix("صفحه $pageNumber از $totalPages"), style: const pw.TextStyle(fontSize: 7)),
            pw.Text(_fix("سامانه مدیریت خاتون بار"), style: const pw.TextStyle(fontSize: 7)),
          ],
        ),
      ],
    );
  }

  static String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return "نقدی";
      case PaymentMethod.check: return "چک";
      case PaymentMethod.card: return "کارت";
      case PaymentMethod.sheba: return "شبا";
    }
  }
}
