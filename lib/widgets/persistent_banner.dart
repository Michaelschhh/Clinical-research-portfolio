import 'package:flutter/material.dart';

class PersistentBanner extends StatelessWidget {
  const PersistentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade900,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: const Text(
        "Demo Environment — Not validated for clinical use. PHI must not be entered.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
