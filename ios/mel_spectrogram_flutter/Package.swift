// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    // TODO: Update your plugin name.
    name: "mel_spectrogram_flutter",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "mel-spectrogram-flutter", targets: ["mel_spectrogram_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "MelSpectrogramBridge",
            path: "Sources/MelSpectrogramBridge",
            sources: [
                "MelSpectrogramBridge.mm"
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath(".")
            ],
            linkerSettings: [
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("AVFAudio")
            ]
        ),
        .target(
            name: "mel_spectrogram_flutter",
            dependencies: [
                "MelSpectrogramBridge"
            ],
            path: "Sources/mel_spectrogram_flutter",
            sources: [
                "MelSpectrogramFlutterPlugin.swift"
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
