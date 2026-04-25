import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:invoice_flow/models/invoice.dart';
import 'package:invoice_flow/utils/formatters.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  final PdfColor primaryColor = const PdfColor.fromInt(0xFFFED200);
  final PdfColor accentColor = const PdfColor.fromInt(0xFF030404);
  final PdfColor greyColor = PdfColors.grey700;
  final PdfColor lightGreyColor = PdfColors.grey200;

  Future<Uint8List> generateInvoicePdf(Invoice invoice, String currency) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();

    pw.MemoryImage? logoImage;
    if (invoice.sender.logoData != null) {
      try {
        logoImage = pw.MemoryImage(base64Decode(invoice.sender.logoData!));
      } catch (e) {}
    } else {
      try {
        final ByteData bytes = await rootBundle.load('assets/logo.png');
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (e) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Use zero margin for full-bleed elements
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                // Left Accent Bar
                pw.Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: pw.Container(width: 15, color: primaryColor),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(50, 60, 40, 60),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfHeader(invoice, logoImage),
                      pw.SizedBox(height: 50),
                      _buildAddresses(invoice),
                      pw.SizedBox(height: 50),
                      _buildItemsTable(invoice, currency),
                      pw.SizedBox(height: 40),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 1,
                            child: invoice.notes.isNotEmpty
                                ? _buildNotesSection(invoice)
                                : pw.SizedBox(),
                          ),
                          pw.SizedBox(width: 50),
                          pw.Expanded(
                            flex: 1,
                            child: _buildTotalSection(invoice, currency),
                          ),
                        ],
                      ),
                      pw.Spacer(),
                      _buildPdfFooter(invoice),
                    ],
                  ),
                ),
                if (invoice.status == InvoiceStatus.paid) _buildPaidStamp(),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeader(Invoice invoice, pw.MemoryImage? logoImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Container(
                height: 60,
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Image(logoImage),
              ),
            pw.Text(
              invoice.sender.businessName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
                letterSpacing: 1.5,
              ),
            ),
            if (invoice.sender.registrationNumber.isNotEmpty)
              pw.Text('REGISTRATION: ${invoice.sender.registrationNumber}',
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: greyColor,
                      fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              color: accentColor,
              child: pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 2,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('#${invoice.invoiceNumber}',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor)),
            pw.SizedBox(height: 12),
            _buildHeaderLabelValue(
                'DATE', AppFormatters.formatDate(invoice.issueDate)),
            _buildHeaderLabelValue(
                'DUE DATE', AppFormatters.formatDate(invoice.dueDate)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildHeaderLabelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: greyColor)),
          pw.SizedBox(width: 8),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildAddresses(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildAddressBox('BILL TO', [
          pw.Text(invoice.client.name,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 3),
          if (invoice.client.email.isNotEmpty) ...[
            pw.Text(invoice.client.email,
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 3),
          ],
          if (invoice.client.address.isNotEmpty)
            pw.Container(
              width: 180,
              child: pw.Text(invoice.client.address,
                  style: pw.TextStyle(fontSize: 10, color: greyColor)),
            ),
        ]),
        _buildAddressBox(
            'ISSUED BY',
            [
              pw.Text(invoice.sender.businessName,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 12),
                  textAlign: pw.TextAlign.right),
              pw.SizedBox(height: 3),
              if (invoice.sender.email.isNotEmpty) ...[
                pw.Text(invoice.sender.email,
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.right),
                pw.SizedBox(height: 3),
              ],
              if (invoice.sender.phone.isNotEmpty) ...[
                pw.Text(invoice.sender.phone,
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.right),
                pw.SizedBox(height: 3),
              ],
              if (invoice.sender.address.isNotEmpty)
                pw.Container(
                  width: 180,
                  child: pw.Text(invoice.sender.address,
                      style: pw.TextStyle(fontSize: 10, color: greyColor),
                      textAlign: pw.TextAlign.right),
                ),
            ],
            align: pw.CrossAxisAlignment.end),
      ],
    );
  }

  pw.Widget _buildAddressBox(String title, List<pw.Widget> content,
      {pw.CrossAxisAlignment align = pw.CrossAxisAlignment.start}) {
    return pw.Column(
      crossAxisAlignment: align,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: pw.BoxDecoration(
            border:
                pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
          ),
          child: pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 1)),
        ),
        pw.SizedBox(height: 10),
        ...content,
      ],
    );
  }

  pw.Widget _buildItemsTable(Invoice invoice, String currency) {
    return pw.Table(
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: lightGreyColor, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: primaryColor,
          ),
          children: [
            _tableHeader('DESCRIPTION', pw.Alignment.centerLeft),
            _tableHeader('QTY'),
            _tableHeader('UNIT PRICE'),
            _tableHeader('TOTAL'),
          ],
        ),
        ...List.generate(invoice.items.length, (index) {
          final item = invoice.items[index];
          final isEven = index % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: isEven ? PdfColors.white : PdfColors.grey50),
            children: [
              _tableCell(item.description, align: pw.Alignment.centerLeft),
              _tableCell(item.quantity.toString()),
              _tableCell(
                  AppFormatters.formatCurrency(item.unitPrice, currency)),
              _tableCell(AppFormatters.formatCurrency(item.amount, currency),
                  isBold: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _tableHeader(String text,
      [pw.Alignment align = pw.Alignment.center]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              letterSpacing: 0.5),
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text,
      {pw.Alignment align = pw.Alignment.center, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : null,
              color: isBold ? accentColor : greyColor),
        ),
      ),
    );
  }

  pw.Widget _buildTotalSection(Invoice invoice, String currency) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildTotalRow('SUBTOTAL',
            AppFormatters.formatCurrency(invoice.subtotal, currency)),
        _buildTotalRow('TAX (${invoice.taxPercentage}%)',
            AppFormatters.formatCurrency(invoice.taxAmount, currency)),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: accentColor,
            borderRadius: pw.BorderRadius.circular(2),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL AMOUNT',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: primaryColor)),
              pw.Text(AppFormatters.formatCurrency(invoice.total, currency),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                      color: primaryColor)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: greyColor)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor)),
        ],
      ),
    );
  }

  pw.Widget _buildNotesSection(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: lightGreyColor, width: 1)),
          ),
          child: pw.Text('NOTES & TERMS',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 1)),
        ),
        pw.SizedBox(height: 10),
        pw.Text(invoice.notes,
            style: pw.TextStyle(fontSize: 9, color: greyColor, height: 1.5)),
      ],
    );
  }

  pw.Widget _buildPdfFooter(Invoice invoice) {
    return pw.Column(
      children: [
        pw.Divider(color: lightGreyColor),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                    'Payment is due within ${invoice.dueDate.difference(invoice.issueDate).inDays} days.',
                    style: pw.TextStyle(fontSize: 8, color: greyColor)),
                pw.SizedBox(height: 2),
                pw.Text(
                    'Please include invoice number #${invoice.invoiceNumber} in your payment reference.',
                    style: pw.TextStyle(fontSize: 8, color: greyColor)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('THANK YOU FOR YOUR BUSINESS',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor)),
                pw.SizedBox(height: 4),
                pw.Text('Generated by ClinchX',
                    style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey400,
                        fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPaidStamp() {
    return pw.Positioned(
      bottom: 250,
      right: 40,
      child: pw.Transform.rotate(
        angle: -0.4,
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.green700, width: 3),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'PAID',
            style: pw.TextStyle(
              color: PdfColors.green700,
              fontSize: 48,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> downloadPdf(Invoice invoice, String currency) async {
    try {
      final pdfBytes = await generateInvoicePdf(invoice, currency);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'invoice_${invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      print('PDF Error: $e');
      rethrow;
    }
  }
}
