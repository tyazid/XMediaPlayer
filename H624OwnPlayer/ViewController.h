//
//  ViewController.h
//  H624OwnPlayer
//
//  Created by tyazid on 17/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "XPCore.h"
#import "XPlayer.h"
@interface ViewController : UIViewController<XPlayerDelegate>
//@property (strong,nonatomic) AVSampleBufferDisplayLayer* videoLayer;
//@property (strong, nonatomic) UIWindow *window;
//@property (nonatomic, readonly) MediaConsumerType type;
 
@property NSString*baseUrl;
@property NSString*asset;
 
@end

