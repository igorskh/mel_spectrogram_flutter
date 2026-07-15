#import "MelSpectrogramBridge.h"

#include "mel_spectrogram_pocketfft.h"

#define MINIAUDIO_IMPLEMENTATION
#define MA_NO_ENCODING
#define MA_NO_ENGINE
#define MA_NO_NODE_GRAPH
#include "miniaudio.h"

#include <vector>

@implementation MelSpectrogramBridge

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
        fprintf(stderr, "Failed to open file: %s (error %d)\n", file_path, result);
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


+ (NSArray<NSArray<NSNumber*>*>*)computeMelSpectrogram:(const float*)samples
                                                                length:(NSUInteger)length
                                                             sampleRate:(double)sampleRate
                                                             frameSize:(NSUInteger)frameSize
                                                               hopSize:(NSUInteger)hopSize
                                                               numBands:(NSUInteger)numBands 
                                                               minFreq:(double)minFreq
                                                               maxFreq:(double)maxFreq 
                                                               power:(double)power {

    std::vector<float> input(samples, samples + length);
    std::vector<std::vector<float>> mel_spectrogram = mel_spectrogram::compute_mel_spectrogram(input, sampleRate, frameSize, hopSize, numBands, minFreq, maxFreq, power);

    NSMutableArray<NSMutableArray<NSNumber*>*> *result = [NSMutableArray arrayWithCapacity:mel_spectrogram.size()];
    for (const auto &frame : mel_spectrogram)
    {
        NSMutableArray<NSNumber*> *frame_array = [NSMutableArray arrayWithCapacity:frame.size()];
        for (float value : frame)
        {
            [frame_array addObject:@(value)];
        }
        [result addObject:frame_array];
    }
    return result;
}

+ (NSArray<NSArray<NSNumber*>*>*)decodeFileAndComputeMelSpectrogram:(NSString*)filePath
                          sampleRate:(double)sampleRate
                          frameSize:(NSUInteger)frameSize
                            hopSize:(NSUInteger)hopSize
                            numBands:(NSUInteger)numBands
                            minFreq:(double)minFreq
                            maxFreq:(double)maxFreq
                            power:(double)power {

    std::vector<float> pcm_data;
    read_pcm_frames([filePath UTF8String], pcm_data, sampleRate);

    std::vector<std::vector<float>> mel_spectrogram = mel_spectrogram::compute_mel_spectrogram(
        pcm_data, sampleRate, frameSize, hopSize, numBands, minFreq, maxFreq, power);

    NSMutableArray<NSMutableArray<NSNumber*>*> *result = [NSMutableArray arrayWithCapacity:mel_spectrogram.size()];
    for (const auto &frame : mel_spectrogram)
    {
        NSMutableArray<NSNumber*> *frame_array = [NSMutableArray arrayWithCapacity:frame.size()];
        for (float value : frame)
        {
            [frame_array addObject:@(value)];
        }
        [result addObject:frame_array];
    }
    return result;
}

+ (NSArray<NSNumber*>*)decodeFile:(NSString*)filePath
                      sampleRate:(double)sampleRate {
    std::vector<float> pcm_data;
    read_pcm_frames([filePath UTF8String], pcm_data, sampleRate);

    NSMutableArray<NSNumber*> *result = [NSMutableArray arrayWithCapacity:pcm_data.size()];
    for (float value : pcm_data)    {
        [result addObject:@(value)];
    }
    return result;
}

+ (NSArray<NSString*>*)listCaptureDevices {
    ma_context context;
    ma_result res = ma_context_init(NULL, 0, NULL, &context);
    if (res != MA_SUCCESS)
    {
        fprintf(stderr, "Failed to initialize miniaudio context (error %d)\n", res);
        return nil;
    }

    ma_device_info* pDeviceInfos;
    ma_uint32 deviceCount;
    res = ma_context_get_devices(&context, NULL, &deviceCount, &pDeviceInfos, NULL);
    if (res != MA_SUCCESS)
    {
        fprintf(stderr, "Failed to get devices (error %d)\n", res);
        ma_context_uninit(&context);
        return nil;
    }

    std::vector<std::string> device_names;
    for (ma_uint32 i = 0; i < deviceCount; ++i)
    {
        device_names.push_back(pDeviceInfos[i].name);
    }

    ma_context_uninit(&context);

    NSMutableArray<NSString*> *result = [NSMutableArray arrayWithCapacity:device_names.size()];
    for (const auto& name : device_names) {
        [result addObject:@(name.c_str())];
    }
    return result;
}

@end

