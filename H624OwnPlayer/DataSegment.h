//
//  DataSegment.h
//  XMediaPlayer
//
//  Created by tyazid on 29/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "M3U8SegmentInfo.h"
#import "XPCore.h"
//#define DSEG_DBG

@interface DataSegment : NSObject
typedef NS_ENUM(NSInteger, DataSegmentState) {
    Idle, Loading, Loaded, Failed, Cancelled
};
@property BOOL consuming;

@property (readonly,nonatomic) M3U8SegmentInfo* segment;
@property (readonly,nonatomic) BOOL consumed;
@property (readonly,nonatomic) BOOL playing;


@property (nonatomic) DataSegmentState state;
@property (atomic) NSData* data;
-(instancetype)initWith: (M3U8SegmentInfo*)segment ;
-(BOOL) load;
-(void) invalidate;
/*-(void)consume:(MediaExtractorCB) cb
   consumeType:(MediaConsumerType)type
        source:(id<MediaConsumer>)mediaConsumer;*/

-(void)consume:(MediaExtractorCB) cb
     consumers:(NSMutableDictionary<NSNumber*,id<MediaConsumer>> *)consumers;

//(MediaConsumerType)type source:(id<MediaConsumer>)dataSource
-(instancetype) init __attribute__((unavailable("init not available")));

 @end
