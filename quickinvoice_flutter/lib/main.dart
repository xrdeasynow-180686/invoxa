import 'package:flutter/material.dart';

import 'screens/invoice_form_screen.dart';

void main() {
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
