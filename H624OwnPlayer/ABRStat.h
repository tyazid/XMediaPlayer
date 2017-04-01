//
//  ABRStat.h
//  XMediaPlayer
//
//  Created by tyazid on 31/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "M3U8Kit.h"
 
#define MAX_SEG_BITRATE             @"vqan.max.br"
#define REQUESTED_SEG_BITRATE       @"vqan.req.br"
#define APPLIED_SEG_BITRATE         @"vqan.app.br"
#define APPLIED_SEG                 @"vqan.app.seg"
#define REQUESTED_SEG               @"vqan.req.seg"
#define MAX_SEG                     @"vqan.max.seg"

#define OBSERVED_BITRATE            @"vqan.observed.br"
#define MIN_OBSERVED_SEG_BITRATE    @"vqan.min.seg.br"
#define MAX_OBSERVED_SEG_BITRATE    @"vqan.max.seg.br"
#define CAUSED_SWITCH_BITRATE       @"vqan.switch.seg.br"





@interface ABRStat : NSObject


@property (readonly ) NSUInteger MaxBitrate;
@property (readonly ) NSUInteger RequestedBitrate;
@property (readonly ) NSUInteger AppliedBitrate;
@property (readonly ) NSUInteger EstimatedBitrate;

@property (readonly ) NSTimeInterval When;

@property (readonly ) M3U8SegmentInfo* AppliedSegment;
@property (readonly ) M3U8SegmentInfo* RequestedSegment;
@property (readonly ) M3U8SegmentInfo* TopSegment;

-(instancetype)initWithDictionary:(NSDictionary *)dictionary ;

@end
