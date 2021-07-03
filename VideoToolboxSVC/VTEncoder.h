//
//  VTEncoder.h
//  VideoToolboxSVCTests
//
//  Created by Joey on 2021/7/2.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface VTEncoder : NSObject

- (instancetype)initWithExportPath:(NSString *)path duration:(NSTimeInterval)duration;

- (void)prepareVideoToolBox;

- (void)encode:(CMSampleBufferRef)sampleBuffer;

- (void)start;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
