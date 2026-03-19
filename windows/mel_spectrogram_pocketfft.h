#pragma warning(push)
#pragma warning(disable: 4127) 
#pragma warning(disable: 4324) 
#include "pocketfft_hdronly.h"
#pragma warning(pop)

#include <vector>
#include <complex>
#include <cmath>
#include <cstddef>
#include <stdexcept>
#include <thread>
#include <algorithm>

using namespace pocketfft;

namespace mel_spectrogram
{

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

    static inline float hz_to_mel(float hz)
    {
        return 2595.0f * std::log10(1.0f + hz / 700.0f);
    }

    static inline float mel_to_hz(float mel)
    {
        return 700.0f * (std::pow(10.0f, mel / 2595.0f) - 1.0f);
    }

    // ---------- Portable parallel_for using std::thread ----------

    static void parallel_for(int start, int end, int n_threads,
                             std::function<void(int thread_id, int lo, int hi)> body)
    {
        if (end <= start)
            return;

        n_threads = std::min(n_threads, end - start);
        n_threads = std::max(n_threads, 1);

        std::vector<std::thread> threads;
        threads.reserve(n_threads);

        int total = end - start;
        int chunk = total / n_threads;
        int remainder = total % n_threads;

        int lo = start;
        for (int t = 0; t < n_threads; ++t)
        {
            // Distribute remainder evenly across the first threads
            int hi = lo + chunk + (t < remainder ? 1 : 0);
            threads.emplace_back(body, t, lo, hi);
            lo = hi;
        }

        for (auto &th : threads)
            th.join();
    }

    // ---------- Mel filterbank (Slaney-style, librosa-like) ----------
    struct MelFilter
    {
        int start_bin;              // first non-zero bin
        int end_bin;                // one past last non-zero bin
        std::vector<float> weights; // only non-zero weights
    };

    static std::vector<MelFilter> create_mel_filterbank_sparse(
        int n_fft, int n_mels, int sample_rate, float fmin, float fmax)
    {
        int n_fft_bins = n_fft / 2 + 1;
        float mel_min = hz_to_mel(fmin);
        float mel_max = hz_to_mel(fmax);

        // n_mels + 2 points (including start/end)
        std::vector<float> mel_points(n_mels + 2);
        float mel_step = (mel_max - mel_min) / (n_mels + 1);
        for (int i = 0; i < n_mels + 2; ++i)
        {
            mel_points[i] = mel_min + mel_step * i;
        }

        // Convert mel points to FFT bin indices
        std::vector<int> bin_points(n_mels + 2);
        for (int i = 0; i < n_mels + 2; ++i)
        {
            float hz = mel_to_hz(mel_points[i]);
            int bin = static_cast<int>(std::floor(n_fft * hz / sample_rate));
            if (bin < 0)
                bin = 0;
            if (bin > n_fft_bins - 1)
                bin = n_fft_bins - 1;
            bin_points[i] = bin;
        }
        std::vector<MelFilter> filters(n_mels);
        for (int m = 0; m < n_mels; ++m)
        {
            int left = bin_points[m];
            int center = bin_points[m + 1];
            int right = bin_points[m + 2];
            if (center <= left || right <= center)
                continue;

            filters[m].start_bin = left;
            filters[m].end_bin = right;
            filters[m].weights.resize(right - left, 0.0f);

            for (int k = left; k < center; ++k)
                filters[m].weights[k - left] =
                    static_cast<float>(k - left) / (center - left);
            for (int k = center; k < right; ++k)
                filters[m].weights[k - left] =
                    static_cast<float>(right - k) / (right - center);
        }
        return filters;
    }

    // ---------- Main Mel spectrogram computation using pocketfft ----------

    std::vector<std::vector<float>> compute_mel_spectrogram(
        const std::vector<float> &audio,
        int sample_rate,
        int n_fft,
        int hop_length,
        int n_mels,
        float fmin,
        float fmax,
        float power = 2.0f)
    {
        if (audio.size() < static_cast<size_t>(n_fft))
            return {}; // not enough samples

        int n_frames = 1 + static_cast<int>((audio.size() - n_fft) / hop_length);
        int n_fft_bins = n_fft / 2 + 1;

        // Precompute Hann window
        std::vector<float> window(n_fft);
        const float two_pi = 2.0f * static_cast<float>(M_PI);
        for (int n = 0; n < n_fft; ++n)
        {
            window[n] = 0.5f - 0.5f * std::cos(two_pi * n / (n_fft - 1));
        }

        // Precompute mel filterbank
        auto mel_fb = create_mel_filterbank_sparse(n_fft, n_mels, sample_rate, fmin, fmax);

        // pocketfft shapes/strides for 1D r2c transform
        shape_t shape{static_cast<size_t>(n_fft)};
        stride_t stride_in{sizeof(float)};
        stride_t stride_out{sizeof(std::complex<float>)};
        shape_t axes{0};

        // Pre-allocate output (each frame's slice is written by exactly one thread)
        std::vector<std::vector<float>> mel_spec(
            n_frames, std::vector<float>(n_mels, 0.0f));

        // Determine thread count
        int n_threads = static_cast<int>(std::thread::hardware_concurrency());
        if (n_threads <= 0)
            n_threads = 1;
        n_threads = std::min(n_threads, n_frames);

        // Pre-allocate per-thread scratch buffers to avoid
        // heap allocations inside the hot loop
        std::vector<std::vector<float>> t_frames(
            n_threads, std::vector<float>(n_fft));
        std::vector<std::vector<std::complex<float>>> t_spectra(
            n_threads, std::vector<std::complex<float>>(n_fft_bins));
        std::vector<std::vector<float>> t_mag_exp(
            n_threads, std::vector<float>(n_fft_bins));

        parallel_for(0, n_frames, n_threads,
                     [&](int tid, int lo, int hi)
                     {
                         // Each thread uses its own scratch buffers
                         auto &frame = t_frames[tid];
                         auto &spectrum = t_spectra[tid];
                         auto &mag_exp = t_mag_exp[tid];

                         for (int frame_idx = lo; frame_idx < hi; ++frame_idx)
                         {
                             size_t start = static_cast<size_t>(frame_idx * hop_length);

                             // Windowed frame -> float array
                             for (int i = 0; i < n_fft; ++i)
                             {
                                 frame[i] = audio[start + i] * window[i];
                             }

                             // Real-to-complex FFT: frame -> spectrum
                             r2c(shape, stride_in, stride_out, axes, FORWARD,
                                 frame.data(), spectrum.data(), 1.0f);

                             // ---- Magnitude exponentiation ----
                             for (int k = 0; k < n_fft_bins; ++k)
                             {
                                 float re = spectrum[k].real();
                                 float im = spectrum[k].imag();
                                 if (power == 2.0f)
                                 {
                                     mag_exp[k] = re * re + im * im;
                                 }
                                 else
                                 {
                                     float mag = std::sqrt(re * re + im * im);
                                     mag_exp[k] = std::pow(mag, power);
                                 }
                             }

                             // Apply sparse mel filterbank
                             for (int m = 0; m < n_mels; ++m)
                             {
                                 const auto &f = mel_fb[m];
                                 float e = 0.0f;
                                 for (int k = 0; k < static_cast<int>(f.weights.size()); ++k)
                                 {
                                     e += mag_exp[f.start_bin + k] * f.weights[k];
                                 }
                                 mel_spec[frame_idx][m] = e;
                             }
                         }
                     });

        return mel_spec;
    }

}