#include "include/mel_spectrogram_flutter/mel_spectrogram_flutter_plugin.h"

#include <flutter/plugin_registrar_windows.h>

#include "mel_spectrogram_flutter_plugin.h"

void MelSpectrogramFlutterPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  mel_spectrogram_flutter::MelSpectrogramFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
