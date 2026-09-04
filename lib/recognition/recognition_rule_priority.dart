/// Higher numbers win within a recognition phase and field.
abstract final class RecognitionRulePriority {
  static const explicitStrong = 100;
  static const explicitContext = 90;
  static const explicitWeak = 80;
  static const inference = 10;
}
