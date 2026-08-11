import 'package:flutter/material.dart';

class MySpotsScreen extends StatelessWidget {
  const MySpotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis spots')),
      body: const Center(child: Text('Mis spots (próximamente)')),
    );
  }
}
