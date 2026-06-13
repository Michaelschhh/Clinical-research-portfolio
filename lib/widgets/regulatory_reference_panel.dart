import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../constants/regulatory_data.dart';
import '../constants/theme.dart';
import 'glass_container.dart';

class RegulatoryReferencePanel extends StatelessWidget {
  const RegulatoryReferencePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Regulatory Reference Data — Simulated / Educational Only',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Gap(8),
          const Text('Reference only — verify at eur-lex.europa.eu for current status.', style: TextStyle(color: Colors.white70)),
          const Gap(24),
          const Text('GDPR Adequacy Decisions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.flagBlue)),
          const Gap(16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: RegulatoryData.gdprStatus.map((status) {
              return SizedBox(
                width: 300,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status['destination']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Gap(8),
                      Text('Status: ${status['status']}', style: TextStyle(color: status['status']!.contains('Adequate') ? Colors.greenAccent : Colors.orangeAccent)),
                      const Gap(4),
                      Text(status['notes']!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(32),
          const Text('ICH-GCP E6(R3) Key Principles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.flagBlue)),
          const Gap(16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: RegulatoryData.ichGcpPrinciples.map((principle) {
              return SizedBox(
                width: 300,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(principle['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Gap(8),
                      Text(principle['description']!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(32),
          Text('Last Updated: ${RegulatoryData.lastUpdated}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
