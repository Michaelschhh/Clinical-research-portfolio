import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/theme.dart';

class LoadingSpinnerOverlay extends StatelessWidget {
  const LoadingSpinnerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black26,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.glassPanel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.flagBlue),
                    const SizedBox(height: 16),
                    const Text('Analyzing Document...').animate().fadeIn().shimmer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
