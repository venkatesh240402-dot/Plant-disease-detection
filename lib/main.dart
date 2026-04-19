import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: AgroScanApp()));
}

class AgroScanApp extends StatelessWidget {
  const AgroScanApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroScan',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const Scaffold(body: Center(child: Text('AgroScan Loaded'))),
    );
  }
}
