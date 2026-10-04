import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Client-side PDF → plain text — one page per line.
///
/// Pure Dart + top-level so callers can offload it via `compute(...)` to
/// an isolate instead of jank-ing the UI thread. Used by both the CV
/// picker (AI Matching sheet) and the resume upload flow — the latter
/// extracts text on upload so the AI pipeline never needs the binary
/// file to be stored in Firebase Storage.
String extractPdfText(Uint8List bytes) {
  final doc = PdfDocument(inputBytes: bytes);
  try {
    final extractor = PdfTextExtractor(doc);
    final buf = StringBuffer();
    for (var i = 0; i < doc.pages.count; i++) {
      buf
        ..write(extractor.extractText(startPageIndex: i))
        ..write('\n');
    }
    return buf.toString();
  } finally {
    doc.dispose();
  }
}
