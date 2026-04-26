import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';
import 'pdf_builder.dart';

class PdfService {
  static const _defaultLogoAsset = 'assets/default_invoice_logo.png';

  /// Builds the invoice PDF and returns the raw bytes.
  /// If the user did not upload a logo, the bundled default brand logo is used.
  static Future<Uint8List> buildPdf(Invoice invoice) async {
    pw.MemoryImage? logo;
    final userBytes = invoice.logoBytes;
    if (userBytes != null && userBytes.isNotEmpty) {
      logo = pw.MemoryImage(Uint8List.fromList(userBytes));
    } else {
      try {
        final bd = await rootBundle.load(_defaultLogoAsset);
        logo = pw.MemoryImage(bd.buffer.asUint8List());
      } catch (_) {
        logo = null;
      }
    }
    return PdfBuilder(invoice, logo).build();
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
}
