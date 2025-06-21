import 'package:flutter/material.dart';

class FarewellScreen extends StatelessWidget {
  const FarewellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Goodbye")),
      body: const Center(
        child: Text(
          "¡Gracias por usar la app! 👋",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
