import 'package:flutter/material.dart';

class AdminPendingScreen extends StatelessWidget {
  const AdminPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pendientes')),
      body: const Center(child: Text('Admin (próximamente)')),
    );
  }
}
