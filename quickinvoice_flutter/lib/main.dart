import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/invoice_form_screen.dart';
import 'services/billing_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fast path: load the cached Pro flag from SharedPreferences (~ms) so the
  // first frame already reflects the correct entitlement.
  await BillingService.instance.warmCache();
  // Slow path: connect to Google Play, query products, restore purchases —
  // runs in the background so the UI is not blocked on app start.
  unawaited(BillingService.instance.initialize());
  runApp(const InovXAApp());
}

class InovXAApp extends StatelessWidget {
  const InovXAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InovXA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const InvoiceFormScreen(),
    );
  }
}
