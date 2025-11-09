import 'package:flutter/material.dart';
import '../core/routes.dart';

class StartButton extends StatelessWidget {
  const StartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.navigation),
      label: const Text('Navigate to CCA Campus Map'),
      onPressed: () => Navigator.pushNamed(context, AppRoutes.mapSelection),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
