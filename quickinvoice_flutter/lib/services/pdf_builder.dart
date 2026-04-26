import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';

/// Brand palette
const _navy = PdfColor.fromInt(0xFF0E1F4D);
const _accent = PdfColor.fromInt(0xFF1F6FEB);
const _accentSoft = PdfColor.fromInt(0xFFEFF4FF);
const _ink = PdfColor.fromInt(0xFF0F172A);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _line = PdfColor.fromInt(0xFFE5E7EB);

class PdfBuilder {
  final Invoice invoice;
  final pw.MemoryImage? logo;
  late final String _dateStr;
  late final String _dueDateStr;
  late final String _currency;

  PdfBuilder(this.invoice, this.logo) {
    _dateStr = DateFormat('dd MMM yyyy').format(invoice.date);
    _dueDateStr = DateFormat('dd MMM yyyy')
        .format(invoice.date.add(const Duration(days: 14)));
    _currency = invoice.currency.trim().isEmpty ? '' : '${invoice.currency} ';
  }

  Future<Uint8List> build() async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 0),
        build: (_) => [
          _topRow(),
          pw.SizedBox(height: 22),
          _billToRow(),
          pw.SizedBox(height: 18),
          _itemsTable(),
          pw.SizedBox(height: 14),
          _summaryRow(),
        ],
        footer: (_) => _footer(),
      ),
    );

    return doc.save();
  }

  // ─────────────── Header (logo+business  |  INVOICE+meta) ───────────────
  pw.Widget _topRow() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // LEFT
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null)
                    pw.Container(
                      width: 56,
                      height: 56,
                      margin: const pw.EdgeInsets.only(right: 12),
                      child: pw.Image(logo!, fit: pw.BoxFit.contain),
                    ),
                  pw.Expanded(
                    child: pw.Text(
                      (invoice.businessName.isEmpty
                              ? 'INOVXA'
                              : invoice.businessName)
                          .toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              if (invoice.businessAddress.isNotEmpty)
                _iconLine('PIN', invoice.businessAddress),
              if (invoice.businessPhone.isNotEmpty)
                _iconLine('TEL', invoice.businessPhone),
              if (invoice.businessEmail.isNotEmpty)
                _iconLine('AT', invoice.businessEmail),
              if (invoice.businessAbn.isNotEmpty)
                _iconLine('ID', 'ABN: ${invoice.businessAbn}'),
            ],
          ),
        ),
        // Vertical divider
        pw.Container(
          width: 0.6,
          height: 170,
          color: _line,
          margin: const pw.EdgeInsets.symmetric(horizontal: 18),
        ),
        // RIGHT
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('INVOICE',
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy,
                    letterSpacing: 2,
                  )),
              pw.SizedBox(height: 14),
              _metaRow('INVOICE #', invoice.invoiceNumber),
              pw.SizedBox(height: 10),
              _metaRow('DATE', _dateStr),
              pw.SizedBox(height: 10),
              _metaRow('DUE DATE', _dueDateStr),
            ],
          ),
        ),
      ],
    );
  }

  /// Small navy circle marker + label/value
  pw.Widget _iconLine(String _, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _bullet(),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(text,
                style: const pw.TextStyle(fontSize: 10.5, color: _ink)),
          ),
        ],
      ),
    );
  }

  pw.Widget _metaRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _bullet(),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 9,
                    color: _accent,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8)),
            pw.SizedBox(height: 2),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink)),
          ],
        ),
      ],
    );
  }

  pw.Widget _bullet() => pw.Container(
        width: 18,
        height: 18,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: _accent, width: 1.4),
        ),
        child: pw.Center(
          child: pw.Container(
            width: 6,
            height: 6,
            decoration: const pw.BoxDecoration(
                color: _accent, shape: pw.BoxShape.circle),
          ),
        ),
      );

  // ─────────────── Bill To + Thank You row ───────────────
  pw.Widget _billToRow() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // BILL TO
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: const pw.BoxDecoration(color: _navy),
                child: pw.Text('BILL TO',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1.2,
                    )),
              ),
              pw.SizedBox(height: 10),
              pw.Text(invoice.clientName,
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.clientAddress,
                  style: const pw.TextStyle(fontSize: 11, color: _ink)),
            ],
          ),
        ),
        pw.SizedBox(width: 18),
        // THANK YOU card
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _accentSoft,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('THANK YOU!',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _accent,
                        letterSpacing: 1)),
                pw.SizedBox(height: 6),
                pw.Text('Thank you for your business.',
                    style: const pw.TextStyle(fontSize: 10.5, color: _ink)),
                pw.Text('We appreciate your trust and support.',
                    style: const pw.TextStyle(fontSize: 10.5, color: _ink)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────── Items table ───────────────
  pw.Widget _itemsTable() {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _accent),
        children: [
          _th('#', pw.Alignment.center),
          _th('DESCRIPTION', pw.Alignment.centerLeft),
          _th('QTY', pw.Alignment.center),
          _th('UNIT PRICE', pw.Alignment.centerRight),
          _th('TOTAL', pw.Alignment.centerRight),
        ],
      ),
      ...invoice.items.asMap().entries.map((e) {
        final i = e.key;
        final it = e.value;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
          ),
          children: [
            _td('${i + 1}', pw.Alignment.center),
            _td(it.name, pw.Alignment.centerLeft, bold: true),
            _td('${it.quantity}', pw.Alignment.center),
            _td('$_currency${it.price.toStringAsFixed(2)}',
                pw.Alignment.centerRight),
            _td('$_currency${it.total.toStringAsFixed(2)}',
                pw.Alignment.centerRight, bold: true),
          ],
        );
      }),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _line)),
      child: pw.Table(
        columnWidths: {
          0: const pw.FixedColumnWidth(36),
          1: const pw.FlexColumnWidth(4),
          2: const pw.FixedColumnWidth(50),
          3: const pw.FlexColumnWidth(1.6),
          4: const pw.FlexColumnWidth(1.8),
        },
        children: rows,
      ),
    );
  }

  pw.Widget _th(String text, pw.Alignment align) => pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: pw.Text(text,
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 0.6,
            )),
      );

  pw.Widget _td(String text, pw.Alignment align, {bool bold = false}) =>
      pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 11,
            color: _ink,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  // ─────────────── Summary (payment info | subtotal/discount/tax/total) ───────────────
  pw.Widget _summaryRow() {
    final subtotal = invoice.total;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Payment info
        pw.Expanded(
          flex: 3,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _bullet(),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PAYMENT INFORMATION',
                          style: pw.TextStyle(
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _accent,
                              letterSpacing: 0.8)),
                      pw.SizedBox(height: 6),
                      pw.Text('Payment is due by $_dueDateStr.',
                          style: const pw.TextStyle(
                              fontSize: 10.5, color: _ink)),
                      pw.Text('Bank Transfer / Cash / Card Accepted.',
                          style: const pw.TextStyle(
                              fontSize: 10.5, color: _ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Totals stack
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            children: [
              _totalLine('SUBTOTAL',
                  '$_currency${subtotal.toStringAsFixed(2)}', divider: true),
              _totalLine('DISCOUNT',
                  '${_currency}0.00', divider: true),
              _totalLine('TAX (GST 0%)',
                  '${_currency}0.00', divider: true),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      decoration: const pw.BoxDecoration(color: _accentSoft),
                      child: pw.Text('TOTAL',
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: _accent,
                              letterSpacing: 1)),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      alignment: pw.Alignment.centerRight,
                      decoration: const pw.BoxDecoration(color: _navy),
                      child: pw.Text(
                          '$_currency${subtotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _totalLine(String label, String value, {bool divider = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: pw.BoxDecoration(
        border: divider
            ? pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5))
            : null,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink)),
          pw.Text(value,
              style: const pw.TextStyle(fontSize: 11, color: _ink)),
        ],
      ),
    );
  }

  // ─────────────── Footer ───────────────
  pw.Widget _footer() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _footerCell(
                    'CONNECT WITH US',
                    invoice.businessEmail.isNotEmpty
                        ? invoice.businessEmail
                        : 'www.inovxa.com.au'),
                _footerCell(
                    'NEED HELP?',
                    invoice.businessPhone.isNotEmpty
                        ? invoice.businessPhone
                        : '+61 432 123 456'),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Thank you!',
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontStyle: pw.FontStyle.italic,
                              color: _navy)),
                      pw.Text('We appreciate your business.',
                          style: const pw.TextStyle(
                              fontSize: 10, color: _muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            color: _navy,
            child: pw.Center(
              child: pw.Text(
                'Generated by InovXA  •  Invoices Made Simple',
                style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                    letterSpacing: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _footerCell(String label, String value) {
    return pw.Expanded(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _bullet(),
          pw.SizedBox(width: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _accent,
                      letterSpacing: 0.6)),
              pw.SizedBox(height: 2),
              pw.Text(value,
                  style: const pw.TextStyle(fontSize: 10, color: _ink)),
            ],
          ),
        ],
      ),
    );
  }
}
