//
//  XPlayer.m
//  XMediaPlayer
//
//  Created by tyazid on 26/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//
#import "XPUtil.h"
#import "XPlayer.h"

#import "M3U8Kit.h"
#import "AbrLoader.h"
#import "ABRKeys.h"

//        [self addObserver:self forKeyPath:@"startLoad" options:NSKeyValueObservingOptionNew context:startLoadContext];

@interface XPlayer()
{
@private
    NSString* previousUrl;
@private
    XTimer prepTimer;
@private
    M3U8PlaylistModel* model;
@private
    AbrLoader* abrLoader;
@private
    NSMutableDictionary<NSNumber*,  id<MediaConsumer>> *consumers;
@private
    SupportedMediaType currentType;
@private
    NSDictionary* extraConfig;
@private BOOL preparing;
@private BOOL isBuffering;
    
    
}
@property NSMutableSet< id<XPlayerDelegate> >* delegates;
-(void)internalStartStop;
-(void)tearDown;
-(void) dispatchFaillureEventToDelegats:(NSString*)errMsg;
-(void) dispatchTimePosEventToDelegats:(double)position;
-(void) dispatchBufferingEventToDelegats:(BOOL)buffering;
-(void) dispatchEndedEventToDelegats;

@end
@implementation XPlayer
static double lastPos ;
static double very1stPos ;
BOOL paused;
NSTimeInterval t0, pos;
static void *startStopToggleCtx = &startStopToggleCtx;

-(instancetype)init
{
    
    [XPUtil initialize];
    
    if(self = [super init])
    {
        lastPos =very1stPos = -1.f;
        previousUrl=Nil;
        _playWhenReady=NO;
        _playing = paused = _loopMode = NO;
        t0=pos=0.f;
        currentType = NOT_SUPPORTED_MEDIA;
        consumers=[NSMutableDictionary new];
        
        extraConfig=Nil;
        [self setDelegates:[NSMutableSet new]] ;
        [self addObserver:self forKeyPath:@"playWhenReady" options:NSKeyValueObservingOptionNew context:startStopToggleCtx];
        
       // REGISTER_NOTIFICATION_RECEIVER_GEN(XPL_NOTIF_CENTER_NAME);
        REGISTER_NOTIFICATION_RECEIVER;
    }
    return self;
}
-(void)dealloc{
    UNREGISTER_NOTIFICATION_RECEIVER;
    [[self delegates] removeAllObjects];
    [self tearDown];
}

-(void)setPlayerDelegate:(id<XPlayerDelegate>)playerDelegate
{
    [[self delegates]addObject:playerDelegate];
}



//double position
-(void) dispatchFaillureEventToDelegats:(NSString*)errMsg{
    for (id<XPlayerDelegate> d in [self delegates])
         [d onPlayerError:errMsg];
}

-(void) dispatchTimePosEventToDelegats:(double)position{
    for (id<XPlayerDelegate> d in [self delegates]){
             [d onTimeBaseChanged:position totalDuration:_duration];
    }
}

-(void) dispatchBufferingEventToDelegats:(BOOL)buffering{
    for (  id<XPlayerDelegate> d in [self delegates]){
         if(buffering)
          [d onPlayerStateChanged:NO state:STATE_BUFFERING];
        else
          [d onPlayerStateChanged:NO state:STATE_READY];
    }
}


-(void) dispatchEndedEventToDelegats{
    for (  id<XPlayerDelegate> d in [self delegates]){
             [d onPlayerStateChanged:YES state:STATE_ENDED];
    }
}

//dispatchEndedEventToDelegats

RECEIVE_NOTIFICATION_METHOD_IN


if([[self delegates] count])
{
 
    {
    GET_RECEIVED_NOTIFICATION_VALUE(NSNumber,BUFFERING_MSG_KEY,buffering);
    
    if(buffering  ){//isBuffering
        BOOL vb = [buffering boolValue];
         if(vb ^ isBuffering){
            NSLog(@"**************** MSG BUFFERING SEND  EVT :: %i,// %i == %i",vb, isBuffering,(vb ^ isBuffering) );
            isBuffering = vb;
            [self dispatchBufferingEventToDelegats:vb];
        }
      }
    }
    
    {
    GET_RECEIVED_NOTIFICATION_VALUE(NSNumber,PLAYPOS_MSG_KEY,pos);
    if(pos){
        double position = [pos doubleValue];
        very1stPos = very1stPos == -1.f? position : very1stPos;
        if(lastPos == -1.f || (position - lastPos >=.987f))
        {
            [self dispatchTimePosEventToDelegats:position-very1stPos];
             lastPos = position;
        }
     }
    }
    
    
    {
    //PLAY_FAILLURE_MSG_KEY
        GET_RECEIVED_NOTIFICATION_VALUE(NSString,PLAY_FAILLURE_MSG_KEY,error);
        if(error){
            [self tearDown];
            [self  dispatchFaillureEventToDelegats:error];
        }
    }
    
    
    //PLAY_EOS_MSG_KEY
    {
        //PLAY_FAILLURE_MSG_KEY
        GET_RECEIVED_NOTIFICATION_VALUE(NSString,PLAY_EOS_MSG_KEY,eos);
        if(eos){
            [self pause:NO];
            [self  dispatchEndedEventToDelegats];
            //STATE_ENDED
        }
    }
    
}

RECEIVE_NOTIFICATION_METHOD_OUT


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSLog(@"XPLayer#observeValueForKeyPath :%@ ctx:%p",keyPath, context);
    if (context == startStopToggleCtx) {
        NSLog(@"observeValueForKeyPath change :%@",  change);
        if([keyPath isEqualToString:@"playWhenReady"] )
            [self internalStartStop];
    }else
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
}


-(void)internalStartStop
{
    
    
    if (_playWhenReady && !_playing) {
        NSLog(@"internalStartStop _playWhenReady :%i _playing:%i --> START ",  _playWhenReady,_playing);

        [self startPlay];
        
    }else if (!_playWhenReady && _playing) {
        NSLog(@"internalStartStop _playWhenReady :%i _playing:%i --> STOP ",  _playWhenReady,_playing);

        [self stopPlay];
        
    }
    
    
}


-(void)stopPlay
{
    NSLog(@"-------------- >>STOP PLAYER abrLoader ixists:%i ",abrLoader?YES:NO);
    
    _playing=NO;
    paused=NO;
    if(abrLoader)
        abrLoader.startLoad=NO;
    
}
-(void)startPlay
{
    NSLog(@"-------------- >>START PLAYER paused:%in currentType:%lu",paused,currentType);
    
    t0 = [XPUtil systemUpTime];
    if(paused){
        t0-=pos;
        paused = _stalled= NO;
    }else{
        if(currentType == NOT_SUPPORTED_MEDIA)
            @throw   [NSException
                      exceptionWithName:NSInternalInconsistencyException
                      reason: [NSString stringWithFormat:@"Player is not prepared"]
                      userInfo:nil];
        
        
        //#import "DefaultBandwidthMeter.h"
        NSLog(@"-------------- >>START PLAYER(ABR LOADER : %@) ", abrLoader);
        if(abrLoader){
            abrLoader.startLoad=YES;
        }
        
    }
    
    _playing = YES;
    
    
    
    
    
}
 -(void) pause:(BOOL)stalled

{
    // NSLog(@"-------------- PAUSE PLAYER ");
    
    [self playerPosition];
    paused = YES;
    _stalled = stalled;
}

-(void)loop
{
    // NSLog(@"-------------- LOOP PLAYER ");
    
    if(!_playing)
        return;
    t0=[XPUtil systemUpTime];
}

-(NSTimeInterval)playerPosition{
    // NSLog(@"-------------- POS PLAYER playing = %i",_playing);
    
    if(!_playing)
        return 0;
    if(!paused)
        pos = [XPUtil systemUpTime] - t0;
    return pos;
}
-(void)tearDown
{
    
    
    @try {[self stopPlay];}
    @catch (NSException *exception) {
        NSLog(@"WARN: Err during player stop:%@",exception);
    }
    @finally {
        @try {
            if(preparing)
            [XPUtil cancelTimer:prepTimer];}
        @catch (NSException *exception) { NSLog(@"WARN: Err during player prep  timer stop:%@",exception);}
        @finally {
            @try {
                if(consumers)
                    [consumers removeAllObjects];
            } @catch (NSException *exception) { NSLog(@"WARN: Err during player purge consumers:%@",exception); }
            @finally {
                if([self delegates])
                    [[self delegates]removeAllObjects];
             }
         
        }
    }
   

    consumers = Nil;
    extraConfig=Nil;
    SEND_NOTIFICATION_MSG(PLAYER_TEARED_DOWN_MSG_KEY, @"");
    
}
-(BOOL)isSupportedUrl:(NSString*)url{
    return (url &&  [XPUtil isSupportedURL:url] != NOT_SUPPORTED_MEDIA);
}

-(void)setMediaConsumer:(id<MediaConsumer>)mediaConsumer
{
    @synchronized (self) {
        
        NSLog(@"### SET PLAYER WITH MEDIA CONSUMER TYPE : %ld; PREPARED:%i", (long)[mediaConsumer type], currentType != NOT_SUPPORTED_MEDIA);
        if(currentType == NOT_SUPPORTED_MEDIA){
            NSNumber *k = [NSNumber numberWithUnsignedInteger:[mediaConsumer type]];
            consumers[k] = mediaConsumer;
        }else {
            if(abrLoader)
                [abrLoader setMediaConsumer:mediaConsumer];
        }
    }
}
-(id<MediaConsumer>)getMediaConsumerForType :(MediaConsumerType) type
{
    @synchronized (self) {
        return [consumers objectForKey:[NSNumber numberWithUnsignedInteger:type]];
    }
}

-(SupportedMediaType) getCurrentMediaType{
    
    return currentType;
}
/*
 1./  @"abr.vqan.delta.note" --> float 0..5
 */
-(void)setExtraConfiguration:(NSDictionary*)config{
    if(config){
        if(currentType != NOT_SUPPORTED_MEDIA){
            
             
            if([config objectForKey:BANDWIDTH_FRACTION])
                
            {
                float bf = [config[BANDWIDTH_FRACTION] floatValue];
                
                if(abrLoader && [abrLoader selector])
                    [[abrLoader selector] setBandwidthFraction:bf];
            }
            
        }else
            extraConfig = config;
    }
}

-(id<XPlayerDelegate>) playerDelegate{
    return [[self delegates] count]? [[self delegates] anyObject]:Nil;
}

/**
 *
 **/
-(void)prepare:(NSString*)baseUrl asset:(NSString*)assetUrl

{
    @synchronized (self)
    {
        preparing = YES;
        NSString*url = [XPUtil concatUrl:baseUrl asset:assetUrl];
        
        if(![self isSupportedUrl:assetUrl])
            @throw   [NSException
                      exceptionWithName:@"UrlNotSupported"
                      reason: [NSString stringWithFormat:@"Url not supported : %@",assetUrl]
                      userInfo:nil];
        
        if(previousUrl)
        {
            if( [previousUrl isEqualToString:url])
                return;
            [self tearDown];
        }
        
        previousUrl = url;
        SupportedMediaType supportedType = [XPUtil isSupportedURL:url];
        if(supportedType == ABR_MEDIA){
            
            prepTimer= [XPUtil startTimer:0 dispatch:^(void){
                isBuffering=NO;

                 for (id<XPlayerDelegate> d in [self delegates])
                     [d onPlayerStateChanged:NO state:STATE_BUFFERING];

                @try {
                    
                    
                    NSError *error;
                    NSString *str = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:&error];
                    if (error) {
                        NSLog(@"error: %@", error);
                        //NOTIFY ERROR
 
                      SEND_NOTIFICATION_MSG(PLAY_FAILLURE_MSG_KEY,
                      ([NSString stringWithFormat:@"error when reparing player: %@; when trying to load %@", error,url]) );
                        
                      
                        return ;
                    }
                    
                    NSLog(@"##MAIN LIST: \n%@", str);
                    NSLog(@"baseURL: %@", baseUrl);
                    NSLog(@"Asset: %@", assetUrl);
                    
                    model = [[M3U8PlaylistModel alloc] initWithString:str baseURL:baseUrl error:NULL];
                    if(!model ){
                        NSLog(@">> DATA MODEL KO");
                        
                        SEND_NOTIFICATION_MSG(PLAY_FAILLURE_MSG_KEY,  ([NSString stringWithFormat:@"error, cannot create data model for url: %@", url]) );
                       
                        return ;
                    }
                    
                    
                    //compute totla duration;
                    //duration
                    if(model.playLists && [model.playLists count])
                    {
                        NSTimeInterval durarion=0.f;
                        M3U8SegmentInfoList* segs =   model.playLists[0].segmentList;
                        for (int i=0; i<segs.count; i++){
                            durarion+=[segs segmentInfoAtIndex:i].duration;
                        }
                        _duration=durarion;

                    }
                      NSLog(@">> DATA MODEL OK , Player duration:%lf",_duration);
                  //  _smartAbr = [model svqMap] && [[model svqMap] count]? YES:NO;
                   // NSLog(@">> SvQ MAP : %s",_smartAbr? "OK" : "KO");
                    
                  //  NSLog(@">> SvQ MAP : %@", [model svqMap]  );
                    
                    DefaultBandwidthMeter  * meter = [[DefaultBandwidthMeter alloc] init];
                    //[player setLoopMode:YES];
                    abrLoader= [[AbrLoader alloc] initWith:model andPlayer:self bandwidthMeter:meter andConsumer:Nil];
                    
                    previousUrl = url;
                    
                    currentType = supportedType;
                    
                    [self setExtraConfiguration:extraConfig];//set pending extra config.
                    BOOL hasConsumers= NO;
                    @synchronized (self) {
                        hasConsumers = [consumers count]?YES:NO;
                        if(consumers){
                            for (id<MediaConsumer> consumer in [consumers allValues])
                                [abrLoader setMediaConsumer:consumer];
                        }
                        [consumers removeAllObjects];
                    }
                    
                    for (id<XPlayerDelegate> d in [self delegates])
                           [d onPlayerStateChanged:hasConsumers state:STATE_READY];
                   
                } @finally {
                    [XPUtil cancelTimer:prepTimer];
                }
            }];
            
            
        }
        
        
    }
    //has previous
    //!= from the new --> stop all
    
}

@end
