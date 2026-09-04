import 'package:packagehub/recognition/credential_segment.dart';
import 'package:packagehub/recognition/pickup_code_anchor.dart';

/// Creates bounded, line-aware contexts around pickup-code anchors.
class CredentialSegmenter {
  final int contextLines;

  const CredentialSegmenter({this.contextLines = 3});

  List<CredentialTextSegment> segment(
    String normalizedText,
    List<String> lines,
    Iterable<PickupCodeAnchor> input,
  ) {
    final anchors = [...input]
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));
    if (anchors.isEmpty) return const [];
    final offsets = <int>[0];
    var offset = 0;
    for (final line in lines) {
      offset += line.length + 1;
      offsets.add(offset);
    }
    int lineStart(int line) => offsets[line.clamp(0, lines.length)];
    int lineEnd(int line) => offsets[(line + 1).clamp(0, lines.length)];

    final result = <CredentialTextSegment>[];
    for (var i = 0; i < anchors.length; i++) {
      final anchor = anchors[i];
      final midpointBefore = i == 0
          ? 0
          : (anchors[i - 1].endOffset + anchor.startOffset) ~/ 2;
      final midpointAfter = i == anchors.length - 1
          ? normalizedText.length
          : (anchor.endOffset + anchors[i + 1].startOffset) ~/ 2;
      final startLine = (anchor.lineIndex - contextLines)
          .clamp(0, lines.length)
          .toInt();
      final endLine = (anchor.lineIndex + contextLines + 1)
          .clamp(0, lines.length)
          .toInt();
      final lineStartOffset = lineStart(startLine);
      final lineEndOffset = lineEnd(endLine - 1);
      // Never cut through a line containing a tracking number or a courier
      // header. The adjacent anchor line is the hard block boundary; the
      // midpoint remains the fallback for anchors on the same line.
      final blockStart = i == 0 || anchors[i - 1].lineIndex == anchor.lineIndex
          ? midpointBefore
          : lineStart(anchor.lineIndex - 1);
      final blockEnd =
          i == anchors.length - 1 ||
              anchors[i + 1].lineIndex == anchor.lineIndex
          ? midpointAfter
          : lineStart(anchors[i + 1].lineIndex);
      final start = lineStartOffset > blockStart ? lineStartOffset : blockStart;
      final end = lineEndOffset < blockEnd ? lineEndOffset : blockEnd;
      result.add(
        CredentialTextSegment(
          anchor: anchor,
          localText: normalizedText.substring(start, end),
          startOffset: start,
          endOffset: end,
          startLine: startLine,
          endLine: endLine,
        ),
      );
    }
    return result;
  }
}
