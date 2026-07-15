import Flutter
import UIKit
#if SWIFT_PACKAGE
import MelSpectrogramBridge
#endif

public class MelSpectrogramFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let taskQueue = registrar.messenger().makeBackgroundTaskQueue?()
      
    let channel = FlutterMethodChannel(
        name: "mel_spectrogram_flutter",
        binaryMessenger: registrar.messenger(),
        codec: FlutterStandardMethodCodec.sharedInstance(),
        taskQueue: taskQueue)
    let instance = MelSpectrogramFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "computeMelSpectrogram":
            guard let args = call.arguments as? [String: Any],
                  let audioSamples = args["audioSamples"] as? [Float],
                  let sampleRate = args["sampleRate"] as? Int,
                  let frameSize = args["frameSize"] as? Int,
                  let hopSize = args["hopSize"] as? Int,
                  let numBands = args["numBands"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required parameters", details: nil))
                return
            }
            // read optional arguments
            let minFreq = args["minFreq"] as? Int ?? 0
            let maxFreq = args["maxFreq"] as? Int ?? sampleRate / 2
            let power = args["power"] as? Double ?? 2.0

            result(MelSpectrogramBridge.computeMelSpectrogram(
              audioSamples, 
              length: UInt(audioSamples.count),
              sampleRate: Double(sampleRate), 
              frameSize: UInt(frameSize), 
              hopSize: UInt(hopSize), 
              numBands: UInt(numBands), 
              minFreq: Double(minFreq), 
              maxFreq: Double(maxFreq), 
              power: power))
    case "decodeFile":
      guard let args = call.arguments as? [String: Any],
            let path = args["filePath"] as? String,
            let sampleRate = args["targetSampleRate"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Path is required", details: nil))
          return
      }

      result(MelSpectrogramBridge.decodeFile(path, sampleRate: Double(sampleRate)))
    case "decodeFileAndComputeMelSpectrogram":
            guard let args = call.arguments as? [String: Any],
                  let path = args["filePath"] as? String,
                  let sampleRate = args["sampleRate"] as? Int,
                  let frameSize = args["frameSize"] as? Int,
                  let hopSize = args["hopSize"] as? Int,
                  let numBands = args["numBands"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required parameters", details: nil))
                return
            }
            // read optional arguments
            let minFreq = args["minFreq"] as? Int ?? 0
            let maxFreq = args["maxFreq"] as? Int ?? sampleRate / 2
            let power = args["power"] as? Double ?? 2.0

            result(MelSpectrogramBridge.decodeFileAndComputeMelSpectrogram(
              path, 
              sampleRate: Double(sampleRate), 
              frameSize: UInt(frameSize), 
              hopSize: UInt(hopSize), 
              numBands: UInt(numBands), 
              minFreq: Double(minFreq), 
              maxFreq: Double(maxFreq), 
              power: power))
    case "listCaptureDevices":
      result(MelSpectrogramBridge.listCaptureDevices())
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
