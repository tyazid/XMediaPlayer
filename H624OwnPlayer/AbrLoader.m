//
//  AbrLoader.m
//  XMediaPlayer
//
//  Created by tyazid on 29/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "AbrLoader.h"
#import "M3U8SegmentInfo.h"
#import "TrackSelector.h"
#import "SegmentLoader.h"

#import "XPUtil.h"
#import "ABRKeys.h"
/*#define ABR_DBG*/
@interface AbrLoader()
@property(nonatomic,strong) SegmentLoader* segmentLoader ;
@property M3U8SegmentInfo* previous;
@property NSTimeInterval playbackPositionUs;
@property(nonatomic,strong) M3U8PlaylistModel* abrData ;
@property(nonatomic,strong) XPlayer* player ;

-(void)performStartStop;
-(void)runTask;
@end
@implementation AbrLoader
id timer;
NSUInteger formatIndex;
NSUInteger maxSeg;
BOOL loading = NO;
//BOOL svqMode=NO;
//M3U8SegmentInfo* previous;
static void *startLoadContext = &startLoadContext;




/****** INIT ****/
-(instancetype)
initWith:(M3U8PlaylistModel*)model
andPlayer:(XPlayer*)player
bandwidthMeter:(DefaultBandwidthMeter*)meter
andConsumer:(id<MediaConsumer>) mediaConsumer{//Meter
    if(self = [super init])
    {
        _abrData = model;
        _previous=Nil;
        _player=player;
        timer=Nil;
        _selector=[[TrackSelector alloc] initWithModel:model andBandWidthMeter:meter];
        [self addObserver:self forKeyPath:@"startLoad" options:NSKeyValueObservingOptionNew context:startLoadContext];
        ///// SEGMENT LOADER
        _segmentLoader=[[SegmentLoader alloc] initWithBandwidthMeter:meter];
        [self setMediaConsumer:mediaConsumer];
        
#ifdef ABR_DBG
        NSLog(@"@@@@@@ AbrLoader CTOR PLAYER:%@ ",player);
#endif
        
    }
    
    return self;
}


-(void)setMediaConsumer :(id<MediaConsumer>) mediaConsumer
{
#ifdef ABR_DBG
    NSLog(@"ABR LOADER: receives consumer TYPE :%lu Weh  _segmentLoader is ok:%i",[mediaConsumer type], _segmentLoader?YES:NO);
#endif
    if(_segmentLoader)
        [ [self segmentLoader] setTypedConsumer:mediaConsumer];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
#ifdef ABR_DBG
    NSLog(@"observeValueForKeyPath :%@ ctx:%p",keyPath, startLoadContext);
#endif
    
    // make sure we don't interfere with other observed props
    // and check the context param
    if (context == startLoadContext) {
#ifdef ABR_DBG
        NSLog(@"observeValueForKeyPath change :%@",  change);
#endif
        
        [self performStartStop];
    }else
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
}
-(void)performStartStop{
    NSLog(@"*********** ABR LOADER /START/STOP:%i ",_startLoad);
    
#ifdef ABR_DBG
    NSLog(@"performStartStop : ");
#endif
    if(_startLoad){
        formatIndex  = NSUIntegerMax;
        maxSeg = NSUIntegerMax;
        NSLog(@"######### ABR LOADER WILL START SEGLOADER : ");
        [[self segmentLoader] start];
        
        timer=self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //Your code to execute in background...
            SEND_NOTIFICATION_MSG(BUFFERING_MSG_KEY,[NSNumber numberWithBool:YES]);

            while(timer){
                
                [self runTask];
                [NSThread sleepForTimeInterval:0.3f];
                
            }
        });
        
        /* timer = [XPUtil startTimer:0.3f dispatch:^{
         
         [self runTask];
         
         }];*/
    }else {
        [[self segmentLoader] stop];
        timer=Nil;
        
        
        // [XPUtil cancelTimer:timer];
        // running ///started
        //join with //starting
    }
}

-(void)runTask
{
#ifdef ABR_DBG
    NSLog(@"TASK RUN ------ IN");
#endif
    

    
    if (formatIndex == NSUIntegerMax) {
        formatIndex  = (NSInteger)[[self selector]determineMinBitrateIndex];
        
        
    }
   
    _playbackPositionUs = [[self player] playerPosition];
    //  NSLog(@">>>>>> TASK RUN ------  P O S :%lf",_playbackPositionUs);
    
    NSTimeInterval bufferedDurationUs = _previous == Nil ? (double)0 :
    MAX(0.f, _previous.startTime + _previous.duration - _playbackPositionUs);
    
    if(bufferedDurationUs==0.f){
        if( [[self player] playWhenReady]){
            [[self player]pause:YES];
            [[self segmentLoader]setEnableConsume:NO ];
#ifdef ABR_DBG
            
            NSLog(@"TASK RUN ------ SET STALLED PLAYER");
#endif
            
        }
    }
    double loadedTime=[[self segmentLoader] loadedEndTime ];
#ifdef ABR_DBG
    NSLog(@"TASK RUN ------ SEG LOADED TIME : %lf ",loadedTime);
#endif
    //@property BOOL stalled;
    
    if(loadedTime> [self playbackPositionUs]
       && [[ self player] stalled])
    {
        NSLog(@"TASK RUN ------ RESUM STALLED PLAYER");
        [[self player] startPlay];
        
        [[self segmentLoader]setEnableConsume:YES ];
        
        
    }
#ifdef ABR_DBG
    NSLog(@">>>>> TASK RUN BufferedDurationUs = %lf  ; PPOS=%lf",bufferedDurationUs, _playbackPositionUs);
#endif
    
    ////no need to load if we have anought cache
    if(![[self selector] continueLoadSegs:bufferedDurationUs :loading])
        return;
    
    [[self selector] updateSelectedTrack:bufferedDurationUs];
    NSUInteger newFormatIdx = [[self selector]selectedIndex];
    BOOL switchVariant = (newFormatIdx != formatIndex);
    
    M3U8MediaPlaylist *mediaPlaylist =  _abrData.playLists[newFormatIdx];
    NSUInteger idx = [[self selector] resolveSegIndex:_previous playPos:_playbackPositionUs playlist:mediaPlaylist switched:switchVariant];
    if ((!_previous || _previous.number!=idx) &&
        ![[self segmentLoader]segmentAtIndexIsLoaded:idx])
    {
        
        if( idx != NSUIntegerMax)
        {
            maxSeg = maxSeg == NSUIntegerMax ? idx :  MAX(maxSeg, idx);
        }else
        {
            BOOL leave =NO;
            M3U8SegmentInfo* s = [mediaPlaylist.segmentList segmentInfoWithNumber:maxSeg];
            if(_playbackPositionUs >= ( s.startTime + s.duration))
            {
                [[self segmentLoader] clear];
                _previous = Nil;
                //Pause ?
                //cancel?
//#ifdef ABR_DBG
                NSLog(@"ENDOF STREAM ");
//#endif
                SEND_NOTIFICATION_MSG(PLAY_EOS_MSG_KEY, @"");

                leave = YES;
                
            }
            [[self segmentLoader] purgeDoneSegmentsAfterTime:/*leave?  */(_playbackPositionUs)];
            if(leave)
                [self setStartLoad:NO];
            
            return;
            
        }
    }
    //segmentInfoWithNumber
    M3U8SegmentInfo* bs = [mediaPlaylist.segmentList segmentInfoWithNumber:idx];
    NSInteger maxFIdx = (NSInteger)[[self selector]determineMinBitrateIndex];
    M3U8MediaPlaylist *maxMediaPlaylist =  _abrData.playLists[maxFIdx];
    M3U8SegmentInfo* mbs = [maxMediaPlaylist.segmentList segmentInfoWithNumber:idx];

    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSString stringWithFormat:@"%lu",(NSUInteger)[maxMediaPlaylist.format bandwidth]],MAX_SEG_BITRATE,
                          [NSString stringWithFormat:@"%lu",(NSUInteger)[mediaPlaylist.format bandwidth]],REQUESTED_SEG_BITRATE,
                          [NSString stringWithFormat:@"%lu",(NSUInteger)[mediaPlaylist.format  bandwidth]],APPLIED_SEG_BITRATE,
                          bs,REQUESTED_SEG,
                          bs,APPLIED_SEG,
                          mbs,MAX_SEG,
                          
                          
                          nil];
    ABRStat* stat = [[ABRStat alloc] initWithDictionary:dict];
    SEND_NOTIFICATION_MSG_GEN(NOTIFICATION_SMARTABR_CENTER_NAME,SVQN_STAT_EVENT_NAME,stat);
    
  
    //SMART OUT
    //load
    M3U8SegmentInfo* segment = [mediaPlaylist.segmentList segmentInfoWithNumber:idx];
#ifdef ABR_DBG
    NSLog(@">>############ ABRLOADER: LOAD IDX : %lu SEG : %@",idx, segment);
#endif
    
    @try {
        [[self segmentLoader]addDataSegment:[[DataSegment alloc]initWith:segment]];
     } @catch (NSException *exception) {
        NSLog(@">>############ ABRLOADER: ERROR WHEN LOADING %@", exception);
        SEND_NOTIFICATION_MSG(PLAY_FAILLURE_MSG_KEY,([ NSString stringWithFormat: @"ABRLoader loader was able to start loading segment:%@",segment]));
        return;
    } @finally {
        formatIndex = newFormatIdx;
        _previous = segment;
        
    }
#ifdef ABR_DBG
    NSLog(@"TASK RUN ------ OUT");
#endif
    [[self segmentLoader] purgeDoneSegmentsAfterTime:_playbackPositionUs];
    
}
//


@end
