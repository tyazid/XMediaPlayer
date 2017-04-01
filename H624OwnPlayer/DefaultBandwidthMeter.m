//
//  AbrBandwidthMeter.m
//  XMediaPlayer
//
//  Created by tyazid on 29/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "DefaultBandwidthMeter.h"
#import "XPCore.h"
#import "XPUtil.h"
#include <math.h>

@interface DefaultBandwidthMeter()
 @property (nonatomic, readonly, strong) SlidingPercentile* slidingPercentile;
@property (nonatomic,  strong) NSMutableArray<id>* set;

@end
@implementation DefaultBandwidthMeter
  static const int DEFAULT_MAX_WEIGHT = 2000;

// static const NSInteger NO_ESTIMATE = -1;
  static const NSUInteger ELAPSED_MILLIS_FOR_ESTIMATE = 2000;
  static const NSUInteger BYTES_TRANSFERRED_FOR_ESTIMATE = 512 * 1024;
  dispatch_group_t group ;
  NSUInteger streamCount;
  NSUInteger sampleStartTimeMs;
  NSUInteger sampleBytesTransferred;

  NSUInteger totalElapsedTimeMs;
  NSUInteger totalBytesTransferred;
  NSInteger bitrateEstimate;

-(instancetype)init
{
    return [self initWithMax:DEFAULT_MAX_WEIGHT andListener:Nil];
}
-(instancetype)initWithMax:(NSUInteger)maxWeight andListener:(id<BandwidthMeterListener>)listener
{
    if(self = [super init])
    {
        _listener = listener;
        _slidingPercentile=[[SlidingPercentile alloc] initWithMax:maxWeight];
        bitrateEstimate=[DefaultBandwidthMeter NO_ESTIMATE];
        _set=[NSMutableArray new];
        group = dispatch_group_create();
    }
    return self;
}
-(NSInteger)getBitrateEstimate
{
    return bitrateEstimate;
    
}
+ (NSInteger)NO_ESTIMATE{
    return -1L;
}

-(void)onTransferStart:(id)source{
   if(![[self set] containsObject:source])
       [[self set] addObject:source];
    
    if (streamCount == 0) {
 
        sampleStartTimeMs = [XPUtil systemUpTime]*1000;// SystemClock.elapsedRealtime();
        
        // System.out.println("# START AT :"+sampleStartTimeMs);
    }
    streamCount++;
    
}

-(NSUInteger)getStreamCount{
    return streamCount;
}
-(void) onBytesTransferred:(id)source transferred:(NSUInteger)bytes
{
    sampleBytesTransferred += bytes;
}

-(void) onTransferEnd:(id)source
{
    if (!(streamCount > 0))
      @throw   [NSException
         exceptionWithName:@"Illegal state"
         reason:@"streamCount<=0 "
                userInfo:nil];
     NSUInteger nowMs =  (NSUInteger)([XPUtil systemUpTime] * 1000.);
    __block NSUInteger sampleElapsedTimeMs = (int) (nowMs - sampleStartTimeMs);
    totalElapsedTimeMs += sampleElapsedTimeMs;
    totalBytesTransferred += sampleBytesTransferred;
   // NSLog(@"======================== END TRANSFERT : sampleElapsedTimeMs=%ld, Transfered :%ld",sampleElapsedTimeMs,sampleBytesTransferred );

    if (sampleElapsedTimeMs > 0) {
        float bitsPerSecond = (sampleBytesTransferred * 8000) / sampleElapsedTimeMs;
        [[self slidingPercentile] addSample:(NSUInteger) sqrt(sampleBytesTransferred) value:bitsPerSecond];
        
         if (totalElapsedTimeMs >= ELAPSED_MILLIS_FOR_ESTIMATE
            || totalBytesTransferred >= BYTES_TRANSFERRED_FOR_ESTIMATE) {
             float bitrateEstimateFloat = [[self slidingPercentile] getPercentile:0.5f];
             bitrateEstimate = isnan(bitrateEstimateFloat)  ? [DefaultBandwidthMeter NO_ESTIMATE] : (long) bitrateEstimateFloat;
        }
    }
    
    if(_listener){
        //capture var
        __block NSUInteger byteTransfered = sampleBytesTransferred;
        __block  NSUInteger estimated = bitrateEstimate;
    
    dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        [ _listener onBandwidthSample:sampleElapsedTimeMs transferred:byteTransfered bitrate:estimated];
    });
    }
   
    if (--streamCount > 0) {
        sampleStartTimeMs = nowMs;
    } 
    sampleBytesTransferred = 0;
}

@end
