import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../constants/theme.dart';
import 'glass_container.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final String apiKey;
  final ValueChanged<String> onApiKeyChanged;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.apiKey,
    required this.onApiKeyChanged,
  });

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.flagBlue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.flagBlue.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.flagBlue : Colors.white70),
            const Gap(12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_circle, color: AppTheme.flagBlue, size: 32),
                    const Gap(12),
                    const Text(
                      'Overcast Engine',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const Gap(48),
                const Text('ANALYSIS HUBS', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                const Gap(16),
                _buildTab(0, 'Protocol Hub', Icons.science),
                const Gap(8),
                _buildTab(1, 'Source Text Auditor', Icons.plagiarism),
                const Gap(8),
                _buildTab(2, 'Unstructured Formatter', Icons.table_chart),
                const Gap(8),
                _buildTab(3, 'Spreadsheet Validator', Icons.analytics),
                const Gap(32),
                const Text('REFERENCE', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                const Gap(16),
                _buildTab(4, 'Regulatory Panel', Icons.gavel),
                const Gap(8),
                _buildTab(5, 'Test Documents', Icons.folder_special),
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(32),
                const Divider(color: Colors.white24),
                const Gap(16),
                const Text('SETTINGS', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                const Gap(16),
                TextField(
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'OpenRouter API Key',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.key, color: Colors.white54, size: 20),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: TextEditingController(text: apiKey)..selection = TextSelection.collapsed(offset: apiKey.length),
                  onChanged: onApiKeyChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
