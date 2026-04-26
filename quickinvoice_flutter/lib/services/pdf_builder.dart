import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';

/// Brand palette
const _navy = PdfColor.fromInt(0xFF0E1F4D);
const _accent = PdfColor.fromInt(0xFF1F6FEB);
const _ink = PdfColor.fromInt(0xFF0F172A);
const _muted = PdfColor.fromInt(0xFF64748B);
const _line = PdfColor.fromInt(0xFFE2E8F0);
const _tableHeaderBg = PdfColor.fromInt(0xFFEFF4FF);
const _totalBg = PdfColor.fromInt(0xFF0E1F4D);

class PdfBuilder {
  final Invoice invoice;
  final pw.MemoryImage? logo;
  late final String _dateStr;
  late final String _currency;

  PdfBuilder(this.invoice, this.logo) {
    _dateStr = DateFormat('dd MMM yyyy').format(invoice.date);
    _currency = invoice.currency.trim().isEmpty ? '' : '${invoice.currency} ';
  }

  Future<Uint8List> build() async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        build: (_) => [
          _header(),
          pw.SizedBox(height: 12),
          pw.Divider(color: _line, thickness: 0.6),
          pw.SizedBox(height: 18),
          _billTo(),
          pw.SizedBox(height: 22),
          _itemsTable(),
          pw.SizedBox(height: 18),
          _total(),
        ],
        footer: (_) => _footer(),
      ),
    );

    return doc.save();
  }

  // ───────────────────────── Header ─────────────────────────
  pw.Widget _header() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // LEFT — logo + business
        pw.Expanded(
          flex: 3,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null)
                pw.Container(
                  width: 70,
                  height: 70,
                  margin: const pw.EdgeInsets.only(right: 14),
                  child: pw.Image(logo!, fit: pw.BoxFit.contain),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      invoice.businessName.isEmpty ? 'Your Business' : invoice.businessName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    if (invoice.businessAddress.isNotEmpty)
                      _meta(invoice.businessAddress),
                    if (invoice.businessPhone.isNotEmpty)
                      _meta('Phone: ${invoice.businessPhone}'),
                    if (invoice.businessEmail.isNotEmpty)
                      _meta('Email: ${invoice.businessEmail}'),
                    if (invoice.businessAbn.isNotEmpty)
                      _meta('Business / Tax No.: ${invoice.businessAbn}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // RIGHT — INVOICE block
        pw.Container(
          width: 170,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 10),
              _infoRow('Invoice #', invoice.invoiceNumber),
              pw.SizedBox(height: 4),
              _infoRow('Date', _dateStr),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _meta(String s) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(s, style: const pw.TextStyle(fontSize: 10.5, color: _muted)),
      );

  pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.white.shade(0.2),
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.4)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  // ───────────────────────── Bill To ─────────────────────────
  pw.Widget _billTo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('BILL TO',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent,
                  letterSpacing: 1.2)),
          pw.SizedBox(height: 6),
          pw.Text(invoice.clientName,
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink)),
          pw.SizedBox(height: 3),
          pw.Text(invoice.clientAddress,
              style: const pw.TextStyle(fontSize: 11, color: _ink)),
        ],
      ),
    );
  }

  // ───────────────────────── Items table ─────────────────────────
  pw.Widget _itemsTable() {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _tableHeaderBg),
        children: [
          _th('ITEM', pw.Alignment.centerLeft),
          _th('QTY', pw.Alignment.center),
          _th('PRICE', pw.Alignment.centerRight),
          _th('TOTAL', pw.Alignment.centerRight),
        ],
      ),
      ...invoice.items.asMap().entries.map((e) {
        final it = e.value;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
          ),
          children: [
            _td(it.name, pw.Alignment.centerLeft),
            _td('${it.quantity}', pw.Alignment.center),
            _td('$_currency${it.price.toStringAsFixed(2)}', pw.Alignment.centerRight),
            _td('$_currency${it.total.toStringAsFixed(2)}', pw.Alignment.centerRight,
                bold: true),
          ],
        );
      }),
    ];

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FlexColumnWidth(1.6),
        3: const pw.FlexColumnWidth(1.8),
      },
      children: rows,
    );
  }

  pw.Widget _th(String text, pw.Alignment align) => pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: pw.Text(text,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
              letterSpacing: 0.6,
            )),
      );

  pw.Widget _td(String text, pw.Alignment align, {bool bold = false}) =>
      pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 11,
            color: _ink,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  // ───────────────────────── Total ─────────────────────────
  pw.Widget _total() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: pw.BoxDecoration(
            color: _totalBg,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Text(
                '$_currency${invoice.total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Footer ─────────────────────────
  pw.Widget _footer() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
      ),
      child: pw.Column(
        children: [
          pw.Text('Thank you for your business!',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              )),
          pw.SizedBox(height: 3),
          pw.Text('Generated by InovXA',
              style: const pw.TextStyle(fontSize: 9, color: _muted)),
        ],
      ),
    );
  }
}
