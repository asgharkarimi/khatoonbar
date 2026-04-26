import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../models/models.dart';
import 'formatters.dart';
import 'persian_text_shaper.dart';

class PdfService {
  static String fixPersian(String text) {
    if (text.isEmpty) return "";
    return PersianTextShaper.shape(text);
  }

  static Future<pw.ThemeData> _getTheme() async {
    final fontData = await rootBundle.load("assets/fonts/iranyekan.ttf");
    final ttf = pw.Font.ttf(fontData);
    // تنظیم فونت برای تمامی استایل‌ها جهت جلوگیری از نمایش مربع (Boxes)
    return pw.ThemeData.withFont(
      base: ttf,
      bold: ttf,
      italic: ttf,
      boldItalic: ttf,
    );
  }

  static Future<void> generateAndPrintService(LoadService service) async {
    final pdf = pw.Document();
    final theme = await _getTheme();

    final bool isTransportOnly = service.purchasePricePerTon == 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: theme,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      fixPersian("صورت‌حساب باربری خاتون بار"),
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(fixPersian("شماره: ${service.id.toPersianDigit()}"), style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(fixPersian("تاریخ: ${service.date.toPersianDate()}"), style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Divider(thickness: 1),
                  
                  _buildPdfRow("طرف حساب (مشتری):", service.customer?.fullName ?? "---"),
                  _buildPdfRow("نام راننده:", service.driver.fullName),
                  _buildPdfRow("خودرو:", service.car.name),
                  
                  pw.SizedBox(height: 5),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                  
                  _buildPdfRow("نوع بار:", service.loadType.name),
                  _buildPdfRow("مبدا:", service.origin),
                  _buildPdfRow("مقصد:", service.destination),
                  _buildPdfRow("وزن بار:", "${service.weight.toString().toPersianDigit()} تن"),
                  
                  pw.SizedBox(height: 5),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey300),

                  if (!isTransportOnly)
                    _buildPdfRow("فی خرید (هر تن):", "${AppFormatters.formatCurrency(service.purchasePricePerTon)} تومان"),
                  
                  _buildPdfRow("فی حمل (هر تن):", "${AppFormatters.formatCurrency(service.transportPricePerTon)} تومان"),
                  
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 15),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          fixPersian(isTransportOnly ? "کل کرایه حمل قابل پرداخت:" : "جمع کل (خرید + حمل):"), 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)
                        ),
                        pw.Text(
                          fixPersian("${AppFormatters.formatCurrency(service.totalServicePriceForCustomer)} تومان"),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  pw.Spacer(),
                  
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Text(fixPersian("امضا راننده"), style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(fixPersian("مهر و امضا باربری"), style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice-${service.id}',
    );
  }

  static Future<void> generateAndPrintCustomerLedger(Customer customer, List<LoadService> services, List<Payment> payments) async {
    final pdf = pw.Document();
    final theme = await _getTheme();

    double totalDebt = services.fold(0, (sum, s) => sum + s.totalServicePriceForCustomer);
    double totalPaid = payments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);
    double balance = totalDebt - totalPaid;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Center(child: pw.Text(fixPersian("صورت‌حساب مالی مشتری"), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(fixPersian("مشتری: ${customer.fullName}")),
                  pw.Text(fixPersian("تاریخ گزارش: ${DateTime.now().toPersianDate()}")),
                ],
              ),
              pw.Divider(),
            ],
          ),
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 10),
                pw.Text(fixPersian("لیست سرویس‌ها"), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.TableHelper.fromTextArray(
                  headers: ['ردیف', 'تاریخ', 'نوع بار', 'وزن (تن)', 'کد سفارش', 'مبلغ کل (تومان)'].map((e) => fixPersian(e)).toList(),
                  data: List.generate(services.length, (index) {
                    final s = services[index];
                    return [
                      (index + 1).toString().toPersianDigit(),
                      s.date.toPersianDate(),
                      s.loadType.name,
                      s.weight.toString().toPersianDigit(),
                      s.orderCode.toPersianDigit(),
                      AppFormatters.formatCurrency(s.totalServicePriceForCustomer),
                    ].map((e) => fixPersian(e)).toList();
                  }),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 20),
                pw.Text(fixPersian("لیست پرداختی‌ها"), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.TableHelper.fromTextArray(
                  headers: ['ردیف', 'تاریخ', 'روش پرداخت', 'بانک/شماره چک', 'توضیحات', 'مبلغ (تومان)'].map((e) => fixPersian(e)).toList(),
                  data: List.generate(payments.length, (index) {
                    final p = payments[index];
                    String info = "";
                    if (p.method == PaymentMethod.check) {
                      info = "${p.bankName ?? ''} - ${p.checkNumber ?? ''}";
                    } else if (p.method == PaymentMethod.card || p.method == PaymentMethod.sheba) {
                      info = p.bankName ?? "";
                    }
                    return [
                      (index + 1).toString().toPersianDigit(),
                      p.date.toPersianDate(),
                      _getPaymentMethodName(p.method),
                      info,
                      p.description ?? "",
                      AppFormatters.formatCurrency(p.amount),
                    ].map((e) => fixPersian(e)).toList();
                  }),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(), color: PdfColors.grey100),
                  child: pw.Column(
                    children: [
                      _buildSummaryRow("جمع کل بدهی سرویس‌ها:", totalDebt),
                      _buildSummaryRow("جمع کل دریافتی‌ها:", totalPaid),
                      pw.Divider(),
                      _buildSummaryRow("مانده بدهی نهایی:", balance, isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ledger-${customer.fullName}',
    );
  }

  static Future<void> generateAndPrintSellerLedger(Seller seller, List<LoadService> services, List<Payment> payments) async {
    final pdf = pw.Document();
    final theme = await _getTheme();

    double totalDebt = services.fold(0, (sum, s) => sum + s.totalPurchaseAmount);
    double totalPaid = payments.where((p) => p.isCleared).fold(0, (sum, p) => sum + p.amount);
    double balance = totalDebt - totalPaid;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Center(child: pw.Text(fixPersian("صورت‌حساب مالی فروشنده"), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(fixPersian("فروشنده: ${seller.name}")),
                  pw.Text(fixPersian("تاریخ گزارش: ${DateTime.now().toPersianDate()}")),
                ],
              ),
              pw.Divider(),
            ],
          ),
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 10),
                pw.Text(fixPersian("لیست بارها"), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.TableHelper.fromTextArray(
                  headers: ['ردیف', 'تاریخ', 'نوع بار', 'وزن (تن)', 'کد سفارش', 'مبلغ خرید (تومان)'].map((e) => fixPersian(e)).toList(),
                  data: List.generate(services.length, (index) {
                    final s = services[index];
                    return [
                      (index + 1).toString().toPersianDigit(),
                      s.date.toPersianDate(),
                      s.loadType.name,
                      s.weight.toString().toPersianDigit(),
                      s.orderCode.toPersianDigit(),
                      AppFormatters.formatCurrency(s.totalPurchaseAmount),
                    ].map((e) => fixPersian(e)).toList();
                  }),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 20),
                pw.Text(fixPersian("لیست پرداخت‌های ما"), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.TableHelper.fromTextArray(
                  headers: ['ردیف', 'تاریخ', 'روش پرداخت', 'بانک/شماره چک', 'توضیحات', 'مبلغ (تومان)'].map((e) => fixPersian(e)).toList(),
                  data: List.generate(payments.length, (index) {
                    final p = payments[index];
                    String info = "";
                    if (p.method == PaymentMethod.check) {
                      info = "${p.bankName ?? ''} - ${p.checkNumber ?? ''}";
                    } else if (p.method == PaymentMethod.card || p.method == PaymentMethod.sheba) {
                      info = p.bankName ?? "";
                    }
                    return [
                      (index + 1).toString().toPersianDigit(),
                      p.date.toPersianDate(),
                      _getPaymentMethodName(p.method),
                      info,
                      p.description ?? "",
                      AppFormatters.formatCurrency(p.amount),
                    ].map((e) => fixPersian(e)).toList();
                  }),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(), color: PdfColors.grey100),
                  child: pw.Column(
                    children: [
                      _buildSummaryRow("جمع کل بدهی ما:", totalDebt),
                      _buildSummaryRow("جمع کل پرداختی‌ها:", totalPaid),
                      pw.Divider(),
                      _buildSummaryRow("مانده بدهی نهایی ما:", balance, isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'SellerLedger-${seller.name}',
    );
  }

  static String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return fixPersian("نقدی");
      case PaymentMethod.check: return fixPersian("چک");
      case PaymentMethod.card: return fixPersian("کارت");
      case PaymentMethod.sheba: return fixPersian("شبا");
    }
  }

  static pw.Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(fixPersian(label), style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
        pw.Text(fixPersian("${AppFormatters.formatCurrency(amount)} تومان"), style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
      ],
    );
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Text(fixPersian(label), style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
          pw.SizedBox(width: 5),
          pw.Text(fixPersian(value), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
