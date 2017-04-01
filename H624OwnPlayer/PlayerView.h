//
//  PlayerView.h
//  XMediaPlayer
//
//  Created by tyazid on 20/02/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XPlayer.h"
#import "XPlayerLayer.h"

@interface PlayerView : UIView
@property XPlayer *player;
@property (readonly) XPlayerLayer *playerLayer;
@end
