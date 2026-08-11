import 'package:flutter/material.dart';

class CreateSpotScreen extends StatelessWidget {
  const CreateSpotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo spot')),
      body: const Center(child: Text('Crear spot (próximamente)')),
    );
  }
}
