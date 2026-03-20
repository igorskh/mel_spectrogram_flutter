#define NOMINMAX

#include "mel_spectrogram_flutter_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

#include "mel_spectrogram_pocketfft.h"

#define MINIAUDIO_IMPLEMENTATION
#define MA_NO_ENCODING
// #define MA_NO_DEVICE_IO
#define MA_NO_ENGINE
#define MA_NO_NODE_GRAPH

#pragma warning(push)
#pragma warning(disable: 4244) 
#include "miniaudio.h"
#pragma warning(pop)


namespace mel_spectrogram_flutter {

void read_pcm_frames(const char* file_path, std::vector<float>& out_pcm, ma_uint32 target_sample_rate)
{
    ma_decoder_config config = ma_decoder_config_init(
        ma_format_f32, // output format: 32-bit float
        1,             // output channels: mono
        target_sample_rate);

    ma_decoder decoder;
    ma_result result = ma_decoder_init_file(file_path, &config, &decoder);
    if (result != MA_SUCCESS)
    {
        return;
    }

    ma_uint64 total_frames;
    ma_decoder_get_length_in_pcm_frames(&decoder, &total_frames);

    if (total_frames > 0)
    {
        out_pcm.resize(total_frames);
        ma_uint64 frames_read = 0;
        ma_decoder_read_pcm_frames(&decoder, out_pcm.data(), total_frames, &frames_read);
        out_pcm.resize(frames_read);
    }
    else
    {
        out_pcm.reserve(1024 * 1024);
        std::vector<float> chunk(65536);

        while (true)
        {
            ma_uint64 read = 0;
            ma_decoder_read_pcm_frames(&decoder, chunk.data(), chunk.size(), &read);
            if (read == 0)
                break;
            out_pcm.insert(out_pcm.end(), chunk.begin(), chunk.begin() + read);
        }
    }

    ma_decoder_uninit(&decoder);
}

// static
void MelSpectrogramFlutterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "mel_spectrogram_flutter",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<MelSpectrogramFlutterPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

MelSpectrogramFlutterPlugin::MelSpectrogramFlutterPlugin() {}

MelSpectrogramFlutterPlugin::~MelSpectrogramFlutterPlugin() {}

void MelSpectrogramFlutterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  }
  else if (method_call.method_name().compare("listCaptureDevices") == 0) {
      ma_context context;
      ma_result res = ma_context_init(NULL, 0, NULL, &context);
      if (res != MA_SUCCESS)
      {
		  result->Error("ContextInitializationFailed", "Failed to initialize audio context.");
          return;
      }

      ma_device_info* pDeviceInfos;
      ma_uint32 deviceCount;


      res = ma_context_get_devices(&context, NULL, &deviceCount, &pDeviceInfos, NULL);
      if (res != MA_SUCCESS)
      {
          ma_context_uninit(&context);
		  result->Error("DeviceEnumerationFailed", "Failed to enumerate audio devices.");   
          return;
      }


      std::vector<std::string> device_names;
      for (ma_uint32 i = 0; i < deviceCount; ++i)
      {
          device_names.push_back(pDeviceInfos[i].name);
      }

      ma_context_uninit(&context);

      std::vector<flutter::EncodableValue> encodable_device_names;
      for (const auto& name : device_names) {
          encodable_device_names.push_back(flutter::EncodableValue(name));
      }
      result->Success(flutter::EncodableValue(encodable_device_names));
  }
  else if (method_call.method_name().compare("decodeFile") == 0) {
	  const char* file_path = nullptr;
      int target_sample_rate = 44100;

      const auto* args = method_call.arguments();
      const auto& map = std::get<flutter::EncodableMap>(*args);

      auto it = map.find(flutter::EncodableValue("filePath"));
      if (it != map.end()) {
          const std::string& path = std::get<std::string>(it->second);
          file_path = path.c_str();
      }

      it = map.find(flutter::EncodableValue("targetSampleRate"));
      if (it != map.end()) {
          target_sample_rate = std::get<int>(it->second);
      }

      std::vector<float> pcm_data;
      read_pcm_frames(file_path, pcm_data, (ma_uint32)target_sample_rate);

	  std::vector<flutter::EncodableValue> encodable_pcm_data;
      for (float sample : pcm_data) {
          encodable_pcm_data.push_back(flutter::EncodableValue(sample));
      }
	  result->Success(flutter::EncodableValue(encodable_pcm_data));
  }
  else if ((method_call.method_name().compare("computeMelSpectrogram") == 0 || 
      (method_call.method_name().compare("decodeFileAndComputeMelSpectrogram") == 0))) {
      
      int sample_rate = 44100;
	  int frame_size = 1024;
	  int hop_size = 512;
	  int num_bands = 60;
      double min_freq = 0.0;
      double max_freq = 0.0;
      double power = 2.0;

      const auto* args = method_call.arguments();
      const auto& map = std::get<flutter::EncodableMap>(*args);
      auto it = map.find(flutter::EncodableValue("sampleRate"));
      if (it != map.end()) {
          sample_rate = std::get<int>(it->second);
      }

	  it = map.find(flutter::EncodableValue("frameSize"));
      if (it != map.end()) {
          frame_size = std::get<int>(it->second);
	  }

	  it = map.find(flutter::EncodableValue("hopSize"));
      if (it != map.end()) {
          hop_size = std::get<int>(it->second);
	  }

	  it = map.find(flutter::EncodableValue("numBands"));
	  if (it != map.end()) {
		  num_bands = std::get<int>(it->second);
	  }

	  it = map.find(flutter::EncodableValue("minFreq"));
	  if (it != map.end()) {
          if (auto* val = std::get_if<double>(&it->second)) {
              min_freq = *val;
          }
	  }

	  it = map.find(flutter::EncodableValue("maxFreq"));
      if (it != map.end()) {
          if (auto* val = std::get_if<double>(&it->second)) {
              max_freq = *val;
		  }
          else {
              max_freq = double(sample_rate) / 2;
          }
      }

	  it = map.find(flutter::EncodableValue("power"));
      if (it != map.end()) {
          if (auto* val = std::get_if<double>(&it->second)) {
              power = *val;
          }
	  }
      
      std::vector<float> pcm_data;
       
      if (method_call.method_name().compare("decodeFileAndComputeMelSpectrogram") == 0) {
          const char* file_path = nullptr;
          it = map.find(flutter::EncodableValue("filePath"));
          if (it != map.end()) {
              const std::string& path = std::get<std::string>(it->second);
              file_path = path.c_str();
          }
          read_pcm_frames(file_path, pcm_data, (ma_uint32)sample_rate);
      }
      else {
          it = map.find(flutter::EncodableValue("audioSamples"));
          if (it != map.end()) {
              const auto& pcm_list = std::get<flutter::EncodableList>(it->second);

              for (const auto& sample : pcm_list) {
                  pcm_data.push_back(static_cast<float>(std::get<double>(sample)));
              }
          }
      }
     
#pragma warning(push)
#pragma warning(disable: 4244)
      std::vector<std::vector<float>> mel_spectrogram;
      auto mel = mel_spectrogram::compute_mel_spectrogram(
          pcm_data,
          sample_rate,
          frame_size,
          hop_size,
          num_bands,
          min_freq,
          max_freq,
          power);
      std::vector<flutter::EncodableValue> encodable_mel_spectrogram;
      for (const auto& frame : mel) {
          std::vector<flutter::EncodableValue> encodable_frame;
          for (float value : frame) {
              encodable_frame.push_back(flutter::EncodableValue(value));
          }
          encodable_mel_spectrogram.push_back(flutter::EncodableValue(encodable_frame));
      }
#pragma warning(pop)
      result->Success(flutter::EncodableValue(encodable_mel_spectrogram));
  }
}

}  // namespace mel_spectrogram_flutter
