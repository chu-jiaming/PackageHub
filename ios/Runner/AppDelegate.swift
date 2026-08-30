import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var ocrChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerOcrChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  private func registerOcrChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "packagehub/ocr", binaryMessenger: messenger)
    ocrChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "recognizeText" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let self else {
        result(
          FlutterError(
            code: "OCR_UNAVAILABLE",
            message: "OCR channel is unavailable.",
            details: nil
          )
        )
        return
      }

      self.handleRecognizeText(call: call, result: result)
    }
  }

  private func handleRecognizeText(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let rawImagePath = arguments["imagePath"] as? String
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Expected a non-empty imagePath.",
          details: nil
        )
      )
      return
    }

    let imagePath = rawImagePath.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !imagePath.isEmpty else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Expected a non-empty imagePath.",
          details: nil
        )
      )
      return
    }

    guard FileManager.default.fileExists(atPath: imagePath) else {
      result(
        FlutterError(
          code: "FILE_NOT_FOUND",
          message: "Image file does not exist.",
          details: imagePath
        )
      )
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let text = try self.performTextRecognition(imagePath: imagePath)
        DispatchQueue.main.async {
          result(text)
        }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "OCR_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }

  private func performTextRecognition(imagePath: String) throws -> String {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["zh-Hans", "en-US"]
    request.usesLanguageCorrection = false

    let imageURL = URL(fileURLWithPath: imagePath)
    let handler = VNImageRequestHandler(url: imageURL, options: [:])
    try handler.perform([request])

    guard let observations = request.results else {
      return ""
    }

    let lines = observations.compactMap { observation in
      observation.topCandidates(1).first?.string
    }

    return lines.joined(separator: "\n")
  }
}
