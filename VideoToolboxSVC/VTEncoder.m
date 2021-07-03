//
//  VTEncoder.m
//  VideoToolboxSVCTests
//
//  Created by Joey on 2021/7/2.
//

#import "VTEncoder.h"

@interface VTEncoder() {
    VTCompressionSessionRef                     encodingSession;
    CMFormatDescriptionRef                      format;
    CMSampleTimingInfo *                        timingInfo;
    int64_t                                     encodingTimeMills;
}

@property (nonatomic, strong) dispatch_queue_t encodeQueue;
@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, assign) int actualFPS;
@property (nonatomic, copy)   NSString *error;

@end

@implementation VTEncoder

- (instancetype)initWithExportPath:(NSString *)path duration:(NSTimeInterval)duration {
    self = [super init];
    if (self) {
        self.encodeQueue = dispatch_queue_create("encode", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)prepareVideoToolBox {
    int width = 720;
    int height = 1280;
    int fps = 24;
    self.actualFPS = fps;
    int bitrate = 2048000; //2048kbps
    float maxBitrateRatio = 1.5;
    
    __weak VTEncoder *weakEncoder = self;
    dispatch_sync(self.encodeQueue, ^() {
        __strong VTEncoder *weakSelf = weakEncoder;
        CFMutableDictionaryRef encoderSpecification =
                    CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);

        //enable low-latency encoding
        CFDictionarySetValue(encoderSpecification,
                             kVTVideoEncoderSpecification_EnableLowLatencyRateControl,
                             kCFBooleanTrue);

        // Create the compression session
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, encoderSpecification, NULL, NULL, didCompressH264Callback, (__bridge void *)(weakSelf),  &weakSelf->encodingSession);
        if (status != 0) {
            NSLog(@"H264: Unable to create a H264 session, status is %d", (int)status);
            return ;
        }

        // Set the properties
        VTSessionSetProperty(weakSelf->encodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(weakSelf->encodingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_High_AutoLevel);
        //disable B-frame
        VTSessionSetProperty(weakSelf->encodingSession , kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
        //GOP size
        VTSessionSetProperty(weakSelf->encodingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)(@(fps)));
        //FPS
        VTSessionSetProperty(weakSelf->encodingSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)(@(fps)));
        //Target Bitrate
        VTSessionSetProperty(weakSelf->encodingSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(bitrate));
        //Max Bitrate Limitation
        VTSessionSetProperty(weakSelf->encodingSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bitrate * maxBitrateRatio / 8), @1.0]);
        
        //by defualt, all frames will be base layer. here we use 0.5, coz only 0.5 is valid for now
        //low-latency mode is required
        float baseLayerFPSRatio = 0.5;
        CFNumberRef baseLayerFPSRatioRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &baseLayerFPSRatio);
        VTSessionSetProperty(weakSelf->encodingSession, kVTCompressionPropertyKey_BaseLayerFrameRateFraction, baseLayerFPSRatioRef);
        
        //default is 0.6, value in range [0.6, 0.8] is recommanded, iOS 15+ is needed
//        float baseLayerBitrateRatio = 0.6;
//        CFNumberRef baseLayerBitrateRatioRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &baseLayerBitrateRatio);
//        VTSessionSetProperty(self->encodingSession, kVTCompressionPropertyKey_BaseLayerBitRateFraction, baseLayerBitrateRatioRef);
        
        // Tell the encoder to start encoding
        VTCompressionSessionPrepareToEncodeFrames(weakSelf->encodingSession);
    });

    self.initialized = YES;
}

- (void)encode:(CMSampleBufferRef )sampleBuffer {
    __weak VTEncoder *weakEncoder = self;
    dispatch_sync(self.encodeQueue, ^{
        __strong VTEncoder *weakSelf = weakEncoder;

        if (!weakSelf.initialized) {
            return;
        }
        int64_t currentTimeMills = CFAbsoluteTimeGetCurrent() * 1000;
        if (-1 == weakSelf->encodingTimeMills) {
            weakSelf->encodingTimeMills = currentTimeMills;
        }
        int64_t encodingDuration = currentTimeMills - weakSelf->encodingTimeMills;
        // Get the CV Image buffer
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        
        // Create properties
        CMTime pts = CMTimeMake(encodingDuration, 1000.); // timestamp is in ms.
        CMTime dur = CMTimeMake(1, weakSelf->_actualFPS);
        VTEncodeInfoFlags flags;
        
        // Pass it to the encoder
        OSStatus statusCode = VTCompressionSessionEncodeFrame(weakSelf->encodingSession,
                                                              imageBuffer,
                                                              pts,
                                                              dur,
                                                              NULL, NULL, &flags);
        // Check for error
        if (statusCode != noErr) {
            weakSelf->_error = @"H264: VTCompressionSessionEncodeFrame failed ";
            return;
        }
    });
}


void didCompressH264Callback(void *outputCallbackRefCon,
                             void *sourceFrameRefCon,
                             OSStatus status,
                             VTEncodeInfoFlags infoFlags,
                             CMSampleBufferRef sampleBuffer ) {
    if (status != noErr) {
        NSLog(@"encoder error");
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"encoder sample buffer is not ready");
        return;
    }
        
    CFDictionaryRef dict = (CFDictionaryRef)(CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0));
    
    // Check if we have got a key frame first
    BOOL isKeyframe = !CFDictionaryContainsKey(dict, (const void *)kCMSampleAttachmentKey_NotSync);
    
    CFBooleanRef isBaseLayerRef = (CFBooleanRef)CFDictionaryGetValue(dict, (const void *)kCMSampleAttachmentKey_IsDependedOnByOthers);
    Boolean isBaseLayer = CFBooleanGetValue(isBaseLayerRef);
        
    NSLog(@"encoder sample buffer got, isKey: %@, isBaseLayer: %@", @(isKeyframe), @(isBaseLayer));
}

- (void)endCompresseion {
    self.initialized = NO;
    // Mark the completion
    VTCompressionSessionCompleteFrames(encodingSession, kCMTimeInvalid);
    // End the session
    VTCompressionSessionInvalidate(encodingSession);
    CFRelease(encodingSession);
    encodingSession = NULL;
    _error = NULL;
}


- (void)start {
    [self prepareVideoToolBox];
}

- (void)stop {
    [self endCompresseion];
}


@end
