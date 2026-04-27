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

/// Material Icons codepoints
const _icPin = 0xe0c8; // location_on
const _icPhone = 0xe0cd; // phone
const _icMail = 0xe0be; // email
const _icBadge = 0xe873; // description
const _icDoc = 0xe873; // description (invoice #)
const _icCal = 0xe935; // calendar_today
const _icClock = 0xe8b5; // schedule
const _icPerson = 0xe7fd; // person
const _icQuote = 0xe244; // format_quote
const _icCard = 0xe870; // credit_card
const _icWorld = 0xe80b; // public

class PdfBuilder {
  final Invoice invoice;
  final pw.MemoryImage? logo;
  final pw.Font? iconFont;
  late final String _dateStr;
  late final String _dueDateStr;
  late final String _currency;

  PdfBuilder(this.invoice, this.logo, [this.iconFont]) {
    _dateStr = DateFormat('dd MMM yyyy').format(invoice.date);
    _dueDateStr = DateFormat('dd MMM yyyy')
        .format(invoice.date.add(const Duration(days: 14)));
    _currency = invoice.currency.trim().isEmpty ? '' : '${invoice.currency} ';
  }

  Future<Uint8List> build() async {
    final doc = pw.Document(
      theme: pw.ThemeData.base().copyWith(
        iconTheme: iconFont != null
            ? pw.IconThemeData(font: iconFont, color: _accent, size: 12)
            : null,
      ),
    );

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

  // ─────────────── Header ───────────────
  pw.Widget _topRow() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
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
                      width: 64,
                      height: 64,
                      margin: const pw.EdgeInsets.only(right: 14),
                      child: pw.Image(logo!, fit: pw.BoxFit.contain),
                    ),
                  pw.Expanded(
                    child: pw.Text(
                      (invoice.businessName.isEmpty
                              ? 'INOVXA'
                              : invoice.businessName)
                          .toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 27,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              if (invoice.businessAddress.isNotEmpty)
                _iconLine(_icPin, invoice.businessAddress, multiline: true),
              if (invoice.businessPhone.isNotEmpty)
                _iconLine(_icPhone, invoice.businessPhone),
              if (invoice.businessEmail.isNotEmpty)
                _iconLine(_icMail, invoice.businessEmail),
              if (invoice.businessAbn.isNotEmpty)
                _iconLine(_icBadge, 'ABN: ${invoice.businessAbn}'),
            ],
          ),
        ),
        pw.Container(
          width: 0.6,
          height: 180,
          color: _line,
          margin: const pw.EdgeInsets.symmetric(horizontal: 18),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('INVOICE',
                  style: pw.TextStyle(
                    fontSize: 38,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy,
                    letterSpacing: 2,
                  )),
              pw.SizedBox(height: 14),
              _metaRow(_icDoc, 'INVOICE #', invoice.invoiceNumber),
              pw.SizedBox(height: 10),
              _metaRow(_icCal, 'DATE', _dateStr),
              pw.SizedBox(height: 10),
              _metaRow(_icClock, 'DUE DATE', _dueDateStr),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _iconLine(int codepoint, String text, {bool multiline = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _iconCircle(codepoint),
          pw.SizedBox(width: 9),
          pw.Expanded(
            child: pw.Text(
              text,
              softWrap: true,
              maxLines: multiline ? 4 : 2,
              style: const pw.TextStyle(
                  fontSize: 11, color: _ink, lineSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _metaRow(int codepoint, String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _iconCircle(codepoint, size: 22, glyph: 13),
        pw.SizedBox(width: 11),
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

  pw.Widget _iconCircle(int codepoint, {double size = 18, double glyph = 11}) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _accent, width: 1.2),
      ),
      child: pw.Center(
        child: iconFont != null
            ? pw.Icon(pw.IconData(codepoint),
                size: glyph, color: _accent)
            : pw.Container(
                width: 5,
                height: 5,
                decoration: const pw.BoxDecoration(
                    color: _accent, shape: pw.BoxShape.circle)),
      ),
    );
  }

  // ─────────────── Bill To row ───────────────
  pw.Widget _billToRow() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: const pw.BoxDecoration(color: _navy),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    _iconCircle(_icPerson, size: 16, glyph: 10),
                    pw.SizedBox(width: 8),
                    pw.Text('BILL TO',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 1.2,
                        )),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(invoice.clientName,
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.clientAddress,
                  softWrap: true,
                  style: const pw.TextStyle(
                      fontSize: 11, color: _ink, lineSpacing: 2)),
            ],
          ),
        ),
        pw.SizedBox(width: 18),
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _accentSoft,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _iconCircle(_icQuote, size: 22, glyph: 13),
                pw.SizedBox(width: 10),
                pw.Expanded(
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
                          style: const pw.TextStyle(
                              fontSize: 10.5, color: _ink)),
                      pw.Text('We appreciate your trust and support.',
                          style: const pw.TextStyle(
                              fontSize: 10.5, color: _ink)),
                    ],
                  ),
                ),
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

  // ─────────────── Summary row ───────────────
  pw.Widget _summaryRow() {
    final subtotal = invoice.total;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _iconCircle(_icCard, size: 22, glyph: 13),
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
    final hasEmail = invoice.businessEmail.trim().isNotEmpty;
    final hasPhone = invoice.businessPhone.trim().isNotEmpty;

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
                _footerCell(_icMail, 'CONNECT WITH US',
                    hasEmail ? invoice.businessEmail : '—'),
                _footerCell(_icPhone, 'NEED HELP?',
                    hasPhone ? invoice.businessPhone : '—'),
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
                'Generated by InovXA  -  Invoices Made Simple',
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

  pw.Widget _footerCell(int codepoint, String label, String value) {
    return pw.Expanded(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _iconCircle(codepoint, size: 22, glyph: 13),
          pw.SizedBox(width: 9),
          pw.Expanded(
            child: pw.Column(
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
          ),
        ],
      ),
    );
  }
}
