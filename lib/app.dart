import 'package:flutter/material.dart';

class VaultlyApp extends StatelessWidget {
  const VaultlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vaultly',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Vaultly'),
        ),
      ),
    );
  }
}