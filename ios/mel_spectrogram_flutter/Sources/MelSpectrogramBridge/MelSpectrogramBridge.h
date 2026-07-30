//
//  MelSpectrogramBridge.h
//


#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface MelSpectrogramBridge : NSObject

+ (NSArray<NSNumber*>*)decodeFile:(NSString*)filePath
                        sampleRate:(double)sampleRate;

+ (NSArray<NSArray<NSNumber*>*>*)computeMelSpectrogram:(const float*)samples
                                                                length:(NSUInteger)length
                                                                sampleRate:(double)sampleRate
                                                                frameSize:(NSUInteger)frameSize
                                                                hopSize:(NSUInteger)hopSize
                                                                numBands:(NSUInteger)numBands
                                                                minFreq:(double)minFreq
                                                                maxFreq:(double)maxFreq
                                                                power:(double)power;

+ (NSArray<NSArray<NSNumber*>*>*)decodeFileAndComputeMelSpectrogram:(NSString*)filePath
                            sampleRate:(double)sampleRate
                            frameSize:(NSUInteger)frameSize
                            hopSize:(NSUInteger)hopSize
                            numBands:(NSUInteger)numBands
                            minFreq:(double)minFreq
                            maxFreq:(double)maxFreq
                            power:(double)power;


+ (NSArray<NSString*>*)listCaptureDevices;


@end

NS_ASSUME_NONNULL_END
