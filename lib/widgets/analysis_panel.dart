import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../constants/theme.dart';
import 'glass_container.dart';

class AnalysisPanel extends StatelessWidget {
  final List<dynamic> flags;
  final bool isFormatter;
  final dynamic formatterData;
  final void Function(dynamic)? onFlagTap;

  const AnalysisPanel({super.key, required this.flags, this.isFormatter = false, this.formatterData, this.onFlagTap});

  Color _getColor(String colorCode) {
    switch (colorCode.toLowerCase()) {
      case 'red': return AppTheme.flagRed;
      case 'orange': return AppTheme.flagOrange;
      case 'yellow': return AppTheme.flagYellow;
      case 'blue': return AppTheme.flagBlue;
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isFormatter) {
      if (formatterData == null) {
        return const Center(
          child: Text(
            "Upload a document and click 'Analyze Document'\nto generate a structured table.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      try {
        final rawColumns = formatterData['columns'] ?? formatterData['headers'] ?? formatterData['keys'] ?? [];
        final rawRows = formatterData['rows'] ?? formatterData['data'] ?? formatterData['values'] ?? [];

        final columns = (rawColumns as List).map((e) => e.toString()).toList();
        final rows = (rawRows as List).map((r) => (r as List).toList()).toList();

        if (columns.isEmpty) return const Center(child: Text("No columns found in AI response.", style: TextStyle(color: Colors.white70)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Extracted Structured Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Gap(16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.flagBlue)))).toList(),
                    rows: rows.map((r) {
                      List<dynamic> safeRow = List.from(r);
                      if (safeRow.length > columns.length) {
                        safeRow = safeRow.sublist(0, columns.length);
                      } else while (safeRow.length < columns.length) {
                        safeRow.add("");
                      }
                      return DataRow(
                        cells: safeRow.map((c) => DataCell(Text(c.toString(), style: const TextStyle(color: Colors.white)))).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      } catch (e) {
        return Center(
          child: Text(
            "Error parsing structured data: $e\n\nRaw Data: $formatterData",
            style: const TextStyle(color: Colors.redAccent),
          ),
        );
      }
    }

    if (flags.isEmpty) {
      return const Center(
        child: Text(
          "No flags identified. Review input or adjust the prompt.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analysis Key & Explanations',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Gap(16),
        Expanded(
          child: ListView.builder(
            itemCount: flags.length,
            itemBuilder: (context, index) {
              final flag = flags[index];
              final color = _getColor(flag['color_code'] ?? '');
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () {
                    if (onFlagTap != null) onFlagTap!(flag);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              "AI-${index + 1} - ${flag['flag_type'] ?? 'Unknown Flag'}",
                              style: TextStyle(color: color, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        flag['rationale'] ?? 'No rationale provided.',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      if (flag['text_snippet'] != null) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "AI Snippet Match:",
                                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const Gap(4),
                              Text(
                                '"${flag['text_snippet']}"',
                                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (flag['contradiction_reference'] != null) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.5), style: BorderStyle.solid),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                                  const Gap(6),
                                  Text(
                                    "Contradicts With:",
                                    style: TextStyle(color: Colors.redAccent.shade100, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Gap(6),
                              Text(
                                flag['contradiction_reference'].toString(),
                                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (flag['start_line'] != null && flag['end_line'] != null) ...[
                        const Gap(4),
                        Text(
                          "Found near Lines ${flag['start_line']} - ${flag['end_line']}",
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
          ),
        ),
      ],
    );
  }
}
