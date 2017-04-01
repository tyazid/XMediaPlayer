//
//  ViewController.m
//  H624OwnPlayer
//
//  Created by tyazid on 17/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "ViewController.h"
#import "HttpDataSource.h"
#import "TsExtractor.h"
#import <AVFoundation/AVFoundation.h>
#import "AbrLoader.h"
#import "XPlayerLayer.h"
#import "XPlayer.h"
#import "XPCore.h"
#import "ABRKeys.h"
#import "ABRStat.h"
 

/*****************************************************************************/

@interface  DetailledStat :CALayer
-(instancetype)initWithBound:(CGRect) bounds;
@end
@interface DetailledStat()
@property CATextLayer* text;

-(void) activate;
-(void)unactivate;


@end
@implementation DetailledStat
-(instancetype)initWithBound:(CGRect)parentBounds
{
    if(self = [super init])
    {
        self.frame=CGRectMake(parentBounds.size.width/2, 40, parentBounds.size.width/2 , parentBounds.size.height-100);
        [self setBackgroundColor : [[UIColor blackColor] CGColor]];
        [self setOpacity:0.5f];
        [self setText:[[CATextLayer alloc] init]];
        [[self text] setFrame:CGRectMake(0, 0, parentBounds.size.width/2 , parentBounds.size.height-100)];
        [[self text] setFontSize:13];
        [[self text]  setForegroundColor:[[UIColor whiteColor] CGColor]];
        [[self text] setString:@"Detailled stat info:"];
        [self addSublayer:[self text]];
        
    }
    return self;
}

-(void)dealloc
{
    [self unactivate];
}
-(void)activate{
    REGISTER_NOTIFICATION_RECEIVER_GEN(NOTIFICATION_SMARTABR_CENTER_NAME);
    
}
-(void)unactivate{
    UNREGISTER_NOTIFICATION_RECEIVER;
    
}


RECEIVE_NOTIFICATION_METHOD_IN

{
    NSLog(@"------------------------->>>>> STAT EVENT : %@",notification.userInfo);

    
   GET_RECEIVED_NOTIFICATION_VALUE(ABRStat,SVQN_STAT_EVENT_NAME,stat);
    NSLog(@"------------------------->>>>> STAT EVENT.DICO : %@",stat);
    if(stat){//isBuffering
 
        [[self text] setString:[NSString stringWithFormat: @"Detailled stat info:\n%@", [stat description]]];
        [CATransaction lock];
        [CATransaction commit];
        [CATransaction unlock];
    }
}


RECEIVE_NOTIFICATION_METHOD_OUT
@end


/*****************************************************************************/

@interface ViewController ()
 
@property DetailledStat* detailledStat;

@property (nonatomic, retain) IBOutlet UISwitch *smartAbrSwitch;
@property XPlayerLayer* playerLayer;
@property XPlayer* player;
 //@property (strong )AbrLoader* abrLoader;
//-(void) prepareVideoLayer;
//-(void)setupTimebase : (NSUInteger) ms;
-(void)toast:(NSString*)msg duration:(NSUInteger) dur;
@end

@implementation ViewController

 
-(BOOL)shouldAutorotate{return NO;}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationLandscapeLeft;
}

-(void)toast:(NSString*)msg duration:(NSUInteger) dur
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [self presentViewController:alert animated:YES completion:nil];
    int duration = dur; // duration in seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
   
    
    NSLog(@" IN VIEW @viewDidLoad@:%@; BASE URL:%@",[self asset], [self baseUrl]);
    
    [self setPlayer:[[XPlayer alloc] init]];
    if([self asset]&& [self baseUrl])
    {
        NSLog(@" IN VIEW CTRL ASSET:%@; BASE URL:%@",[self asset], [self baseUrl]);
        [[self player] setLoopMode:YES];
      //  [self setPlayerLayer:[[XPlayerLayer alloc] initLayerWithPlayer:[self player] andBounds:self.view.bounds ] ];
        
        //
        [self setPlayerLayer:[[XPlayerLayer alloc] initLayerWithPlayer:[self player]  andBounds:self.view.bounds withWaitingAnimSupport:YES]];
        [[[self view] layer] addSublayer:[self playerLayer]];
        [[self player]setPlayerDelegate:self];
        [[self player ] prepare:[self baseUrl] asset:[self asset]];
    

        
        [self setDetailledStat:[[DetailledStat alloc]initWithBound:self.view.bounds  ]];
       
       // [[self playerLayer] addSublayer:[self detailledStat]];
        

        
         [[self detailledStat] activate];
        
     }
}


-(void) viewDidDisappear:(BOOL)animated{
    NSLog(@" IN VIEW  @viewDidDisappear@" );
    [[self detailledStat] unactivate];

    [[self playerLayer] removeFromSuperlayer];
    [[self playerLayer]releasePlayerLayer];
     [[self detailledStat] removeFromSuperlayer];

  //  [[[self view] layer] addSublayer:[self playerLayer]];

    [self setPlayerLayer:Nil];
    [[self player] tearDown];

    [self setPlayer:Nil];
     [self setDetailledStat:Nil];
    
 
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void) prepareVideoLayer
{
    // [self setupSampleBufferDisplayLayer];
    // [[self videoLayer] setNeedsDisplay];
    
}

-(void) onLoadingChanged:(BOOL)isLoading{
  //  NSLog(@"-------------- NOTIF FROM PLAYER : onLoadingChanged :%i ", isLoading);
}
-(void) onTimeBaseChanged:(NSTimeInterval)timeBase totalDuration:(NSTimeInterval)duration
{
  //  NSLog(@"-------------- NOTIF FROM PLAYER : onTimeBaseChanged :%lf/%lf , player-layer dur:%lf, speed:%f, t-offset:%lf, fill-mode:%@",
    //      timeBase, duration,[[self playerLayer] duration],[[self playerLayer]speed], [[self playerLayer]timeOffset], [[self playerLayer]fillMode]);
    
}

-(void) onPlayerError:(NSString*) error{
    NSLog(@"-------------- NOTIF FROM PLAYER : onPlayerError :%@ ", error);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Player Error."  message:error preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        
        dispatch_queue_t queue = dispatch_queue_create("XMediaPlayer.demo", NULL);
        dispatch_async(queue, ^{
            //code to be executed in the background
            dispatch_async(dispatch_get_main_queue(), ^{
                UIViewController *main=self.navigationController.viewControllers[0];
                [self.navigationController popToViewController:main animated:YES];
            });
        });
        

    }];
    [alertController addAction:ok];
    
    [self presentViewController:alertController animated:YES completion:Nil];
    
   
    
    
}
-(void) onPlayerStateChanged:(BOOL)isReady state:(XPlayerState)playbackState
{
   // NSLog(@"-------------- NOTIF FROM PLAYER : onPlayerStateChanged :isReady=%i ; playbackState: ", isReady);
    switch (playbackState) {
        case STATE_BUFFERING:
            NSLog(@"\t STATE_BUFFERING");
        {
         /*    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.center = CGPointMake(400, 400);
           // spinner.tag = 12;
            //[self.view  addSubview:spinner];
            //[[self view] bringSubviewToFront:spinner];
            [spinner setColor:[UIColor redColor]];

            [[self playerLayer]  addSublayer:[spinner layer]];
            
            [[spinner layer] setZPosition:1000];
             [spinner startAnimating];*/
           // NSLog(@"\t WAIT ANIM STARTED. pos:%f/%f",[[spinner layer]zPosition], [[self playerLayer] zPosition]);

            
      
             //[spinner release];
        }
            break;
        case STATE_ENDED:
            NSLog(@"\t STATE_ENDED");
            
            break;
        case STATE_IDLE:
            NSLog(@"\t STATE_IDLE");
            
            break;
        case STATE_READY:
            NSLog(@"\t STATE_READY");
            [[self player] setPlayWhenReady:TRUE];
            [self toast:[NSString stringWithFormat:@"Start Player-ABR . ASSET :%@",[self asset]] duration:3];
            
 
            NSLog(@"\t STATE_READY --> POS:%lf",[[self player] playerPosition]);
            
            break;
        default:
            break;
    }
    
}
-(void) onPlayerReleased{
    NSLog(@"\t Player is now released.");

}
/*[self setPlayer: [[XPlayerLayer alloc]initLayerWithPlayer:[XPlayer new] andBounds:self.view.bounds]];
 TsExtractor* tsExtractor0 = [TsExtractor new];
 [tsExtractor0 setMediaConsumer:VIDEO_CONSUMER source:self];
 NSURL* url =[NSURL URLWithString:URL];
 [tsExtractor0 setData:[NSData dataWithContentsOfURL:url]];
 
 */

@end
