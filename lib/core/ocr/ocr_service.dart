import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class TextRecognitionService {
  Future<String> recognizeText(String imagePath);
}

class OcrService implements TextRecognitionService {
  const OcrService() : _channel = _defaultChannel;

  @visibleForTesting
  const OcrService.withChannel(this._channel);

  static const MethodChannel _defaultChannel = MethodChannel('packagehub/ocr');

  final MethodChannel _channel;

  @override
  Future<String> recognizeText(String imagePath) async {
    if (imagePath.trim().isEmpty) {
      throw ArgumentError.value(imagePath, 'imagePath', 'Image path is empty.');
    }

    if (defaultTargetPlatform != TargetPlatform.iOS) {
      throw UnsupportedError('OCR is currently only supported on iOS.');
    }

    final text = await _channel.invokeMethod<String>('recognizeText', {
      'imagePath': imagePath,
    });

    return text ?? '';
  }
}
