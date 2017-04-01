//
//  ABRStat.m
//  XMediaPlayer
//
//  Created by tyazid on 31/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

/*
 
 #define MXNOTEKEY   @"svq.max.note"
 #define RQNOTEKEY   @"svq.req.note"
 #define APPNOTEKEY  @"svq.app.note"
 #define MXBTRATE    @"svq.max.br"
 #define RQBITRATE   @"svq.req.br"
 #define APPBTRATE   @"svq.app.br"
 #define ESTBITRATE  @"svq.est.br"
 #define APPSEGKEY   @"svq.app.seg"
 #define RQSEGKEY    @"svq.req.seg"
 #define TOPSEGKEY   @"svq.max.seg"
 
 */
#import "ABRStat.h"
#import "XPUtil.h"
@interface ABRStat()
@property (strong,readonly,nonatomic)NSDictionary * dictionary;
@end

@implementation ABRStat
-( NSUInteger) MaxBitrate {
    return [[self dictionary][MXBITRATE] floatValue];
    
}
-(NSUInteger) RequestedBitrate { return [[self dictionary][RQBITRATE] floatValue];}
-( NSUInteger) AppliedBitrate { return [[self dictionary][APPBITRATE] floatValue];}
-( NSUInteger) EstimatedBitrate { return [[self dictionary][ESTBITRATE] floatValue];}
-( M3U8SegmentInfo*) AppliedSegment {return [self dictionary][APPLIED_SEG];}//later
-( M3U8SegmentInfo*) RequestedSegment {return [self dictionary][REQUESTED_SEG];}//later
-( M3U8SegmentInfo*) TopSegment {return [self dictionary][MAX_SEG];}//later

 
-(instancetype)initWithDictionary:(NSDictionary *)dictionary  {
    
    if(self = [super init])
    {
        _When = [XPUtil systemUpTime];
        _dictionary = dictionary;
    }
    return self;
}
-(NSString*) description{
    return [NSString stringWithFormat:@"ABR STAT: Seg.Bitrate:%lu\n\tReq.Bitrate:%lu\n\tMax.Bitrate:%lu",
            [self AppliedBitrate],
            [self RequestedBitrate],
            [self MaxBitrate]
            ];
}
@end
