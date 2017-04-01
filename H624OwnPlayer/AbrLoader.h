//
//  AbrLoader.h
//  XMediaPlayer
//
//  Created by tyazid on 29/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XPCore.h"
#import "M3U8PlaylistModel.h"

#import "DefaultBandwidthMeter.h"
#import "XPlayer.h"
#import "TrackSelector.h"

 @interface AbrLoader : NSObject
@property(atomic)BOOL startLoad; //toggle false to stop
@property (readonly, nonatomic,strong) TrackSelector* selector;
//@property M3U8PlaylistModel* toto;
-(instancetype)initWith: (M3U8PlaylistModel*)model andPlayer:(XPlayer*)player bandwidthMeter:(DefaultBandwidthMeter*)meter
            andConsumer:(id<MediaConsumer>) mediaConsumer;

-(void)setMediaConsumer :(id<MediaConsumer>) mediaConsumer;

-(instancetype) init __attribute__((unavailable("init not available")));

@end
