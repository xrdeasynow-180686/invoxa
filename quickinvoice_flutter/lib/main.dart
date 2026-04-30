import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/billing_service.dart';
import 'services/invoice_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BillingService.instance.warmCache();
  unawaited(BillingService.instance.initialize());
  final store = InvoiceStore();
  await store.bootstrap();
  runApp(InovXAApp(store: store));
}

class InovXAApp extends StatelessWidget {
  final InvoiceStore store;
  const InovXAApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: Consumer<InvoiceStore>(
        builder: (_, s, __) => MaterialApp(
          title: 'InovXA',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: s.themeMode,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
