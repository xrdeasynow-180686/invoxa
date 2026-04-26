import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';

class PdfService {
  /// Builds the invoice PDF and returns the raw bytes.
  static Future<Uint8List> buildPdf(Invoice invoice) async {
    final doc = pw.Document();

    pw.MemoryImage? logo;
    if (invoice.logoBytes != null && invoice.logoBytes!.isNotEmpty) {
      logo = pw.MemoryImage(Uint8List.fromList(invoice.logoBytes!));
    }

    final dateStr = DateFormat('dd MMM yyyy').format(invoice.date);
    final currency = invoice.currency.trim().isEmpty ? '' : '${invoice.currency} ';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(invoice, logo),
          pw.SizedBox(height: 24),
          _buildPartiesRow(invoice, dateStr),
          pw.SizedBox(height: 24),
          _buildItemTable(invoice, currency),
          pw.SizedBox(height: 16),
          _buildTotal(invoice, currency),
          pw.SizedBox(height: 32),
          pw.Divider(),
          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Saves the PDF bytes to the **public Downloads** folder on Android
  /// (visible in the device's file manager), or to the app's documents
  /// directory on iOS / when the public folder is unavailable.
  /// Returns the absolute file path that was written.
  static Future<String> savePdf(Uint8List bytes, String invoiceNumber) async {
    final safeName = invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final filename = 'InovXA_$safeName.pdf';

    Directory? targetDir;

    if (Platform.isAndroid) {
      // Public Downloads folder — visible in any file manager.
      // Requires WRITE_EXTERNAL_STORAGE (API ≤ 32) +
      // android:requestLegacyExternalStorage="true" in AndroidManifest.
      final publicDownloads = Directory('/storage/emulated/0/Download');
      try {
        if (!await publicDownloads.exists()) {
          await publicDownloads.create(recursive: true);
        }
        // Quick write-probe so we don't keep a stale handle on permission denial.
        final probe = File('${publicDownloads.path}/.inovxa_probe');
        await probe.writeAsBytes(<int>[], flush: true);
        await probe.delete();
        targetDir = publicDownloads;
      } catch (_) {
        targetDir = null; // fall through to app docs
      }
    }

    targetDir ??= await getApplicationDocumentsDirectory();

    final file = File('${targetDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ---------- helpers ----------

  static pw.Widget _buildHeader(Invoice invoice, pw.MemoryImage? logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Container(
            width: 80,
            height: 80,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          )
        else
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Center(
              child: pw.Text(
                'LOGO',
                style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
              ),
            ),
          ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                invoice.businessName.isEmpty ? 'Your Business' : invoice.businessName,
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              if (invoice.businessAddress.isNotEmpty)
                pw.Text(invoice.businessAddress, style: const pw.TextStyle(fontSize: 11)),
              if (invoice.businessPhone.isNotEmpty)
                pw.Text('Phone: ${invoice.businessPhone}',
                    style: const pw.TextStyle(fontSize: 11)),
              if (invoice.businessEmail.isNotEmpty)
                pw.Text('Email: ${invoice.businessEmail}',
                    style: const pw.TextStyle(fontSize: 11)),
              if (invoice.businessAbn.isNotEmpty)
                pw.Text('Business / Tax No.: ${invoice.businessAbn}',
                    style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPartiesRow(Invoice invoice, String dateStr) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.clientName,
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(invoice.clientAddress, style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Invoice #',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            pw.Text(invoice.invoiceNumber, style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 8),
            pw.Text('Date',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            pw.Text(dateStr, style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemTable(Invoice invoice, String currency) {
    final headers = ['#', 'Item', 'Qty', 'Price', 'Total'];
    final rows = <List<String>>[];
    for (var i = 0; i < invoice.items.length; i++) {
      final it = invoice.items[i];
      rows.add([
        '${i + 1}',
        it.name,
        '${it.quantity}',
        '$currency${it.price.toStringAsFixed(2)}',
        '$currency${it.total.toStringAsFixed(2)}',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        0: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      cellStyle: const pw.TextStyle(fontSize: 11),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.4),
      },
    );
  }

  static pw.Widget _buildTotal(Invoice invoice, String currency) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.indigo50,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('TOTAL: ',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                '$currency${invoice.total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
