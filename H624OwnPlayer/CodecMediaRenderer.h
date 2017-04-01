//
//  CodecMediaRenderer.h
//  XMediaPlayer
//
//  Created by tyazid on 25/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPCore.h"

@interface CodecMediaRenderer : NSObject<MediaRenderer>
@property (nonatomic) MediaConsumerType type;
 
-(instancetype) init __attribute__((unavailable("init not available")));
-(instancetype)initWithType: (MediaConsumerType)type NS_DESIGNATED_INITIALIZER;

@end
