import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:gap/gap.dart';
import '../constants/theme.dart';
import 'glass_container.dart';
import 'highlighted_text.dart';
import 'analysis_panel.dart';

class DocumentViewer extends StatefulWidget {
  final String text;
  final ValueChanged<String> onTextChanged;
  final List<dynamic> flags;
  final Uint8List? pdfBytes;
  final void Function(Uint8List, String, List<dynamic>)? onPdfLoaded;
  final VoidCallback? onPdfCleared;
  final PdfViewerController? pdfViewerController;

  const DocumentViewer({
    super.key,
    required this.text,
    required this.onTextChanged,
    required this.flags,
    this.pdfBytes,
    this.onPdfLoaded,
    this.onPdfCleared,
    this.pdfViewerController,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  bool _isPdfMode = false;
  String? _pdfError;
  late final PdfViewerController _pdfViewerController;
  double _currentZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = widget.pdfViewerController ?? PdfViewerController();
    if (widget.pdfBytes != null) {
      _isPdfMode = true;
    }
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final Uint8List bytes = result.files.single.bytes!;
        // Extract text using Syncfusion line by line
        final syncfusion.PdfDocument document = syncfusion.PdfDocument(inputBytes: bytes);
        final syncfusion.PdfTextExtractor extractor = syncfusion.PdfTextExtractor(document);
        final rawLines = extractor.extractTextLines();
        final lines = rawLines.where((l) => l.text.trim().isNotEmpty).toList();
        
        StringBuffer sb = StringBuffer();
        for (int i = 0; i < lines.length; i++) {
           sb.writeln('[Line ${i + 1}] ${lines[i].text}');
        }
        final String extractedText = sb.toString();
        document.dispose();

        setState(() {
          _isPdfMode = true;
          _pdfError = null;
        });

        if (widget.onPdfLoaded != null) {
          widget.onPdfLoaded!(bytes, extractedText, lines);
        }
      }
    } catch (e) {
      setState(() {
        _pdfError = "PDF could not be loaded. Ensure the file is not password-protected.";
      });
    }
  }

  void _jumpToFlag(Map flag, PdfViewerController controller) {
    if (flag.containsKey('page_index')) {
      int pageIndex = flag['page_index'] as int;
      controller.jumpToPage(pageIndex + 1);
      
      if (flag.containsKey('bounds_top')) {
        double boundsTop = flag['bounds_top'] as double;
        // Wait briefly for jumpToPage to update the scroll view
        Future.delayed(const Duration(milliseconds: 150), () {
          double currentY = controller.scrollOffset.dy;
          double zoom = controller.zoomLevel;
          // Calculate precise Y offset taking zoom into account
          double preciseY = currentY + (boundsTop * zoom) - 50; 
          controller.jumpTo(yOffset: preciseY);
        });
      }
    }
  }

  void _openFullScreenPdf() {
    if (widget.pdfBytes == null) return;
    
    showDialog(
      context: context,
      builder: (context) {
        final PdfViewerController fsController = PdfViewerController();
        double fsZoom = 1.0;
        return StatefulBuilder(
          builder: (context, setStateFs) {
            return Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: AppTheme.backgroundDark,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF1E293B), // Slate 800
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Full Screen PDF Review", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.zoom_out, color: Colors.white),
                                onPressed: () {
                                  setStateFs(() { fsZoom = (fsZoom - 0.25).clamp(0.5, 3.0); });
                                  fsController.zoomLevel = fsZoom;
                                },
                              ),
                              Text('${(fsZoom * 100).toInt()}%', style: const TextStyle(color: Colors.white)),
                              IconButton(
                                icon: const Icon(Icons.zoom_in, color: Colors.white),
                                onPressed: () {
                                  setStateFs(() { fsZoom = (fsZoom + 0.25).clamp(0.5, 3.0); });
                                  fsController.zoomLevel = fsZoom;
                                },
                              ),
                              const Gap(24),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: SfPdfViewer.memory(
                              widget.pdfBytes!,
                              controller: fsController,
                              canShowScrollHead: true,
                              enableDoubleTapZooming: true,
                            ),
                          ),
                          if (widget.flags.isNotEmpty)
                            Container(
                              width: 350,
                              decoration: const BoxDecoration(
                                border: Border(left: BorderSide(color: Colors.white24)),
                                color: AppTheme.backgroundDark,
                              ),
                              child: AnalysisPanel(
                                flags: widget.flags,
                                onFlagTap: (flag) {
                                  if (flag is Map) {
                                    _jumpToFlag(flag, fsController);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildPdfControls() {
    if (widget.pdfBytes == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white),
            onPressed: () {
              setState(() { _currentZoom = (_currentZoom - 0.25).clamp(0.5, 3.0); });
              _pdfViewerController.zoomLevel = _currentZoom;
            },
            tooltip: "Zoom Out",
          ),
          Text(
            '${(_currentZoom * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white),
            onPressed: () {
              setState(() { _currentZoom = (_currentZoom + 0.25).clamp(0.5, 3.0); });
              _pdfViewerController.zoomLevel = _currentZoom;
            },
            tooltip: "Zoom In",
          ),
          const Gap(16),
          ElevatedButton.icon(
            onPressed: _openFullScreenPdf,
            icon: const Icon(Icons.fullscreen),
            label: const Text("Full Screen"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.flagBlue.withOpacity(0.2),
              foregroundColor: AppTheme.flagBlue,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegend() {
    if (widget.flags.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _legendItem(AppTheme.flagRed, "Red", "Critical Violation / Contradiction"),
          _legendItem(AppTheme.flagOrange, "Orange", "Unmitigated Safety / Toxicity"),
          _legendItem(AppTheme.flagYellow, "Yellow", "Vague Language / Missing Definition"),
          _legendItem(AppTheme.flagBlue, "Blue", "PHI / Identifiers"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String description) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const Gap(6),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const Gap(4),
        Text("($description)", style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Document Workspace',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (!_isPdfMode)
                    ElevatedButton.icon(
                      onPressed: _pickPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Upload PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.flagBlue.withOpacity(0.2),
                        foregroundColor: AppTheme.flagBlue,
                      ),
                    ),
                  if (widget.pdfBytes != null)
                    IconButton(
                       icon: const Icon(Icons.clear),
                       onPressed: () {
                         widget.onPdfCleared?.call();
                         setState(() {
                           _isPdfMode = false;
                         });
                       },
                       tooltip: "Clear PDF",
                    ),
                  const Gap(16),
                  ToggleButtons(
                    isSelected: [!_isPdfMode, _isPdfMode],
                    onPressed: (index) {
                      setState(() {
                        _isPdfMode = index == 1;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: AppTheme.flagBlue.withOpacity(0.5),
                    color: Colors.white70,
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Text Mode')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('PDF Mode')),
                    ],
                  ),
                ],
              )
            ],
          ),
          const Gap(16),
          _buildLegend(),
          Expanded(
            child: _isPdfMode
                ? Column(
                    children: [
                      if (_pdfError != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: AppTheme.flagRed.withOpacity(0.2),
                          child: Text(_pdfError!, style: const TextStyle(color: AppTheme.flagRed)),
                        ),
                      if (widget.pdfBytes != null) _buildPdfControls(),
                      if (widget.pdfBytes != null) const Gap(8),
                      Expanded(
                        child: widget.pdfBytes == null
                            ? Center(
                                child: ElevatedButton(
                                  onPressed: _pickPdf,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.flagBlue.withOpacity(0.2), foregroundColor: AppTheme.flagBlue),
                                  child: const Text('Upload a PDF to view it here.'),
                                ),
                              )
                            : SfPdfViewer.memory(
                                widget.pdfBytes!,
                                controller: _pdfViewerController,
                                canShowScrollHead: true,
                                enableDoubleTapZooming: true,
                                onZoomLevelChanged: (PdfZoomDetails details) {
                                  setState(() {
                                    _currentZoom = details.newZoomLevel;
                                  });
                                },
                              ),
                      ),
                    ],
                  )
                : Stack(
                        children: [
                          if (widget.flags.isEmpty && widget.text.isEmpty)
                            TextField(
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                              decoration: const InputDecoration(
                                hintText: 'Paste unstructured text or clinical narrative here...',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                              ),
                              onChanged: widget.onTextChanged,
                              controller: TextEditingController(text: widget.text)
                                ..selection = TextSelection.collapsed(offset: widget.text.length),
                            )
                          else if (widget.flags.isEmpty && widget.text.isNotEmpty)
                             TextField(
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              onChanged: widget.onTextChanged,
                              controller: TextEditingController(text: widget.text)
                                ..selection = TextSelection.collapsed(offset: widget.text.length),
                            )
                          else
                            SingleChildScrollView(
                              child: HighlightedText(
                                text: widget.text,
                                flags: widget.flags,
                              ),
                            ),
                          if (widget.flags.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit Text',
                                onPressed: () => widget.onTextChanged(widget.text), // We can clear flags from parent
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
