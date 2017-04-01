//
//  VideoCodecMediaRendered.m
//  XMediaPlayer
//
//  Created by tyazid on 25/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "VideoCodecMediaRendered.h"
#define WAIT4READY (.005)
@implementation VideoCodecMediaRendered
-(instancetype) init
{
    return [super initWithType:VIDEO_CONSUMER];
}
-(BOOL)consume:(CMSampleBufferRef)buffer at:(NSUInteger)pts{
    if([self videoLayer]){
        while (![[self videoLayer] isReadyForMoreMediaData])
            [NSThread sleepForTimeInterval:WAIT4READY];
         [[self videoLayer] enqueueSampleBuffer:buffer ];
        return TRUE;
    }
    return NO;
}
@end
