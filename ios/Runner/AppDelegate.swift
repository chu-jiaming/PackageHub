import Flutter
import UIKit
import Vision
import Security

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var ocrChannel: FlutterMethodChannel?
  private let appleSignInService = AppleSignInService()
  private var storeKitService: AnyObject?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerOcrChannel(messenger: engineBridge.applicationRegistrar.messenger())
    registerAppleSignInChannel(messenger: engineBridge.applicationRegistrar.messenger())
    registerKeychainChannel(messenger: engineBridge.applicationRegistrar.messenger())
    if #available(iOS 15.0, *) {
      let service = StoreKitService()
      service.attach(messenger: engineBridge.applicationRegistrar.messenger())
      FlutterMethodChannel(name: "packagehub/storekit", binaryMessenger: engineBridge.applicationRegistrar.messenger()).setMethodCallHandler { call, result in
        service.handle(call, result: result)
      }
      storeKitService = service
    }
  }

  private func registerKeychainChannel(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "packagehub/keychain", binaryMessenger: messenger).setMethodCallHandler { call, result in
      guard let args = call.arguments as? [String: Any], let key = args["key"] as? String else { result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil)); return }
      let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key]
      switch call.method {
      case "read": var item: CFTypeRef?; var readQuery = query; readQuery[kSecReturnData as String] = true; let status = SecItemCopyMatching(readQuery as CFDictionary, &item); result(status == errSecSuccess ? String(data: item as! Data, encoding: .utf8) : nil)
      case "write": guard let value = args["value"] as? String else { result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil)); return }; SecItemDelete(query as CFDictionary); var q=query; q[kSecValueData as String]=value.data(using:.utf8); result(SecItemAdd(q as CFDictionary,nil) == errSecSuccess ? nil : FlutterError(code:"KEYCHAIN_ERROR",message:nil,details:nil))
      case "delete": result(SecItemDelete(query as CFDictionary) == errSecSuccess ? nil : nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerAppleSignInChannel(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "packagehub/apple_sign_in", binaryMessenger: messenger).setMethodCallHandler { [weak self] call, result in
      guard call.method == "authorize", let args = call.arguments as? [String: Any], let self else { result(FlutterMethodNotImplemented); return }
      self.appleSignInService.authorize(arguments: args, result: result)
    }
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
