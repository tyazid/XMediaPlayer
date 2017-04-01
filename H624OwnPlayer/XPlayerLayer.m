//
//  XPlayerLayer.m
//  XMediaPlayer
//
//  Created by tyazid on 26/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "XPlayerLayer.h"
#import "XPUtil.h"
#import "ABRStat.h"
#import "ABRKeys.h"

/*****************************************************************************/

@interface  WaintingAnim :CALayer
@property (nonatomic,assign) BOOL isAnimating;
@property (nonatomic,assign) BOOL hidesWhenStopped;
@property UIImage* image;
- (instancetype)initWithCenterPosition: (CGPoint) center;
- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

- (void)addRotationAnimationToLayer/*:(CALayer*)layer*/;
- (void)pauseLayer ;
- (void)resumeLayer ;

@end

/*
@interface WaintingAnim()
 @property (nonatomic,assign) BOOL isAnimating;
- (void)addRotationAnimationToLayer /;
- (void)pauseLayer:(CALayer*)layer;
- (void)resumeLayer:(CALayer*)layer;
@end
*/

@implementation WaintingAnim
@synthesize /*animationLayer,*/isAnimating;
/*****************************************************************************/

- (instancetype)initWithCenterPosition: (CGPoint) center
{
    self  = [self init];
    self.image =  [UIImage imageNamed:@"waiting"];
    
    CGFloat x = center.x - self.image.size.width/2;
    CGFloat y = center.y - self.image.size.height/2;
    self.frame=CGRectMake(x, y, self.image.size.width,self.image.size.height);
  
   self.contents = (id)[self.image CGImage];
   // self.backgroundColor = [UIColor orangeColor].CGColor;

    self .masksToBounds = YES;
    [self addRotationAnimationToLayer];
    [self pauseLayer];
    self.hidesWhenStopped = YES;
    return self;
}
/*****************************************************************************/

- (void)addRotationAnimationToLayer
{
    CABasicAnimation *rotation =
    [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.duration = 2.0;
    rotation.removedOnCompletion = NO;
    rotation.repeatCount = HUGE_VALF;
    rotation.fillMode = kCAFillModeForwards;
    rotation.fromValue = [NSNumber numberWithFloat:0.0];
    rotation.toValue = [NSNumber numberWithFloat:3.14*2];
    [self/*.animationLayer*/ addAnimation:rotation forKey:@"rotate"];
}
/*****************************************************************************/
-(void)pauseLayer
{
    CFTimeInterval pausedTime =
    [self convertTime:CACurrentMediaTime()
             fromLayer:nil];
    self.speed = 0.0;
    self.timeOffset = pausedTime;
    isAnimating = NO;
}
-(void)resumeLayer
{
    CFTimeInterval pausedTime = [self timeOffset];
    self.speed = 1.0;
    self.timeOffset = 0.0;
    self.beginTime = 0.0;
    CFTimeInterval timeSincePause =
    [self convertTime:CACurrentMediaTime()  fromLayer:nil] - pausedTime;
    self.beginTime = timeSincePause;
    isAnimating = YES;
}
- (void)startAnimating
{ if(isAnimating)return;
    NSLog(@"------------------ START ANIM ");
    if(self.hidesWhenStopped){
        [self setHidden:NO];
    }
    [self resumeLayer];
}
- (void)stopAnimating
{
    if(self.hidesWhenStopped){
        [self setHidden:YES];
    }
    [self pauseLayer ];
}
- (BOOL)isAnimating
{
    return isAnimating;
}

@end
/******************************PROG BAR*********************************/

@interface PlayerProgressBar:CALayer
-(void) setProgress :(double)persent;
-(instancetype)initWithBound:(CGRect) bounds;
@end
@interface PlayerProgressBar()
@property CAShapeLayer* baseLine, *progressLine;
@property CATextLayer* start,*end;

@end
@implementation PlayerProgressBar
-(instancetype)initWithBound:(CGRect) parentBounds
{
    if(self=[super init])
    {
        self.frame=CGRectMake(0, parentBounds.size.height - 40.f, parentBounds.size.width ,20);
        float margin=40.0f;
        [self setBaseLine:[CAShapeLayer layer]];
        [self setProgressLine:[CAShapeLayer layer]];
        [self setStart:[[CATextLayer alloc] init]];
        [self setEnd:[[CATextLayer alloc]   init]];
        [[self baseLine]     setFrame:CGRectMake(margin, 0,self.frame.size.width-2*margin,self.frame.size.height)];
        [[self progressLine] setFrame:CGRectMake(margin, 0,self.frame.size.width-2*margin,self.frame.size.height)];
        
        [[self start]   setFrame:CGRectMake(0, 0,margin,20)];
        [[self end]     setFrame:CGRectMake(self.frame.size.width-margin, 0,margin,20)];
 
        UIBezierPath *linePath=[UIBezierPath bezierPath];
        [linePath moveToPoint:CGPointMake(0, 0)];
        [linePath addLineToPoint:CGPointMake(_baseLine.frame.size.width, 0)];
        [[self baseLine] setPath:linePath.CGPath];
        [[self baseLine] setFillColor:Nil];
        [[self baseLine] setLineWidth:10.0f];
        [[self baseLine] setStrokeColor:[UIColor darkGrayColor].CGColor];
        [[self baseLine] setOpacity:0.8f];
        [[self progressLine] setStrokeColor:[UIColor redColor].CGColor];
        [[self progressLine] setLineWidth:5.0f];
        
        
        [[self start] setFontSize:13];
        [[self end] setFontSize:13];
        
        [[self start]  setAlignmentMode:kCAAlignmentLeft];
        [[self end]  setAlignmentMode:kCAAlignmentRight];
 

        [[self start]  setForegroundColor:[[UIColor whiteColor] CGColor]];
        [[self end] setForegroundColor:[[UIColor whiteColor] CGColor]];
        
        [[self start] setString:@"00:00"];
        [[self end] setString:@"00:00"];

        
        [self addSublayer:[self baseLine]];
        [self addSublayer:[self progressLine]];
        
        
        [self addSublayer:[self start]];
        [self addSublayer:[self end]];
        //init texts
        
        
        
        

        

        
       


        
        
        
        
       // self.frame=CGRectMake(x, y, self.image.size.width,self.image.size.height);
       // self.frame.origin.y,self.frame.size.width,self.frame.size.height,self.image.size.width,self.image.size.height, center.x,center.y);
        
        

    }
    return self;
}
-(void)setProgress:(double)time total:(double)duration
{
   // NSLog(@">>>>>>>>SET PROGRESS  IN");
    UIBezierPath *linePath=[UIBezierPath bezierPath];
    [linePath moveToPoint:CGPointMake(0,0 )];
    
    NSString*start=[NSString  stringWithFormat:@"%02d:%02d",  ((int)time/60) ,  ((int)time%60)];
    NSString*end=[NSString  stringWithFormat:@"%02d:%02d",  ((int)duration/60) ,  ((int)duration%60)];
    [[self start] setString:start];
    [[self end] setString:end];

    [linePath addLineToPoint:CGPointMake(_progressLine.frame.size.width*(duration!=0.f? (time/duration):0.f), 0)];
    _progressLine.path = linePath.CGPath;
 //   [self setNeedsDisplay];
//    [self displayIfNeeded];
    [CATransaction lock];
     [CATransaction commit];
  [CATransaction unlock];
    

  //  NSLog(@">>>>>>>>SET PROGRESS  OUT");

}


@end

/*****************************************************************************/

@interface XPlayerLayer()
@property BOOL hasObserver, timed,bufferNotifyed;
@property BOOL eos;
@property WaintingAnim* waitAnim;
@property PlayerProgressBar* progress;
 - (void)setupTimebase : (NSUInteger) ms;

-(void)setupDisplayLayer:(BOOL)creating withBounds:(CGRect) bounds;
-(void)enqueueSampleBuffer:(CMSampleBufferRef)buffer at: (NSUInteger) pts withDts:(NSUInteger) dts andFps:(double) fps consumerBaseTime:(NSUInteger)time;
-(void)setWaitingAnimVisible:(BOOL)visible;
@end

@implementation XPlayerLayer

-(instancetype)init
{
    if(self = [super init]){
        _type = VIDEO_CONSUMER;
        [self setBufferNotifyed:NO];
        [self setTimed:NO];
        [self setEos:NO];
        [self addObserver];


    }
    return self;
  
}
-(instancetype )initLayerWithPlayer:(XPlayer *)player
                  andBounds:(CGRect) bounds
                  withWaitingAnimSupport:(BOOL)anim{
    if(self = [self init])
    {
        [self setPlayer:player];
        [self setBounds:bounds withWaitingAnimSupport:anim];
                          //  [self addSublayer:[self progress]];
         //         [[sel deatailledStat] unactivate];
         //TODO BE LISTENER ON EXTRA SETTING  -- undate ihm


     }
    return self;
}

-(void)setBounds:(CGRect)bounds  withWaitingAnimSupport:(BOOL)anim
{
    if(anim)
    {
        CGPoint center =
        CGPointMake( bounds.size.width/2,
                    bounds.size.height/2);
        [self setWaitAnim:
         [[WaintingAnim  alloc] initWithCenterPosition:center]];
        [self addSublayer:[self waitAnim]];
    }
    [self setupDisplayLayer:YES withBounds:bounds];
    [self setProgress:[[PlayerProgressBar alloc] initWithBound:bounds] ];
    [self addSublayer:[self progress]];
    [[self progress] setProgress:0.f total:0.f];
}

-(void) setPlayer:(XPlayer *)player
{
    _player=player;
    [[self player] setPlayerDelegate:self];
    [[self player] setMediaConsumer:self];
}

-(void) onLoadingChanged:(BOOL) isLoading{}

-(void) onTimeBaseChanged:(NSTimeInterval) timeBase totalDuration:(NSTimeInterval)duration
{
 //   NSLog(@"************** TIME:%lf   **** * DUR:%lf SELF=%@, PLAYER=%@",timeBase,duration, self, _player);
       if([self eos])
        
        [[self progress] setProgress:_player.duration total:_player.duration];
       else  [[self progress] setProgress:timeBase total:duration];


}


-(void) onPlayerStateChanged:(BOOL)isReady state:(XPlayerState) playbackState{
    
    [self setWaitingAnimVisible:(playbackState == STATE_BUFFERING)];
    
    if(playbackState == STATE_ENDED)
    {
        [self setEos:YES];        [[self progress] setProgress:_player.duration total:_player.duration];

 
    }

}
-(void) onPlayerError:(NSString*) error{}

-(void) onPlayerReleased{
    @try {
        [self  flush];
        [self  stopRequestingMediaData];
    } @catch (NSException *exception) {
        
    }

}
-(BOOL)consume :(CMSampleBufferRef)buffer at: (NSUInteger) pts withDts:(NSUInteger) dts andFps:(double) fps consumerBaseTime:(NSUInteger)time
{
    
    [self enqueueSampleBuffer:buffer at:pts withDts:dts andFps:fps consumerBaseTime:time];
    
   
    return YES;
}
-(void)setWaitingAnimVisible:(BOOL)visible
{
 
    if(![self waitAnim])
        return;
    if(visible){
        [[self waitAnim] startAnimating];
    }else {
        [[self waitAnim] stopAnimating];
    }
}
-(void)releasePlayerLayer{
    if(_hasObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    if([self waitAnim])
     [[self waitAnim] removeFromSuperlayer];
    if([self progress])
        [[self progress] removeFromSuperlayer];
    [self setProgress:Nil];
    [self setWaitAnim:Nil];
    _hasObserver=NO;
    _player = Nil;
    _progress=Nil;
    _waitAnim=Nil;
}
- (void)dealloc
{    NSLog(@"###XPlayerLayer@dealloc");
    [self releasePlayerLayer];
    
}


- (void) appResignActive:(NSNotification *) notification{
    NSLog(@"###XPlayerLayer@appResignActive");
    if ([[notification name] isEqualToString:UIApplicationWillResignActiveNotification])
        [self releaseDisplayLayer];
    
    
}
- (void) appBecomeActive:(NSNotification *) notification{
    NSLog(@"###XPlayerLayer@appBecomeActive");
    
    if ([[notification name] isEqualToString:UIApplicationWillResignActiveNotification])
        [self rebuildDisplayLayer];
    
    
    
}



- (void)addObserver{
    if (!_hasObserver){
        NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver: self selector:@selector(appResignActive:)
                                   name:UIApplicationWillResignActiveNotification object:nil];
        
        [notificationCenter addObserver: self selector:@selector(appBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification object:nil];
        _hasObserver = YES;
    }
}



-(void)setupDisplayLayer:(BOOL)creating withBounds:(CGRect) bounds
{
    
    
    if (creating){
        [self setBounds:bounds];
        [self setPosition: CGPointMake(CGRectGetMidX( bounds), CGRectGetMidY( bounds))];
        [self  setVideoGravity:AVLayerVideoGravityResizeAspectFill ];//] ResizeAspect];
        [self setBackgroundColor : [[UIColor blackColor] CGColor]];
        [self setOpaque:YES];
        //[[[self view] layer] addSublayer:[self videoLayer]];
        
    }else{
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self setFrame:bounds];
        [self setPosition: CGPointMake(CGRectGetMidX( bounds), CGRectGetMidY( bounds))];
        [CATransaction commit];
    }
}
- (void)rebuildDisplayLayer{
    @synchronized(self) {
        CALayer*parent = [self superlayer];
        [self releaseDisplayLayer];
        [self setupDisplayLayer:NO withBounds:[self bounds]];
        if(parent)
            [parent addSublayer:self];
    }
    
}

- (void)releaseDisplayLayer
{
    
    [self  stopRequestingMediaData];
    [self removeFromSuperlayer];
    
}

- (void)setupTimebase : (NSUInteger) ms
{
    
    CMTimebaseRef controlTimebase  ;
    
    if(CMTimebaseCreateWithMasterClock( CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase )==0)
    {
        CMTimebaseSetTime(controlTimebase, CMTimeMake(ms, 1000));
        CMTimebaseSetRate(controlTimebase,1.f);
        [self setControlTimebase:controlTimebase];
        CFRelease(controlTimebase);
    }
    return;
    
}
-(void)enqueueSampleBuffer:(CMSampleBufferRef)buffer at: (NSUInteger) pts withDts:(NSUInteger) dts andFps:(double) fps consumerBaseTime:(NSUInteger)time
{
    if( time!=NSUIntegerMax)
    {
         if(!_timed){
            [self setupTimebase: time ];
            _timed= YES;
        }
        // NSLog(@" ----------------> DRAW FRAME @ : %lu ",pts );
        
        while(![self isReadyForMoreMediaData])
            [NSThread sleepForTimeInterval:.01];
        
        [super enqueueSampleBuffer:buffer ];
        
    }
}

@end
