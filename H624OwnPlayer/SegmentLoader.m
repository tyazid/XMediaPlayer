//
//  SegmentLoader.m
//  XMediaPlayer
//
//  Created by tyazid on 30/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "SegmentLoader.h"
#import "XPUtil.h"
#define MIN_SEG_BEFORE_PLAY 3
@interface SegmentLoader()


@property (strong) NSMutableDictionary<NSNumber*,id<MediaConsumer>>* consumers;

@property (nonatomic,readonly,strong) DefaultBandwidthMeter* listener;
@property MediaExtractorCB myConsumeCB ;
@property (nonatomic,strong) XPBlockingQueue* dataSegments;
@property (nonatomic,strong) NSMutableArray<DataSegment*>* doneSegments;
@property (nonatomic,strong) DataSegment* dataSegment;
@property (nonatomic,strong) id owner;
@property BOOL firstConsumed;
@property NSUInteger loadedSeg;
//SEL
- (void)run:(NSTimer *)timer;

@end
@implementation SegmentLoader

NSLock* doneLock;
-(instancetype)initWithBandwidthMeter:(DefaultBandwidthMeter *)meter
{
    if(self = [super init])
    {
        _listener=meter;
        _loadedSeg=0;
        _firstConsumed=NO;
        _dataSegments=[XPBlockingQueue new];
        _doneSegments = [NSMutableArray new];
        doneLock= [NSLock new];
        _dataSegment=Nil;
        _owner=Nil;
        __block SegmentLoader *blocksafeSelf = self;
        _myConsumeCB =^(MediaExtractorConsumeEvent event) {
            if(event == END_CONSUME)
            {
                if(![blocksafeSelf started])
                    return;
#ifdef DSEG_DBG
                NSLog(@"*********** CONSUME CB  EVT :END_CONSUME  NB SEG : %lu; %@",  blocksafeSelf.doneSegments.count,blocksafeSelf.doneSegments);
#endif
                while(blocksafeSelf.started)
                {
                    //PLAY NEXT
                    [doneLock lock];
                    for (DataSegment* ds in blocksafeSelf.doneSegments) {
#ifdef DSEG_DBG
                        
                        NSLog(@"*********** CONSUME CB LOOP ds: %@ ",ds );
#endif
                        if(ds.playing)//cb ?
                        {
#ifdef DSEG_DBG
                            NSLog(@"*********** CONSUME CB SEG ALREADY PLAYING BREAK : %@",ds.segment.mediaURL);
#endif
                            [doneLock unlock];
                            return ;
                        }
                        if(!ds.consumed && !ds.consuming)
                        {
#ifdef DSEG_DBG
                            NSLog(@"*********** CONSUME CB START PLAYING  %@",ds.segment.mediaURL);
#endif
                            if([blocksafeSelf enableConsume] && [[blocksafeSelf consumers] count] ){
#ifdef DSEG_DBG
                                NSLog(@"*********** SEG CB CALL CONSUME ON SEG : %@",ds.segment.mediaURL);
#endif
                                [ds setConsuming:YES];
                                [ds consume:[ blocksafeSelf myConsumeCB]                                                 consumers: [blocksafeSelf consumers]  ];
                                /*   [ds consume: [ blocksafeSelf myConsumeCB]
                                 consumeType:VIDEO_CONSUMER // VIDEO ????? REDO LATER
                                 source:[blocksafeSelf mediaConsumer]];*/
                                [doneLock unlock];
                                return;
                            }
#ifdef DSEG_DBG
                            NSLog(@"*********** CONSUME CB NOT AVIBLE TO STRAT !!! PLAYING  %@",ds.segment.mediaURL);
#endif
                        }
                    }
                    [doneLock unlock];
#ifdef DSEG_DBG
                    NSLog(@"*********** CONSUME CB NO SEG to PLAY ---> RETRY  %@");
#endif
                    [NSThread sleepForTimeInterval:.0020f];
                }
            }};
    }
    
     
    return self;
}


-(double)loadedEndTime
{
    double end = 0;
    [doneLock lock];
    @try {
        for (DataSegment* seg in [self doneSegments])
            end = MAX(end,   [[seg segment]startTime ] + [[seg segment]duration]);
    } @finally {
        [doneLock unlock];
    }
    return end;
}




-(void)addDataSegment:(DataSegment*)segment{
#ifdef DSEG_DBG
    
    NSLog(@"====>LOAD SEG :%@",segment.segment.mediaURL);
#endif
    
    [doneLock lock];
    @try {
        if(  [[self dataSegments] containsObject:segment]  ||
           [[self doneSegments] containsObject:segment])
            return;
    } @finally {
        [doneLock unlock];
    }
#ifdef DSEG_DBG
    
    NSLog(@"====>LOAD SEG :%@ STARTED ... Q:.l:%lu",segment.segment.mediaURL,[[self dataSegments] count]);
#endif
    
    [[self dataSegments]enqueue:segment];
}

-(BOOL) started{
    return [self owner]?YES : NO;
}

-(BOOL)start{
    if ([self started]) {
        return YES; //already started.
    }
    [self setOwner:(self)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Your code to execute in background...
        [self run:Nil];
    });
    /*  [self setOwner:
     [NSTimer scheduledTimerWithTimeInterval:2.0
     target:self
     selector:@selector(run:)
     userInfo:nil
     repeats:NO]];*/
    
    
    return [self started];
}
-(DataSegment*)nextToConsume
{
    
    DataSegment*next=Nil;
    
    [doneLock lock];
    @try {
        for (DataSegment* seg in [self doneSegments])
        {
            if(!seg.consumed && !seg.consuming)
            {
                next = seg;
                break;
            }
        }
    } @finally {
        [doneLock unlock];
    }
    
    
    return next;
}
-(void)run:(NSTimer *)timer0
{
    
    
    SEND_NOTIFICATION_MSG(BUFFERING_MSG_KEY,[NSNumber numberWithBool:YES]);
    
    while([self started])
    {
        @try {
            
            if ( [[self dataSegments]count] == 0 &&
                [self listener] &&
                [[self listener] getStreamCount]){
                [[self listener] onTransferEnd:self];
            }
            [self setDataSegment: [[self dataSegments] dequeue]]; //waiting fo the next.
            if(![[self listener] getStreamCount])
                [[self listener] onTransferStart:self];
            
        } @catch (NSException *exception) {
            NSLog(@"SegmentLoader task interrupted.");
            break;
        } @finally {
        }
        //syn load here .
        
        
        if(  [[self dataSegment] load])
        {
#ifdef DSEG_DBG
            
            NSLog(@"*********** SEG LOAD DONE:%@",[[[self dataSegment]segment] mediaURL] );
#endif
            [[self listener] onBytesTransferred:self transferred:[[[self dataSegment] data] length]];
            // static BOOL CONS = NO; //1st time....
            
            if(_firstConsumed ||
               ([self loadedEndTime] >= (double)DEFAULT_MIN_DURATION_FOR_QUALITY_INCREASE_MS/1000.f)    /* ++   _loadedSeg>MIN_SEG_BEFORE_PLAY*/)
                
            {
                //MIN_SEG_BEFORE_PLAY
                
                
#ifdef DSEG_DBG
                NSLog(@"*********** SEG LOOP  CALL CONSUMERS NB:%lu  ; consume is enabled :%i, nb.done:%lu;; CONS=%i ", [[self consumers] count],  [self enableConsume], [[self doneSegments] count],_firstConsumed);
                
#endif
                if(!_firstConsumed&& [self enableConsume] &&  [[self consumers] count]){
                    _firstConsumed=YES;
#ifdef DSEG_DBG
                    NSLog(@"*********** SEG LOOP  CALL CONSUME ON SEG ");
#endif
                    DataSegment*toConsume=[self nextToConsume];
                    if(toConsume)
                    {
                        [toConsume setConsuming:YES];
                        [toConsume consume:_myConsumeCB
                                 consumers: [self consumers]];
                    }
                    else{
                        
#ifdef DSEG_DBG
                        
                        
                        NSLog(@"*********** NO seg to consume ");
#endif
                    }
                    
                    //PLAYPOS_MSG_KEY
                }
                //  NSLog(@"*********** SEG LOOP  LOADED DONE ");
            }
        }else{
            //PLAY_FAILLURE_MSG_KEY
            SEND_NOTIFICATION_MSG(PLAY_FAILLURE_MSG_KEY,
                                  ([ NSString stringWithFormat: @"Segment loader was not able to load segment:%@",[[self dataSegment]segment]]));
            
        }
        
        
        
        [doneLock lock];
        @try {
            [[self doneSegments] addObject:[self dataSegment]];
        }  @finally {
            [doneLock unlock];
        }
    }
}
-(void)clear{
    if(_dataSegments)
        [_dataSegments clear];
    if(_doneSegments)
        [_doneSegments removeAllObjects];
}
-(BOOL)stop
{
#ifdef DSEG_DBG
    NSLog(@"*********** SEG LOOP  STOP ");
#endif
    
    BOOL ret = YES;
    if([self started])
        [self setOwner:Nil];
    
    /* if([self started] && [self owner]){
     @try {
     [[self owner] invalidate];
     } @catch (NSException *exception) {
     NSLog( @"%@", [NSString stringWithFormat:@"Error durring sengment loader stop: %@",exception]);
     ret=NO;
     } @finally {
     [self setOwner:Nil];
     }
     }*/
    return ret;
}

-(void)purgeDoneSegmentsAfterTime:(NSTimeInterval)timeSec
{
    [doneLock lock];
    @try {
        if(![[self doneSegments] count])
            return;
        
        NSMutableSet<DataSegment*>* rm = [NSMutableSet new];
        
        for (DataSegment* seg in [self doneSegments])
            if(  ( [[seg segment]startTime ] + [[seg segment]duration])< timeSec )
                [rm addObject:seg];
        if([rm count])
            for (DataSegment* seg in rm){
                [[self doneSegments] removeObject:seg];
                seg.data = Nil;
            }
        rm = Nil;
    } @finally {
        [doneLock unlock];
    }
}
-(void)setTypedConsumer:(id<MediaConsumer>) mediaConsumer{
    if(![self consumers])
        [self setConsumers:[NSMutableDictionary new]];
#ifdef DSEG_DBG
    
    NSLog(@" #### SEG LOADER ADD CONSUMER TYPE : %lu o:%@ ",[mediaConsumer type], mediaConsumer);
#endif
    if(!mediaConsumer)
        return;
    NSNumber *k = [NSNumber numberWithUnsignedInteger:[mediaConsumer type]];
    [self consumers][k] = mediaConsumer;
    
}

-(BOOL)segmentAtIndexIsLoaded:   (NSUInteger)index
{
    BOOL loaded = NO;
    
    
    [doneLock lock];
    @try {
        if([[self dataSegments] containsObjectWithCond:^BOOL(id obj) {
            return ([[((DataSegment*) obj) segment] number]== index) ? YES : NO;
        }])
            loaded = YES;
        else
            for (DataSegment* ds in [self doneSegments])
                if( ([[ds segment] number]== index) )  {
                    loaded = YES;
                    break;
                }
    } @finally {
        [doneLock unlock];
    }
    return loaded;
}



@end
/*
 
 -(BOOL)start;
 -(BOOL)stop;
 -(void)clear;
 -(void)purgeDoneSegmentsAfterTime:(NSUInteger)timeMs;
 -(BOOL)segmentAtIndexIsLoaded:(NSUInteger)index;
 */
