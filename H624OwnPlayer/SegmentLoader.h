//
//  SegmentLoader.h
//  XMediaPlayer
//
//  Created by tyazid on 30/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DefaultBandwidthMeter.h"
#import "DataSegment.h"
#import "XPCore.h"

@interface SegmentLoader : NSObject
@property (atomic,readonly)BOOL started;
@property (atomic)BOOL enableConsume;

-(instancetype)initWithBandwidthMeter:(DefaultBandwidthMeter*)meter;
-(instancetype) init __attribute__((unavailable("init not available")));
-(void)addDataSegment:(DataSegment*)segment;
-(BOOL)start;
-(BOOL)stop;
-(void)clear;
-(void)purgeDoneSegmentsAfterTime:(NSTimeInterval)timeSec;
-(BOOL)segmentAtIndexIsLoaded:(NSUInteger)index;
-(void)setTypedConsumer:(id<MediaConsumer>) mediaConsumer;
-(double)loadedEndTime;

@end
