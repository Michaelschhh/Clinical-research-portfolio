import 'package:syncfusion_flutter_pdf/pdf.dart';
void main() {
  PdfDocument document = PdfDocument();
  PdfPage page = document.pages.add();
  page.graphics.drawString('Hello', PdfStandardFont(PdfFontFamily.helvetica, 12));
  PdfTextExtractor extractor = PdfTextExtractor(document);
  var lines = extractor.extractTextLines();
  print(lines.runtimeType);
  if (lines.isNotEmpty) {
    print(lines[0].text);
    print(lines[0].bounds);
    print(lines[0].pageIndex);
  }
}
