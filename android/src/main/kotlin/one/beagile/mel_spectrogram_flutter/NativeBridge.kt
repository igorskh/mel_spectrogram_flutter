package one.beagile.mel_spectrogram_flutter

object NativeBridge {
    init {
        System.loadLibrary("native-bridge")
    }

    external fun returnVersion(): String;

    external fun computeMelSpectrogram(
        audioSamples: FloatArray,
        sampleRate: Int,
        frameSize: Int,
        hopSize: Int,
        numBands: Int,
        minFreq: Int,
        maxFreq: Int,
        power: Float = 2.0f
    ): Array<FloatArray>

    external fun decodeFile(
        filePath: String, 
        targetSampleRate: Int): FloatArray?

    external fun decodeFileAndComputeMelSpectrogram(
        filePath: String,
        targetSampleRate: Int,
        frameSize: Int,
        hopSize: Int,
        numBands: Int,
        minFreq: Int,
        maxFreq: Int,
        power: Float = 2.0f
    ): Array<FloatArray>?

    external fun listCaptureDevices(): Array<String>?
}