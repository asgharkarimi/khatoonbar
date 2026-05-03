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

  static Future<bool> generateAndPrintService(LoadService service) async {
    try {
      final pdf = pw.Document();
      final theme = await _getTheme();
      final isTransportOnly = service.purchasePricePerTon == 0;

      String logisticsName = service.logisticsCo?.name ?? service.logisticsName ?? "";

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          theme: theme,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildHeader("صورت‌حساب حمل بار"),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _infoText("شماره فاکتور:", service.orderCode.toPersianDigit()),
                    _infoText("تاریخ:", service.date.toPersianDate()),
                  ],
                ),
                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                pw.SizedBox(height: 10),
                
                _buildSectionTitle("اطلاعات طرفین"),
                _rowInfo("مشتری:", service.customer?.fullName ?? "---"),
                _rowInfo("راننده:", service.driver.fullName),
                _rowInfo("خودرو:", service.car.name),
                if (logisticsName.isNotEmpty)
                  _rowInfo("باربری:", logisticsName),
                
                pw.SizedBox(height: 10),
                _buildSectionTitle("جزئیات بار"),
                _rowInfo("نوع بار:", service.loadType.name),
                _rowInfo("مسیر:", "${service.origin} به ${service.destination}"),
                _rowInfo("وزن خالص:", "${service.weight.toString().toPersianDigit()} تن"),
                
                pw.SizedBox(height: 10),
                _buildSectionTitle("محاسبات مالی"),
                if (!isTransportOnly)
                  _rowInfo("فی خرید:", "${AppFormatters.formatCurrency(service.purchasePricePerTon)} تومان"),
                _rowInfo("فی حمل:", "${AppFormatters.formatCurrency(service.transportPricePerTon)} تومان"),
                
                if (service.fareAccountNumber != null && service.fareAccountNumber!.isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  _rowInfo("واریز به:", "${service.fareAccountOwner ?? ''} (${service.fareBankName ?? ''})"),
                  _rowInfo("شماره حساب:", service.fareAccountNumber!.toPersianDigit()),
                ],

                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    border: pw.Border.all(color: secondaryColor, width: 0.5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(_fix("${AppFormatters.formatCurrency(service.totalServicePriceForCustomer)} تومان"),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: secondaryColor)),
                      pw.Text(_fix(isTransportOnly ? "مبلغ قابل پرداخت:" : "جمع کل فاکتور:"),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: secondaryColor)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildSignatures(),
                pw.Spacer(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      );

      return await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Service-${service.orderCode}');
    } catch (e) {
      debugPrint("PDF Error: $e");
      return false;
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
            _buildSectionTitle("لیست پرداختی‌های ما"),
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

      double totalEarned = services.fold(0, (sum, s) => sum + s.netProfit);
      double totalPaid = payments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);
      double pendingChecks = payments.where((p) => p.method == PaymentMethod.check && !p.isCleared).fold(0, (sum, p) => sum + p.amount);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          header: (context) => _buildHeader("صورت‌حساب مالی راننده: ${driver.fullName}"),
          footer: (context) => _buildFooter(pageNumber: context.pageNumber, totalPages: context.pagesCount),
          build: (context) => [
            _buildSectionTitle("لیست سرویس‌های انجام شده (سود خالص)"),
            _buildTable(
              ['ردیف', 'تاریخ', 'نوع بار', 'کد سفارش', 'سود راننده'],
              services.asMap().entries.map((e) => [
                (e.key + 1).toString().toPersianDigit(),
                e.value.date.toPersianDate(),
                e.value.loadType.name,
                e.value.orderCode.toPersianDigit(),
                AppFormatters.formatCurrency(e.value.netProfit),
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle("لیست پرداختی‌های ما به راننده"),
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

  static pw.Widget _rowInfo(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(_fix(value), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 8),
          pw.Text(_fix(label), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
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
