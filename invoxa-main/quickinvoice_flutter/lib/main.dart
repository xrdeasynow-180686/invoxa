import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/invoice_history_screen.dart';
import 'services/analytics_service.dart';
import 'services/billing_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — wrapped in try/catch so the app still boots on dev
  // machines that haven't added google-services.json yet. Analytics
  // becomes a no-op until Firebase is configured.
  try {
    await Firebase.initializeApp();
    AnalyticsService.enable();
    unawaited(AnalyticsService.logAppOpen());
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[main] Firebase not initialised — analytics disabled: $e');
    }
  }

  // Fast path: load the cached Pro flag from SharedPreferences (~ms) so
  // the first frame already reflects the last-known entitlement.
  await BillingService.instance.warmCache();
  // Slow path: connect to Google Play, query products, restore purchases —
  // runs in the background so the UI is not blocked on app start.
  unawaited(BillingService.instance.initialize());

  runApp(const InovXAApp());
}

class InovXAApp extends StatelessWidget {
  const InovXAApp({super.key});

  // Stronger, sunlight-friendly indigo.
  static const _seed = Color(0xFF1D2D8C);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InovXA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          primary: _seed,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        textTheme: const TextTheme().apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const InvoiceHistoryScreen(),
    );
  }
}
