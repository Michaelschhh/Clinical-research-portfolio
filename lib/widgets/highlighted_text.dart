import 'package:flutter/material.dart';
import '../constants/theme.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final List<dynamic> flags;

  const HighlightedText({super.key, required this.text, required this.flags});

  Color _getColor(String colorCode) {
    switch (colorCode.toLowerCase()) {
      case 'red': return AppTheme.flagRed;
      case 'orange': return AppTheme.flagOrange;
      case 'yellow': return AppTheme.flagYellow;
      case 'blue': return AppTheme.flagBlue;
      default: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 16, height: 1.5));
    }

    List<TextSpan> spans = [];
    int currentIndex = 0;

    // Create a copy of flags and sort them by appearance in text
    final sortedFlags = List.from(flags);
    sortedFlags.sort((a, b) {
      final indexA = text.indexOf(a['text_snippet'] ?? '');
      final indexB = text.indexOf(b['text_snippet'] ?? '');
      return indexA.compareTo(indexB);
    });

    for (var flag in sortedFlags) {
      final String snippet = flag['text_snippet']?.toString() ?? '';
      if (snippet.isEmpty) continue;

      final startIndex = text.indexOf(snippet, currentIndex);
      if (startIndex != -1) {
        // Add unhighlighted text before the snippet
        if (startIndex > currentIndex) {
          spans.add(TextSpan(text: text.substring(currentIndex, startIndex)));
        }

        // Add highlighted text
        spans.add(
          TextSpan(
            text: snippet,
            style: TextStyle(
              backgroundColor: _getColor(flag['color_code'] ?? '').withOpacity(0.3),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: _getColor(flag['color_code'] ?? ''),
              decorationStyle: TextDecorationStyle.wavy,
            ),
          ),
        );

        currentIndex = startIndex + snippet.length;
      }
    }

    // Add remaining unhighlighted text
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
        children: spans,
      ),
    );
  }
}
