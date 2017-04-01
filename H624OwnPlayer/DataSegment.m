//
//  DataSegment.m
//  XMediaPlayer
//
//  Created by tyazid on 29/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "DataSegment.h"
#import "TsExtractor.h"
@interface DataSegment()
@property MediaExtractorCB inCb, outCb;
@property TsExtractor* tsExtractor;
@property BOOL playP;
@property BOOL comsumeP;
@property BOOL valid;

+(dispatch_group_t)segmentLoaderGrp;
+(dispatch_queue_t)segmentLoaderQueue;
@end
@implementation DataSegment
+(dispatch_queue_t)segmentLoaderQueue
{
    static dispatch_queue_t q=Nil;
    if(!q)
        q= dispatch_queue_create("XPlayer-DataSegment", NULL);
    return q;
}

//intenal cb MediaExtractorCB
+(dispatch_group_t)segmentLoaderGrp
{
    static dispatch_group_t segmentLoaderGrp=Nil;
    if(!segmentLoaderGrp)
        segmentLoaderGrp = dispatch_group_create();
    return segmentLoaderGrp;
}

-(BOOL)consumed{
    
    return _comsumeP;
}
-(BOOL)playing{
    return _playP;
}
-(instancetype)initWith: (M3U8SegmentInfo*)segment{
    if(self= [super init])
    {
        _segment = segment;
        _data = Nil;
        _playP= _comsumeP=_consuming=NO;
        self.valid=YES;
        __block DataSegment *blocksafeSelf = self;
        _inCb = ^(MediaExtractorConsumeEvent event)
        {
            if(! blocksafeSelf.valid)
                return;
#ifdef DSEG_DBG
            NSLog(@"*********** IN DSEG EVT : %lu SEG:%@", event,blocksafeSelf.segment.URI);
#endif
            
            if(event ==START_CONSUME )
            {
                blocksafeSelf.playP = YES;
            }
            else  if(event ==END_CONSUME )
            {
                blocksafeSelf.comsumeP = YES;
                blocksafeSelf.consuming=NO;
                blocksafeSelf.playP=NO;
            }
#ifdef DSEG_DBG
            
            NSLog(@"*********** IN DSEG NEW STATE P:%i C:%i",[blocksafeSelf playing], [blocksafeSelf consumed]);
#endif
            
            if([blocksafeSelf outCb])
                [blocksafeSelf outCb](event);
            if(event ==END_CONSUME )
                dispatch_group_leave([DataSegment segmentLoaderGrp]);
        };
        
    }
    
    return self;
}
-(void)consume:(MediaExtractorCB) cb
     consumers:(NSMutableDictionary<NSNumber*,id<MediaConsumer>> *)consumers
 {
#ifdef DSEG_DBG
    
    NSLog(@"********** IN DATA SEGMENT consume:%@ CONSUMER:%i cb:%i  ",self,consumers && [consumers count]?YES:NO, cb?YES:NO);
#endif
 
    [self setOutCb:cb];
    [self setTsExtractor:[TsExtractor new]];
    
     for (id<MediaConsumer> consumer in [consumers allValues])
          [[self tsExtractor] setMediaConsumer:consumer];
     
    [[self tsExtractor] setExtractorCB:[self inCb]];
    //segmentLoaderGrp
    dispatch_group_enter([DataSegment segmentLoaderGrp]);
    
    //segmentLoaderQueue
    dispatch_async([DataSegment segmentLoaderQueue], ^{
        
#ifdef DSEG_DBG
 NSLog(@"********** IN DATA SEGMENT Data extracted for SEG:%@",[[self segment] mediaURL]);
#endif
        
#ifdef DSEG_DBG
        BOOL extracted  =
#endif
        [[self tsExtractor] setData:[self data]]; /// go go go
        
        
#ifdef DSEG_DBG
        
        NSLog(@"********** IN DATA SEGMENT Data extracted : %i",extracted);
#endif
        //        dispatch_group_leave([DataSegment segmentLoaderGrp]);
    });
    
    
    
}
-(void)dealloc{
    [self setData:Nil];
    

}

-(void) invalidate{
    self.valid = NO;
    if([self tsExtractor])
    {
        
    }
   }



-(BOOL)load
{
#ifdef DSEG_DBG
    NSLog(@"****** IN DATA SEGMENT WILL LOAD : %@", [[self segment] mediaURL]);
#endif
    NSURL* url =[NSURL URLWithString:[[self segment] mediaURL]];
 
    [self setData:[NSData dataWithContentsOfURL:url]];
    url = Nil;
#ifdef DSEG_DBG
    NSLog(@"****** IN DATA SEGMENT WILL LOAD  DONE : %ld", [self data]? ([[self data] length]) :(-1) );
#endif
    
    return [self data] && [[self data]length]? YES: NO;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"DataSegment: SEG:(%@); Consumed:%i; Playing:%i\n",[[self segment] URI], [self consumed],[self playing]];
}
@end
