import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'dart:html' as html;
import '../constants/theme.dart';
import 'glass_container.dart';

class TestDocumentsPanel extends StatelessWidget {
  const TestDocumentsPanel({super.key});

  void _downloadFile(String filename) {
    html.AnchorElement(href: 'test_documents/$filename')
      ..setAttribute('download', filename)
      ..click();
  }

  Widget _buildSection(String title, IconData icon, List<String> filenames) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.flagBlue, size: 24),
            const Gap(8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const Gap(16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: filenames.map((filename) {
            String displayName = filename.replaceAll('_', ' ').replaceAll('.pdf', '');
            if (displayName.length > 50) {
               displayName = '${displayName.substring(0, 47)}...';
            }
            return SizedBox(
              width: 300,
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 32),
                    const Gap(12),
                    SizedBox(
                      height: 40,
                      child: Text(
                        displayName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap(16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadFile(filename),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.flagBlue.withValues(alpha: 0.2),
                          foregroundColor: AppTheme.flagBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Documents',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Gap(16),
          const Text(
            'Use these sample clinical documents to test the capabilities of the Overcast Engine. Download a file, then upload it into the corresponding analysis hub.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const Gap(40),
          _buildSection('Protocol Hub', Icons.science, [
            '01_Protocol_Hub_ZENITH001_Protocol_v2.3.pdf',
            '02_Protocol_Hub_AURORA77_Investigators_Brochure.pdf',
          ]),
          const Gap(32),
          _buildSection('Source Text Auditor', Icons.plagiarism, [
            '03_Source_Auditor_PhysicianNote_Visit4_Fitzgerald.pdf',
            '04_Source_Auditor_Discharge_Summary_Whitmore.pdf',
          ]),
          const Gap(32),
          _buildSection('Unstructured Formatter', Icons.table_chart, [
            '05_Formatter_Ward_Round_Notes_Day14.pdf',
            '06_Formatter_Site_Visit_Narrative_Week8.pdf',
          ]),
          const Gap(32),
          _buildSection('Spreadsheet Validator', Icons.analytics, [
            '07_Validator_Subject_Data_Listing_Week12.pdf',
            '08_Validator_AE_Lab_Safety_Log_AllSites.pdf',
          ]),
          const Gap(40),
        ],
      ),
    );
  }
}
