import 'package:packagehub/recognition/pickup_code_anchor.dart';

class CredentialTextSegment {
  final PickupCodeAnchor anchor;
  final String localText;
  final int startOffset;
  final int endOffset;
  final int startLine;
  final int endLine;

  const CredentialTextSegment({
    required this.anchor,
    required this.localText,
    required this.startOffset,
    required this.endOffset,
    required this.startLine,
    required this.endLine,
  });
}
