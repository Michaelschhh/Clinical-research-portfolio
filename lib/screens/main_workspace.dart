import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../constants/theme.dart';
import '../constants/prompts.dart';
import '../services/openrouter_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/document_viewer.dart';
import '../widgets/analysis_panel.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/persistent_banner.dart';
import '../widgets/regulatory_reference_panel.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:html' as html;
import 'dart:convert';

class MainWorkspace extends StatefulWidget {
  const MainWorkspace({super.key});

  @override
  State<MainWorkspace> createState() => _MainWorkspaceState();
}

class _MainWorkspaceState extends State<MainWorkspace> {
  int _selectedTab = 0;
  String _apiKey = '';
  String _documentText = '';
  Uint8List? _originalPdfBytes;
  Uint8List? _displayPdfBytes;
  bool _isLoading = false;
  List<dynamic> _flags = [];
  dynamic _formatterData;
  List<dynamic> _pdfLines = [];
  final OpenRouterService _apiService = OpenRouterService();
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await _apiService.getApiKey();
    if (key != null) {
      setState(() => _apiKey = key);
    }
  }

  void _onApiKeyChanged(String value) {
    setState(() => _apiKey = value);
    _apiService.saveApiKey(value);
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTab = index;
      _flags = [];
      _formatterData = null;
    });
  }

  String _getSystemPromptForTab() {
    switch (_selectedTab) {
      case 0: return AppPrompts.protocolHubPrompt;
      case 1: return AppPrompts.sourceTextAuditorPrompt;
      case 2: return AppPrompts.unstructuredFormatterPrompt;
      case 3: return AppPrompts.spreadsheetValidatorPrompt;
      default: return '';
    }
  }

  PdfColor _getPdfColor(String colorCode) {
    switch (colorCode.toLowerCase()) {
      case 'red': return PdfColor(255, 0, 0); // Pure Red
      case 'orange': return PdfColor(255, 128, 0); // Vivid Orange
      case 'yellow': return PdfColor(255, 255, 0); // Pure Yellow
      case 'blue': return PdfColor(0, 191, 255); // Deep Sky Blue
      default: return PdfColor(255, 255, 255);
    }
  }

  Future<void> _analyzeDocument() async {
    if (_documentText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or upload text/PDF to analyze.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _flags = [];
      _formatterData = null;
      // Reset PDF to original before annotating
      if (_originalPdfBytes != null) {
        _displayPdfBytes = _originalPdfBytes;
      }
    });

    try {
      final isFormatter = _selectedTab == 2;
      final result = await _apiService.analyzeText(
        _getSystemPromptForTab(),
        _documentText,
        isFormatter: isFormatter,
      );

      setState(() {
        if (isFormatter) {
          _formatterData = result;
        } else {
          _flags = result as List<dynamic>;
        }
      });

      if (!isFormatter && _originalPdfBytes != null && _flags.isNotEmpty) {
        _annotatePdfWithFlags();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.flagRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _annotatePdfWithFlags() {
    if (_originalPdfBytes == null) return;
    try {
      final PdfDocument document = PdfDocument(inputBytes: _originalPdfBytes!);

      final PdfTextExtractor extractor = PdfTextExtractor(document);
      Map<int, List<Rect>> drawnBadges = {};

      for (int i = 0; i < _flags.length; i++) {
        var flag = _flags[i];
        final id = i + 1;
        final colorCode = flag['color_code']?.toString() ?? '';
        final int startLine = flag['start_line'] != null ? int.tryParse(flag['start_line'].toString()) ?? -1 : -1;
        final int endLine = flag['end_line'] != null ? int.tryParse(flag['end_line'].toString()) ?? -1 : -1;
        final String snippet = flag['text_snippet']?.toString() ?? '';
        
        final pdfColor = _getPdfColor(colorCode);
        
        bool foundMatch = false;
        
        // 1. Try Line-Based Coordination First
        if (startLine >= 1 && endLine >= startLine) {
            bool isFirstMatch = true;
            for (int lineIdx = startLine - 1; lineIdx < endLine && lineIdx < _pdfLines.length; lineIdx++) {
                final line = _pdfLines[lineIdx];
                final int pageIndex = line.pageIndex;
                final Rect bounds = line.bounds;
                
                if (bounds.isEmpty || bounds.width <= 0 || bounds.height <= 0) continue;
                
                foundMatch = true;

                final PdfPage page = document.pages[pageIndex];
                if (isFirstMatch && !flag.containsKey('page_index')) {
                  flag['page_index'] = pageIndex;
                  flag['bounds_top'] = bounds.top;
                  flag['bounds_left'] = bounds.left;
                }
                
                final PdfTextMarkupAnnotation annotation = PdfTextMarkupAnnotation(
                  bounds,
                  "Found Flag #$id",
                  pdfColor,
                );
                annotation.textMarkupAnnotationType = PdfTextMarkupAnnotationType.highlight;
                annotation.author = "Overcast AI";
                annotation.subject = flag['flag_type'] ?? 'Analysis';
                annotation.text = flag['rationale'] ?? '';
                page.annotations.add(annotation);
                
                if (isFirstMatch) {
                  double badgeX = bounds.left;
                  double badgeY = bounds.top - 15;
                  if (badgeY < 0) badgeY = bounds.top + bounds.height + 2;
                  
                  // Check for overlaps with previously drawn badges on this page
                  drawnBadges.putIfAbsent(pageIndex, () => []);
                  Rect badgeRect = Rect.fromLTWH(badgeX, badgeY, 35, 15);
                  
                  bool overlaps = true;
                  while (overlaps) {
                    overlaps = false;
                    for (final drawn in drawnBadges[pageIndex]!) {
                      if (badgeRect.overlaps(drawn)) {
                        overlaps = true;
                        // Shift it right to avoid overlapping
                        badgeRect = badgeRect.translate(badgeRect.width + 5, 0);
                        break;
                      }
                    }
                  }
                  
                  drawnBadges[pageIndex]!.add(badgeRect);
                  
                  page.graphics.drawRectangle(brush: PdfSolidBrush(pdfColor), bounds: badgeRect);
                  page.graphics.drawString(
                    "AI-$id",
                    PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                    brush: PdfSolidBrush(PdfColor(255, 255, 255)),
                    bounds: badgeRect,
                    format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
                  );
                  isFirstMatch = false;
                }
            }
        }
        
        // 2. Fallback to Fuzzy Text Matching if AI hallucinated lines or lines were empty
        if (!foundMatch && snippet.isNotEmpty) {
           var matches = extractor.findText([snippet]);
           if (matches.isEmpty) {
              final cleanSnippet = snippet.replaceAll(RegExp(r'\s+'), ' ').trim();
              matches = extractor.findText([cleanSnippet]);
           }
           
           if (matches.isNotEmpty) {
              // Sort matches by proximity to the expected page to avoid grabbing identical phrases on the wrong page
              int expectedPage = 0;
              if (startLine > 0 && startLine <= _pdfLines.length) {
                  expectedPage = _pdfLines[startLine - 1].pageIndex;
              }
              
              matches.sort((a, b) => (a.pageIndex - expectedPage).abs().compareTo((b.pageIndex - expectedPage).abs()));
              
              // Only take the closest occurrence to avoid over-highlighting
              matches = <MatchedItem>[matches.first];
              final int pageIndex = matches.first.pageIndex;
              final Rect bounds = matches.first.bounds;
              
              if (!flag.containsKey('page_index')) {
                flag['page_index'] = pageIndex;
                flag['bounds_top'] = bounds.top;
                flag['bounds_left'] = bounds.left;
              }
              
              final PdfPage page = document.pages[pageIndex];
              final PdfTextMarkupAnnotation annotation = PdfTextMarkupAnnotation(
                bounds,
                "Found Flag #$id",
                pdfColor,
              );
              annotation.textMarkupAnnotationType = PdfTextMarkupAnnotationType.highlight;
              annotation.author = "Overcast AI (Fallback)";
              annotation.subject = flag['flag_type'] ?? 'Analysis';
              annotation.text = flag['rationale'] ?? '';
              page.annotations.add(annotation);
              
              double badgeX = bounds.left;
              double badgeY = bounds.top - 15;
              if (badgeY < 0) badgeY = bounds.top + bounds.height + 2;

              drawnBadges.putIfAbsent(pageIndex, () => []);
              Rect badgeRect = Rect.fromLTWH(badgeX, badgeY, 35, 15);
              
              bool overlaps = true;
              while (overlaps) {
                overlaps = false;
                for (final drawn in drawnBadges[pageIndex]!) {
                  if (badgeRect.overlaps(drawn)) {
                    overlaps = true;
                    badgeRect = badgeRect.translate(badgeRect.width + 5, 0);
                    break;
                  }
                }
              }
              
              drawnBadges[pageIndex]!.add(badgeRect);

              page.graphics.drawRectangle(brush: PdfSolidBrush(pdfColor), bounds: badgeRect);
              page.graphics.drawString(
                "AI-$id",
                PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                brush: PdfSolidBrush(PdfColor(255, 255, 255)),
                bounds: badgeRect,
                format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
              );
           }
        }
      }

      setState(() {
        _displayPdfBytes = Uint8List.fromList(document.saveSync());
      });
      document.dispose();
    } catch (e) {
       print("Failed to annotate PDF: $e");
    }
  }

  void _downloadPdf() {
    if (_displayPdfBytes == null) return;
    final blob = html.Blob([_displayPdfBytes!], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "annotated_document.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _downloadReport() {
    if (_flags.isEmpty) return;
    
    StringBuffer sb = StringBuffer();
    sb.writeln("ID,Type,Rationale,Lines");
    for (int i = 0; i < _flags.length; i++) {
      final flag = _flags[i];
      final id = i + 1;
      final type = (flag['flag_type'] ?? '').toString().replaceAll('"', '""');
      final rationale = (flag['rationale'] ?? '').toString().replaceAll('"', '""');
      final lines = "Lines ${flag['start_line']}-${flag['end_line']}";
      sb.writeln('"$id","$type","$rationale","$lines"');
    }

    final bytes = utf8.encode(sb.toString());
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "analysis_report.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _downloadFormatterTablePdf() {
    if (_formatterData == null) return;
    
    try {
      final rawColumns = _formatterData['columns'] ?? _formatterData['headers'] ?? _formatterData['keys'] ?? [];
      final rawRows = _formatterData['rows'] ?? _formatterData['data'] ?? _formatterData['values'] ?? [];

      final columns = (rawColumns as List).map((e) => e.toString()).toList();
      final rows = (rawRows as List).map((r) => (r as List).toList()).toList();

      if (columns.isEmpty) return;

      final document = PdfDocument();
      
      // Dynamically adjust page format based on column count
      if (columns.length > 5) {
        document.pageSettings.orientation = PdfPageOrientation.landscape;
      }
      
      if (columns.length > 8) {
        // Wide data requires a much larger canvas (A3)
        document.pageSettings.size = PdfPageSize.a3;
      }
      if (columns.length > 13) {
        // Extreme data requires massive canvas (A2)
        document.pageSettings.size = PdfPageSize.a2;
      }

      final page = document.pages.add();
      
      final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
      page.graphics.drawString("Extracted Structured Data", titleFont, bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 30));
      
      final stringFormat = PdfStringFormat(
        alignment: PdfTextAlignment.left,
        lineAlignment: PdfVerticalAlignment.top,
        wordWrap: PdfWordWrapType.word,
      );

      final grid = PdfGrid();
      grid.columns.add(count: columns.length);
      final headerRow = grid.headers.add(1)[0];
      for (int i = 0; i < columns.length; i++) {
        headerRow.cells[i].value = columns[i];
        headerRow.cells[i].stringFormat = stringFormat;
        headerRow.cells[i].style = PdfGridCellStyle(
          font: PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
          backgroundBrush: PdfSolidBrush(PdfColor(30, 41, 59)), // Slate 800
          textBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
        );
      }
      
      for (final r in rows) {
        final row = grid.rows.add();
        List<dynamic> safeRow = List.from(r);
        if (safeRow.length > columns.length) safeRow = safeRow.sublist(0, columns.length);
        else while (safeRow.length < columns.length) safeRow.add("");
        
        for (int i = 0; i < columns.length; i++) {
          row.cells[i].value = safeRow[i].toString();
          row.cells[i].stringFormat = stringFormat;
        }
      }
      
      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 8, right: 8, top: 8, bottom: 8),
        font: PdfStandardFont(PdfFontFamily.helvetica, 10),
      );
      
      grid.draw(page: page, bounds: const Rect.fromLTWH(0, 40, 0, 0));
      
      final bytes = document.saveSync();
      document.dispose();
      
      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "extracted_structured_data.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  void _downloadReferenceSlipPdf() {
    if (_flags.isEmpty) return;

    final document = PdfDocument();
    
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final textFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    
    PdfPage page = document.pages.add();
    double currentY = 0;
    
    page.graphics.drawString("AI Reference Slip", titleFont, bounds: Rect.fromLTWH(0, currentY, page.getClientSize().width, 30));
    currentY += 40;
    
    for (int i = 0; i < _flags.length; i++) {
      if (currentY > page.getClientSize().height - 80) {
        page = document.pages.add();
        currentY = 0;
      }
      
      final flag = _flags[i];
      final id = i + 1;
      final type = (flag['flag_type'] ?? 'Unknown').toString();
      final rationale = (flag['rationale'] ?? '').toString();
      final snippet = "Lines ${flag['start_line']}-${flag['end_line']}";
      final colorCode = flag['color_code']?.toString() ?? '';
      
      final pdfColor = _getPdfColor(colorCode);
      
      final headerText = "Flag #$id - $type";
      final headerElement = PdfTextElement(text: headerText, font: headerFont, brush: PdfSolidBrush(pdfColor));
      final headerLayoutResult = headerElement.draw(
          page: page,
          bounds: Rect.fromLTWH(0, currentY, page.getClientSize().width, 0))!;
      
      currentY = headerLayoutResult.bounds.bottom + 10;
      page = headerLayoutResult.page;
      
      final rationaleElement = PdfTextElement(text: "Rationale:\n$rationale", font: textFont);
      final rationaleResult = rationaleElement.draw(
          page: page,
          bounds: Rect.fromLTWH(0, currentY, page.getClientSize().width, 0),
          format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate))!;
          
      currentY = rationaleResult.bounds.bottom + 10;
      page = rationaleResult.page;
      
      final snippetElement = PdfTextElement(text: "Document Text:\n$snippet", font: textFont, brush: PdfSolidBrush(PdfColor(100, 100, 100)));
      final snippetResult = snippetElement.draw(
          page: page,
          bounds: Rect.fromLTWH(0, currentY, page.getClientSize().width, 0),
          format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate))!;
          
      currentY = snippetResult.bounds.bottom + 30;
      page = snippetResult.page;
    }
    
    final bytes = document.saveSync();
    document.dispose();
    
    final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "ai_reference_slip.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildWorkspaceContent() {
    if (_selectedTab == 4) {
      return const RegulatoryReferencePanel();
    }

    return Row(
      children: [
        // Left Panel (70%)
        Expanded(
          flex: 7,
          child: Column(
            children: [
              Expanded(
                child: DocumentViewer(
                  text: _documentText,
                  onTextChanged: (text) {
                    setState(() {
                      _documentText = text;
                      _flags = []; 
                      _formatterData = null;
                    });
                  },
                  flags: _flags,
                  pdfBytes: _displayPdfBytes,
                  pdfViewerController: _pdfViewerController,
                  onPdfLoaded: (originalBytes, extractedText, lines) {
                     setState(() {
                        _originalPdfBytes = originalBytes;
                        _displayPdfBytes = originalBytes;
                        _documentText = extractedText;
                        _pdfLines = lines;
                        _flags = [];
                     });
                  },
                  onPdfCleared: () {
                     setState(() {
                        _originalPdfBytes = null;
                        _displayPdfBytes = null;
                        _documentText = '';
                        _flags = [];
                     });
                  }
                ),
              ),
              const Gap(16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (_displayPdfBytes != null)
                    ElevatedButton.icon(
                      onPressed: _downloadPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.backgroundDark,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  if (_flags.isNotEmpty && _selectedTab != 2)
                    ElevatedButton.icon(
                      onPressed: _downloadReport,
                      icon: const Icon(Icons.download),
                      label: const Text('Download CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.backgroundDark,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  if (_flags.isNotEmpty && _selectedTab != 2)
                    ElevatedButton.icon(
                      onPressed: _downloadReferenceSlipPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download AI Slip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.backgroundDark,
                        foregroundColor: AppTheme.flagBlue,
                        side: const BorderSide(color: AppTheme.flagBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  if (_selectedTab == 2 && _formatterData != null)
                    ElevatedButton.icon(
                      onPressed: _downloadFormatterTablePdf,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Download Table PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.backgroundDark,
                        foregroundColor: AppTheme.flagBlue,
                        side: const BorderSide(color: AppTheme.flagBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: (_apiKey.isEmpty || _isLoading) ? null : _analyzeDocument,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(_apiKey.isEmpty ? 'Add API Key to Analyze' : 'Analyze Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.flagBlue,
                      foregroundColor: AppTheme.backgroundDark,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap(24),
        // Right Panel (30%)
        Expanded(
          flex: 3,
          child: AnalysisPanel(
            flags: _flags,
            isFormatter: _selectedTab == 2,
            formatterData: _formatterData,
            onFlagTap: (flag) {
              if (flag is Map && flag.containsKey('page_index')) {
                int pageIndex = flag['page_index'] as int;
                _pdfViewerController.jumpToPage(pageIndex + 1);
                
                if (flag.containsKey('bounds_top')) {
                  double boundsTop = flag['bounds_top'] as double;
                  Future.delayed(const Duration(milliseconds: 150), () {
                    double currentY = _pdfViewerController.scrollOffset.dy;
                    double zoom = _pdfViewerController.zoomLevel;
                    double preciseY = currentY + (boundsTop * zoom) - 50; 
                    _pdfViewerController.jumpTo(yOffset: preciseY);
                  });
                }
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SelectionArea(
        child: Column(
          children: [
            const PersistentBanner(),
            Expanded(
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isTablet = constraints.maxWidth < 1100 && constraints.maxWidth >= 600;
                      final isMobile = constraints.maxWidth < 600;
  
                      return Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topLeft,
                            radius: 1.5,
                            colors: [
                              Color(0xFF1E293B), // Slate 800
                              AppTheme.backgroundDark,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            if (!isMobile)
                              SizedBox(
                                width: isTablet ? 250 : 300,
                                child: Sidebar(
                                  selectedIndex: _selectedTab,
                                  onTabSelected: _onTabSelected,
                                  apiKey: _apiKey,
                                  onApiKeyChanged: _onApiKeyChanged,
                                ),
                              ),
                            if (!isMobile) const Gap(24),
                            Expanded(
                              child: isMobile
                                  ? const Center(child: Text('Mobile layout not supported. Please use Tablet or Desktop.'))
                                  : _buildWorkspaceContent(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (_isLoading) const LoadingSpinnerOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
