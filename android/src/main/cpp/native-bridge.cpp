#include "mel_spectrogram_pocketfft.cpp"

#define MINIAUDIO_IMPLEMENTATION
#define MA_NO_ENCODING
// #define MA_NO_DEVICE_IO
#define MA_NO_ENGINE
#define MA_NO_NODE_GRAPH
#include "miniaudio.h"

#include <jni.h>
#include <android/log.h>
#include <vector>

#define LOG_TAG "MelSpectrogramCppBridge"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

void read_pcm_frames(const char *file_path, std::vector<float> &out_pcm, ma_uint32 target_sample_rate)
{
    ma_decoder_config config = ma_decoder_config_init(
        ma_format_f32, // output format: 32-bit float
        1,             // output channels: mono
        target_sample_rate);

    ma_decoder decoder;
    ma_result result = ma_decoder_init_file(file_path, &config, &decoder);
    if (result != MA_SUCCESS)
    {
        LOGE("Failed to open file: %s (error %d)", file_path, result);
        return;
    }

    ma_uint64 total_frames;
    ma_decoder_get_length_in_pcm_frames(&decoder, &total_frames);
    ma_uint64 frames_read = 0;

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

jobjectArray convert2DToJava2DArray(JNIEnv *env, const std::vector<std::vector<float>> &matrix)
{
    size_t n_frames = matrix.size();
    size_t n_mels = n_frames > 0 ? matrix[0].size() : 0;

    jclass floatArrayClass = env->FindClass("[F");
    jobjectArray jResult = env->NewObjectArray((jsize)n_frames, floatArrayClass, nullptr);

    for (size_t i = 0; i < n_frames; ++i)
    {
        jfloatArray row = env->NewFloatArray((jsize)n_mels);
        env->SetFloatArrayRegion(row, 0, (jsize)n_mels, matrix[i].data());
        env->SetObjectArrayElement(jResult, (jsize)i, row);
        env->DeleteLocalRef(row);
    }

    return jResult;
}

// get capture devices
extern "C" JNIEXPORT jobjectArray JNICALL
Java_one_beagile_mel_1spectrogram_1flutter_NativeBridge_listCaptureDevices(
    JNIEnv *env, jobject thiz)
{
    ma_context context;
    ma_result result = ma_context_init(NULL, 0, NULL, &context);
    if (result != MA_SUCCESS)
    {
        LOGE("Failed to initialize miniaudio context (error %d)", result);
        return nullptr;
    }

    ma_device_info* pDeviceInfos;
    ma_uint32 deviceCount;
    result = ma_context_get_devices(&context, NULL, &deviceCount, &pDeviceInfos, NULL);
    if (result != MA_SUCCESS)
    {
        LOGE("Failed to get devices (error %d)", result);
        ma_context_uninit(&context);
        return nullptr;
    }

    std::vector<std::string> device_names;
    for (ma_uint32 i = 0; i < deviceCount; ++i)
    {
        device_names.push_back(pDeviceInfos[i].name);
    }

    ma_context_uninit(&context);

    jobjectArray jResult = env->NewObjectArray((jsize)device_names.size(), env->FindClass("java/lang/String"), nullptr);
    for (size_t i = 0; i < device_names.size(); ++i)
    {
        jstring jDeviceName = env->NewStringUTF(device_names[i].c_str());
        env->SetObjectArrayElement(jResult, (jsize)i, jDeviceName);
        env->DeleteLocalRef(jDeviceName);
    }
    return jResult;
}

extern "C" JNIEXPORT jfloatArray JNICALL
Java_one_beagile_mel_1spectrogram_1flutter_NativeBridge_decodeFile(
    JNIEnv *env, jobject thiz,
    jstring jFilePath, jint targetSampleRate)
{
    const char *file_path = env->GetStringUTFChars(jFilePath, nullptr);

    std::vector<float> pcm_data;
    read_pcm_frames(file_path, pcm_data, (ma_uint32)targetSampleRate);

    env->ReleaseStringUTFChars(jFilePath, file_path);

    // Copy to Java float array
    jfloatArray jResult = env->NewFloatArray((jsize)pcm_data.size());
    env->SetFloatArrayRegion(jResult, 0, (jsize)pcm_data.size(), pcm_data.data());

    return jResult;
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_one_beagile_mel_1spectrogram_1flutter_NativeBridge_computeMelSpectrogram(
    JNIEnv *env, jobject thiz,
    jfloatArray audioSamples,
    jint sampleRate,
    jint frameSize,
    jint hopSize,
    jint numBands,
    jint minFreq,
    jint maxFreq,
    jfloat power)
{
    jsize length = env->GetArrayLength(audioSamples);
    jfloat *samples = env->GetFloatArrayElements(audioSamples, nullptr);

    std::vector<float> input(samples, samples + length);
    env->ReleaseFloatArrayElements(audioSamples, samples, 0);

    auto mel = mel_spectrogram::compute_mel_spectrogram(
        input,
        (int)sampleRate,
        (int)frameSize,
        (int)hopSize,
        (int)numBands,
        (float)minFreq,
        (float)maxFreq,
        (float)power);

    return convert2DToJava2DArray(env, mel);
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_one_beagile_mel_1spectrogram_1flutter_NativeBridge_decodeFileAndComputeMelSpectrogram(
    JNIEnv *env, jobject thiz,
    jstring jFilePath,
    jint targetSampleRate,
    jint frameSize,
    jint hopSize,
    jint numBands,
    jint minFreq,
    jint maxFreq,
    jfloat power)
{
    const char *file_path = env->GetStringUTFChars(jFilePath, nullptr);

    std::vector<float> pcm_data;
    read_pcm_frames(file_path, pcm_data, (ma_uint32)targetSampleRate);

    env->ReleaseStringUTFChars(jFilePath, file_path);

    auto mel = mel_spectrogram::compute_mel_spectrogram(
        pcm_data,
        (int)targetSampleRate,
        (int)frameSize,
        (int)hopSize,
        (int)numBands,
        (float)minFreq,
        (float)maxFreq,
        (float)power);
    
    return convert2DToJava2DArray(env, mel);
}
