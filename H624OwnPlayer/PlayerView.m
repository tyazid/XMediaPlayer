//
//  PlayerView.m
//  XMediaPlayer
//
//  Created by tyazid on 20/02/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "PlayerView.h"

// PlayerView.m
@implementation PlayerView
- (XPlayer *)player {
    return self.playerLayer.player;
}

- (void)setPlayer:(XPlayer *)player {
    self.playerLayer.player = player;
}

// Override UIView method
+ (Class)layerClass {
    return [XPlayerLayer class];
}

- (XPlayerLayer *)playerLayer {
    return (XPlayerLayer *)self.layer;
    
}

-(void) setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [[self playerLayer] setBounds:bounds withWaitingAnimSupport:YES];
    
}
@end
