//
//  XPCore.h
//  XMediaPlayer
//
//  Created by tyazid on 24/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

/*
 
 
 
 
   
 
 
 

 
 */
#ifndef XPCore_h
#define XPCore_h
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>




#define DEFAULT_MAX_INITIAL_BITRATE 800000
#define DEFAULT_MIN_DURATION_FOR_QUALITY_INCREASE_MS 10000
#define CACHING_MIN_DURATION_FOR_QUALITY_INCREASE_MS 15000
#define DEFAULT_MAX_DURATION_FOR_QUALITY_DECREASE_MS 25000
#define DEFAULT_MEDIUM_DURATION_FOR_QUALITY_MS 17500
#define DEFAULT_BANDWIDTH_FRACTION 0.75f



@protocol MediaConsumer;
@protocol MediaConsumCB;
typedef NS_ENUM(NSInteger, MediaExtractorConsumeEvent) {
    START_CONSUME,
    END_CONSUME,
    
};
//typedef BOOL (^consumeFnt)(CMSampleBufferRef* data, NSUInteger pts);
typedef void (^DataSourceOpenCb)(BOOL success,NSString* errMsg);
typedef void (^MediaExtractorCB)(MediaExtractorConsumeEvent event);

/**
 * Media Reader.
 */
@protocol MediaReader <NSObject>
typedef NS_ENUM(NSInteger, MediaReaderType) {
    H263_TYPE,
    H264_TYPE,
    MPEG1VIDEO_TYPE,
    MPEG2VIDEO_TYPE,
    MPEG4_TYPE,
    AAC_TYPE,
    AC3_TYPE,
    TXT_TYPE
};
@required
@property  id<MediaConsumer> consumeFrame ;
@property  id<MediaConsumCB> consumeCB ;

//MediaConsumCB
@required
@property (nonatomic,readonly) MediaReaderType type;
@required
-(void)startStream;
-(void)endStream;
-(void) setPacket:(const char*) ptr withOffset:(NSUInteger)offset andSize:(NSUInteger)size isFirst:(BOOL)first;
-(void) setFrameConf:(NSUInteger) pts withdts:(NSUInteger) dts  withFps:(double)fps;
-(void) signalNewFrame:(NSUInteger)frameNumber;
@end

/**
 * Media extrator
 */
@protocol MediaDataSource <NSObject>
typedef NS_ENUM(NSInteger, DataSourceState) {
    IDLE,
    LOADING,
    LOADED,
    FAILED
};
@property (readonly) NSUInteger dataSize ;
@property (readonly) DataSourceState state ;

-(void)close;
/*
 * perform a connection (file, http, ftp...) and retreive data
 */
-(void)open:(DataSourceOpenCb) cb ;
 -(NSInteger)read:(uint8_t*)buffer withOffset:(NSUInteger)offset andSize:(NSUInteger)size;
-(NSInteger)read: (uint8_t*)buffer fromDataPosition:(NSUInteger)dataPos withOffset:(NSUInteger)offset andSize:(NSUInteger)size;


@end

/**
 Media reader factory
 **/
@interface MediaReaderFactory : NSObject
+(id<MediaReader>) getMediaReader : (MediaReaderType) type;
-(instancetype) init __attribute__((unavailable("init not available for util class")));
@end



/**
 * Media consumer.
 */
@protocol MediaConsumer <NSObject>
typedef NS_ENUM(NSInteger, MediaConsumerType) {
    AUDIO_CONSUMER,
    VIDEO_CONSUMER,
    TEXT_CONSUMER
    
};
@property (nonatomic, readonly) MediaConsumerType type;

@required
-(BOOL)consume :(CMSampleBufferRef)buffer at: (NSUInteger) pts withDts:(NSUInteger) dts andFps:(double) fps consumerBaseTime:(NSUInteger)time;
@end

@protocol MediaConsumCB <NSObject>

@required
-(void) startConsume;
-(void) endConsume;
@end

/**
 * Media extrator
 */
@protocol MediaExtractor <NSObject>
@required
@property MediaExtractorCB extractorCB;

-(void)seek:(NSUInteger)position;
-(BOOL)setDataSource:(id<MediaDataSource>)dataSource;
-(BOOL)setData:(NSData*)data;
-(void)setMediaConsumer:(id<MediaConsumer>)dataSource;
//must call init first
-(NSDictionary<NSNumber*,id<MediaReader>>*)getReaders;
@end

/**
 *Band width meter.
 */

@protocol BandwidthMeterListener <NSObject>
 -(void) onBandwidthSample : (NSUInteger) elapsedMs  transferred:(NSUInteger) bytes  bitrate:(NSUInteger) bitrates;

@end

@protocol BandwidthMeter <NSObject>
@property (atomic) id<BandwidthMeterListener> listener;
-(NSInteger)getBitrateEstimate;

@end



/**
 * Media renderer
 */
@protocol MediaRenderer <MediaConsumer>

@property (nonatomic) MediaConsumerType type;

-(CMTime*)getClock;
@end


#endif /* XPCore_h */
