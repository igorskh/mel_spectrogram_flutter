package one.beagile.mel_spectrogram_flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMethodCodec

// import java.util.concurrent.Executors

/** MelSpectrogramFlutterPlugin */
class MelSpectrogramFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    // private val executor = Executors.newSingleThreadExecutor()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val taskQueue = flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()

        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "mel_spectrogram_flutter", 
            StandardMethodCodec.INSTANCE, 
            taskQueue)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "computeMelSpectrogram") {            
            val audioSamples = call.argument<FloatArray>("audioSamples")!!
            val sampleRate = call.argument<Int>("sampleRate")!!
            val frameSize = call.argument<Int>("frameSize")!!
            val hopSize = call.argument<Int>("hopSize")!!
            val numBands = call.argument<Int>("numBands")!!
            val maxChunkSize = call.argument<Int>("maxChunkSize") ?: (sampleRate * 30) // Default: 30 seconds
            var minFreq = call.argument<Int>("minFreq") ?: 0 // Default: 0 Hz
            var maxFreq = call.argument<Int>("maxFreq") ?: (sampleRate / 2) // Default: Nyquist frequency
            var power = call.argument<Double>("power") ?: 2.0f // Default: power=2.0 (magnitude squared)
            
            try {
                val melSpec = NativeBridge.computeMelSpectrogram(
                    audioSamples,
                    sampleRate,
                    frameSize,
                    hopSize,
                    numBands,
                    minFreq,
                    maxFreq,
                    power.toFloat()
                )
                val resultConv: List<List<Float>> = melSpec!!.map { row -> row.map { it } }
                result.success(resultConv)
            } catch (e: Exception) {
                result.error(
                    "COMPUTE_ERROR",
                    e.message ?: "Unknown computation error",
                    null
                )
            }
        } else if (call.method == "decodeFile") { 
            val filePath = call.argument<String>("filePath")!!
            val targetSampleRate = call.argument<Int>("targetSampleRate") ?: 44100
            
            try {
                val audioSamples = NativeBridge.decodeFile(filePath, targetSampleRate)
                if (audioSamples != null) {
                    result.success(audioSamples)
                } else {
                    result.error(
                        "DECODE_ERROR",
                        "Failed to decode file: $filePath",
                        null
                    )
                }
            } catch (e: Exception) {
                result.error(
                    "DECODE_ERROR",
                    e.message ?: "Unknown decoding error",
                    null
                )
            }
        } else if (call.method == "decodeFileAndComputeMelSpectrogram") { 
            val filePath = call.argument<String>("filePath")!!
            val targetSampleRate = call.argument<Int>("targetSampleRate") ?: 44100
            val frameSize = call.argument<Int>("frameSize")!!
            val hopSize = call.argument<Int>("hopSize")!!
            val numBands = call.argument<Int>("numBands")!!
            var minFreq = call.argument<Int>("minFreq") ?: 0 // Default: 0 Hz
            var maxFreq = call.argument<Int>("maxFreq") ?: (targetSampleRate / 2) // Default: Nyquist frequency
            var power = call.argument<Double>("power") ?: 2.0 // Default: power=2.0 (magnitude squared)
    
            try {
                val melSpec = NativeBridge.decodeFileAndComputeMelSpectrogram(
                    filePath,
                    targetSampleRate,
                    frameSize,
                    hopSize,
                    numBands,
                    minFreq,
                    maxFreq,
                    power.toFloat()
                )
                if (melSpec != null) {
                    val resultConv: List<List<Float>> = melSpec!!.map { row -> row.map { it } }
                    result.success(resultConv)
                } else {
                    result.error(
                        "DECODE_COMPUTE_ERROR",
                        "Failed to decode and compute spectrogram for file: $filePath",
                        null
                    )
                }
            } catch (e: Exception) {
                result.error(
                    "DECODE_COMPUTE_ERROR",
                    e.message ?: "Unknown error during decode and compute",
                    null
                )
            }
        } else if (call.method == "listCaptureDevices") {
            try {
                val devices = NativeBridge.listCaptureDevices()
                if (devices != null) {
                    result.success(devices.toCollection(ArrayList()))
                } else {
                    result.error(
                        "LIST_DEVICES_ERROR",
                        "Failed to list capture devices",
                        null
                    )
                }
            } catch (e: Exception) {
                result.error(
                    "LIST_DEVICES_ERROR",
                    e.message ?: "Unknown error during listing devices",
                    null
                )
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
