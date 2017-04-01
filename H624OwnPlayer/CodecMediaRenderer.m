//
//  CodecMediaRenderer.m
//  XMediaPlayer
//
//  Created by tyazid on 25/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "CodecMediaRenderer.h"

@implementation CodecMediaRenderer
-(instancetype)initWithType:(MediaConsumerType)type
{
     if(self = [super init])
     {
         _type = type;
     }
    return self;
}
-(CMTime*)getClock{
    return Nil;
}
@end
//@property (strong,nonatomic) AVSampleBufferDisplayLayer* videoLayer;
