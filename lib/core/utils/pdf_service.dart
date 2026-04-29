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
  static const PdfColor secondaryColor = PdfColors.blue800; // رنگ جدید برای بخش‌های درخواستی

  static String _fix(String? text) {
    if (text == null || text.isEmpty) return "";
    return PersianTextShaper.shape(text);
  }

  static Future<pw.Font> _getFont({bool isBold = false}) async {
    // اگر فایل bold دارید نام آن را اینجا اصلاح کنید
    final fontPath = isBold ? "assets/fonts/iranyekan.ttf" : "assets/fonts/iranyekan.ttf";
    final fontData = await rootBundle.load(fontPath);
    return pw.Font.ttf(fontData);
  }

  static Future<pw.ThemeData> _getTheme() async {
    final font = await _getFont();
    final boldFont = await _getFont(isBold: true);
    return pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
    );
  }

  /// چاپ فاکتور تک سرویس (A5)
  static Future<void> generateAndPrintService(LoadService service) async {
    final pdf = pw.Document();
    final theme = await _getTheme();
    final isTransportOnly = service.purchasePricePerTon == 0;

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
                  _infoText("شماره فاکتور:", service.id.toString().toPersianDigit()),
                  _infoText("تاریخ:", service.date.toPersianDate()),
                ],
              ),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 10),
              
              _buildSectionTitle("اطلاعات طرفین"),
              _rowInfo("مشتری:", service.customer?.fullName ?? "---"),
              _rowInfo("راننده:", service.driver.fullName),
              _rowInfo("خودرو:", service.car.name),
              
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

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Service-${service.id}');
  }

  /// چاپ صورت‌حساب مشتری (A4)
  static Future<void> generateAndPrintCustomerLedger(Customer customer, List<LoadService> services, List<Payment> payments) async {
    final pdf = pw.Document();
    final theme = await _getTheme();

    double totalDebt = services.fold(0, (sum, s) => sum + s.totalServicePriceForCustomer);
    double totalPaid = payments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        header: (context) => _buildHeader("صورت‌حساب مالی مشتری: ${customer.fullName}"),
        footer: (context) => _buildFooter(pageNumber: context.pageNumber, totalPages: context.pagesCount),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.SizedBox(height: 10),
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
                  ['ردیف', 'تاریخ', 'روش', 'توضیحات/بانک', 'مبلغ'],
                  payments.asMap().entries.map((e) => [
                    (e.key + 1).toString().toPersianDigit(),
                    e.value.date.toPersianDate(),
                    _getPaymentMethodName(e.value.method),
                    e.value.bankName ?? "-",
                    AppFormatters.formatCurrency(e.value.amount),
                  ]).toList(),
                ),
                pw.SizedBox(height: 30),
                _buildSummaryBox("بدهی کل:", totalDebt, "دریافتی کل:", totalPaid),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'CustomerLedger-${customer.fullName}');
  }

  /// چاپ صورت‌حساب فروشنده (A4)
  static Future<void> generateAndPrintSellerLedger(Seller seller, List<LoadService> services, List<Payment> payments) async {
    final pdf = pw.Document();
    final theme = await _getTheme();

    double totalDebt = services.fold(0, (sum, s) => sum + s.totalPurchaseAmount);
    double totalPaid = payments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        header: (context) => _buildHeader("صورت‌حساب مالی فروشنده: ${seller.name}"),
        footer: (context) => _buildFooter(pageNumber: context.pageNumber, totalPages: context.pagesCount),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.SizedBox(height: 10),
                _buildSectionTitle("لیست بارهای خریداری شده"),
                _buildTable(
                  ['ردیف', 'تاریخ', 'نوع بار', 'وزن', 'مبلغ خرید'],
                  services.asMap().entries.map((e) => [
                    (e.key + 1).toString().toPersianDigit(),
                    e.value.date.toPersianDate(),
                    e.value.loadType.name,
                    e.value.weight.toString().toPersianDigit(),
                    AppFormatters.formatCurrency(e.value.totalPurchaseAmount),
                  ]).toList(),
                ),
                pw.SizedBox(height: 20),
                _buildSectionTitle("لیست پرداختی‌های ما به فروشنده"),
                _buildTable(
                  ['ردیف', 'تاریخ', 'روش', 'توضیحات/بانک', 'مبلغ'],
                  payments.asMap().entries.map((e) => [
                    (e.key + 1).toString().toPersianDigit(),
                    e.value.date.toPersianDate(),
                    _getPaymentMethodName(e.value.method),
                    e.value.bankName ?? "-",
                    AppFormatters.formatCurrency(e.value.amount),
                  ]).toList(),
                ),
                pw.SizedBox(height: 30),
                _buildSummaryBox("جمع کل خرید:", totalDebt, "جمع پرداختی‌ها:", totalPaid, balanceLabel: "مانده طلب فروشنده:"),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'SellerLedger-${seller.name}');
  }

  // --- متدهای کمکی برای طراحی ---

  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(_fix(title),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryColor)),
        ),
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text(_fix("مدیریت حمل‌ونقل خاتون بار"), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
        pw.Divider(thickness: 1.5, color: primaryColor),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 10, bottom: 5),
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: const pw.BoxDecoration(
        border: pw.Border(right: pw.BorderSide(color: secondaryColor, width: 3)),
      ),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(_fix(title), 
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: secondaryColor)),
      ),
    );
  }

  static pw.Widget _rowInfo(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(_fix(value), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.SizedBox(
            width: 60,
            child: pw.Text(_fix(label), style: const pw.TextStyle(fontSize: 9, color: secondaryColor)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoText(String label, String value) {
    return pw.Text(_fix("$label $value"), style: const pw.TextStyle(fontSize: 8));
  }

  static pw.Widget _buildTable(List<String> headers, List<List<String>> data) {
    return pw.TableHelper.fromTextArray(
      headers: headers.reversed.map((e) => _fix(e)).toList(),
      data: data.map((row) => row.reversed.map((cell) => _fix(cell)).toList()).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.center,
    );
  }

  static pw.Widget _buildSummaryBox(String label1, double amount1, String label2, double amount2, {String balanceLabel = "مانده نهایی:"}) {
    final balance = amount1 - amount2;
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: accentColor,
          border: pw.Border.all(color: primaryColor, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Column(
          children: [
            _summaryRow(label1, amount1),
            _summaryRow(label2, amount2),
            pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            _summaryRow(balanceLabel, balance, isBold: true),
          ],
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, double amount, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(_fix("${AppFormatters.formatCurrency(amount)} تومان"),
            style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : null)),
        pw.Text(_fix(label), style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : null)),
      ],
    );
  }

  static pw.Widget _buildSignatures() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            children: [
              pw.Text(_fix("مهر و امضای باربری"), style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 35),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(_fix("امضای مشتری / راننده"), style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 35),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter({int? pageNumber, int? totalPages}) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_fix(DateTime.now().toPersianDate()), style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            if (pageNumber != null)
              pw.Text(_fix("صفحه $pageNumber از $totalPages"), style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            pw.Text(_fix("سامانه مدیریت خاتون بار"), style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
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
