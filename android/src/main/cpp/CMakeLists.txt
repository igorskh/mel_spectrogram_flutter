cmake_minimum_required(VERSION 3.22.1)
project("MelSpectrogramFlutterPlugin")

# Include headers from the .h files
include_directories(
    ${CMAKE_SOURCE_DIR}/miniaudio
    ${CMAKE_SOURCE_DIR}/mel_spectrogram_pocketfft
)

# Build your JNI bridge as a shared library
add_library(
    native-bridge
    SHARED
    native-bridge.cpp
)

find_library(log-lib log)

# Link your bridge against the pre-built lib and Android log
target_link_libraries(
    native-bridge
    ${log-lib}
    android
)

target_link_options(
    native-bridge
    PRIVATE
    "-Wl,-z,max-page-size=16384"
)