import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../domain/entities/order.dart';

class PrinterService {
  static Future<Printer?> _getDefaultPrinter() async {
    final printers = await Printing.listPrinters();
    try {
      return printers.firstWhere((p) => p.isDefault);
    } catch (_) {
      return printers.isNotEmpty ? printers.first : null;
    }
  }

  static Future<void> printReceipt(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('RESTAURANT KIOSK',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Order: ${order.orderNumber}'),
              pw.Text(
                  'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)}'),
              pw.Text('Status: ${order.status.label}'),
              pw.Divider(),
              ...order.items.map((item) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('${item.quantity}x ${item.productName}'),
                          pw.Text('${item.subtotal.toStringAsFixed(2)} TND'),
                        ],
                      ),
                      if (item.modifiers.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: item.modifiers
                                .map((mod) => pw.Text(
                                    '+ ${mod.name} (${mod.extraPrice.toStringAsFixed(2)} TND)',
                                    style: const pw.TextStyle(fontSize: 10)))
                                .toList(),
                          ),
                        ),
                    ],
                  )),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${order.totalPrice.toStringAsFixed(2)} TND',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                  child: pw.Text('Thank you for your order!',
                      style: const pw.TextStyle(fontSize: 12))),
            ],
          );
        },
      ),
    );

    final printer = await _getDefaultPrinter();
    if (printer != null) {
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Receipt_${order.orderNumber}',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Receipt_${order.orderNumber}',
      );
    }
  }

  static Future<void> printSummary(
      List<Order> orders, DateTime? startDate, DateTime? endDate) async {
    final pdf = pw.Document();

    final totalRevenue = orders.fold(0.0, (sum, order) => sum + order.totalPrice);

    String period = 'All Time';
    if (startDate != null && endDate != null) {
      if (startDate.year == endDate.year &&
          startDate.month == endDate.month &&
          startDate.day == endDate.day) {
        period = DateFormat('yyyy-MM-dd').format(startDate);
      } else {
        period =
            '${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}';
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                  child: pw.Text('SALES SUMMARY',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Text('Period: $period'),
              pw.Text('Total Orders: ${orders.length}'),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL REVENUE',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${totalRevenue.toStringAsFixed(2)} TND',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              ...orders.map((order) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            '${order.orderNumber} (${DateFormat('HH:mm').format(order.createdAt)})',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('${order.totalPrice.toStringAsFixed(2)} TND',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );

    final printer = await _getDefaultPrinter();
    if (printer != null) {
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Summary',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Summary',
      );
    }
  }
}
