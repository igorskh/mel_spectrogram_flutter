#ifndef FLUTTER_PLUGIN_MEL_SPECTROGRAM_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_MEL_SPECTROGRAM_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace mel_spectrogram_flutter {

class MelSpectrogramFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MelSpectrogramFlutterPlugin();

  virtual ~MelSpectrogramFlutterPlugin();

  // Disallow copy and assign.
  MelSpectrogramFlutterPlugin(const MelSpectrogramFlutterPlugin&) = delete;
  MelSpectrogramFlutterPlugin& operator=(const MelSpectrogramFlutterPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace mel_spectrogram_flutter

#endif  // FLUTTER_PLUGIN_MEL_SPECTROGRAM_FLUTTER_PLUGIN_H_
