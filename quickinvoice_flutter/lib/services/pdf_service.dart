import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';
import 'usage_storage.dart';

/// Brand palette — mutable so it can be themed at runtime per the user's
/// stored colour choice (set on the Paywall/Pro screen).
PdfColor _navy = const PdfColor.fromInt(0xFF0E1F4D);
PdfColor _accent = const PdfColor.fromInt(0xFF1F6FEB);
PdfColor _accentSoft = const PdfColor.fromInt(0xFFEFF4FF);
const _ink = PdfColor.fromInt(0xFF0F172A);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _line = PdfColor.fromInt(0xFFE5E7EB);

/// Material Icons codepoints (matches Flutter's Icons.* values)
const _icPin = 0xe0c8; // location_on
const _icPhone = 0xe0cd; // phone
const _icMail = 0xe0be; // email
const _icDoc = 0xe873; // description
const _icCal = 0xe935; // calendar_today
const _icClock = 0xe8b5; // schedule
const _icPerson = 0xe7fd; // person
const _icQuote = 0xe244; // format_quote
const _icCard = 0xe870; // credit_card

/// All PDF generation lives here. No partial helpers in other files.
class PdfService {
  static const _defaultLogoAsset = 'assets/default_invoice_logo.png';
  static const _iconFontAsset = 'assets/fonts/MaterialIcons-Regular.ttf';

  // ───────────────────────── PUBLIC API ─────────────────────────

  /// Builds the invoice PDF and returns the raw bytes.
  /// Pulls every value (logo, business name, address, phone, email, ABN,
  /// client info, items, currency) from the [Invoice] passed in.
  /// If the user has not uploaded a logo, the bundled default brand logo is used.
  static Future<Uint8List> buildPdf(Invoice invoice) async {
    // Apply the user's stored colour choice (default = Ocean blue).
    final paletteIndex = await UsageStorage.getColorIndex();
    final p = (paletteIndex >= 0 && paletteIndex < kPalettes.length)
        ? kPalettes[paletteIndex]
        : kPalettes[0];
    _navy = PdfColor.fromInt(p.navy);
    _accent = PdfColor.fromInt(p.accent);
    _accentSoft = PdfColor.fromInt(p.accentSoft);

    final logo = await _resolveLogo(invoice.logoBytes);
    final iconFont = await _loadIconFont();
    final showWatermark = !UsageStorage.isPro();

    final doc = pw.Document(
      theme: pw.ThemeData.base().copyWith(
        iconTheme: iconFont != null
            ? pw.IconThemeData(font: iconFont, color: _accent, size: 12)
            : null,
      ),
    );

    final dateStr = DateFormat('dd MMM yyyy').format(invoice.date);
    final dueStr = DateFormat('dd MMM yyyy')
        .format(invoice.date.add(Duration(days: invoice.dueDays)));
    final cur =
        invoice.currency.trim().isEmpty ? '' : '${invoice.currency.trim()} ';

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 0),
          buildBackground:
              showWatermark ? (context) => _buildWatermark() : null,
        ),
        build: (_) => [
          _header(invoice, logo, dateStr, dueStr, iconFont != null),
          pw.SizedBox(height: 22),
          _billToRow(invoice, iconFont != null),
          pw.SizedBox(height: 18),
          _itemsTable(invoice, cur),
          pw.SizedBox(height: 14),
          _summaryRow(invoice, cur, dueStr, iconFont != null),
        ],
        footer: (_) => _footer(invoice, iconFont != null),
      ),
    );

    return doc.save();
  }

  /// Diagonal "InovXA FREE" watermark — only applied when the user is NOT
  /// Pro. Removed automatically as soon as entitlement flips to Pro.
  static pw.Widget _buildWatermark() {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: -0.6,
          child: pw.Opacity(
            opacity: 0.14,
            child: pw.Text(
              'InovXA  FREE',
              style: pw.TextStyle(
                fontSize: 110,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ),
      ),
    );
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
      final publicDownloads = Directory('/storage/emulated/0/Download');
      try {
        if (!await publicDownloads.exists()) {
          await publicDownloads.create(recursive: true);
        }
        final probe = File('${publicDownloads.path}/.inovxa_probe');
        await probe.writeAsBytes(<int>[], flush: true);
        await probe.delete();
        targetDir = publicDownloads;
      } catch (_) {
        targetDir = null;
      }
    }

    targetDir ??= await getApplicationDocumentsDirectory();

    final file = File('${targetDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ───────────────────────── ASSET HELPERS ─────────────────────────

  static Future<pw.MemoryImage?> _resolveLogo(List<int>? userBytes) async {
    if (userBytes != null && userBytes.isNotEmpty) {
      return pw.MemoryImage(Uint8List.fromList(userBytes));
    }
    try {
      final bd = await rootBundle.load(_defaultLogoAsset);
      return pw.MemoryImage(bd.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<pw.Font?> _loadIconFont() async {
    try {
      final f = await rootBundle.load(_iconFontAsset);
      return pw.Font.ttf(f);
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────── HEADER ─────────────────────────

  static pw.Widget _header(Invoice invoice, pw.MemoryImage? logo,
      String dateStr, String dueStr, bool hasIcons) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // LEFT — logo, business name, contact stack
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
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                  pw.Expanded(
                    child: pw.Text(
                      (invoice.businessName.isEmpty
                              ? 'Your Business'
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
              if (invoice.businessAddress.trim().isNotEmpty)
                _iconLine(_icPin, invoice.businessAddress, hasIcons,
                    multiline: true),
              if (invoice.businessPhone.trim().isNotEmpty)
                _iconLine(_icPhone, invoice.businessPhone, hasIcons),
              if (invoice.businessEmail.trim().isNotEmpty)
                _iconLine(_icMail, invoice.businessEmail, hasIcons),
              if (invoice.businessAbn.trim().isNotEmpty)
                _iconLine(
                    _icDoc,
                    'Business / Tax Number:\n${invoice.businessAbn}',
                    hasIcons,
                    multiline: true),
            ],
          ),
        ),
        // Vertical divider
        pw.Container(
          width: 0.6,
          height: 180,
          color: _line,
          margin: const pw.EdgeInsets.symmetric(horizontal: 18),
        ),
        // RIGHT — INVOICE wordmark + meta
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 38,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 14),
              _metaRow(_icDoc, 'INVOICE #', invoice.invoiceNumber, hasIcons),
              pw.SizedBox(height: 10),
              _metaRow(_icCal, 'DATE', dateStr, hasIcons),
              pw.SizedBox(height: 10),
              _metaRow(_icClock, 'DUE DATE', dueStr, hasIcons),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _iconLine(int codepoint, String text, bool hasIcons,
      {bool multiline = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _iconCircle(codepoint, hasIcons),
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

  static pw.Widget _metaRow(
      int codepoint, String label, String value, bool hasIcons) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _iconCircle(codepoint, hasIcons, size: 22, glyph: 13),
        pw.SizedBox(width: 11),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: _accent,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _iconCircle(int codepoint, bool hasIcons,
      {double size = 18, double glyph = 11}) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _accent, width: 1.2),
      ),
      child: pw.Center(
        child: hasIcons
            ? pw.Icon(pw.IconData(codepoint), size: glyph, color: _accent)
            : pw.Container(
                width: 5,
                height: 5,
                decoration: pw.BoxDecoration(
                  color: _accent,
                  shape: pw.BoxShape.circle,
                ),
              ),
      ),
    );
  }

  // ───────────────────────── BILL TO ─────────────────────────

  static pw.Widget _billToRow(Invoice invoice, bool hasIcons) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(color: _navy),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    _iconCircle(_icPerson, hasIcons, size: 16, glyph: 10),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'BILL TO',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                invoice.clientName,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                invoice.clientAddress,
                softWrap: true,
                style: const pw.TextStyle(
                    fontSize: 11, color: _ink, lineSpacing: 2),
              ),
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
                _iconCircle(_icQuote, hasIcons, size: 22, glyph: 13),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'THANK YOU!',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _accent,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Thank you for your business.',
                        style:
                            const pw.TextStyle(fontSize: 10.5, color: _ink),
                      ),
                      pw.Text(
                        'We appreciate your trust and support.',
                        style:
                            const pw.TextStyle(fontSize: 10.5, color: _ink),
                      ),
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

  // ───────────────────────── ITEMS TABLE ─────────────────────────

  static pw.Widget _itemsTable(Invoice invoice, String cur) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _accent),
        children: [
          _th('#', pw.Alignment.center),
          _th('ITEM', pw.Alignment.centerLeft),
          _th('QTY', pw.Alignment.center),
          _th('PRICE', pw.Alignment.centerRight),
          _th('TOTAL', pw.Alignment.centerRight),
        ],
      ),
      ...invoice.items.asMap().entries.map((e) {
        final i = e.key;
        final it = e.value;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            border:
                pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
          ),
          children: [
            _td('${i + 1}', pw.Alignment.center),
            _td(it.name, pw.Alignment.centerLeft, bold: true),
            _td('${it.quantity}', pw.Alignment.center),
            _td('$cur${it.price.toStringAsFixed(2)}',
                pw.Alignment.centerRight),
            _td('$cur${it.total.toStringAsFixed(2)}',
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

  static pw.Widget _th(String text, pw.Alignment align) => pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 0.6,
          ),
        ),
      );

  static pw.Widget _td(String text, pw.Alignment align, {bool bold = false}) =>
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

  // ───────────────────────── SUMMARY ─────────────────────────

  static pw.Widget _summaryRow(
      Invoice invoice, String cur, String dueStr, bool hasIcons) {
    final subtotal = invoice.subtotal;
    final discount = invoice.discountAmount;
    final tax = invoice.taxAmount;
    final total = invoice.total;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Payment info (LEFT)
        pw.Expanded(
          flex: 3,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _iconCircle(_icCard, hasIcons, size: 22, glyph: 13),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PAYMENT INFORMATION',
                        style: pw.TextStyle(
                          fontSize: 10.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Payment is due by $dueStr.',
                        style:
                            const pw.TextStyle(fontSize: 10.5, color: _ink),
                      ),
                      pw.Text(
                        'Bank Transfer / Cash / Card Accepted.',
                        style:
                            const pw.TextStyle(fontSize: 10.5, color: _ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Totals stack (RIGHT, highlighted)
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            children: [
              _totalLine('SUBTOTAL', '$cur${subtotal.toStringAsFixed(2)}',
                  divider: true),
              _totalLine(
                  'DISCOUNT (${invoice.discountPercent.toStringAsFixed(0)}%)',
                  '-$cur${discount.toStringAsFixed(2)}',
                  divider: true),
              _totalLine(
                  'TAX (${invoice.taxPercent.toStringAsFixed(0)}%)',
                  '$cur${tax.toStringAsFixed(2)}',
                  divider: true),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      decoration: pw.BoxDecoration(color: _accentSoft),
                      child: pw.Text('TOTAL',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: _accent,
                            letterSpacing: 1,
                          )),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      alignment: pw.Alignment.centerRight,
                      decoration: pw.BoxDecoration(color: _navy),
                      child: pw.Text('$cur${total.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          )),
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

  static pw.Widget _totalLine(String label, String value,
      {bool divider = false}) {
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
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11, color: _ink),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── FOOTER ─────────────────────────

  static pw.Widget _footer(Invoice invoice, bool hasIcons) {
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
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Thank you for your business',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                    color: _navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Need help? Contact us:',
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _accent,
                    letterSpacing: 0.6,
                  ),
                ),
                pw.SizedBox(height: 4),
                if (hasPhone)
                  _footerLine(_icPhone, invoice.businessPhone, hasIcons),
                if (hasEmail)
                  _footerLine(_icMail, invoice.businessEmail, hasIcons),
                if (!hasPhone && !hasEmail)
                  pw.Text(
                    'No contact details provided.',
                    style:
                        const pw.TextStyle(fontSize: 10, color: _muted),
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
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footerLine(int codepoint, String value, bool hasIcons) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _iconCircle(codepoint, hasIcons, size: 18, glyph: 11),
          pw.SizedBox(width: 8),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10.5, color: _ink),
          ),
        ],
      ),
    );
  }
}
